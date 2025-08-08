USE HealthCare_HMS;

SELECT '--- Starting Query Verification ---' AS Status;

-- 5.2.1. Test Stored Procedures (Calling them with various inputs)
SELECT 'Testing AddNewPatient procedure...' AS Test;
CALL AddNewPatient(
    'Test', 'Patient1', '1995-03-03', 'Female', 'O+', 'Test Addr',
    '555-TEST-001', 'test1@example.com', 'Test EC', '555-TEST-002',
    'None', 'Clean history'
);
SELECT patient_id, first_name, last_name FROM Patients WHERE last_name = 'Patient1';

SELECT 'Testing ScheduleAppointment procedure with existing data...' AS Test;
-- Assuming patient_id=1, doctor_id=1 exist
CALL ScheduleAppointment(1, 1, '2025-08-05 15:00:00', 'Follow-up consultation');
SELECT * FROM Appointments WHERE patient_id=1 AND doctor_id=1 AND appointment_datetime='2025-08-05 15:00:00';

SELECT 'Testing GetPatientMedicalHistory procedure...' AS Test;
-- Assuming patient_id=1 exists
CALL GetPatientMedicalHistory(1);
-- Review the multiple result sets returned by this procedure.

SELECT 'Testing CreateNewBill with no items...' AS Test;
SET @bill_no_items_id = 0;
CALL CreateNewBill(
    (SELECT patient_id FROM Patients WHERE last_name = 'Patient1' LIMIT 1),
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 30 DAY),
    'Empty Bill Test',
    '[]', -- Empty JSON array for items
    @bill_no_items_id
);
SELECT bill_id, total_amount FROM Billing WHERE bill_id = @bill_no_items_id; -- Should be 0.00

SELECT 'Testing RecordPayment on a partially paid bill...' AS Test;
-- Assuming bill_id for Jane Smith is known from 3.7. It was 2.
-- Find bill_id for Jane Smith
SET @jane_smith_bill_id = (SELECT bill_id FROM Billing WHERE patient_id = (SELECT patient_id FROM Patients WHERE last_name = 'Smith') LIMIT 1);
SELECT 'Initial status for Jane Smith bill:' AS Status, bill_id, total_amount, paid_amount, status FROM Billing WHERE bill_id = @jane_smith_bill_id;

SET @jane_smith_bill_id = (
    SELECT bill_id 
    FROM Billing 
    WHERE patient_id = (SELECT patient_id FROM Patients WHERE last_name = 'Smith') 
    LIMIT 1
);
CALL RecordPayment(
    @jane_smith_bill_id,
    105.00, -- Remaining amount assuming total was 180 and 75 paid
    'Card',
    'TXN_JS_0801_PART2'
);
SELECT 'Final status for Jane Smith bill:' AS Status, bill_id, total_amount, paid_amount, status 
FROM Billing 
WHERE bill_id = @jane_smith_bill_id;
-- Expected: Status should change to 'Paid' if 180 was total.

-- 5.2.2. Test Functions
SELECT 'Testing CalculateAge function...' AS Test;
SELECT CalculateAge('1990-01-01') AS AgeFromDOB;

SELECT 'Testing GetDoctorFullName function...' AS Test;
SELECT GetDoctorFullName((SELECT doctor_id FROM Doctors WHERE last_name = 'Chen')) AS DoctorName;

-- 5.2.3. Test Views
SELECT 'Testing ActivePatients view...' AS Test;
SELECT * FROM ActivePatients LIMIT 5;

SELECT 'Testing DoctorScheduleToday view...' AS Test;
SELECT * FROM DoctorScheduleToday LIMIT 5;

SELECT 'Testing MedicationStockAlerts view...' AS Test;
SELECT * FROM MedicationStockAlerts; -- Should show any meds below reorder level

SELECT 'Testing CurrentOutstandingBills view...' AS Test;
SELECT * FROM CurrentOutstandingBills; -- Should show Alice Johnson's bill, and any others partially/not paid.

SELECT '--- Query Verification Complete. Manually verify results. ---' AS Status;
