USE HealthCare_HMS;

SELECT '--- Starting Phase 5: Data Integrity Testing ---' AS Status;

-- 5.1.1. Test NOT NULL Constraints
-- Attempt to insert a patient without a first_name (NOT NULL)
SELECT 'Testing NOT NULL constraint on Patients.first_name...' AS Test;
-- Expected: Error (Cannot be NULL)
-- If this query produces an error, the constraint is working.
-- If it succeeds, the constraint is NOT working.
START TRANSACTION;
INSERT INTO Patients (last_name, date_of_birth, gender, phone_number) VALUES
('NullNameTest', '1990-01-01', 'Male', '555-NULL-1111');
-- You will need to ROLLBACK this transaction to clean up any partial insertions
ROLLBACK;
SELECT 'NOT NULL test attempted. Check for error message above.' AS Status;

-- 5.1.2. Test UNIQUE Constraints
-- Attempt to insert a patient with a duplicate phone_number
SELECT 'Testing UNIQUE constraint on Patients.phone_number...' AS Test;
-- Expected: Error (Duplicate entry for key 'phone_number')
START TRANSACTION;
INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone_number) VALUES
('Duplicate', 'Phone', '1980-02-02', 'Female', '555-101-2020'); -- John Doe's number
ROLLBACK;
SELECT 'UNIQUE phone_number test attempted. Check for error message above.' AS Status;

-- Attempt to insert a doctor with a duplicate license_number
SELECT 'Testing UNIQUE constraint on Doctors.license_number...' AS Test;
-- Expected: Error (Duplicate entry for key 'license_number')
START TRANSACTION;
INSERT INTO Doctors (first_name, last_name, specialty_id, license_number, hire_date) VALUES
('Dr. Duplicate', 'License', (SELECT specialty_id FROM MedicalSpecialties WHERE specialty_name = 'General Practice'), 'MD1001', '2023-01-01'); -- Dr. Alex Chen's license
ROLLBACK;
SELECT 'UNIQUE license_number test attempted. Check for error message above.' AS Status;

-- 5.1.3. Test FOREIGN KEY Constraints (ON DELETE RESTRICT and ON UPDATE CASCADE)
-- Test ON DELETE RESTRICT: Try to delete a doctor who has appointments
SELECT 'Testing ON DELETE RESTRICT for Doctors...' AS Test;
-- Expected: Error (Cannot delete or update a parent row: a foreign key constraint fails)
START TRANSACTION;
DELETE FROM Doctors WHERE doctor_id = (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen' LIMIT 1);
ROLLBACK;
SELECT 'ON DELETE RESTRICT test attempted. Check for error message above.' AS Status;

-- Test ON UPDATE CASCADE: Update a patient_id (assuming an old system had non-auto-increment PKs that changed)
-- For AUTO_INCREMENT PKs, typically they don't change, but FK cascade still works if they did.
-- Let's simulate an update on a doctor's PK and see if appointments update.
SELECT 'Testing ON UPDATE CASCADE for Doctors...' AS Test;
-- NOTE: Directly updating an AUTO_INCREMENT PK is highly unusual and generally discouraged.
-- This is primarily to demonstrate the CASCADE effect if a PK were to change.
-- For this test, we might need a temporary table or careful setup.
-- More practical test: update a FK-referenced lookup table value, e.g., MedicalSpecialties
START TRANSACTION;
UPDATE MedicalSpecialties SET specialty_id = 999 WHERE specialty_name = 'General Practice';
-- Check if Doctors.specialty_id for Dr. Chen changed to 999
SELECT d.first_name, d.last_name, d.specialty_id, ms.specialty_name
FROM Doctors d JOIN MedicalSpecialties ms ON d.specialty_id = ms.specialty_id
WHERE d.last_name = 'Chen';
ROLLBACK; -- Revert the change to keep original IDs
SELECT 'ON UPDATE CASCADE test on MedicalSpecialties attempted. Verify specialty_id changed for Dr. Chen and reverted.' AS Status;


-- 5.1.4. Test CHECK Constraints (if applicable and MySQL version supports them)
SELECT 'Testing CHECK constraint for Billing.total_amount...' AS Test;
-- Expected: Error (Constraint fails)
START TRANSACTION;
INSERT INTO Billing (patient_id, bill_date, total_amount) VALUES
((SELECT patient_id FROM Patients LIMIT 1), CURDATE(), -10.00);
ROLLBACK;
SELECT 'CHECK constraint test for Billing.total_amount attempted. Check for error message above.' AS Status;


-- 5.1.5. Verify Trigger Actions
-- Data created in 3.7 should already reflect trigger actions (e.g., Medication stock, Bill totals)
-- Re-verify medication stock after prescriptions
SELECT 'Verifying medication stock after prescriptions (from Phase 3.7 data)...' AS Test;
SELECT name, stock_quantity, reorder_level FROM Medications WHERE name IN ('Paracetamol', 'Lisinopril');
-- Expected: Stock for Paracetamol and Lisinopril should be reduced from initial.

-- Re-verify calculated bill totals and statuses
SELECT 'Verifying calculated bill totals and statuses (from Phase 3.7 data)...' AS Test;
SELECT bill_id, patient_id, total_amount, paid_amount, status FROM Billing;
-- Expected: John Doe's bill paid, Jane Smith's partially paid, Alice Johnson's outstanding, amounts correct.

-- Check AuditLog entries
SELECT 'Verifying AuditLog entries...' AS Test;
SELECT * FROM AuditLog ORDER BY log_id DESC LIMIT 10;
-- Expected: Entries for inserts, updates, deletes on Patients and potentially other tables if triggers added.

SELECT '--- Data Integrity Testing Complete. Manually verify error messages and data states. ---' AS Status;
