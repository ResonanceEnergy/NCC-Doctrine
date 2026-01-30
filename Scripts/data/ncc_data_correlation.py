#!/usr/bin/env python3
"""
NCC Data Correlation Engine
Cross-campaign data correlation and analysis
Correlates data across all 10 data scraping campaigns
Identifies patterns, trends, and insights across domains
"""

import os
import json
import time
from datetime import datetime, timedelta
from typing import List, Dict, Any
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import schedule

class DataCorrelationEngine:
    def __init__(self):
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
        self.correlation_dir = os.path.join(self.data_dir, 'correlations')
        os.makedirs(self.correlation_dir, exist_ok=True)
        
        self.campaigns = [
            'social_trends', 'financial_sentiment', 'news_aggregation', 
            'ecommerce_pricing', 'academic_research', 'job_market',
            'real_estate', 'crypto_blockchain', 'health_wellness', 'tech_innovation'
        ]
    
    def load_recent_campaign_data(self, campaign: str, hours_back: int = 24) -> Dict[str, Any]:
        """Load recent data from a specific campaign"""
        campaign_dir = os.path.join(self.data_dir, campaign)
        if not os.path.exists(campaign_dir):
            return {}
        
        cutoff_time = datetime.now() - timedelta(hours=hours_back)
        recent_data = []
        
        # Find recent files
        for file_name in os.listdir(campaign_dir):
            if file_name.endswith('.json') or file_name.endswith('.jsonl'):
                file_path = os.path.join(campaign_dir, file_name)
                try:
                    file_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                    if file_time > cutoff_time:
                        if file_name.endswith('.jsonl'):
                            with open(file_path, 'r') as f:
                                for line in f:
                                    recent_data.append(json.loads(line))
                        else:
                            with open(file_path, 'r') as f:
                                recent_data.append(json.load(f))
                except Exception as e:
                    print(f"Error loading {file_path}: {e}")
        
        return {'campaign': campaign, 'data': recent_data, 'count': len(recent_data)}
    
    def extract_key_metrics(self, campaign_data: Dict) -> Dict[str, Any]:
        """Extract key metrics from campaign data for correlation"""
        campaign = campaign_data['campaign']
        data = campaign_data['data']
        
        metrics = {'campaign': campaign, 'timestamp': datetime.now().isoformat()}
        
        if not data:
            return metrics
        
        try:
            if campaign == 'social_trends':
                # Social media sentiment and trends
                sentiments = [item.get('sentiment_score', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_sentiment': np.mean(sentiments) if sentiments else 0,
                    'total_posts': len(data),
                    'sentiment_volatility': np.std(sentiments) if sentiments else 0
                })
                
            elif campaign == 'financial_sentiment':
                # Financial market sentiment
                sentiments = [item.get('average_sentiment', 0) for item in data if isinstance(item, dict)]
                market_signals = [item.get('market_signal', 'neutral') for item in data if isinstance(item, dict)]
                bullish_count = market_signals.count('bullish')
                metrics.update({
                    'avg_sentiment': np.mean(sentiments) if sentiments else 0,
                    'bullish_signals': bullish_count,
                    'total_signals': len(market_signals),
                    'bullish_ratio': bullish_count / len(market_signals) if market_signals else 0
                })
                
            elif campaign == 'news_aggregation':
                # News sentiment and topics
                sentiments = [item.get('average_sentiment', 0) for item in data if isinstance(item, dict)]
                topics = []
                for item in data:
                    if isinstance(item, dict) and 'trending_topics' in item:
                        topics.extend([t[0] for t in item.get('trending_topics', [])])
                metrics.update({
                    'avg_sentiment': np.mean(sentiments) if sentiments else 0,
                    'total_articles': sum(item.get('total_articles', 0) for item in data if isinstance(item, dict)),
                    'unique_topics': len(set(topics))
                })
                
            elif campaign == 'ecommerce_pricing':
                # E-commerce pricing trends
                prices = []
                for item in data:
                    if isinstance(item, dict) and 'price_numeric' in item:
                        prices.append(item['price_numeric'])
                metrics.update({
                    'avg_price': np.mean(prices) if prices else 0,
                    'price_volatility': np.std(prices) if prices else 0,
                    'total_products': len(data)
                })
                
            elif campaign == 'academic_research':
                # Academic publication metrics
                citation_counts = [item.get('citation_count', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_citations': np.mean(citation_counts) if citation_counts else 0,
                    'total_papers': len(data),
                    'max_citations': max(citation_counts) if citation_counts else 0
                })
                
            elif campaign == 'job_market':
                # Job market metrics
                salaries = [item.get('salary_avg', 0) for item in data if isinstance(item, dict) and item.get('salary_avg')]
                demand_scores = [item.get('total_jobs', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_salary': np.mean(salaries) if salaries else 0,
                    'total_jobs': sum(demand_scores),
                    'salary_volatility': np.std(salaries) if salaries else 0
                })
                
            elif campaign == 'real_estate':
                # Real estate metrics
                prices = [item.get('price_numeric', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_price': np.mean(prices) if prices else 0,
                    'total_properties': len(data),
                    'price_volatility': np.std(prices) if prices else 0
                })
                
            elif campaign == 'crypto_blockchain':
                # Crypto market metrics
                prices = [item.get('current_price', 0) for item in data if isinstance(item, dict)]
                changes = [item.get('price_change_24h', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_price': np.mean(prices) if prices else 0,
                    'avg_change_24h': np.mean(changes) if changes else 0,
                    'price_volatility': np.std(changes) if changes else 0,
                    'total_cryptos': len(data)
                })
                
            elif campaign == 'health_wellness':
                # Health trends
                sentiments = [item.get('average_sentiment', 0) for item in data if isinstance(item, dict)]
                interests = [item.get('average_interest', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'avg_sentiment': np.mean(sentiments) if sentiments else 0,
                    'avg_interest': np.mean(interests) if interests else 0,
                    'total_topics': len(data)
                })
                
            elif campaign == 'tech_innovation':
                # Innovation metrics
                patent_counts = [item.get('total_patents', 0) for item in data if isinstance(item, dict)]
                metrics.update({
                    'total_patents': sum(patent_counts),
                    'avg_patents_per_cycle': np.mean(patent_counts) if patent_counts else 0,
                    'innovation_velocity': len(data)
                })
                
        except Exception as e:
            print(f"Error extracting metrics for {campaign}: {e}")
        
        return metrics
    
    def correlate_campaigns(self, all_metrics: List[Dict]) -> Dict[str, Any]:
        """Find correlations across campaigns"""
        if not all_metrics:
            return {'correlations': {}, 'insights': []}
        
        # Create correlation matrix
        df = pd.DataFrame(all_metrics)
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        if len(numeric_cols) > 1:
            corr_matrix = df[numeric_cols].corr()
        else:
            corr_matrix = pd.DataFrame()
        
        # Find strong correlations
        correlations = {}
        if not corr_matrix.empty:
            for i in range(len(corr_matrix.columns)):
                for j in range(i+1, len(corr_matrix.columns)):
                    col1, col2 = corr_matrix.columns[i], corr_matrix.columns[j]
                    corr_value = corr_matrix.loc[col1, col2]
                    if abs(corr_value) > 0.5:  # Strong correlation threshold
                        correlations[f"{col1}_vs_{col2}"] = corr_value
        
        # Generate insights
        insights = []
        
        # Economic indicators correlation
        economic_indicators = ['avg_price', 'avg_salary', 'avg_change_24h', 'bullish_ratio']
        economic_data = df[economic_indicators].dropna()
        if not economic_data.empty:
            economic_corr = economic_data.corr()
            if not economic_corr.empty:
                max_corr = economic_corr.max().max()
                if max_corr > 0.7:
                    insights.append(f"Strong economic correlation detected (r={max_corr:.2f})")
        
        # Sentiment analysis across domains
        sentiment_cols = [col for col in df.columns if 'sentiment' in col.lower()]
        if sentiment_cols:
            avg_sentiment = df[sentiment_cols].mean().mean()
            sentiment_trend = 'positive' if avg_sentiment > 0.1 else 'negative' if avg_sentiment < -0.1 else 'neutral'
            insights.append(f"Overall sentiment across campaigns: {sentiment_trend} ({avg_sentiment:.3f})")
        
        # Innovation and market correlation
        if 'total_patents' in df.columns and 'bullish_ratio' in df.columns:
            patent_market_corr = df[['total_patents', 'bullish_ratio']].corr().iloc[0,1]
            if abs(patent_market_corr) > 0.3:
                direction = 'positive' if patent_market_corr > 0 else 'negative'
                insights.append(f"Innovation and market sentiment show {direction} correlation (r={patent_market_corr:.2f})")
        
        return {
            'correlation_matrix': corr_matrix.to_dict() if not corr_matrix.empty else {},
            'strong_correlations': correlations,
            'cross_domain_insights': insights,
            'total_campaigns_analyzed': len(all_metrics),
            'correlation_timestamp': datetime.now().isoformat()
        }
    
    def generate_actionable_insights(self, correlations: Dict) -> List[str]:
        """Generate actionable insights from correlations"""
        insights = []
        
        strong_correlations = correlations.get('strong_correlations', {})
        
        # Investment insights
        if any('bullish_ratio' in key and 'avg_price' in key for key in strong_correlations.keys()):
            corr_value = next((v for k, v in strong_correlations.items() if 'bullish_ratio' in k and 'avg_price' in k), 0)
            if corr_value > 0.5:
                insights.append("INVESTMENT: Positive correlation between market sentiment and pricing trends suggests bullish investment climate")
        
        # Business strategy insights
        if any('total_jobs' in key and 'avg_salary' in key for key in strong_correlations.keys()):
            insights.append("TALENT: Job market and salary trends are correlated - monitor for recruitment opportunities")
        
        # Technology insights
        if any('total_patents' in key for key in strong_correlations.keys()):
            insights.append("INNOVATION: High patent activity detected - potential breakthrough technologies emerging")
        
        # Health and market correlation
        if any('avg_sentiment' in key and 'bullish_ratio' in key for key in strong_correlations.keys()):
            insights.append("MARKET HEALTH: Public sentiment correlated with market performance - monitor consumer confidence")
        
        return insights
    
    def store_correlation_analysis(self, all_metrics: List[Dict], correlations: Dict, insights: List[str]):
        """Store correlation analysis results"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        analysis_data = {
            'timestamp': timestamp,
            'campaign_metrics': all_metrics,
            'correlations': correlations,
            'actionable_insights': insights,
            'summary': {
                'campaigns_analyzed': len(all_metrics),
                'strong_correlations_found': len(correlations.get('strong_correlations', {})),
                'insights_generated': len(insights)
            }
        }
        
        file_path = os.path.join(self.correlation_dir, f'cross_campaign_correlation_{timestamp}.json')
        with open(file_path, 'w') as f:
            json.dump(analysis_data, f, indent=2, default=str)
    
    def run_correlation_cycle(self):
        """Complete cross-campaign correlation cycle"""
        # Load recent data from all campaigns
        all_campaign_data = []
        all_metrics = []
        
        for campaign in self.campaigns:
            campaign_data = self.load_recent_campaign_data(campaign)
            if campaign_data.get('count', 0) > 0:
                all_campaign_data.append(campaign_data)
                metrics = self.extract_key_metrics(campaign_data)
                all_metrics.append(metrics)
        
        # Perform correlation analysis
        correlations = self.correlate_campaigns(all_metrics)
        insights = self.generate_actionable_insights(correlations)
        
        # Store results
        self.store_correlation_analysis(all_metrics, correlations, insights)
        
        # Alert system
        strong_correlations = len(correlations.get('strong_correlations', {}))
        if strong_correlations > 3:
            print(f"ALERT: {strong_correlations} strong cross-domain correlations detected")
        
        if insights:
            print(f"INSIGHTS: {len(insights)} actionable insights generated")
            for insight in insights[:3]:
                print(f"  {insight}")
        
        print(f"Cross-campaign correlation complete: {len(all_metrics)} campaigns analyzed, {strong_correlations} strong correlations found")
        
        return correlations

def main():
    engine = DataCorrelationEngine()
    
    # Run initial correlation
    engine.run_correlation_cycle()
    
    # Schedule continuous correlation analysis
    schedule.every(1).hours.do(engine.run_correlation_cycle)
    
    print("NCC Data Correlation Engine started. Analyzing cross-campaign correlations every hour...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()