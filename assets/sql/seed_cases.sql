-- =============================================
-- HIV CASES SEED DATA (Realistic Sample)
-- Run AFTER seed.sql
-- =============================================

BEGIN;

TRUNCATE TABLE hiv_cases RESTART IDENTITY CASCADE;

INSERT INTO hiv_cases (
    case_code, year_reported, month_reported, date_diagnosed,
    age_at_diagnosis, gender, nationality,
    region_id, facility_id, province, municipality,
    transmission_mode, sexual_mode,
    hiv_stage, art_status, cd4_count, viral_load_status,
    is_deceased, data_quality_flag, entered_by
) VALUES

-- 2025 Cases (Recent)
('HIV-2025-0001', 2025, 1, '2025-01-15', 28, 'male', 'Filipino', 1, 1, 'Metro Manila', 'Manila', 'sexual', 'msm', 'stage2', 'on_art', 450, 'undetectable', FALSE, 'verified', 2),
('HIV-2025-0002', 2025, 2, '2025-02-03', 22, 'male', 'Filipino', 1, 2, 'Metro Manila', 'Quezon City', 'sexual', 'msm', 'stage1', 'on_art', 720, 'undetectable', FALSE, 'verified', 5),
('HIV-2025-0003', 2025, 3, '2025-03-20', 34, 'female', 'Filipino', 1, 1, 'Metro Manila', 'Manila', 'sexual', 'heterosexual', 'stage3', 'not_yet', 180, 'detectable', FALSE, 'complete', 2),
('HIV-2025-0004', 2025, 1, '2025-01-28', 19, 'male', 'Filipino', 14, 6, 'Davao del Sur', 'Davao City', 'sexual', 'msm', 'stage1', 'on_art', 890, 'undetectable', FALSE, 'verified', 3),

-- 2024 Cases
('HIV-2024-0123', 2024, 11, '2024-11-10', 31, 'male', 'Filipino', 5, 4, 'Pampanga', 'San Fernando', 'sexual', 'msm', 'stage2', 'on_art', 320, 'low', FALSE, 'verified', 2),
('HIV-2024-0456', 2024, 8, '2024-08-15', 27, 'female', 'Filipino', 10, 5, 'Cebu', 'Cebu City', 'sexual', 'heterosexual', 'stage1', 'on_art', 650, 'undetectable', FALSE, 'verified', 5),
('HIV-2024-0789', 2024, 12, '2024-12-05', 42, 'male', 'Filipino', 1, 3, 'Metro Manila', 'Makati', 'sexual', 'bisexual', 'aids', 'on_art', 95, 'detectable', FALSE, 'verified', 2),

-- 2023 Cases
('HIV-2023-1122', 2023, 6, '2023-06-22', 25, 'male', 'Filipino', 14, 7, 'Davao del Norte', 'Tagum', 'sexual', 'msm', 'stage2', 'on_art', 410, 'undetectable', FALSE, 'complete', 3),
('HIV-2023-3344', 2023, 9, '2023-09-12', 36, 'transgender', 'Filipino', 1, 1, 'Metro Manila', 'Manila', 'sexual', 'msm', 'stage3', 'lost_to_followup', 210, 'high', FALSE, 'flagged', 2),
('HIV-2023-5566', 2023, 4, '2023-04-18', 29, 'male', 'Filipino', 10, 5, 'Cebu', 'Cebu City', 'sexual', 'heterosexual', 'stage1', 'on_art', 780, 'undetectable', FALSE, 'verified', 5),

-- Additional varied cases
('HIV-2025-0010', 2025, 4, '2025-04-02', 17, 'male', 'Filipino', 1, 1, 'Metro Manila', 'Pasig', 'sexual', 'msm', 'stage1', 'not_yet', 890, 'not_tested', FALSE, 'pending_verification', 5),
('HIV-2024-0901', 2024, 7, '2024-07-25', 51, 'male', 'Filipino', 5, 4, 'Pampanga', 'Angeles', 'blood_transfusion', 'not_applicable', 'stage3', 'deceased', 45, 'high', TRUE, 'verified', 2),
('HIV-2023-7788', 2023, 10, '2023-10-30', 24, 'female', 'Filipino', 14, 6, 'Davao del Sur', 'Davao City', 'mtct', 'not_applicable', 'stage2', 'on_art', 550, 'low', FALSE, 'verified', 3),
('HIV-2025-0015', 2025, 5, '2025-05-01', 33, 'male', 'Filipino', 1, 2, 'Metro Manila', 'Quezon City', 'sexual', 'msm', 'stage1', 'on_art', 680, 'undetectable', FALSE, 'verified', 2);

COMMIT;

-- Final Status
DO $$
BEGIN
    RAISE NOTICE '🎉 HIV CASES SEED SUCCESSFULLY INSERTED!';
    RAISE NOTICE 'Total HIV Cases: %', (SELECT COUNT(*) FROM hiv_cases);
    RAISE NOTICE '2025 Cases: %', (SELECT COUNT(*) FROM hiv_cases WHERE year_reported = 2025);
END $$;