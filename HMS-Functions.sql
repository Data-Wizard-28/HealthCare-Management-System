USE HealthCare_HMS;

-- Function: CalculateAge
-- Description: Calculates age in years from a given date of birth.

DELIMITER //
CREATE FUNCTION CalculateAge(p_date_of_birth DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_date_of_birth, CURDATE());
END //
DELIMITER ;

SELECT 'Function CalculateAge created.' AS Status;

-- Function: GetDoctorFullName
-- Description: Returns the full name of a doctor given their ID.

DELIMITER //
CREATE FUNCTION GetDoctorFullName(p_doctor_id INT)
RETURNS VARCHAR(201) -- Max length of first_name + space + last_name
DETERMINISTIC
BEGIN
    DECLARE full_name VARCHAR(201);
    SELECT CONCAT(first_name, ' ', last_name) INTO full_name
    FROM Doctors
    WHERE doctor_id = p_doctor_id;
    RETURN full_name;
END //
DELIMITER ;

SELECT 'Function GetDoctorFullName created.' AS Status;

SELECT 'Finished creation of Functions.' AS Status;
