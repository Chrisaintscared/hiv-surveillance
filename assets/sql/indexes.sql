-- =============================================================================
-- HIV & AIDS Surveillance Data Repository System
-- Fixed Database Indexes — PostgreSQL 15+
-- Run AFTER schema.sql
-- =============================================================================

-- =============================================================================
-- REGIONS
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_regions_code        ON regions (region_code);
CREATE INDEX IF NOT EXISTS idx_regions_island      ON regions (island_group);
CREATE INDEX IF NOT EXISTS idx_regions_active      ON regions (is_active);

-- =============================================================================
-- USERS
-- =============================================================================
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique 
    ON users (LOWER(email));

CREATE INDEX IF NOT EXISTS idx_users_role          ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_region        ON users (region_id);
CREATE INDEX IF NOT EXISTS idx_users_facility      ON users (facility_id);
CREATE INDEX IF NOT EXISTS idx_users_active        ON users (is_active);
CREATE INDEX IF NOT EXISTS idx_users_last_login    ON users (last_login DESC);

CREATE INDEX IF NOT EXISTS idx_users_reset_token 
    ON users (password_reset_token) 
    WHERE password_reset_token IS NOT NULL;

-- =============================================================================
-- FACILITIES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_facilities_region   ON facilities (region_id);
CREATE INDEX IF NOT EXISTS idx_facilities_type     ON facilities (facility_type);
CREATE INDEX IF NOT EXISTS idx_facilities_art_hub  
    ON facilities (is_art_hub) WHERE is_art_hub = TRUE;

CREATE INDEX IF NOT EXISTS idx_facilities_active   ON facilities (is_active);
CREATE INDEX IF NOT EXISTS idx_facilities_province ON facilities (province);

-- Full-text search
CREATE INDEX IF NOT EXISTS idx_facilities_name_trgm 
    ON facilities USING GIN (facility_name gin_trgm_ops);

-- =============================================================================
-- HIV_CASES (Most Critical)
-- =============================================================================
CREATE UNIQUE INDEX IF NOT EXISTS idx_cases_code_unique 
    ON hiv_cases (case_code);

-- Time-based
CREATE INDEX IF NOT EXISTS idx_cases_year_reported ON hiv_cases (year_reported DESC);
CREATE INDEX IF NOT EXISTS idx_cases_year_month    
    ON hiv_cases (year_reported DESC, month_reported DESC);
CREATE INDEX IF NOT EXISTS idx_cases_date_diagnosed 
    ON hiv_cases (date_diagnosed DESC);

-- Geographic
CREATE INDEX IF NOT EXISTS idx_cases_region        ON hiv_cases (region_id);
CREATE INDEX IF NOT EXISTS idx_cases_facility      ON hiv_cases (facility_id);
CREATE INDEX IF NOT EXISTS idx_cases_province      ON hiv_cases (province);
CREATE INDEX IF NOT EXISTS idx_cases_municipality  ON hiv_cases (municipality);

-- Demographic & Clinical
CREATE INDEX IF NOT EXISTS idx_cases_gender        ON hiv_cases (gender);
CREATE INDEX IF NOT EXISTS idx_cases_age_group     ON hiv_cases (age_group);
CREATE INDEX IF NOT EXISTS idx_cases_art_status    ON hiv_cases (art_status);
CREATE INDEX IF NOT EXISTS idx_cases_hiv_stage     ON hiv_cases (hiv_stage);
CREATE INDEX IF NOT EXISTS idx_cases_transmission  ON hiv_cases (transmission_mode);
CREATE INDEX IF NOT EXISTS idx_cases_viral_load    ON hiv_cases (viral_load_status);

-- Outcome
CREATE INDEX IF NOT EXISTS idx_cases_deceased 
    ON hiv_cases (is_deceased) WHERE is_deceased = TRUE;

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_cases_region_year   
    ON hiv_cases (region_id, year_reported DESC);
CREATE INDEX IF NOT EXISTS idx_cases_year_gender   
    ON hiv_cases (year_reported, gender);
CREATE INDEX IF NOT EXISTS idx_cases_year_art      
    ON hiv_cases (year_reported, art_status);
CREATE INDEX IF NOT EXISTS idx_cases_active_year_region 
    ON hiv_cases (is_active, year_reported DESC, region_id) 
    WHERE is_active = TRUE;

-- Full-text
CREATE INDEX IF NOT EXISTS idx_cases_code_trgm 
    ON hiv_cases USING GIN (case_code gin_trgm_ops);

-- =============================================================================
-- OTHER TABLES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_reports_type        ON reports (report_type);
CREATE INDEX IF NOT EXISTS idx_reports_generated   ON reports (generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_unresolved   
    ON alerts (is_resolved, triggered_at DESC) WHERE is_resolved = FALSE;
CREATE INDEX IF NOT EXISTS idx_awareness_published 
    ON awareness_content (is_published, display_order) WHERE is_published = TRUE;

-- Audit
CREATE INDEX IF NOT EXISTS idx_audit_user_time    
    ON audit_logs (user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp    
    ON audit_logs (timestamp DESC);

-- =============================================================================
-- COMPLETE
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Indexes created successfully. Next: Run views.sql';
END $$;