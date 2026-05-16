-- =============================================
-- Hospital Database - SQL Server Version
-- =============================================
-- Create Database
    CREATE DATABASE HospitalDB;
USE HospitalDB;

-- 1. Department
CREATE TABLE Department (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL UNIQUE,
    Location VARCHAR(100) NOT NULL,
    PhoneExtension VARCHAR(10)
);
-- 2. Patient
CREATE TABLE Patient (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender VARCHAR(10) NOT NULL CHECK (Gender IN ('Male', 'Female', 'Other')),
    Address VARCHAR(255),
    PhoneNumber VARCHAR(20) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    EmergencyContactName VARCHAR(100),
    EmergencyContactPhone VARCHAR(20)
);
GO

-- 3. Doctor
CREATE TABLE Doctor (
    DoctorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Specialization VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(20) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    DepartmentID INT NOT NULL,
    Availability VARCHAR(20) NOT NULL DEFAULT 'Available' 
        CHECK (Availability IN ('Available', 'Busy', 'OnLeave')),
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID) ON DELETE NO ACTION
);
GO

-- 4. Staff
CREATE TABLE Staff (
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Role VARCHAR(100) NOT NULL,
    DepartmentID INT,
    PhoneNumber VARCHAR(20) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    ShiftHours VARCHAR(50),
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID) ON DELETE SET NULL
);
GO

-- 5. Room
CREATE TABLE Room (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomNumber VARCHAR(10) NOT NULL UNIQUE,
    DepartmentID INT NOT NULL,
    RoomType VARCHAR(20) NOT NULL CHECK (RoomType IN ('General', 'Private', 'ICU', 'Semi-Private')),
    AvailabilityStatus VARCHAR(20) NOT NULL DEFAULT 'Available' 
        CHECK (AvailabilityStatus IN ('Available', 'Occupied', 'Maintenance')),
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID) ON DELETE NO ACTION
);
GO

-- 6. Medicine
CREATE TABLE Medicine (
    MedicineID INT IDENTITY(1,1) PRIMARY KEY,
    MedicineName VARCHAR(100) NOT NULL,
    Manufacturer VARCHAR(100),
    StockQuantity INT DEFAULT 0,
    Price DECIMAL(10,2) NOT NULL
);
GO

-- 7. Appointment
CREATE TABLE Appointment (
    AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    DepartmentID INT NOT NULL,
    AppointmentDate DATE NOT NULL,
    AppointmentTime TIME NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' 
        CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled')),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID) ON DELETE NO ACTION,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID) ON DELETE NO ACTION
);
GO

-- 8. MedicalRecords
CREATE TABLE MedicalRecords (
    RecordID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    VisitDate DATE NOT NULL,
    Diagnosis TEXT,
    TreatmentPlan TEXT,
    Prescription TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID) ON DELETE NO ACTION
);
GO

-- 9. Prescription
CREATE TABLE Prescription (
    PrescriptionID INT IDENTITY(1,1) PRIMARY KEY,
    RecordID INT NOT NULL,
    MedicineID INT NOT NULL,
    Dosage VARCHAR(50) NOT NULL,
    Frequency VARCHAR(50) NOT NULL,
    Duration VARCHAR(50) NOT NULL,
    FOREIGN KEY (RecordID) REFERENCES MedicalRecords(RecordID) ON DELETE CASCADE,
    FOREIGN KEY (MedicineID) REFERENCES Medicine(MedicineID) ON DELETE NO ACTION
);
GO

-- 10. Billing
CREATE TABLE Billing (
    BillingID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    PaymentStatus VARCHAR(10) NOT NULL DEFAULT 'Unpaid' 
        CHECK (PaymentStatus IN ('Paid', 'Unpaid')),
    PaymentDate DATE,
    PaymentMethod VARCHAR(50),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);
GO

-- 11. RoomAssignment
CREATE TABLE RoomAssignment (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT NOT NULL,
    PatientID INT NOT NULL,
    AdmissionDate DATE NOT NULL,
    DischargeDate DATE,
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID) ON DELETE NO ACTION,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);
GO

PRINT 'HospitalDB tables created successfully in SQL Server.';

--Connect the Vs studio code data to the database tables or Insert raandomly generated dataset values


-- 15 Business Questions + SQL Queries (All use JOINs & multiple tables)
-- 1. Average appointments per patient in the last 6 months

SELECT AVG(appointment_count) AS avg_appointments_per_patient
FROM (SELECT p.PatientID, COUNT(a.AppointmentID) AS appointment_count
      FROM Patient p JOIN Appointment a ON p.PatientID = a.PatientID
      WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
      GROUP BY p.PatientID) sub;

--2. Doctors with highest patient load vs availability
SELECT d.FirstName, d.LastName, d.Specialization, d.Availability,
       COUNT(a.AppointmentID) AS patient_load
FROM Doctor d LEFT JOIN Appointment a ON d.DoctorID = a.DoctorID
WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY d.DoctorID ORDER BY patient_load DESC LIMIT 10;

-- 3. Total revenue by department (past quarter)
SELECT d.DepartmentName, SUM(b.TotalAmount) AS total_revenue
FROM Billing b
JOIN Patient p ON b.PatientID = p.PatientID
JOIN Appointment a ON a.PatientID = p.PatientID
JOIN Department d ON a.DepartmentID = d.DepartmentID
WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY d.DepartmentName ORDER BY total_revenue DESC;

