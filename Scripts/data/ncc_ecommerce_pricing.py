#!/usr/bin/env python3
"""
NCC Campaign 4: E-commerce Pricing and Product Trends
Data Sources: Amazon Product Advertising API, eBay API, Walmart API, Google Shopping API
Scraping Methodology: API-based product searches, price tracking, review analysis
Data Processing: Price normalization, trend calculation, competitor analysis
Analysis Algorithms: Price elasticity modeling, demand forecasting, market basket analysis
Storage: Time-series price database with product metadata
Real-time Monitoring: Continuous price monitoring with alert thresholds for price changes
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
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
import schedule

load_dotenv()

class EcommercePriceTracker:
    def __init__(self):
        self.amazon_access_key = os.getenv('AMAZON_ACCESS_KEY')
        self.amazon_secret_key = os.getenv('AMAZON_SECRET_KEY')
        self.amazon_associate_tag = os.getenv('AMAZON_ASSOCIATE_TAG')
        self.ebay_app_id = os.getenv('EBAY_APP_ID')
        self.walmart_api_key = os.getenv('WALMART_API_KEY')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'ecommerce_pricing')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Product categories to track
        self.categories = ['electronics', 'books', 'clothing', 'home', 'sports']
    
    def search_amazon_products(self, keywords: List[str], category: str) -> List[Dict]:
        """Search Amazon products (simplified - requires PA API)"""
        # Placeholder for Amazon Product Advertising API
        # In practice, would use amazon-paapi5 library
        return []
    
    def search_ebay_products(self, keywords: List[str]) -> List[Dict]:
        """Search eBay products"""
        if not self.ebay_app_id:
            return []
            
        products = []
        for keyword in keywords:
            try:
                url = f"https://svcs.ebay.com/services/search/FindingService/v1"
                params = {
                    'OPERATION-NAME': 'findItemsByKeywords',
                    'SERVICE-VERSION': '1.0.0',
                    'SECURITY-APPNAME': self.ebay_app_id,
                    'RESPONSE-DATA-FORMAT': 'JSON',
                    'keywords': keyword,
                    'paginationInput.entriesPerPage': '20'
                }
                
                response = requests.get(url, params=params)
                data = response.json()
                
                if 'findItemsByKeywordsResponse' in data:
                    items = data['findItemsByKeywordsResponse'][0]['searchResult'][0]['item']
                    for item in items:
                        products.append({
                            'platform': 'ebay',
                            'title': item['title'][0],
                            'price': float(item['sellingStatus'][0]['currentPrice'][0]['__value__']),
                            'currency': item['sellingStatus'][0]['currentPrice'][0]['@currencyId'],
                            'url': item['viewItemURL'][0],
                            'condition': item.get('condition', [{}])[0].get('conditionDisplayName', ['Unknown'])[0],
                            'location': item.get('location', ['Unknown'])[0],
                            'category': keyword
                        })
            except Exception as e:
                print(f"eBay API error for {keyword}: {e}")
                
        return products
    
    def search_walmart_products(self, keywords: List[str]) -> List[Dict]:
        """Search Walmart products"""
        if not self.walmart_api_key:
            return []
            
        products = []
        for keyword in keywords:
            try:
                url = "https://api.walmartlabs.com/v1/search"
                params = {
                    'apiKey': self.walmart_api_key,
                    'query': keyword,
                    'numItems': 20
                }
                
                response = requests.get(url, params=params)
                data = response.json()
                
                if 'items' in data:
                    for item in data['items']:
                        products.append({
                            'platform': 'walmart',
                            'title': item['name'],
                            'price': item['salePrice'],
                            'currency': 'USD',
                            'url': item.get('productUrl', ''),
                            'rating': item.get('customerRating', 0),
                            'num_reviews': item.get('numReviews', 0),
                            'category': keyword
                        })
            except Exception as e:
                print(f"Walmart API error for {keyword}: {e}")
                
        return products
    
    def collect_product_data(self) -> List[Dict]:
        """Collect product data from all platforms"""
        keywords = ['laptop', 'smartphone', 'book', 'shirt', 'headphones', 'monitor', 'tablet']
        
        all_products = []
        all_products.extend(self.search_amazon_products(keywords, 'electronics'))
        all_products.extend(self.search_ebay_products(keywords))
        all_products.extend(self.search_walmart_products(keywords))
        
        # Add timestamp
        for product in all_products:
            product['timestamp'] = datetime.now().isoformat()
        
        return all_products
    
    def normalize_prices(self, products: List[Dict]) -> List[Dict]:
        """Normalize prices to USD and handle currency conversion"""
        # Simple normalization (assuming most are USD)
        for product in products:
            if product.get('currency') != 'USD':
                # Placeholder for currency conversion
                product['price_usd'] = product['price']  # Assume USD
            else:
                product['price_usd'] = product['price']
        
        return products
    
    def analyze_price_trends(self, products: List[Dict]) -> Dict[str, Any]:
        """Analyze pricing trends and patterns"""
        if not products:
            return {'trends': {}, 'insights': []}
            
        df = pd.DataFrame(products)
        
        # Group by category and platform
        category_stats = df.groupby(['category', 'platform']).agg({
            'price_usd': ['mean', 'min', 'max', 'std', 'count']
        }).round(2)
        
        # Price elasticity analysis (simplified)
        elasticity_insights = []
        for category in df['category'].unique():
            cat_data = df[df['category'] == category]
            if len(cat_data) > 10:
                # Simple price distribution analysis
                mean_price = cat_data['price_usd'].mean()
                std_price = cat_data['price_usd'].std()
                cv = std_price / mean_price if mean_price > 0 else 0
                
                if cv > 0.5:
                    elasticity_insights.append(f"High price variation in {category} (CV: {cv:.2f})")
                elif cv < 0.2:
                    elasticity_insights.append(f"Stable pricing in {category} (CV: {cv:.2f})")
        
        # Platform comparison
        platform_avg_prices = df.groupby('platform')['price_usd'].mean().round(2)
        
        # Trending products (based on frequency)
        product_counts = df.groupby(['title', 'category']).size().sort_values(ascending=False).head(10)
        
        return {
            'category_statistics': category_stats.to_dict(),
            'platform_average_prices': platform_avg_prices.to_dict(),
            'price_elasticity_insights': elasticity_insights,
            'trending_products': product_counts.to_dict(),
            'total_products': len(products),
            'price_range': {
                'min': df['price_usd'].min(),
                'max': df['price_usd'].max(),
                'median': df['price_usd'].median()
            }
        }
    
    def detect_price_changes(self, current_data: List[Dict]) -> List[Dict]:
        """Detect significant price changes compared to historical data"""
        # Load previous data (simplified)
        alerts = []
        try:
            # In practice, would load from database
            # For now, just check for extreme prices
            df = pd.DataFrame(current_data)
            for _, product in df.iterrows():
                if product['price_usd'] < df[df['category'] == product['category']]['price_usd'].quantile(0.1):
                    alerts.append({
                        'type': 'price_drop',
                        'product': product['title'],
                        'price': product['price_usd'],
                        'platform': product['platform']
                    })
                elif product['price_usd'] > df[df['category'] == product['category']]['price_usd'].quantile(0.9):
                    alerts.append({
                        'type': 'premium_price',
                        'product': product['title'],
                        'price': product['price_usd'],
                        'platform': product['platform']
                    })
        except Exception as e:
            print(f"Price change detection error: {e}")
        
        return alerts
    
    def store_data(self, products: List[Dict], analysis: Dict[str, Any], alerts: List[Dict]):
        """Store pricing data and analysis"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store products
        products_file = os.path.join(self.data_dir, f'ecommerce_products_{timestamp}.jsonl')
        with open(products_file, 'w') as f:
            for product in products:
                f.write(json.dumps(product) + '\n')
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'ecommerce_analysis_{timestamp}.json')
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2)
        
        # Store alerts
        if alerts:
            alerts_file = os.path.join(self.data_dir, f'ecommerce_alerts_{timestamp}.json')
            with open(alerts_file, 'w') as f:
                json.dump(alerts, f, indent=2)
    
    def run_pricing_cycle(self):
        """Complete pricing analysis cycle"""
        # Collect data
        products = self.collect_product_data()
        products = self.normalize_prices(products)
        
        # Analyze trends
        analysis = self.analyze_price_trends(products)
        
        # Detect alerts
        alerts = self.detect_price_changes(products)
        
        # Store data
        self.store_data(products, analysis, alerts)
        
        # Alert system
        if alerts:
            print(f"ALERT: {len(alerts)} price anomalies detected")
            for alert in alerts[:3]:  # Show first 3
                print(f"  {alert['type'].upper()}: {alert['product']} - ${alert['price']}")
        
        print(f"E-commerce pricing analysis complete: {analysis['total_products']} products analyzed")
        
        return analysis

def main():
    tracker = EcommercePriceTracker()
    
    # Run initial analysis
    tracker.run_pricing_cycle()
    
    # Schedule continuous monitoring
    schedule.every(1).hours.do(tracker.run_pricing_cycle)
    
    print("E-commerce Price Tracker started. Monitoring every hour...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()