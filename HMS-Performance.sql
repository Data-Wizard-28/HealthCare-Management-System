USE HealthCare_HMS;

SELECT '--- Starting Performance Testing and Optimization ---' AS Status;

-- 5.3.1. Analyze Slow Queries using EXPLAIN
-- Identify some complex or frequently used queries (e.g., from your views or stored procedures).
-- Run EXPLAIN before them to see the execution plan.

-- Example 1: Analyzing GetPatientMedicalHistory's subqueries or joins
SELECT 'Analyzing complex query for patient medical records (simplified example)...' AS Test;
EXPLAIN SELECT
    P.first_name, P.last_name, MR.encounter_datetime, MR.diagnosis_description
FROM
    Patients P
JOIN
    MedicalRecords MR ON P.patient_id = MR.patient_id
WHERE
    P.last_name = 'Doe' AND MR.encounter_datetime BETWEEN '2025-01-01' AND '2025-12-31';
-- Look for 'Using filesort', 'Using temporary', full table scans ('type: ALL').
-- Ensure indexes are being used effectively.

-- Example 2: Analyzing a join for doctor's specific appointments
SELECT 'Analyzing doctor appointment query...' AS Test;
EXPLAIN SELECT
    A.appointment_id, A.appointment_datetime, P.first_name, P.last_name
FROM
    Appointments A
JOIN
    Patients P ON A.patient_id = P.patient_id
WHERE
    A.doctor_id = (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen')
    AND A.appointment_datetime >= CURDATE();
-- Ensure indexes on `Appointments.doctor_id` and `Appointments.appointment_datetime` are used.

-- 5.3.2. Index Tuning (Based on EXPLAIN output)
-- If EXPLAIN showed full table scans or poor index usage on frequently queried columns,
-- consider adding or modifying indexes.
-- Example: If you frequently search by patient's email, ensure it's indexed (it is unique already).
-- ALTER TABLE Patients ADD INDEX idx_patients_email (email); -- Already UNIQUE so an index exists

-- Re-evaluating existing indexes:
-- CREATE INDEX idx_appointments_datetime ON Appointments (appointment_datetime); (Already done)
-- Consider composite indexes if queries often filter on multiple columns together (e.g., doctor_id AND appointment_datetime).
-- (Already handled partially by UNIQUE KEY idx_unique_appointment(patient_id, doctor_id, appointment_datetime)
-- which covers searches by patient+doctor+time, but separate indexes are still good for just doctor_id or just datetime)

-- 5.3.3. Analyze and Optimize Tables (For very large tables)
-- For tables that experience many updates/deletes, data can become fragmented.
-- ANALYZE TABLE and OPTIMIZE TABLE can help, though InnoDB handles this somewhat automatically.
SELECT 'Analyzing Patients table...' AS Test;
ANALYZE TABLE Patients;
-- If a table is very large and has seen many deletions/updates, OPTIMIZE TABLE can reclaim space and defragment.
-- OPTIMIZE TABLE Patients; -- Use with caution on production as it can lock the table.

-- 5.3.4. Basic Server Status Monitoring (Directly from MySQL Client)
-- Check current connections, slow queries, etc.
SELECT 'Checking MySQL Server Status (basic)...' AS Test;
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Questions';
SHOW GLOBAL STATUS LIKE 'Slow_queries';
SHOW GLOBAL VARIABLES LIKE 'long_query_time';
-- To enable slow query log, you'd modify MySQL config (my.cnf/my.ini):
-- slow_query_log = 1
-- slow_query_log_file = /var/log/mysql/mysql-slow.log
-- long_query_time = 1

SELECT '--- Performance Testing and Optimization Complete. Review EXPLAIN outputs and consider further index tuning. ---' AS Status;
