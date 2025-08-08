USE HealthCare_HMS;

SELECT '--- Starting User Acceptance Testing (UAT) - Conceptual ---' AS Status;

SELECT 'UAT for a MySQL-only HMS primarily involves stakeholders reviewing:' AS UAT_Guidance;
SELECT '- The database schema (ERD or CREATE TABLE scripts) for logical correctness.' AS UAT_Point;
SELECT '- Sample data to ensure it represents real-world scenarios.' AS UAT_Point;
SELECT '- Querying the database directly, using `SELECT` statements, views, and stored procedures.' AS UAT_Point;
SELECT '- Providing feedback on data availability, ease of retrieval, and data accuracy.' AS UAT_Point;
SELECT '- Examples of UAT queries/tasks to provide to a "SQL-savvy" end-user:' AS UAT_Examples;

-- Example UAT Task: "Find all patients with 'Diabetes' in their medical history summary."
SELECT patient_id, first_name, last_name, medical_history_summary
FROM Patients
WHERE medical_history_summary LIKE '%Diabetes%';

-- Example UAT Task: "List all appointments for Dr. Alex Chen for next week."
SELECT
    A.appointment_datetime, P.first_name AS patient_first_name, P.last_name AS patient_last_name
FROM
    Appointments A
JOIN
    Patients P ON A.patient_id = P.patient_id
WHERE
    A.doctor_id = (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen')
    AND A.appointment_datetime BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY
    A.appointment_datetime;

-- Example UAT Task: "Generate a report of all overdue bills."
SELECT * FROM CurrentOutstandingBills WHERE due_date < CURDATE();

-- Example UAT Task: "How would I update a patient's address?"
-- Response: Use the UPDATE statement or create a stored procedure for it.
-- UPDATE Patients SET address = 'New Address' WHERE patient_id = X;

SELECT '--- UAT Phase Complete (Conceptual). Collect feedback from domain experts. ---' AS Status;
