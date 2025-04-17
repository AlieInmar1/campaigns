-- Check and verify provider and prescription tables
BEGIN;

-- Check providers table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'providers';

-- Check prescriptions table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'prescriptions';

-- Check medications table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'medications';

-- Check sample data
SELECT p.provider_id, p.name, p.specialty, p.geographic_area,
       COUNT(DISTINCT pr.medication_id) as medication_count
FROM providers p
LEFT JOIN prescriptions pr ON p.provider_id = pr.provider_id
GROUP BY p.provider_id, p.name, p.specialty, p.geographic_area
LIMIT 5;

-- Check medication categories
SELECT DISTINCT category
FROM medications
WHERE category IS NOT NULL
ORDER BY category;

-- Check provider specialties
SELECT DISTINCT specialty
FROM providers
WHERE specialty IS NOT NULL
ORDER BY specialty;

-- Check geographic areas
SELECT DISTINCT geographic_area
FROM providers
WHERE geographic_area IS NOT NULL
ORDER BY geographic_area;

-- Check prescription counts
SELECT COUNT(*) as total_prescriptions,
       COUNT(DISTINCT provider_id) as unique_providers,
       COUNT(DISTINCT medication_id) as unique_medications
FROM prescriptions;

COMMIT;
