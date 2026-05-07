-- =============================================
-- SEED DATA FOR SUPABASE (Safe Version)
-- =============================================

BEGIN;

-- 1. Regions
TRUNCATE TABLE regions RESTART IDENTITY CASCADE;

INSERT INTO regions (region_code, region_name, island_group) VALUES
('NCR',  'National Capital Region', 'Luzon'),
('CAR',  'Cordillera Administrative Region', 'Luzon'),
('R01',  'Region I — Ilocos Region', 'Luzon'),
('R02',  'Region II — Cagayan Valley', 'Luzon'),
('R03',  'Region III — Central Luzon', 'Luzon'),
('R04A', 'Region IV-A — CALABARZON', 'Luzon'),
('R04B', 'Region IV-B — MIMAROPA', 'Luzon'),
('R05',  'Region V — Bicol Region', 'Luzon'),
('R06',  'Region VI — Western Visayas', 'Visayas'),
('R07',  'Region VII — Central Visayas', 'Visayas'),
('R08',  'Region VIII — Eastern Visayas', 'Visayas'),
('R09',  'Region IX — Zamboanga Peninsula', 'Mindanao'),
('R10',  'Region X — Northern Mindanao', 'Mindanao'),
('R11',  'Region XI — Davao Region', 'Mindanao'),
('R12',  'Region XII — SOCCSKSARGEN', 'Mindanao'),
('R13',  'Region XIII — Caraga', 'Mindanao'),
('BARMM','Bangsamoro Autonomous Region in Muslim Mindanao', 'Mindanao');

-- 2. Facilities
TRUNCATE TABLE facilities RESTART IDENTITY CASCADE;

INSERT INTO facilities (facility_name, facility_type, region_id, province, municipality, is_art_hub) VALUES
('San Lazaro Hospital', 'government_hospital', 1, 'Metro Manila', 'Manila', TRUE),
('Philippine General Hospital', 'government_hospital', 1, 'Metro Manila', 'Manila', TRUE),
('Makati Medical Center', 'private_hospital', 1, 'Metro Manila', 'Makati', FALSE),
('Jose B. Lingad Memorial Regional Hospital', 'government_hospital', 5, 'Pampanga', 'San Fernando', TRUE),
('Vicente Sotto Memorial Medical Center', 'government_hospital', 10, 'Cebu', 'Cebu City', TRUE),
('Southern Philippines Medical Center', 'government_hospital', 14, 'Davao del Sur', 'Davao City', TRUE),
('Davao Regional Medical Center', 'government_hospital', 14, 'Davao del Norte', 'Tagum', FALSE);

-- 3. Users
TRUNCATE TABLE users RESTART IDENTITY CASCADE;

INSERT INTO users (full_name, email, password_hash, role, region_id, facility_id, is_active) VALUES
('System Administrator', 'admin@doh.gov.ph', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', NULL, NULL, TRUE),
('Dr. Maria Santos', 'health.officer.ncr@doh.gov.ph', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'health_officer', 1, 1, TRUE),
('Dr. Jose Reyes', 'health.officer.r11@doh.gov.ph', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'health_officer', 14, 6, TRUE),
('Prof. Ana Dela Cruz', 'researcher@doh.gov.ph', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'researcher', NULL, NULL, TRUE),
('Juan Dela Cruz', 'encoder@doh.gov.ph', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'data_encoder', 1, 1, TRUE);

COMMIT;

-- Final Status
DO $$
BEGIN
    RAISE NOTICE '🎉 SEED DATA SUCCESSFULLY INSERTED!';
    RAISE NOTICE 'Regions   : %', (SELECT COUNT(*) FROM regions);
    RAISE NOTICE 'Facilities: %', (SELECT COUNT(*) FROM facilities);
    RAISE NOTICE 'Users     : %', (SELECT COUNT(*) FROM users);
END $$;