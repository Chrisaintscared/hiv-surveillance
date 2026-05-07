-- =============================================================================
-- Fixed Database Views
-- Run AFTER indexes.sql
-- =============================================================================

-- Active Cases
CREATE OR REPLACE VIEW v_active_cases AS
SELECT 
    hc.*,
    r.region_code,
    r.region_name,
    r.island_group,
    f.facility_name,
    f.facility_type,
    f.is_art_hub,
    u.full_name AS entered_by_name,
    v.full_name AS verified_by_name
FROM hiv_cases hc
LEFT JOIN regions r ON hc.region_id = r.id
LEFT JOIN facilities f ON hc.facility_id = f.id
LEFT JOIN users u ON hc.entered_by = u.id
LEFT JOIN users v ON hc.verified_by = v.id
WHERE hc.is_active = TRUE;

-- Annual Summary
CREATE OR REPLACE VIEW v_annual_case_counts AS
SELECT 
    hc.year_reported,
    r.region_name,
    COUNT(*) AS total_cases,
    COUNT(*) FILTER (WHERE hc.gender = 'male') AS male,
    COUNT(*) FILTER (WHERE hc.gender = 'female') AS female,
    COUNT(*) FILTER (WHERE hc.art_status = 'on_art') AS on_art,
    ROUND(COUNT(*) FILTER (WHERE hc.art_status = 'on_art')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS art_coverage_pct
FROM hiv_cases hc
LEFT JOIN regions r ON hc.region_id = r.id
WHERE hc.is_active = TRUE
GROUP BY hc.year_reported, r.region_name
ORDER BY hc.year_reported DESC;

-- Dashboard Summary
CREATE OR REPLACE VIEW v_dashboard_summary AS
SELECT
    COUNT(*) AS total_active_cases,
    COUNT(*) FILTER (WHERE year_reported = EXTRACT(YEAR FROM NOW())::int) AS cases_this_year,
    COUNT(*) FILTER (WHERE art_status = 'on_art') AS total_on_art,
    ROUND(COUNT(*) FILTER (WHERE art_status = 'on_art')::NUMERIC / NULLIF(COUNT(*),0) * 100, 2) AS overall_art_pct,
    COUNT(*) FILTER (WHERE is_deceased = TRUE) AS total_deceased
FROM hiv_cases
WHERE is_active = TRUE;

-- Other useful views (kept clean)
CREATE OR REPLACE VIEW v_facility_performance AS
SELECT 
    f.facility_name,
    r.region_name,
    COUNT(hc.id) AS total_cases,
    COUNT(CASE WHEN hc.art_status = 'on_art' THEN 1 END) AS on_art,
    MAX(hc.created_at) AS last_submission
FROM facilities f
LEFT JOIN regions r ON f.region_id = r.id
LEFT JOIN hiv_cases hc ON hc.facility_id = f.id AND hc.is_active = TRUE
WHERE f.is_active = TRUE
GROUP BY f.id, f.facility_name, r.region_name;

-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Views created successfully. Next: Run seed.sql';
END $$;