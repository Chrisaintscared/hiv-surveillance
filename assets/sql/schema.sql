-- =============================================================================
-- HIV & AIDS Surveillance Data Repository System
-- Philippine Department of Health
-- Fixed Database Schema — PostgreSQL 15+
-- Run this file FIRST
-- =============================================================================

-- Drop existing tables if rebuilding (in correct dependency order)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS alert_thresholds CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS awareness_content CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS hiv_cases CASCADE;
DROP TABLE IF EXISTS facilities CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS regions CASCADE;

-- =============================================================================
-- EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For trigram-based full-text search

-- =============================================================================
-- REGIONS TABLE
-- =============================================================================
CREATE TABLE regions (
    id              SERIAL PRIMARY KEY,
    region_code     VARCHAR(20) UNIQUE NOT NULL,
    region_name     VARCHAR(100) NOT NULL,
    island_group    VARCHAR(30) CHECK (island_group IN ('Luzon', 'Visayas', 'Mindanao')),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- USERS TABLE
-- =============================================================================
CREATE TABLE users (
    id                      SERIAL PRIMARY KEY,
    full_name               VARCHAR(150) NOT NULL,
    email                   VARCHAR(150) UNIQUE NOT NULL,
    password_hash           VARCHAR(255) NOT NULL,
    role                    VARCHAR(30) NOT NULL CHECK (role IN ('admin', 'health_officer', 'researcher', 'data_encoder', 'viewer')),
    region_id               INTEGER REFERENCES regions(id) ON DELETE SET NULL,
    facility_id             INTEGER,                    -- FK will be added after facilities table
    is_active               BOOLEAN DEFAULT TRUE,
    last_login              TIMESTAMP,
    failed_login_attempts   INTEGER DEFAULT 0,
    locked_until            TIMESTAMP,
    password_reset_token    VARCHAR(100),
    password_reset_expires  TIMESTAMP,
    must_change_password    BOOLEAN DEFAULT FALSE,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- FACILITIES TABLE
-- =============================================================================
CREATE TABLE facilities (
    id                  SERIAL PRIMARY KEY,
    facility_name       VARCHAR(200) NOT NULL,
    facility_type       VARCHAR(50) CHECK (facility_type IN ('government_hospital', 'private_hospital', 'health_center', 'clinic', 'treatment_hub', 'social_hygiene_clinic', 'other')),
    region_id           INTEGER REFERENCES regions(id) ON DELETE SET NULL,
    province            VARCHAR(100),
    municipality        VARCHAR(100),
    address             TEXT,
    contact_number      VARCHAR(30),
    email               VARCHAR(150),
    is_art_hub          BOOLEAN DEFAULT FALSE,
    is_active           BOOLEAN DEFAULT TRUE,
    last_report_date    DATE,
    total_cases         INTEGER DEFAULT 0,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- Add foreign key for users.facility_id after facilities table exists
ALTER TABLE users 
    ADD CONSTRAINT fk_users_facility 
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL;

-- =============================================================================
-- HIV_CASES TABLE (Core Table)
-- =============================================================================
CREATE TABLE hiv_cases (
    id                          SERIAL PRIMARY KEY,
    case_code                   VARCHAR(30) UNIQUE NOT NULL,
    year_reported               INTEGER NOT NULL CHECK (year_reported >= 1984),
    month_reported              INTEGER CHECK (month_reported BETWEEN 1 AND 12),
    date_diagnosed              DATE,
    date_enrolled_art           DATE,

    age_at_diagnosis            INTEGER CHECK (age_at_diagnosis BETWEEN 0 AND 120),
    age_group                   VARCHAR(20),
    gender                      VARCHAR(20) CHECK (gender IN ('male', 'female', 'transgender', 'other')),
    nationality                 VARCHAR(50) DEFAULT 'Filipino',

    region_id                   INTEGER REFERENCES regions(id) ON DELETE SET NULL,
    facility_id                 INTEGER REFERENCES facilities(id) ON DELETE SET NULL,
    province                    VARCHAR(100),
    municipality                VARCHAR(100),

    transmission_mode           VARCHAR(30) CHECK (transmission_mode IN ('sexual', 'blood_transfusion', 'needle_sharing', 'mtct', 'occupational', 'unknown')),
    sexual_mode                 VARCHAR(30) CHECK (sexual_mode IN ('msm', 'heterosexual', 'bisexual', 'not_applicable', 'unknown')),

    hiv_stage                   VARCHAR(20) CHECK (hiv_stage IN ('stage1', 'stage2', 'stage3', 'aids')),
    art_status                  VARCHAR(30) CHECK (art_status IN ('on_art', 'not_yet', 'lost_to_followup', 'deceased', 'transferred')),
    cd4_count                   INTEGER CHECK (cd4_count >= 0),
    viral_load_copies           BIGINT CHECK (viral_load_copies >= 0),
    viral_load_status           VARCHAR(20) CHECK (viral_load_status IN ('undetectable', 'low', 'detectable', 'high', 'not_tested')),
    opportunistic_infections    TEXT[],
    comorbidities               TEXT[],

    is_deceased                 BOOLEAN DEFAULT FALSE,
    date_of_death               DATE,
    cause_of_death              TEXT,

    data_quality_flag           VARCHAR(20) DEFAULT 'complete' CHECK (data_quality_flag IN ('complete', 'incomplete', 'pending_verification', 'verified', 'flagged')),
    is_active                   BOOLEAN DEFAULT TRUE,

    entered_by                  INTEGER REFERENCES users(id) ON DELETE SET NULL,
    verified_by                 INTEGER REFERENCES users(id) ON DELETE SET NULL,

    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- REPORTS, ALERTS, AWARENESS, AUDIT, SETTINGS, THRESHOLDS
-- =============================================================================
CREATE TABLE reports (
    id              SERIAL PRIMARY KEY,
    report_title    VARCHAR(200) NOT NULL,
    report_type     VARCHAR(30) CHECK (report_type IN ('monthly','quarterly','annual','custom','regional')),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    region_id       INTEGER REFERENCES regions(id) ON DELETE SET NULL,
    parameters      JSONB,
    file_path       VARCHAR(255),
    file_size       INTEGER,
    file_format     VARCHAR(10) DEFAULT 'pdf' CHECK (file_format IN ('pdf', 'xlsx', 'csv')),
    generated_by    INTEGER REFERENCES users(id) ON DELETE SET NULL,
    generated_at    TIMESTAMP DEFAULT NOW(),
    download_count  INTEGER DEFAULT 0,
    is_deleted      BOOLEAN DEFAULT FALSE
);

CREATE TABLE alerts (
    id                  SERIAL PRIMARY KEY,
    alert_type          VARCHAR(20) CHECK (alert_type IN ('critical','warning','info','success')),
    category            VARCHAR(50),
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    region_id           INTEGER REFERENCES regions(id) ON DELETE SET NULL,
    threshold_metric    VARCHAR(100),
    threshold_value     NUMERIC,
    actual_value        NUMERIC,
    is_auto_generated   BOOLEAN DEFAULT FALSE,
    is_resolved         BOOLEAN DEFAULT FALSE,
    resolved_at         TIMESTAMP,
    resolved_by         INTEGER REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes    TEXT,
    triggered_at        TIMESTAMP DEFAULT NOW(),
    expires_at          TIMESTAMP
);

CREATE TABLE awareness_content (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    category        VARCHAR(50) CHECK (category IN ('prevention','testing','treatment','stigma','legal_rights','support_services','transmission','general')),
    content         TEXT NOT NULL,
    icon            VARCHAR(50),
    color_scheme    VARCHAR(30),
    tags            TEXT[],
    is_published    BOOLEAN DEFAULT TRUE,
    display_order   INTEGER DEFAULT 0,
    created_by      INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action          VARCHAR(30) NOT NULL,
    module          VARCHAR(50),
    table_affected  VARCHAR(50),
    record_id       INTEGER,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    additional_info TEXT,
    timestamp       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE system_settings (
    id              SERIAL PRIMARY KEY,
    setting_key     VARCHAR(100) UNIQUE NOT NULL,
    setting_value   TEXT,
    setting_type    VARCHAR(30) CHECK (setting_type IN ('string','integer','boolean','json','email','url')),
    description     TEXT,
    is_public       BOOLEAN DEFAULT FALSE,
    updated_by      INTEGER REFERENCES users(id) ON DELETE SET NULL,
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE alert_thresholds (
    id                  SERIAL PRIMARY KEY,
    metric_name         VARCHAR(100) NOT NULL,
    metric_label        VARCHAR(150),
    critical_threshold  NUMERIC,
    warning_threshold   NUMERIC,
    comparison          VARCHAR(10) CHECK (comparison IN ('gt','lt','gte','lte','eq')),
    unit                VARCHAR(30),
    description         TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- TRIGGERS
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER trg_regions_updated_at      BEFORE UPDATE ON regions        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_users_updated_at        BEFORE UPDATE ON users          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_facilities_updated_at   BEFORE UPDATE ON facilities     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_hiv_cases_updated_at    BEFORE UPDATE ON hiv_cases      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_awareness_updated_at    BEFORE UPDATE ON awareness_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_settings_updated_at     BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_thresholds_updated_at   BEFORE UPDATE ON alert_thresholds FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Prevent audit log tampering
CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit log records cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_no_update BEFORE UPDATE ON audit_logs FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();
CREATE TRIGGER trg_audit_no_delete BEFORE DELETE ON audit_logs FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();

-- Auto compute age_group
CREATE OR REPLACE FUNCTION compute_age_group()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.age_at_diagnosis IS NOT NULL THEN
        NEW.age_group := CASE
            WHEN NEW.age_at_diagnosis < 15  THEN 'under15'
            WHEN NEW.age_at_diagnosis < 25  THEN '15to24'
            WHEN NEW.age_at_diagnosis < 35  THEN '25to34'
            WHEN NEW.age_at_diagnosis < 45  THEN '35to44'
            ELSE '45plus'
        END;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hiv_cases_age_group
    BEFORE INSERT OR UPDATE OF age_at_diagnosis ON hiv_cases
    FOR EACH ROW EXECUTE FUNCTION compute_age_group();

-- Auto update facility case count
CREATE OR REPLACE FUNCTION update_facility_case_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.is_active AND NEW.facility_id IS NOT NULL THEN
        UPDATE facilities SET total_cases = total_cases + 1, last_report_date = CURRENT_DATE
        WHERE id = NEW.facility_id;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.facility_id IS DISTINCT FROM NEW.facility_id THEN
            IF OLD.facility_id IS NOT NULL THEN
                UPDATE facilities SET total_cases = GREATEST(total_cases - 1, 0) WHERE id = OLD.facility_id;
            END IF;
            IF NEW.facility_id IS NOT NULL AND NEW.is_active THEN
                UPDATE facilities SET total_cases = total_cases + 1, last_report_date = CURRENT_DATE WHERE id = NEW.facility_id;
            END IF;
        ELSIF OLD.is_active = TRUE AND NEW.is_active = FALSE AND NEW.facility_id IS NOT NULL THEN
            UPDATE facilities SET total_cases = GREATEST(total_cases - 1, 0) WHERE id = NEW.facility_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_facility_case_count
    AFTER INSERT OR UPDATE ON hiv_cases
    FOR EACH ROW EXECUTE FUNCTION update_facility_case_count();

-- =============================================================================
-- FINAL MESSAGE
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE 'Schema created successfully. Next: Run indexes.sql';
END $$;