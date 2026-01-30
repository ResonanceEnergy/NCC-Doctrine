#!/usr/bin/env python3
"""
NCC Campaign 8: Cryptocurrency and Blockchain Analytics
Data Sources: CoinGecko API, CoinMarketCap API, CryptoCompare, Blockchain explorers
Scraping Methodology: API-based crypto data collection, on-chain data analysis
Data Processing: Price normalization, volume analysis, blockchain metrics
Analysis Algorithms: Price prediction models, market correlation analysis, on-chain analytics
Storage: Time-series crypto database with blockchain metrics
Real-time Monitoring: Continuous market monitoring with volatility alerts
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

class CryptoBlockchainAnalyzer:
    def __init__(self):
        self.coingecko_api_key = os.getenv('COINGECKO_API_KEY')
        self.coinmarketcap_api_key = os.getenv('COINMARKETCAP_API_KEY')
        self.cryptocompare_api_key = os.getenv('CRYPTOCOMPARE_API_KEY')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'crypto_blockchain')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Cryptocurrencies to track
        self.cryptos = ['bitcoin', 'ethereum', 'solana', 'cardano', 'polygon', 'avalanche-2', 'chainlink']
    
    def collect_coingecko_data(self, crypto_ids: List[str]) -> List[Dict]:
        """Collect crypto data from CoinGecko"""
        crypto_data = []
        base_url = "https://api.coingecko.com/api/v3/coins"
        
        for crypto_id in crypto_ids:
            try:
                url = f"{base_url}/{crypto_id}"
                params = {
                    'localization': 'false',
                    'tickers': 'false',
                    'market_data': 'true',
                    'community_data': 'false',
                    'developer_data': 'false',
                    'sparkline': 'false'
                }
                
                if self.coingecko_api_key:
                    params['x_cg_demo_api_key'] = self.coingecko_api_key
                
                response = requests.get(url, params=params)
                data = response.json()
                
                if 'market_data' in data:
                    market_data = data['market_data']
                    crypto_data.append({
                        'name': data['name'],
                        'symbol': data['symbol'].upper(),
                        'current_price': market_data['current_price']['usd'],
                        'market_cap': market_data['market_cap']['usd'],
                        'market_cap_rank': market_data['market_cap_rank'],
                        'total_volume': market_data['total_volume']['usd'],
                        'price_change_24h': market_data['price_change_percentage_24h'],
                        'price_change_7d': market_data['price_change_percentage_7d'],
                        'price_change_30d': market_data['price_change_percentage_30d'],
                        'circulating_supply': market_data['circulating_supply'],
                        'total_supply': market_data['total_supply'],
                        'max_supply': market_data['max_supply'],
                        'ath': market_data['ath']['usd'],
                        'atl': market_data['atl']['usd'],
                        'source': 'CoinGecko',
                        'timestamp': datetime.now().isoformat()
                    })
            except Exception as e:
                print(f"CoinGecko API error for {crypto_id}: {e}")
                
        return crypto_data
    
    def collect_coinmarketcap_data(self, symbols: List[str]) -> List[Dict]:
        """Collect data from CoinMarketCap"""
        if not self.coinmarketcap_api_key:
            return []
            
        crypto_data = []
        url = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest"
        headers = {
            'Accepts': 'application/json',
            'X-CMC_PRO_API_KEY': self.coinmarketcap_api_key,
        }
        
        symbols_str = ','.join(symbols)
        params = {
            'symbol': symbols_str,
            'convert': 'USD'
        }
        
        try:
            response = requests.get(url, headers=headers, params=params)
            data = response.json()
            
            if 'data' in data:
                for symbol, crypto_info in data['data'].items():
                    quote = crypto_info['quote']['USD']
                    crypto_data.append({
                        'name': crypto_info['name'],
                        'symbol': symbol,
                        'current_price': quote['price'],
                        'market_cap': quote['market_cap'],
                        'total_volume': quote['volume_24h'],
                        'price_change_24h': quote['percent_change_24h'],
                        'price_change_7d': quote['percent_change_7d'],
                        'price_change_30d': quote.get('percent_change_30d'),
                        'circulating_supply': crypto_info['circulating_supply'],
                        'total_supply': crypto_info['total_supply'],
                        'max_supply': crypto_info['max_supply'],
                        'source': 'CoinMarketCap',
                        'timestamp': datetime.now().isoformat()
                    })
        except Exception as e:
            print(f"CoinMarketCap API error: {e}")
            
        return crypto_data
    
    def collect_blockchain_metrics(self, crypto_ids: List[str]) -> Dict[str, Any]:
        """Collect blockchain-specific metrics"""
        blockchain_data = {}
        
        # Bitcoin network data
        try:
            # Using blockchain.info API for Bitcoin
            btc_stats_url = "https://api.blockchain.info/stats"
            response = requests.get(btc_stats_url)
            btc_data = response.json()
            
            blockchain_data['bitcoin'] = {
                'hash_rate': btc_data.get('hash_rate'),
                'difficulty': btc_data.get('difficulty'),
                'n_blocks_total': btc_data.get('n_blocks_total'),
                'minutes_between_blocks': btc_data.get('minutes_between_blocks'),
                'total_btc_sent': btc_data.get('total_btc_sent'),
                'estimated_transaction_volume_usd': btc_data.get('estimated_transaction_volume_usd')
            }
        except Exception as e:
            print(f"Bitcoin blockchain API error: {e}")
        
        # Ethereum network data (simplified)
        try:
            eth_stats_url = "https://api.etherscan.io/api?module=stats&action=ethsupply&apikey=demo"
            response = requests.get(eth_stats_url)
            eth_data = response.json()
            
            if eth_data.get('status') == '1':
                blockchain_data['ethereum'] = {
                    'eth_supply': int(eth_data['result']) / 10**18  # Convert wei to ETH
                }
        except Exception as e:
            print(f"Ethereum blockchain API error: {e}")
        
        return blockchain_data
    
    def analyze_crypto_market(self, crypto_data: List[Dict], blockchain_data: Dict) -> Dict[str, Any]:
        """Analyze cryptocurrency market trends"""
        if not crypto_data:
            return {'analysis': {}, 'insights': []}
            
        df = pd.DataFrame(crypto_data)
        
        # Market overview
        total_market_cap = df['market_cap'].sum()
        total_volume = df['total_volume'].sum()
        
        # Price change analysis
        price_changes = df[['symbol', 'price_change_24h', 'price_change_7d', 'price_change_30d']].set_index('symbol')
        
        # Market cap distribution
        market_cap_distribution = df.groupby(pd.cut(df['market_cap'], 
                                                  bins=[0, 1e9, 1e10, 1e11, float('inf')], 
                                                  labels=['Small', 'Medium', 'Large', 'Mega']))['market_cap'].sum()
        
        # Volatility analysis
        volatility = df[['symbol', 'price_change_24h']].copy()
        volatility['volatility'] = volatility['price_change_24h'].abs()
        most_volatile = volatility.nlargest(3, 'volatility')
        
        # Correlation analysis (simplified)
        correlation_matrix = df[['current_price', 'market_cap', 'total_volume']].corr()
        
        # Top performers
        top_gainers_24h = df.nlargest(3, 'price_change_24h')[['symbol', 'price_change_24h']]
        top_losers_24h = df.nsmallest(3, 'price_change_24h')[['symbol', 'price_change_24h']]
        
        # Market sentiment indicators
        positive_changes = (df['price_change_24h'] > 0).sum()
        negative_changes = (df['price_change_24h'] < 0).sum()
        market_sentiment = 'bullish' if positive_changes > negative_changes else 'bearish'
        
        # Insights
        insights = []
        insights.append(f"Market sentiment: {market_sentiment.upper()} ({positive_changes} gainers, {negative_changes} losers)")
        
        if not most_volatile.empty:
            insights.append(f"Most volatile: {most_volatile.iloc[0]['symbol']} ({most_volatile.iloc[0]['volatility']:.2f}% change)")
        
        if not top_gainers_24h.empty:
            top_gainer = top_gainers_24h.iloc[0]
            insights.append(f"Top gainer: {top_gainer['symbol']} (+{top_gainer['price_change_24h']:.2f}%)")
        
        # Blockchain metrics integration
        blockchain_insights = []
        for crypto, metrics in blockchain_data.items():
            if crypto.lower() in [c['symbol'].lower() for c in crypto_data]:
                blockchain_insights.append(f"{crypto.upper()}: {len(metrics)} on-chain metrics collected")
        
        return {
            'market_overview': {
                'total_market_cap': total_market_cap,
                'total_volume_24h': total_volume,
                'cryptocurrencies_tracked': len(crypto_data)
            },
            'price_changes': price_changes.to_dict(),
            'market_cap_distribution': market_cap_distribution.to_dict(),
            'volatility_analysis': most_volatile.to_dict('records'),
            'correlation_matrix': correlation_matrix.to_dict(),
            'top_performers': {
                'gainers': top_gainers_24h.to_dict('records'),
                'losers': top_losers_24h.to_dict('records')
            },
            'market_sentiment': market_sentiment,
            'blockchain_metrics': blockchain_data,
            'market_insights': insights,
            'blockchain_insights': blockchain_insights
        }
    
    def predict_price_movements(self, historical_data: List[Dict]) -> Dict[str, Any]:
        """Predict short-term price movements (simplified)"""
        # Placeholder for price prediction
        return {'prediction': 'Mixed signals - monitor key support/resistance levels'}
    
    def detect_market_anomalies(self, crypto_data: List[Dict]) -> List[Dict]:
        """Detect unusual market activity"""
        alerts = []
        try:
            df = pd.DataFrame(crypto_data)
            
            # Volume spikes
            avg_volume = df['total_volume'].mean()
            volume_spikes = df[df['total_volume'] > avg_volume * 2]
            for _, crypto in volume_spikes.iterrows():
                alerts.append({
                    'type': 'volume_spike',
                    'crypto': crypto['symbol'],
                    'volume': crypto['total_volume'],
                    'threshold': avg_volume * 2
                })
            
            # Extreme price movements
            extreme_changes = df[abs(df['price_change_24h']) > 20]
            for _, crypto in extreme_changes.iterrows():
                alerts.append({
                    'type': 'extreme_price_change',
                    'crypto': crypto['symbol'],
                    'change': crypto['price_change_24h'],
                    'direction': 'up' if crypto['price_change_24h'] > 0 else 'down'
                })
                
        except Exception as e:
            print(f"Market anomaly detection error: {e}")
        
        return alerts
    
    def store_data(self, crypto_data: List[Dict], blockchain_data: Dict, analysis: Dict[str, Any], alerts: List[Dict]):
        """Store crypto and blockchain data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store crypto data
        crypto_file = os.path.join(self.data_dir, f'crypto_data_{timestamp}.jsonl')
        with open(crypto_file, 'w') as f:
            for crypto in crypto_data:
                f.write(json.dumps(crypto) + '\n')
        
        # Store blockchain data
        blockchain_file = os.path.join(self.data_dir, f'blockchain_data_{timestamp}.json')
        with open(blockchain_file, 'w') as f:
            json.dump(blockchain_data, f, indent=2)
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'crypto_analysis_{timestamp}.json')
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2)
        
        # Store alerts
        if alerts:
            alerts_file = os.path.join(self.data_dir, f'crypto_alerts_{timestamp}.json')
            with open(alerts_file, 'w') as f:
                json.dump(alerts, f, indent=2)
    
    def run_crypto_analysis_cycle(self):
        """Complete crypto analysis cycle"""
        # Collect data
        coingecko_data = self.collect_coingecko_data(self.cryptos)
        coinmarketcap_data = self.collect_coinmarketcap_data([c.upper() for c in self.cryptos])
        blockchain_data = self.collect_blockchain_metrics(self.cryptos)
        
        # Combine and deduplicate
        all_crypto_data = coingecko_data + coinmarketcap_data
        seen_symbols = set()
        unique_crypto_data = []
        for crypto in all_crypto_data:
            if crypto['symbol'] not in seen_symbols:
                unique_crypto_data.append(crypto)
                seen_symbols.add(crypto['symbol'])
        
        # Analyze
        analysis = self.analyze_crypto_market(unique_crypto_data, blockchain_data)
        alerts = self.detect_market_anomalies(unique_crypto_data)
        
        # Store
        self.store_data(unique_crypto_data, blockchain_data, analysis, alerts)
        
        # Alert system
        if alerts:
            print(f"ALERT: {len(alerts)} crypto market anomalies detected")
            for alert in alerts[:3]:
                print(f"  {alert['type'].upper()}: {alert['crypto']} - {alert.get('change', alert.get('volume', 'N/A'))}")
        
        print(f"Crypto analysis complete: {len(unique_crypto_data)} cryptocurrencies analyzed")
        
        return analysis

def main():
    analyzer = CryptoBlockchainAnalyzer()
    
    # Run initial analysis
    analyzer.run_crypto_analysis_cycle()
    
    # Schedule continuous monitoring
    schedule.every(30).minutes.do(analyzer.run_crypto_analysis_cycle)
    
    print("Crypto Blockchain Analyzer started. Monitoring every 30 minutes...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()