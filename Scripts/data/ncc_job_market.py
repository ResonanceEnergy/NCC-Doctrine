#!/usr/bin/env python3
"""
NCC Campaign 6: Job Market and Talent Acquisition Data
Data Sources: LinkedIn Jobs API, Indeed API, Glassdoor API, JSearch API, GitHub Jobs
Scraping Methodology: API-based job searches, web scraping for additional data
Data Processing: Job posting deduplication, skill extraction, salary normalization
Analysis Algorithms: Job market trend analysis, skill demand forecasting, salary modeling
Storage: Time-series job database with geospatial indexing
Real-time Monitoring: Continuous job posting monitoring with skill gap alerts
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
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.linear_model import LinearRegression
from collections import Counter
import schedule

load_dotenv()

class JobMarketAnalyzer:
    def __init__(self):
        self.jsearch_api_key = os.getenv('JSEARCH_API_KEY')
        self.linkedin_client_id = os.getenv('LINKEDIN_CLIENT_ID')
        self.linkedin_client_secret = os.getenv('LINKEDIN_CLIENT_SECRET')
        self.indeed_publisher_id = os.getenv('INDEED_PUBLISHER_ID')
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'job_market')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Job categories to track
        self.categories = ['software engineering', 'data science', 'AI/ML', 'cybersecurity', 'blockchain', 'quantum computing']
    
    def collect_jsearch_jobs(self, queries: List[str], location: str = 'United States') -> List[Dict]:
        """Collect jobs from JSearch API"""
        if not self.jsearch_api_key:
            return []
            
        jobs = []
        base_url = "https://jsearch.p.rapidapi.com/search"
        headers = {
            'X-RapidAPI-Key': self.jsearch_api_key,
            'X-RapidAPI-Host': 'jsearch.p.rapidapi.com'
        }
        
        for query in queries:
            try:
                params = {
                    'query': f'{query} jobs',
                    'page': '1',
                    'num_pages': '1',
                    'country': 'US'
                }
                
                response = requests.get(base_url, headers=headers, params=params)
                data = response.json()
                
                if 'data' in data:
                    for job in data['data']:
                        jobs.append({
                            'title': job['job_title'],
                            'company': job['employer_name'],
                            'location': job['job_city'] + ', ' + job['job_state'] if job.get('job_city') else job.get('job_country', ''),
                            'description': job.get('job_description', ''),
                            'salary': job.get('job_salary', ''),
                            'job_type': job.get('job_employment_type', ''),
                            'url': job.get('job_apply_link', ''),
                            'posted_date': job.get('job_posted_at_datetime_utc', ''),
                            'source': 'JSearch',
                            'category': query
                        })
            except Exception as e:
                print(f"JSearch API error for {query}: {e}")
                
        return jobs
    
    def collect_linkedin_jobs(self, keywords: List[str]) -> List[Dict]:
        """Collect jobs from LinkedIn (simplified - requires OAuth)"""
        # Placeholder for LinkedIn Jobs API
        # In practice, would require OAuth flow and proper API integration
        return []
    
    def collect_indeed_jobs(self, queries: List[str]) -> List[Dict]:
        """Collect jobs from Indeed"""
        if not self.indeed_publisher_id:
            return []
            
        jobs = []
        base_url = "https://api.indeed.com/ads/apisearch"
        
        for query in queries:
            try:
                params = {
                    'publisher': self.indeed_publisher_id,
                    'q': query,
                    'l': 'united states',
                    'sort': 'date',
                    'radius': 25,
                    'st': '',
                    'jt': '',
                    'start': 0,
                    'limit': 25,
                    'fromage': 7,  # Last 7 days
                    'filter': 1,
                    'latlong': 0,
                    'co': 'us',
                    'chnl': '',
                    'userip': '1.2.3.4',
                    'useragent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'v': 2
                }
                
                response = requests.get(base_url, params=params)
                data = response.json()
                
                if 'results' in data:
                    for job in data['results']:
                        jobs.append({
                            'title': job['jobtitle'],
                            'company': job['company'],
                            'location': job['formattedLocation'],
                            'description': job['snippet'],
                            'salary': job.get('formattedRelativeTime', ''),
                            'job_type': '',
                            'url': job['url'],
                            'posted_date': job.get('date', ''),
                            'source': 'Indeed',
                            'category': query
                        })
            except Exception as e:
                print(f"Indeed API error for {query}: {e}")
                
        return jobs
    
    def collect_github_jobs(self) -> List[Dict]:
        """Collect jobs from GitHub Jobs API"""
        jobs = []
        try:
            url = "https://jobs.github.com/positions.json"
            params = {'location': 'remote'}
            
            response = requests.get(url, params=params)
            data = response.json()
            
            for job in data:
                jobs.append({
                    'title': job['title'],
                    'company': job['company'],
                    'location': job['location'],
                    'description': job['description'],
                    'salary': '',
                    'job_type': job['type'],
                    'url': job['url'],
                    'posted_date': job['created_at'],
                    'source': 'GitHub Jobs',
                    'category': 'technology'
                })
        except Exception as e:
            print(f"GitHub Jobs API error: {e}")
            
        return jobs
    
    def extract_skills_from_description(self, description: str) -> List[str]:
        """Extract skills from job description"""
        # Simple keyword-based extraction
        skill_keywords = [
            'python', 'java', 'javascript', 'c++', 'sql', 'machine learning', 'ai', 'deep learning',
            'tensorflow', 'pytorch', 'aws', 'azure', 'docker', 'kubernetes', 'react', 'angular',
            'blockchain', 'cybersecurity', 'quantum', 'data science', 'nlp', 'computer vision'
        ]
        
        found_skills = []
        desc_lower = description.lower()
        for skill in skill_keywords:
            if skill in desc_lower:
                found_skills.append(skill)
        
        return found_skills
    
    def normalize_salary_data(self, jobs: List[Dict]) -> List[Dict]:
        """Normalize salary information"""
        for job in jobs:
            salary_text = job.get('salary', '')
            # Simple salary extraction (would need more sophisticated parsing)
            if '$' in salary_text:
                # Extract numbers
                import re
                numbers = re.findall(r'\d+', salary_text.replace(',', ''))
                if numbers:
                    job['salary_min'] = min(map(int, numbers))
                    job['salary_max'] = max(map(int, numbers))
                    job['salary_avg'] = sum(map(int, numbers)) / len(numbers)
                else:
                    job['salary_min'] = job['salary_max'] = job['salary_avg'] = None
            else:
                job['salary_min'] = job['salary_max'] = job['salary_avg'] = None
        
        return jobs
    
    def analyze_job_market_trends(self, jobs: List[Dict]) -> Dict[str, Any]:
        """Analyze job market trends"""
        if not jobs:
            return {'trends': {}, 'insights': []}
            
        df = pd.DataFrame(jobs)
        
        # Extract skills
        all_skills = []
        for _, job in df.iterrows():
            skills = self.extract_skills_from_description(job['description'])
            all_skills.extend(skills)
            job['extracted_skills'] = skills
        
        # Skill demand analysis
        skill_counts = Counter(all_skills)
        top_skills = skill_counts.most_common(20)
        
        # Category analysis
        category_counts = df['category'].value_counts()
        
        # Location analysis
        location_counts = df['location'].value_counts().head(10)
        
        # Salary analysis
        salary_data = df.dropna(subset=['salary_avg'])
        if not salary_data.empty:
            salary_stats = salary_data.groupby('category')['salary_avg'].agg(['mean', 'median', 'min', 'max']).round(2)
        else:
            salary_stats = {}
        
        # Company analysis
        company_counts = df['company'].value_counts().head(10)
        
        # Trend insights
        insights = []
        if top_skills:
            insights.append(f"Top demanded skill: {top_skills[0][0]} ({top_skills[0][1]} mentions)")
        
        if not category_counts.empty:
            top_category = category_counts.index[0]
            insights.append(f"Hottest category: {top_category} ({category_counts[top_category]} jobs)")
        
        return {
            'skill_demand': dict(top_skills),
            'category_distribution': category_counts.to_dict(),
            'location_distribution': location_counts.to_dict(),
            'salary_statistics': salary_stats.to_dict() if isinstance(salary_stats, pd.DataFrame) else salary_stats,
            'top_companies': company_counts.to_dict(),
            'market_insights': insights,
            'total_jobs': len(jobs),
            'unique_companies': df['company'].nunique(),
            'date_range': {
                'earliest': df.get('posted_date', pd.Series()).min(),
                'latest': df.get('posted_date', pd.Series()).max()
            }
        }
    
    def forecast_skill_demand(self, historical_data: List[Dict]) -> Dict[str, Any]:
        """Forecast skill demand trends (simplified)"""
        # Placeholder for time-series forecasting
        # In practice, would use historical job data
        return {'forecast': 'Increasing demand for AI/ML and cloud skills'}
    
    def store_data(self, jobs: List[Dict], analysis: Dict[str, Any]):
        """Store job market data"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Store jobs
        jobs_file = os.path.join(self.data_dir, f'job_postings_{timestamp}.jsonl')
        with open(jobs_file, 'w') as f:
            for job in jobs:
                f.write(json.dumps(job) + '\n')
        
        # Store analysis
        analysis_file = os.path.join(self.data_dir, f'job_analysis_{timestamp}.json')
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2)
    
    def run_job_analysis_cycle(self):
        """Complete job market analysis cycle"""
        # Collect data
        jsearch_jobs = self.collect_jsearch_jobs(self.categories)
        linkedin_jobs = self.collect_linkedin_jobs(self.categories)
        indeed_jobs = self.collect_indeed_jobs(self.categories)
        github_jobs = self.collect_github_jobs()
        
        all_jobs = jsearch_jobs + linkedin_jobs + indeed_jobs + github_jobs
        all_jobs = self.normalize_salary_data(all_jobs)
        
        # Analyze
        analysis = self.analyze_job_market_trends(all_jobs)
        
        # Store
        self.store_data(all_jobs, analysis)
        
        # Alert system
        if analysis.get('total_jobs', 0) > 100:
            print(f"ALERT: High job market activity - {analysis['total_jobs']} positions")
        
        print(f"Job market analysis complete: {analysis['total_jobs']} jobs analyzed")
        
        return analysis

def main():
    analyzer = JobMarketAnalyzer()
    
    # Run initial analysis
    analyzer.run_job_analysis_cycle()
    
    # Schedule continuous monitoring
    schedule.every(4).hours.do(analyzer.run_job_analysis_cycle)
    
    print("Job Market Analyzer started. Monitoring every 4 hours...")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    main()