--4. Top 5 most prescribed medicines (last 3 months)
SELECT m.MedicineName, COUNT(pr.PrescriptionID) AS prescription_count
FROM Prescription pr
JOIN MedicalRecords mr ON pr.RecordID = mr.RecordID
JOIN Medicine m ON pr.MedicineID = m.MedicineID
WHERE mr.VisitDate >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY m.MedicineName ORDER BY prescription_count DESC LIMIT 5;

--5. Room occupancy percentage by type (last month)
SELECT r.RoomType,
       ROUND(100.0 * COUNT(CASE WHEN ra.DischargeDate IS NULL THEN 1 END) / COUNT(*), 2) AS occupancy_pct
FROM Room r LEFT JOIN RoomAssignment ra ON r.RoomID = ra.RoomID
WHERE ra.AdmissionDate >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY r.RoomType;

--6. Patient gender distribution
SELECT p.Gender, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patient), 2) AS percentage
FROM Patient p GROUP BY p.Gender;

--7. Appointments by department (last year)
SELECT d.DepartmentName, COUNT(a.AppointmentID) AS appointments
FROM Appointment a JOIN Department d ON a.DepartmentID = d.DepartmentID
WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY d.DepartmentName ORDER BY appointments DESC;

--8. Top 10 most frequent patients (by medical records)
SELECT p.FirstName, p.LastName, COUNT(mr.RecordID) AS visit_count
FROM Patient p JOIN MedicalRecords mr ON p.PatientID = mr.PatientID
GROUP BY p.PatientID ORDER BY visit_count DESC LIMIT 10;

--9. Average patient age for recent appointments
SELECT ROUND(AVG(TIMESTAMPDIFF(YEAR, p.DateOfBirth, CURDATE())), 1) AS avg_age
FROM Patient p JOIN Appointment a ON p.PatientID = a.PatientID
WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

--10 Staff count by role and department
SELECT d.DepartmentName, s.Role, COUNT(s.StaffID) AS staff_count
FROM Staff s LEFT JOIN Department d ON s.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName, s.Role ORDER BY staff_count DESC;

--11. Doctor workload (appointments last month)
SELECT d.FirstName, d.LastName, COUNT(a.AppointmentID) AS appointments
FROM Doctor d LEFT JOIN Appointment a ON d.DoctorID = a.DoctorID
WHERE a.AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY d.DoctorID ORDER BY appointments DESC;

-- 12. Top 5 most common diagnoses
SELECT mr.Diagnosis, COUNT(*) AS occurrences
FROM MedicalRecords mr JOIN Doctor d ON mr.DoctorID = d.DoctorID
GROUP BY mr.Diagnosis ORDER BY occurrences DESC LIMIT 5;

--13. Total revenue vs unpaid amount
SELECT SUM(b.TotalAmount) AS total_revenue,
       SUM(CASE WHEN b.PaymentStatus = 'Unpaid' THEN b.TotalAmount ELSE 0 END) AS unpaid_total
FROM Billing b JOIN Patient p ON b.PatientID = p.PatientID;

--14. Patients with unpaid bills + last appointment
SELECT p.FirstName, p.LastName, b.TotalAmount, b.PaymentStatus,
       MAX(a.AppointmentDate) AS last_appointment
FROM Patient p
JOIN Billing b ON p.PatientID = b.PatientID
LEFT JOIN Appointment a ON p.PatientID = a.PatientID
WHERE b.PaymentStatus = 'Unpaid'
GROUP BY p.PatientID, b.BillingID ORDER BY b.TotalAmount DESC;

--15. Average hospital stay by room type
SELECT r.RoomType,
       ROUND(AVG(DATEDIFF(ra.DischargeDate, ra.AdmissionDate)), 1) AS avg_stay_days
FROM RoomAssignment ra
JOIN Room r ON ra.RoomID = r.RoomID
WHERE ra.DischargeDate IS NOT NULL
GROUP BY r.RoomType;


--section 6. Users & Permissions
-- Admin (full access)
CREATE USER IF NOT EXISTS 'hospital_admin'@'localhost' IDENTIFIED BY 'AdminPass2026!';
GRANT ALL PRIVILEGES ON HospitalDB.* TO 'hospital_admin'@'localhost';

-- 5 Normal users (read-only)
CREATE USER IF NOT EXISTS 'user1'@'localhost' IDENTIFIED BY 'ReadOnly2026!';
CREATE USER IF NOT EXISTS 'user2'@'localhost' IDENTIFIED BY 'ReadOnly2026!';
CREATE USER IF NOT EXISTS 'user3'@'localhost' IDENTIFIED BY 'ReadOnly2026!';
CREATE USER IF NOT EXISTS 'user4'@'localhost' IDENTIFIED BY 'ReadOnly2026!';
CREATE USER IF NOT EXISTS 'user5'@'localhost' IDENTIFIED BY 'ReadOnly2026!';

GRANT SELECT ON HospitalDB.* TO 'user1'@'localhost',
                               'user2'@'localhost',
                               'user3'@'localhost',
                               'user4'@'localhost',
                               'user5'@'localhost';

FLUSH PRIVILEGES;