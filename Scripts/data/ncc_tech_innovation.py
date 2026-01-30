#!/usr/bin/env python3
"""
NCC Campaign 10: Technology Innovation and Patent Tracking
Data Sources: USPTO API, Google Patents API, EPO, WIPO, academic patent databases
Scraping Methodology: API-based patent searches, citation network analysis
Data Processing: Patent classification, inventor tracking, technology clustering
Analysis Algorithms: Innovation trend analysis, patent citation networks, technology forecasting
Storage: Graph database for patent citation networks, document store for patent data
Real-time Monitoring: Continuous patent filing monitoring with innovation alerts
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
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
import networkx as nx
import schedule

load_dotenv()

class TechInnovationTracker:
    def __init__(self):
        self.uspto_api_key = os.getenv('USPTO_API_KEY')
        self.google_patents_api_key = os.getenv('GOOGLE_PATENTS_API_KEY')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'tech_innovation')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Technology areas to track
        self.tech_areas = [
            'artificial intelligence', 'machine learning', 'blockchain', 'quantum computing',
            'biotechnology', 'renewable energy', 'autonomous vehicles', '5G', 'IoT'
        ]
    
    def collect_uspto_patents(self, queries: List[str], days_back: int = 30) -> List[Dict]:
        """Collect patents from USPTO"""
        patents = []
        
        if not self.uspto_api_key:
            return patents
            
        base_url = "https://developer.uspto.gov/ibd-api/v1/search"
        headers = {'X-API-KEY': self.uspto_api_key}
        
        start_date = (datetime.now() - timedelta(days=days_back)).strftime('%Y%m%d')
        end_date = datetime.now().strftime('%Y%m%d')
        
        for query in queries:
            try:
                params = {
                    'q': f'abstract:({query}) AND publicationDate:[{start_date} TO {end_date}]',
                    'fl': 'patentNumber,publicationDate,title,abstract,inventorName,assigneeName',
                    'rows': 50
                }
                
                response = requests.get(base_url, headers=headers, params=params)
                data = response.json()
                
                if 'response' in data and 'docs' in data['response']:
                    for patent in data['response']['docs']:
                        patents.append({
                            'patent_number': patent.get('patentNumber', ''),
                            'title': patent.get('title', ''),
                            'abstract': patent.get('abstract', ''),
                            'inventors': patent.get('inventorName', []),
                            'assignee': patent.get('assigneeName', ''),
                            'publication_date': patent.get('publicationDate', ''),
                            'tech_area': query,
                            'source': 'USPTO'
                        })
            except Exception as e:
                print(f"USPTO API error for {query}: {e}")
                
        return patents
    
    def collect_google_patents(self, queries: List[str]) -> List[Dict]:
        """Collect patents from Google Patents API"""
        patents = []
        
        if not self.google_patents_api_key:
            return patents
            
        base_url = "https://patents.google.com/api/v1/search"
        
        for query in queries:
            try:
                params = {
                    'q': query,
                    'c': 50,  # Number of results
                    'key': self.google_patents_api_key
                }
                
                response = requests.get(base_url, params=params)
                data = response.json()
                
                if 'results' in data:
                    for result in data['results']:
                        patent = result.get('patent', {})
                        patents.append({
                            'patent_number': patent.get('publicationNumber', ''),
                            'title': patent.get('title', ''),
                            'abstract': patent.get('abstract', ''),
                            'inventors': patent.get('inventor', []),
                            'assignee': patent.get('assignee', ''),
                            'publication_date': patent.get('publicationDate', ''),
                            'tech_area': query,
                            'source': 'Google Patents'
                        })
            except Exception as e:
                print(f"Google Patents API error for {query}: {e}")
                
        return patents
    
    def collect_epo_patents(self, queries: List[str]) -> List[Dict]:
        """Collect patents from EPO (European Patent Office)"""
        patents = []
        
        # EPO OPS API (simplified - requires authentication)
        # Placeholder for EPO API integration
        return patents
    
    def build_citation_network(self, patents: List[Dict]) -> Dict[str, Any]:
        """Build patent citation network"""
        G = nx.DiGraph()
        
        # Add nodes
        for patent in patents:
            patent_id = patent['patent_number']
            G.add_node(patent_id, **patent)
        
        # Add citation edges (simplified - would need citation data)
        # In practice, would parse forward/backward citations
        # For now, create edges based on inventor collaboration
        inventor_patents = {}
        for patent in patents:
            for inventor in patent.get('inventors', []):
                if inventor not in inventor_patents:
                    inventor_patents[inventor] = []
                inventor_patents[inventor].append(patent['patent_number'])
        
        # Connect patents by same inventor
        for inventor, patent_ids in inventor_patents.items():
            if len(patent_ids) > 1:
                for i in range(len(patent_ids)):
                    for j in range(i+1, len(patent_ids)):
                        G.add_edge(patent_ids[i], patent_ids[j], relationship='co_inventor')
        
        # Network metrics
        network_metrics = {
            'num_nodes': G.number_of_nodes(),
            'num_edges': G.number_of_edges(),
            'density': nx.density(G),
            'avg_clustering': nx.average_clustering(G) if G.number_of_nodes() > 0 else 0,
            'strongly_connected_components': nx.number_strongly_connected_components(G)
        }
        
        return network_metrics
    
    def analyze_innovation_trends(self, patents: List[Dict]) -> Dict[str, Any]:
        """Analyze technology innovation trends"""
        if not patents:
            return {'trends': {}, 'insights': []}
            
        df = pd.DataFrame(patents)
        
        # Filing trends by tech area
        area_counts = df['tech_area'].value_counts()
        
        # Assignee analysis
        assignee_counts = df['assignee'].value_counts().head(10)
        
        # Inventor productivity
        inventor_counts = {}
        for _, patent in df.iterrows():
            for inventor in patent.get('inventors', []):
                inventor_counts[inventor] = inventor_counts.get(inventor, 0) + 1
        
        top_inventors = sorted(inventor_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        # Technology clustering based on abstracts
        abstracts = df['abstract'].fillna('')
        if abstracts.str.len().sum() > 0:
            vectorizer = TfidfVectorizer(max_features=100, stop_words='english')
            tfidf_matrix = vectorizer.fit_transform(abstracts)
            
            kmeans = KMeans(n_clusters=min(5, len(patents)), random_state=42)
            clusters = kmeans.fit_predict(tfidf_matrix)
            
            df['tech_cluster'] = clusters
            
            cluster_tech_areas = df.groupby('tech_cluster')['tech_area'].agg(lambda x: x.mode().iloc[0] if not x.mode().empty else 'Mixed')
            cluster_sizes = df['tech_cluster'].value_counts()
            
            tech_clusters = {
                f'cluster_{cluster}': {
                    'dominant_tech': cluster_tech_areas[cluster],
                    'size': cluster_sizes[cluster]
                }
                for cluster in cluster_tech_areas.index
            }
        else:
            tech_clusters = {}
        
        # Innovation velocity (patents per day)
        if 'publication_date' in df.columns:
            df['pub_date'] = pd.to_datetime(df['publication_date'], errors='coerce')
            daily_patents = df.groupby(df['pub_date'].dt.date).size()
            avg_daily_patents = daily_patents.mean()
        else:
            avg_daily_patents = 0
        
        # Emerging technologies (based on recent filings)
        recent_threshold = datetime.now() - timedelta(days=90)
        recent_patents = df[df['pub_date'] >= recent_threshold] if 'pub_date' in df.columns else df
        emerging_areas = recent_patents['tech_area'].value_counts().head(3)
        
        # Insights
        insights = []
        if not area_counts.empty:
            top_area = area_counts.index[0]
            insights.append(f"Hottest innovation area: {top_area} ({area_counts[top_area]} patents)")
        
        if top_inventors:
            insights.append(f"Most prolific inventor: {top_inventors[0][0]} ({top_inventors[0][1]} patents)")
        
        if not emerging_areas.empty:
            insights.append(f"Emerging tech: {emerging_areas.index[0]} (recent activity)")
        
        return {
            'patent_filing_trends': area_counts.to_dict(),
            'top_assignees': assignee_counts.to_dict(),
            'top_inventors': top_inventors,
            'technology_clusters': tech_clusters,
            'innovation_velocity': avg_daily_patents,
            'emerging_technologies': emerging_areas.to_dict(),
            'total_patents': len(patents),
            'unique_inventors': len(inventor_counts),
            'unique_assignees': df['assignee'].nunique(),
            'insights': insights
        }
    
    def detect_innovation_alerts(self, patents: List[Dict]) -> List[Dict]:
        """Detect significant innovation developments"""
        alerts = []
        
        if not patents:
            return alerts
            
        df = pd.DataFrame(patents)
        
        # High-activity assignees
        assignee_counts = df['assignee'].value_counts()
        avg_patents_per_assignee = assignee_counts.mean()
        high_activity_assignees = assignee_counts[assignee_counts > avg_patents_per_assignee * 2]
        
        for assignee, count in high_activity_assignees.items():
            alerts.append({
                'type': 'high_innovation_activity',
                'entity': assignee,
                'patent_count': count,
                'entity_type': 'assignee'
            })
        
        # Emerging inventors
        inventor_counts = {}
        for _, patent in df.iterrows():
            for inventor in patent.get('inventors', []):
                inventor_counts[inventor] = inventor_counts.get(inventor, 0) + 1
        
        avg_patents_per_inventor = np.mean(list(inventor_counts.values()))
        prolific_inventors = {k: v for k, v in inventor_counts.items() if v > avg_patents_per_inventor * 3}
        
        for inventor, count in prolific_inventors.items():
            alerts.append({
                'type': 'prolific_inventor',
                'entity': inventor,
                'patent_count': count,
                'entity_type': 'inventor'
            })
        
        return alerts
    
    def store_data(self, patents: List[Dict], analysis: Dict[str, Any], network: Dict[str, Any], alerts: List[Dict]):
        """Store patent and innovation data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store patents
        patents_file = os.path.join(self.data_dir, f'patent_data_{timestamp}.jsonl')
        with open(patents_file, 'w') as f:
            for patent in patents:
                f.write(json.dumps(patent) + '\n')
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'innovation_analysis_{timestamp}.json')
        combined_analysis = {**analysis, 'citation_network': network}
        with open(analysis_file, 'w') as f:
            json.dump(combined_analysis, f, indent=2)
        
        # Store alerts
        if alerts:
            alerts_file = os.path.join(self.data_dir, f'innovation_alerts_{timestamp}.json')
            with open(alerts_file, 'w') as f:
                json.dump(alerts, f, indent=2)
    
    def run_innovation_tracking_cycle(self):
        """Complete innovation tracking cycle"""
        # Collect data
        uspto_patents = self.collect_uspto_patents(self.tech_areas)
        google_patents = self.collect_google_patents(self.tech_areas)
        epo_patents = self.collect_epo_patents(self.tech_areas)
        
        all_patents = uspto_patents + google_patents + epo_patents
        
        # Analyze
        analysis = self.analyze_innovation_trends(all_patents)
        network = self.build_citation_network(all_patents)
        alerts = self.detect_innovation_alerts(all_patents)
        
        # Store
        self.store_data(all_patents, analysis, network, alerts)
        
        # Alert system
        if alerts:
            print(f"ALERT: {len(alerts)} innovation alerts detected")
            for alert in alerts[:3]:
                print(f"  {alert['type'].upper()}: {alert['entity']} - {alert['patent_count']} patents")
        
        print(f"Innovation tracking complete: {analysis['total_patents']} patents analyzed")
        
        return analysis

def main():
    tracker = TechInnovationTracker()
    
    # Run initial tracking
    tracker.run_innovation_tracking_cycle()
    
    # Schedule continuous monitoring
    schedule.every(12).hours.do(tracker.run_innovation_tracking_cycle)
    
    print("Technology Innovation Tracker started. Monitoring every 12 hours...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()