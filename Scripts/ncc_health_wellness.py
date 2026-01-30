#!/usr/bin/env python3
"""
NCC Campaign 9: Health and Wellness Trend Monitoring
Data Sources: Google Trends, social media health discussions, WHO data, fitness app APIs
Scraping Methodology: API-based trend data, social media monitoring, web scraping
Data Processing: Trend normalization, sentiment analysis, topic clustering
Analysis Algorithms: Trend forecasting, sentiment analysis, topic modeling
Storage: Time-series health trends database
Real-time Monitoring: Continuous trend monitoring with health alert detection
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Any
from dotenv import load_dotenv
import pandas as pd
import numpy as np
from pytrends.request import TrendReq
from textblob import TextBlob
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
import schedule

load_dotenv()

class HealthWellnessMonitor:
    def __init__(self):
        self.google_trends_api_key = os.getenv('GOOGLE_TRENDS_API_KEY')
        self.twitter_bearer_token = os.getenv('TWITTER_BEARER_TOKEN')
        self.reddit_client_id = os.getenv('REDDIT_CLIENT_ID')
        self.reddit_client_secret = os.getenv('REDDIT_CLIENT_SECRET')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'health_wellness')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Health topics to monitor
        self.health_topics = [
            'mental health', 'fitness', 'nutrition', 'meditation', 'yoga', 
            'wellness', 'diet', 'exercise', 'sleep', 'stress management'
        ]
        
        self.pytrends = TrendReq(hl='en-US', tz=360)
    
    def collect_google_trends_data(self, keywords: List[str]) -> Dict[str, Any]:
        """Collect Google Trends data"""
        trends_data = {}
        
        try:
            # Build payload for multiple keywords
            self.pytrends.build_payload(keywords, cat=0, timeframe='now 7-d', geo='', gprop='')
            interest_over_time = self.pytrends.interest_over_time
            
            if not interest_over_time.empty:
                trends_data = {
                    'interest_over_time': interest_over_time.to_dict(),
                    'top_charts': {},
                    'rising_queries': {}
                }
                
                # Get related queries for each keyword
                for keyword in keywords:
                    try:
                        related_queries = self.pytrends.related_queries()
                        if keyword in related_queries:
                            trends_data['rising_queries'][keyword] = related_queries[keyword]['rising'].to_dict() if 'rising' in related_queries[keyword] else {}
                    except:
                        pass
                        
        except Exception as e:
            print(f"Google Trends error: {e}")
            
        return trends_data
    
    def collect_social_health_discussions(self, topics: List[str]) -> List[Dict]:
        """Collect health discussions from social media"""
        discussions = []
        
        # Twitter data (simplified - using search API)
        if self.twitter_bearer_token:
            import tweepy
            client = tweepy.Client(bearer_token=self.twitter_bearer_token)
            
            for topic in topics:
                try:
                    tweets = client.search_recent_tweets(
                        query=f"{topic} -is:retweet",
                        max_results=50,
                        tweet_fields=['created_at', 'public_metrics', 'text']
                    )
                    
                    if tweets.data:
                        for tweet in tweets.data:
                            discussions.append({
                                'platform': 'twitter',
                                'topic': topic,
                                'text': tweet.text,
                                'timestamp': tweet.created_at.isoformat(),
                                'likes': tweet.public_metrics['like_count'],
                                'retweets': tweet.public_metrics['retweet_count'],
                                'replies': tweet.public_metrics['reply_count']
                            })
                except Exception as e:
                    print(f"Twitter collection error for {topic}: {e}")
        
        # Reddit data
        if self.reddit_client_id:
            import praw
            reddit = praw.Reddit(
                client_id=self.reddit_client_id,
                client_secret=self.reddit_client_secret,
                user_agent='NCC Health Monitor'
            )
            
            subreddits = ['health', 'fitness', 'nutrition', 'mentalhealth', 'yoga']
            for subreddit_name in subreddits:
                try:
                    subreddit = reddit.subreddit(subreddit_name)
                    for post in subreddit.hot(limit=10):
                        discussions.append({
                            'platform': 'reddit',
                            'topic': 'general_health',
                            'text': f"{post.title} {post.selftext}",
                            'timestamp': datetime.fromtimestamp(post.created_utc).isoformat(),
                            'score': post.score,
                            'num_comments': post.num_comments,
                            'url': post.url
                        })
                except Exception as e:
                    print(f"Reddit collection error for {subreddit_name}: {e}")
        
        return discussions
    
    def collect_health_apis_data(self) -> Dict[str, Any]:
        """Collect data from health-related APIs"""
        health_data = {}
        
        # WHO COVID-19 data (example)
        try:
            who_url = "https://covid19.who.int/WHO-COVID-19-global-data.csv"
            # Note: This would require pandas to read CSV
            # For now, placeholder
            health_data['global_health_metrics'] = {'status': 'API data collection placeholder'}
        except Exception as e:
            print(f"WHO API error: {e}")
        
        return health_data
    
    def analyze_health_trends(self, trends_data: Dict, discussions: List[Dict]) -> Dict[str, Any]:
        """Analyze health and wellness trends"""
        analysis = {
            'trend_analysis': {},
            'sentiment_analysis': {},
            'topic_clustering': {},
            'insights': []
        }
        
        # Analyze Google Trends
        if 'interest_over_time' in trends_data and trends_data['interest_over_time']:
            for keyword, data in trends_data['interest_over_time'].items():
                if isinstance(data, dict) and data:
                    values = list(data.values())
                    if values:
                        avg_interest = sum(values) / len(values)
                        max_interest = max(values)
                        trend_direction = 'rising' if values[-1] > values[0] else 'falling'
                        
                        analysis['trend_analysis'][keyword] = {
                            'average_interest': avg_interest,
                            'max_interest': max_interest,
                            'trend_direction': trend_direction,
                            'data_points': len(values)
                        }
        
        # Analyze social media sentiment
        if discussions:
            df = pd.DataFrame(discussions)
            
            # Sentiment analysis
            sentiments = []
            for text in df['text']:
                if text:
                    blob = TextBlob(text)
                    sentiments.append(blob.sentiment.polarity)
            
            df['sentiment'] = sentiments
            
            # Sentiment by topic
            sentiment_by_topic = df.groupby('topic')['sentiment'].agg(['mean', 'count']).round(3)
            analysis['sentiment_analysis'] = sentiment_by_topic.to_dict()
            
            # Topic clustering
            if len(discussions) > 10:
                texts = [d['text'] for d in discussions if d['text']]
                vectorizer = TfidfVectorizer(max_features=100, stop_words='english')
                tfidf_matrix = vectorizer.fit_transform(texts)
                
                kmeans = KMeans(n_clusters=min(5, len(texts)), random_state=42)
                clusters = kmeans.fit_predict(tfidf_matrix)
                
                feature_names = vectorizer.get_feature_names_out()
                cluster_keywords = {}
                for cluster in range(kmeans.n_clusters):
                    cluster_center = kmeans.cluster_centers_[cluster]
                    top_keywords_idx = cluster_center.argsort()[-3:][::-1]
                    cluster_keywords[f'cluster_{cluster}'] = [feature_names[idx] for idx in top_keywords_idx]
                
                analysis['topic_clustering'] = cluster_keywords
        
        # Generate insights
        insights = []
        
        # Trend insights
        if analysis['trend_analysis']:
            top_trend = max(analysis['trend_analysis'].items(), key=lambda x: x[1]['average_interest'])
            insights.append(f"Top trending health topic: {top_trend[0]} (avg interest: {top_trend[1]['average_interest']:.1f})")
        
        # Sentiment insights
        if analysis['sentiment_analysis'] and 'mean' in analysis['sentiment_analysis']:
            avg_sentiment = np.mean(list(analysis['sentiment_analysis']['mean'].values()))
            sentiment_desc = 'positive' if avg_sentiment > 0.1 else 'negative' if avg_sentiment < -0.1 else 'neutral'
            insights.append(f"Overall health discussion sentiment: {sentiment_desc} ({avg_sentiment:.3f})")
        
        analysis['insights'] = insights
        
        return analysis
    
    def detect_health_alerts(self, trends_data: Dict, discussions: List[Dict]) -> List[Dict]:
        """Detect potential health alerts or concerning trends"""
        alerts = []
        
        # Check for rapidly rising health concerns
        if 'rising_queries' in trends_data:
            for topic, rising_data in trends_data['rising_queries'].items():
                if rising_data and isinstance(rising_data, dict):
                    # Look for queries with high growth
                    for query, value in rising_data.items():
                        if isinstance(value, (int, float)) and value > 5000:  # Arbitrary threshold
                            alerts.append({
                                'type': 'rising_health_concern',
                                'topic': topic,
                                'query': query,
                                'growth_value': value
                            })
        
        # Check for negative sentiment spikes
        if discussions:
            df = pd.DataFrame(discussions)
            if 'sentiment' in df.columns:
                very_negative = df[df['sentiment'] < -0.5]
                if len(very_negative) > len(df) * 0.1:  # More than 10% very negative
                    alerts.append({
                        'type': 'negative_sentiment_spike',
                        'percentage': len(very_negative) / len(df) * 100,
                        'total_discussions': len(df)
                    })
        
        return alerts
    
    def store_data(self, trends_data: Dict, discussions: List[Dict], analysis: Dict[str, Any], alerts: List[Dict]):
        """Store health and wellness data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store trends data
        trends_file = os.path.join(self.data_dir, f'health_trends_{timestamp}.json')
        with open(trends_file, 'w') as f:
            json.dump(trends_data, f, indent=2)
        
        # Store discussions
        discussions_file = os.path.join(self.data_dir, f'health_discussions_{timestamp}.jsonl')
        with open(discussions_file, 'w') as f:
            for discussion in discussions:
                f.write(json.dumps(discussion) + '\n')
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'health_analysis_{timestamp}.json')
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2)
        
        # Store alerts
        if alerts:
            alerts_file = os.path.join(self.data_dir, f'health_alerts_{timestamp}.json')
            with open(alerts_file, 'w') as f:
                json.dump(alerts, f, indent=2)
    
    def run_health_monitoring_cycle(self):
        """Complete health monitoring cycle"""
        # Collect data
        trends_data = self.collect_google_trends_data(self.health_topics)
        discussions = self.collect_social_health_discussions(self.health_topics)
        health_api_data = self.collect_health_apis_data()
        
        # Combine trends data
        trends_data.update(health_api_data)
        
        # Analyze
        analysis = self.analyze_health_trends(trends_data, discussions)
        alerts = self.detect_health_alerts(trends_data, discussions)
        
        # Store
        self.store_data(trends_data, discussions, analysis, alerts)
        
        # Alert system
        if alerts:
            print(f"ALERT: {len(alerts)} health monitoring alerts detected")
            for alert in alerts[:3]:
                print(f"  {alert['type'].upper()}: {alert.get('topic', 'General')} - {alert.get('query', 'N/A')}")
        
        print(f"Health monitoring complete: {len(self.health_topics)} topics, {len(discussions)} discussions analyzed")
        
        return analysis

def main():
    monitor = HealthWellnessMonitor()
    
    # Run initial monitoring
    monitor.run_health_monitoring_cycle()
    
    # Schedule continuous monitoring
    schedule.every(2).hours.do(monitor.run_health_monitoring_cycle)
    
    print("Health & Wellness Monitor started. Monitoring every 2 hours...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()