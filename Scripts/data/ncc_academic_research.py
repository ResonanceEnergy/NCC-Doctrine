#!/usr/bin/env python3
"""
NCC Campaign 5: Academic Research and Publication Tracking
Data Sources: Semantic Scholar API, arXiv API, Google Scholar (web scraping), PubMed API
Scraping Methodology: API calls for structured data, web scraping for Google Scholar
Data Processing: Citation network analysis, topic clustering, author tracking
Analysis Algorithms: Citation analysis, topic modeling, research trend detection
Storage: Graph database for citation networks, document store for papers
Real-time Monitoring: Continuous publication monitoring with citation alerts
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Any
from dotenv import load_dotenv
import feedparser
from scholarly import scholarly
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
import networkx as nx
import schedule

load_dotenv()

class AcademicResearchTracker:
    def __init__(self):
        self.semantic_scholar_key = os.getenv('SEMANTIC_SCHOLAR_API_KEY')
        self.pubmed_api_key = os.getenv('PUBMED_API_KEY')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'academic_research')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Research fields to track
        self.fields = ['artificial intelligence', 'machine learning', 'quantum computing', 'biotechnology', 'neuroscience']
    
    def collect_arxiv_papers(self, categories: List[str], days_back: int = 7) -> List[Dict]:
        """Collect papers from arXiv"""
        papers = []
        base_url = "http://export.arxiv.org/api/query"
        
        for category in categories:
            try:
                # arXiv category codes
                category_codes = {
                    'artificial intelligence': 'cs.AI',
                    'machine learning': 'cs.LG',
                    'quantum computing': 'quant-ph',
                    'biotechnology': 'q-bio',
                    'neuroscience': 'q-bio.NC'
                }
                
                cat_code = category_codes.get(category, 'cs.AI')
                
                params = {
                    'search_query': f'cat:{cat_code}',
                    'sortBy': 'submittedDate',
                    'sortOrder': 'descending',
                    'max_results': 50
                }
                
                response = requests.get(base_url, params=params)
                feed = feedparser.parse(response.content)
                
                for entry in feed.entries:
                    published_date = datetime.strptime(entry.published, '%Y-%m-%dT%H:%M:%SZ')
                    if (datetime.now() - published_date).days <= days_back:
                        papers.append({
                            'title': entry.title,
                            'authors': [author.name for author in entry.authors],
                            'abstract': entry.summary,
                            'published_date': entry.published,
                            'arxiv_id': entry.id.split('/')[-1],
                            'categories': [tag.term for tag in entry.tags],
                            'pdf_url': entry.id.replace('abs', 'pdf'),
                            'source': 'arXiv',
                            'field': category
                        })
            except Exception as e:
                print(f"arXiv collection error for {category}: {e}")
                
        return papers
    
    def collect_semantic_scholar_papers(self, queries: List[str]) -> List[Dict]:
        """Collect papers from Semantic Scholar"""
        if not self.semantic_scholar_key:
            return []
            
        papers = []
        base_url = "https://api.semanticscholar.org/graph/v1/paper/search"
        
        for query in queries:
            try:
                headers = {'x-api-key': self.semantic_scholar_key}
                params = {
                    'query': query,
                    'limit': 20,
                    'fields': 'title,authors,abstract,year,citationCount,influentialCitationCount,fieldsOfStudy'
                }
                
                response = requests.get(base_url, headers=headers, params=params)
                data = response.json()
                
                if 'data' in data:
                    for paper in data['data']:
                        papers.append({
                            'title': paper['title'],
                            'authors': [author['name'] for author in paper.get('authors', [])],
                            'abstract': paper.get('abstract', ''),
                            'year': paper.get('year'),
                            'citation_count': paper.get('citationCount', 0),
                            'influential_citations': paper.get('influentialCitationCount', 0),
                            'fields_of_study': paper.get('fieldsOfStudy', []),
                            'source': 'Semantic Scholar',
                            'field': query
                        })
            except Exception as e:
                print(f"Semantic Scholar error for {query}: {e}")
                
        return papers
    
    def collect_google_scholar_data(self, queries: List[str]) -> List[Dict]:
        """Collect data from Google Scholar (limited due to anti-scraping)"""
        papers = []
        for query in queries:
            try:
                search_query = scholarly.search_pubs(query)
                for i in range(5):  # Limit to 5 per query
                    pub = next(search_query)
                    papers.append({
                        'title': pub['bib']['title'],
                        'authors': pub['bib'].get('author', []),
                        'abstract': pub['bib'].get('abstract', ''),
                        'year': pub['bib'].get('pub_year'),
                        'citation_count': pub.get('num_citations', 0),
                        'source': 'Google Scholar',
                        'field': query
                    })
            except Exception as e:
                print(f"Google Scholar error for {query}: {e}")
                
        return papers
    
    def build_citation_network(self, papers: List[Dict]) -> Dict[str, Any]:
        """Build citation network analysis"""
        G = nx.Graph()
        
        # Add nodes (papers)
        for paper in papers:
            paper_id = paper.get('arxiv_id') or paper['title'][:50]
            G.add_node(paper_id, **paper)
        
        # Add edges based on co-authorship or citations (simplified)
        authors_dict = {}
        for paper in papers:
            for author in paper.get('authors', []):
                if author not in authors_dict:
                    authors_dict[author] = []
                authors_dict[author].append(paper.get('arxiv_id') or paper['title'][:50])
        
        # Connect papers by shared authors
        for author, paper_ids in authors_dict.items():
            if len(paper_ids) > 1:
                for i in range(len(paper_ids)):
                    for j in range(i+1, len(paper_ids)):
                        G.add_edge(paper_ids[i], paper_ids[j], relationship='co_authorship')
        
        # Network metrics
        network_metrics = {
            'num_nodes': G.number_of_nodes(),
            'num_edges': G.number_of_edges(),
            'density': nx.density(G),
            'avg_clustering': nx.average_clustering(G),
            'centrality': dict(nx.degree_centrality(G))
        }
        
        return network_metrics
    
    def analyze_research_trends(self, papers: List[Dict]) -> Dict[str, Any]:
        """Analyze research trends and topics"""
        if not papers:
            return {'trends': {}, 'insights': []}
            
        df = pd.DataFrame(papers)
        
        # Topic clustering using abstracts
        abstracts = df['abstract'].fillna('')
        if abstracts.str.len().sum() > 0:
            vectorizer = TfidfVectorizer(max_features=100, stop_words='english')
            tfidf_matrix = vectorizer.fit_transform(abstracts)
            
            # K-means clustering
            kmeans = KMeans(n_clusters=5, random_state=42)
            clusters = kmeans.fit_predict(tfidf_matrix)
            
            df['topic_cluster'] = clusters
            
            # Topic keywords
            feature_names = vectorizer.get_feature_names_out()
            cluster_keywords = {}
            for cluster in range(5):
                cluster_center = kmeans.cluster_centers_[cluster]
                top_keywords_idx = cluster_center.argsort()[-5:][::-1]
                cluster_keywords[f'cluster_{cluster}'] = [feature_names[idx] for idx in top_keywords_idx]
        else:
            cluster_keywords = {}
        
        # Citation analysis
        citation_stats = df.groupby('field').agg({
            'citation_count': ['mean', 'max', 'sum']
        }).round(2)
        
        # Trending fields
        field_counts = df['field'].value_counts()
        
        # Author productivity
        author_counts = {}
        for _, paper in df.iterrows():
            for author in paper.get('authors', []):
                author_counts[author] = author_counts.get(author, 0) + 1
        
        top_authors = sorted(author_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        return {
            'field_distribution': field_counts.to_dict(),
            'citation_statistics': citation_stats.to_dict(),
            'topic_clusters': cluster_keywords,
            'top_authors': top_authors,
            'total_papers': len(papers),
            'date_range': {
                'earliest': df.get('year', pd.Series()).min() if 'year' in df.columns else None,
                'latest': df.get('year', pd.Series()).max() if 'year' in df.columns else None
            }
        }
    
    def store_data(self, papers: List[Dict], analysis: Dict[str, Any], network: Dict[str, Any]):
        """Store research data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store papers
        papers_file = os.path.join(self.data_dir, f'academic_papers_{timestamp}.jsonl')
        with open(papers_file, 'w') as f:
            for paper in papers:
                f.write(json.dumps(paper) + '\n')
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'academic_analysis_{timestamp}.json')
        combined_analysis = {**analysis, 'citation_network': network}
        with open(analysis_file, 'w') as f:
            json.dump(combined_analysis, f, indent=2)
    
    def run_research_cycle(self):
        """Complete research tracking cycle"""
        # Collect data
        arxiv_papers = self.collect_arxiv_papers(self.fields)
        semantic_papers = self.collect_semantic_scholar_papers(self.fields)
        scholar_papers = self.collect_google_scholar_data(self.fields)
        
        all_papers = arxiv_papers + semantic_papers + scholar_papers
        
        # Analyze
        analysis = self.analyze_research_trends(all_papers)
        network = self.build_citation_network(all_papers)
        
        # Store
        self.store_data(all_papers, analysis, network)
        
        # Alert system
        if analysis.get('total_papers', 0) > 50:
            print(f"ALERT: High research activity detected - {analysis['total_papers']} papers")
        
        print(f"Academic research tracking complete: {analysis['total_papers']} papers analyzed")
        
        return analysis

def main():
    tracker = AcademicResearchTracker()
    
    # Run initial tracking
    tracker.run_research_cycle()
    
    # Schedule continuous monitoring
    schedule.every(6).hours.do(tracker.run_research_cycle)
    
    print("Academic Research Tracker started. Monitoring every 6 hours...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()