#!/usr/bin/env python3
"""
NCC Campaign 1: Social Media Trend Analysis
Data Sources: Twitter/X API v2, Instagram Graph API, TikTok Research API
Scraping Methodology: API-based data collection with rate limiting
Data Processing: Text cleaning, tokenization, sentiment analysis
Analysis Algorithms: Trend detection using TF-IDF, time-series analysis, sentiment scoring
Storage: JSONL files with daily aggregation
Real-time Monitoring: Continuous API polling with alert system
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Any
from dotenv import load_dotenv
import tweepy
from textblob import TextBlob
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
import schedule

load_dotenv()

class SocialMediaTrendsAnalyzer:
    def __init__(self):
        self.twitter_bearer_token = os.getenv('TWITTER_BEARER_TOKEN')
        self.instagram_access_token = os.getenv('INSTAGRAM_ACCESS_TOKEN')
        self.tiktok_access_token = os.getenv('TIKTOK_ACCESS_TOKEN')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'social_trends')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Initialize APIs
        self.twitter_client = tweepy.Client(bearer_token=self.twitter_bearer_token) if self.twitter_bearer_token else None
        
    def collect_twitter_data(self, keywords: List[str], hours_back: int = 24) -> List[Dict]:
        """Collect Twitter data for given keywords"""
        if not self.twitter_client:
            return []
            
        data = []
        start_time = datetime.utcnow() - timedelta(hours=hours_back)
        
        for keyword in keywords:
            try:
                tweets = self.twitter_client.search_recent_tweets(
                    query=keyword,
                    start_time=start_time,
                    max_results=100,
                    tweet_fields=['created_at', 'public_metrics', 'text']
                )
                
                if tweets.data:
                    for tweet in tweets.data:
                        data.append({
                            'platform': 'twitter',
                            'keyword': keyword,
                            'text': tweet.text,
                            'timestamp': tweet.created_at.isoformat(),
                            'likes': tweet.public_metrics['like_count'],
                            'retweets': tweet.public_metrics['retweet_count'],
                            'replies': tweet.public_metrics['reply_count']
                        })
            except Exception as e:
                print(f"Twitter API error for {keyword}: {e}")
                
        return data
    
    def collect_instagram_data(self, hashtags: List[str]) -> List[Dict]:
        """Collect Instagram data (simplified - requires business account)"""
        # Placeholder for Instagram Graph API
        # In practice, would use Facebook Graph API for Instagram
        return []
    
    def collect_tiktok_data(self, keywords: List[str]) -> List[Dict]:
        """Collect TikTok data (simplified - limited API access)"""
        # Placeholder for TikTok Research API
        return []
    
    def process_data(self, raw_data: List[Dict]) -> Dict[str, Any]:
        """Process and analyze collected data"""
        if not raw_data:
            return {'trends': [], 'sentiment': {'positive': 0, 'negative': 0, 'neutral': 0}}
            
        df = pd.DataFrame(raw_data)
        
        # Sentiment analysis
        sentiments = []
        for text in df['text']:
            blob = TextBlob(text)
            polarity = blob.sentiment.polarity
            if polarity > 0.1:
                sentiments.append('positive')
            elif polarity < -0.1:
                sentiments.append('negative')
            else:
                sentiments.append('neutral')
        
        df['sentiment'] = sentiments
        
        # Trend detection using TF-IDF
        vectorizer = TfidfVectorizer(max_features=20, stop_words='english')
        tfidf_matrix = vectorizer.fit_transform(df['text'])
        feature_names = vectorizer.get_feature_names_out()
        
        # Get top trending terms
        mean_tfidf = tfidf_matrix.mean(axis=0).A1
        top_indices = mean_tfidf.argsort()[-10:][::-1]
        trends = [feature_names[i] for i in top_indices]
        
        sentiment_counts = df['sentiment'].value_counts().to_dict()
        
        return {
            'trends': trends,
            'sentiment': sentiment_counts,
            'total_posts': len(raw_data),
            'platforms': df['platform'].value_counts().to_dict() if 'platform' in df.columns else {}
        }
    
    def store_data(self, processed_data: Dict[str, Any], raw_data: List[Dict]):
        """Store raw and processed data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store raw data
        raw_file = os.path.join(self.data_dir, f'raw_social_data_{timestamp}.jsonl')
        with open(raw_file, 'w') as f:
            for item in raw_data:
                f.write(json.dumps(item) + '\n')
        
        # Store processed data
        processed_file = os.path.join(self.data_dir, f'processed_social_trends_{timestamp}.json')
        with open(processed_file, 'w') as f:
            json.dump(processed_data, f, indent=2)
    
    def run_analysis_cycle(self):
        """Complete analysis cycle"""
        keywords = ['NCC', 'AI', 'blockchain', 'crypto', 'technology', 'finance', 'innovation']
        
        # Collect data from all platforms
        twitter_data = self.collect_twitter_data(keywords)
        instagram_data = self.collect_instagram_data(keywords)
        tiktok_data = self.collect_tiktok_data(keywords)
        
        all_data = twitter_data + instagram_data + tiktok_data
        
        # Process data
        processed = self.process_data(all_data)
        
        # Store results
        self.store_data(processed, all_data)
        
        # Alert system (placeholder)
        if processed['total_posts'] > 100:
            print(f"ALERT: High activity detected - {processed['total_posts']} posts analyzed")
        
        print(f"Social media analysis complete: {processed['total_posts']} posts, top trends: {processed['trends'][:3]}")
        
        return processed

def main():
    analyzer = SocialMediaTrendsAnalyzer()
    
    # Run initial analysis
    analyzer.run_analysis_cycle()
    
    # Schedule continuous monitoring
    schedule.every(1).hours.do(analyzer.run_analysis_cycle)
    
    print("Social Media Trends Analyzer started. Monitoring every hour...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()