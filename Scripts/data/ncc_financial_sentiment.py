#!/usr/bin/env python3
"""
NCC Campaign 2: Financial Market Sentiment Analysis
Data Sources: Alpha Vantage API, Yahoo Finance, NewsAPI, Reddit API
Scraping Methodology: API calls for market data, web scraping for news, sentiment analysis
Data Processing: Text preprocessing, financial term extraction, sentiment scoring
Analysis Algorithms: VADER sentiment analysis, market correlation analysis, volatility metrics
Storage: Time-series database with daily sentiment scores
Real-time Monitoring: Continuous market data polling with alert thresholds
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Any
from dotenv import load_dotenv
import yfinance as yf
import praw
from newsapi import NewsApiClient
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import pandas as pd
import numpy as np
import schedule

load_dotenv()

class FinancialSentimentAnalyzer:
    def __init__(self):
        self.alpha_vantage_key = os.getenv('ALPHA_VANTAGE_API_KEY')
        self.news_api_key = os.getenv('NEWS_API_KEY')
        self.reddit_client_id = os.getenv('REDDIT_CLIENT_ID')
        self.reddit_client_secret = os.getenv('REDDIT_CLIENT_SECRET')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'financial_sentiment')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Initialize APIs
        self.news_api = NewsApiClient(api_key=self.news_api_key) if self.news_api_key else None
        self.reddit = praw.Reddit(
            client_id=self.reddit_client_id,
            client_secret=self.reddit_client_secret,
            user_agent='NCC Financial Sentiment Analyzer'
        ) if self.reddit_client_id else None
        self.sentiment_analyzer = SentimentIntensityAnalyzer()
    
    def collect_market_data(self, symbols: List[str]) -> Dict[str, Any]:
        """Collect market data for given symbols"""
        market_data = {}
        for symbol in symbols:
            try:
                ticker = yf.Ticker(symbol)
                hist = ticker.history(period='1d', interval='1h')
                if not hist.empty:
                    market_data[symbol] = {
                        'price': hist['Close'].iloc[-1],
                        'volume': hist['Volume'].iloc[-1],
                        'change': (hist['Close'].iloc[-1] - hist['Open'].iloc[0]) / hist['Open'].iloc[0] * 100
                    }
            except Exception as e:
                print(f"Market data error for {symbol}: {e}")
        return market_data
    
    def collect_news_data(self, keywords: List[str]) -> List[Dict]:
        """Collect financial news"""
        if not self.news_api:
            return []
            
        news_data = []
        for keyword in keywords:
            try:
                articles = self.news_api.get_everything(
                    q=keyword,
                    language='en',
                    sort_by='publishedAt',
                    page_size=20
                )
                
                for article in articles['articles']:
                    news_data.append({
                        'title': article['title'],
                        'description': article['description'] or '',
                        'content': article.get('content', ''),
                        'url': article['url'],
                        'published_at': article['publishedAt'],
                        'source': article['source']['name']
                    })
            except Exception as e:
                print(f"News API error for {keyword}: {e}")
                
        return news_data
    
    def collect_reddit_data(self, subreddits: List[str]) -> List[Dict]:
        """Collect Reddit discussions"""
        if not self.reddit:
            return []
            
        reddit_data = []
        for subreddit_name in subreddits:
            try:
                subreddit = self.reddit.subreddit(subreddit_name)
                for post in subreddit.hot(limit=20):
                    reddit_data.append({
                        'title': post.title,
                        'text': post.selftext,
                        'score': post.score,
                        'num_comments': post.num_comments,
                        'created_utc': post.created_utc,
                        'url': post.url
                    })
            except Exception as e:
                print(f"Reddit API error for {subreddit_name}: {e}")
                
        return reddit_data
    
    def analyze_sentiment(self, texts: List[str]) -> Dict[str, float]:
        """Analyze sentiment of text data"""
        sentiments = []
        for text in texts:
            if text:
                score = self.sentiment_analyzer.polarity_scores(text)
                sentiments.append(score['compound'])
        
        if sentiments:
            return {
                'average_sentiment': np.mean(sentiments),
                'positive_ratio': sum(1 for s in sentiments if s > 0.05) / len(sentiments),
                'negative_ratio': sum(1 for s in sentiments if s < -0.05) / len(sentiments),
                'neutral_ratio': sum(1 for s in sentiments if -0.05 <= s <= 0.05) / len(sentiments)
            }
        return {'average_sentiment': 0, 'positive_ratio': 0, 'negative_ratio': 0, 'neutral_ratio': 1}
    
    def process_data(self, market_data: Dict, news_data: List, reddit_data: List) -> Dict[str, Any]:
        """Process and correlate all data"""
        # Analyze news sentiment
        news_texts = [f"{item['title']} {item['description']}" for item in news_data]
        news_sentiment = self.analyze_sentiment(news_texts)
        
        # Analyze Reddit sentiment
        reddit_texts = [f"{item['title']} {item['text']}" for item in reddit_data]
        reddit_sentiment = self.analyze_sentiment(reddit_texts)
        
        # Calculate market sentiment correlation
        market_sentiment = {}
        for symbol, data in market_data.items():
            # Simple correlation: positive price change + positive sentiment = bullish
            combined_sentiment = (news_sentiment['average_sentiment'] + reddit_sentiment['average_sentiment']) / 2
            market_sentiment[symbol] = {
                'price_change': data['change'],
                'volume': data['volume'],
                'sentiment_score': combined_sentiment,
                'market_signal': 'bullish' if combined_sentiment > 0.1 and data['change'] > 0 else 
                               'bearish' if combined_sentiment < -0.1 and data['change'] < 0 else 'neutral'
            }
        
        return {
            'timestamp': datetime.now().isoformat(),
            'market_sentiment': market_sentiment,
            'news_sentiment': news_sentiment,
            'reddit_sentiment': reddit_sentiment,
            'total_news_articles': len(news_data),
            'total_reddit_posts': len(reddit_data)
        }
    
    def store_data(self, processed_data: Dict[str, Any]):
        """Store processed sentiment data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        file_path = os.path.join(self.data_dir, f'financial_sentiment_{timestamp}.json')
        
        with open(file_path, 'w') as f:
            json.dump(processed_data, f, indent=2)
    
    def run_analysis_cycle(self):
        """Complete sentiment analysis cycle"""
        symbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'BTC-USD', 'ETH-USD']
        keywords = ['stock market', 'cryptocurrency', 'economic indicators', 'fed policy']
        subreddits = ['wallstreetbets', 'CryptoCurrency', 'investing', 'stocks']
        
        # Collect all data
        market_data = self.collect_market_data(symbols)
        news_data = self.collect_news_data(keywords)
        reddit_data = self.collect_reddit_data(subreddits)
        
        # Process and analyze
        processed = self.process_data(market_data, news_data, reddit_data)
        
        # Store results
        self.store_data(processed)
        
        # Alert system
        bullish_signals = sum(1 for s in processed['market_sentiment'].values() if s['market_signal'] == 'bullish')
        if bullish_signals >= 3:
            print(f"ALERT: Bullish market sentiment detected - {bullish_signals} signals")
        
        print(f"Financial sentiment analysis complete: {processed['total_news_articles']} news, {processed['total_reddit_posts']} posts")
        
        return processed

def main():
    analyzer = FinancialSentimentAnalyzer()
    
    # Run initial analysis
    analyzer.run_analysis_cycle()
    
    # Schedule continuous monitoring
    schedule.every(30).minutes.do(analyzer.run_analysis_cycle)
    
    print("Financial Sentiment Analyzer started. Monitoring every 30 minutes...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()