USE HealthCare_HMS;

SELECT '--- Starting Security Testing (Database Level) ---' AS Status;

-- 5.4.1. Verify User Privileges
-- List all users and their global privileges
SELECT 'Listing global user privileges...' AS Test;
SELECT user, host, authentication_string, account_locked, password_expired FROM mysql.user;
-- Expected: Only 'root' or dedicated admin users should have extensive global privileges.

-- List specific grants for your created users
SELECT 'Listing grants for specific users...' AS Test;
SHOW GRANTS FOR 'admin_db'@'localhost';
SHOW GRANTS FOR 'dralex.chen'@'localhost';
SHOW GRANTS FOR 'janerecept'@'localhost';
-- Expected: 'admin_db' should have broad access to 'healthcare_hms'.
-- 'dralex.chen' should only have SELECT, INSERT, UPDATE, DELETE on relevant tables (MedicalRecords, Appointments, Prescriptions).
-- 'janerecept' should only have SELECT on views like 'ReceptionistPatientInfo', 'DoctorScheduleToday', and maybe basic Patients.

-- Test a restricted user trying to perform an unauthorized action
SELECT 'Testing restricted user (janerecept) trying to delete Patients...' AS Test;
-- Expected: Error (Access denied)
-- Note: You would need to connect as 'janerecept' to fully test this.
-- Example of connecting as janerecept from command line: mysql -u janerecept -p
-- Then run:
-- USE healthcare_hms;
-- DELETE FROM Patients WHERE patient_id = 1; -- This should fail with "Access denied"
-- Back to root:
SELECT 'Manual test: Try connecting as `janerecept` and attempting unauthorized DML/DDL.' AS Status;


-- 5.4.2. Data Encryption (Conceptual for MySQL-only context)
-- Data at Rest:
-- MySQL supports Transparent Data Encryption (TDE) for InnoDB tablespaces (MySQL Enterprise Edition).
-- This would be configured at the server level, not via SQL scripts for schema.
-- SQL: You can verify if it's enabled if you have Enterprise Edition.
-- SHOW VARIABLES LIKE 'innodb_encrypt_tables'; (If using TDE)

-- Data in Transit:
-- Ensure client connections use SSL/TLS. This is configured in the client connection string and MySQL server settings.
-- SQL: Check SSL status
SHOW STATUS LIKE 'Ssl_cipher';
-- Expected: Value indicating an active cipher for current connection, or empty if not SSL.
-- You would explicitly connect with SSL from your client (e.g., `mysql --ssl-mode=REQUIRED ...`).

SELECT '--- Security Testing Complete. Manual verification of user permissions and connection security is crucial. ---' AS Status;
