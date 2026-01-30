-- IIC Insights Database Schema
-- Integrated Insurance Corp Research Database
-- Date: January 29, 2026

CREATE DATABASE IF NOT EXISTS iic_insights;
USE iic_insights;

-- Core insights table
CREATE TABLE insights (
    id INT PRIMARY KEY AUTO_INCREMENT,
    insight_number INT UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    source_company VARCHAR(100),
    source_country VARCHAR(50),
    research_date DATE,
    insight_type ENUM('market', 'technology', 'operational', 'strategic') NOT NULL,
    confidence_level ENUM('high', 'medium', 'low') DEFAULT 'medium',
    impact_potential ENUM('transformative', 'significant', 'moderate', 'incremental') DEFAULT 'moderate',
    implementation_complexity ENUM('low', 'medium', 'high', 'very_high') DEFAULT 'medium',
    timeline ENUM('immediate', 'short_term', 'medium_term', 'long_term') DEFAULT 'medium_term',
    key_findings TEXT,
    actionable_recommendations TEXT,
    data_sources TEXT,
    researcher_name VARCHAR(100) DEFAULT 'BigBrain Intelligence',
    review_status ENUM('draft', 'reviewed', 'approved') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_category (category),
    INDEX idx_insight_type (insight_type),
    INDEX idx_confidence (confidence_level),
    INDEX idx_impact (impact_potential),
    INDEX idx_timeline (timeline)
);

-- Companies analyzed table
CREATE TABLE companies_analyzed (
    id INT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(255) NOT NULL,
    country VARCHAR(50),
    market_cap DECIMAL(15,2),
    annual_premium DECIMAL(15,2),
    employee_count INT,
    technology_maturity ENUM('traditional', 'digital', 'advanced', 'leading') DEFAULT 'digital',
    innovation_score INT CHECK (innovation_score >= 0 AND innovation_score <= 100),
    key_products TEXT,
    strategic_focus TEXT,
    analyzed_date DATE DEFAULT (CURRENT_DATE),

    INDEX idx_country (country),
    INDEX idx_tech_maturity (technology_maturity),
    INDEX idx_innovation_score (innovation_score)
);

-- Market data table
CREATE TABLE market_data (
    id INT PRIMARY KEY AUTO_INCREMENT,
    country VARCHAR(50) NOT NULL,
    market_size DECIMAL(15,2), -- in billions USD
    growth_rate DECIMAL(5,2), -- percentage
    penetration_rate DECIMAL(5,2), -- percentage
    regulatory_framework TEXT,
    key_players TEXT,
    emerging_trends TEXT,
    data_year YEAR NOT NULL,

    INDEX idx_country_year (country, data_year)
);

-- Technology trends table
CREATE TABLE technology_trends (
    id INT PRIMARY KEY AUTO_INCREMENT,
    technology_name VARCHAR(100) NOT NULL,
    adoption_rate DECIMAL(5,2), -- percentage
    market_maturity ENUM('emerging', 'growing', 'mature') DEFAULT 'emerging',
    key_use_cases TEXT,
    implementation_challenges TEXT,
    cost_benefit_analysis TEXT,
    timeline_assessment VARCHAR(50),

    INDEX idx_maturity (market_maturity)
);

-- Innovation pipeline table
CREATE TABLE innovation_pipeline (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    development_stage ENUM('concept', 'prototype', 'pilot', 'production', 'launched') DEFAULT 'concept',
    estimated_completion DATE,
    resource_requirement TEXT,
    expected_roi DECIMAL(5,2),
    risk_level ENUM('low', 'medium', 'high') DEFAULT 'medium',
    assigned_team VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_stage (development_stage),
    INDEX idx_category (category)
);

-- Claims analytics table
CREATE TABLE claims_analytics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    claim_type VARCHAR(100),
    average_processing_time INT, -- in days
    automation_potential DECIMAL(5,2), -- percentage
    fraud_detection_rate DECIMAL(5,2), -- percentage
    customer_satisfaction DECIMAL(3,1), -- 1-5 scale
    cost_per_claim DECIMAL(10,2),
    data_date DATE,

    INDEX idx_claim_type (claim_type)
);

-- Regulatory compliance table
CREATE TABLE regulatory_compliance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    jurisdiction VARCHAR(100) NOT NULL,
    regulation_name VARCHAR(255) NOT NULL,
    compliance_requirement TEXT,
    implementation_deadline DATE,
    compliance_status ENUM('not_started', 'in_progress', 'compliant', 'exempt') DEFAULT 'not_started',
    responsible_party VARCHAR(100),
    last_reviewed DATE,

    INDEX idx_jurisdiction (jurisdiction),
    INDEX idx_status (compliance_status)
);</content>
<parameter name="filePath">c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\IntegratedInsuranceCorp\iic_database_schema.sql