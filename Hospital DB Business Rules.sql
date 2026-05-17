-- =============================================
-- Hospital Database - SQL Server Version
-- =============================================
USE HospitalDB;

-- 15 Business Questions + SQL Queries (All use JOINs & multiple tables)
-- 1. Average appointments per patient in the last 6 months

SELECT AVG(CAST(appointment_count AS FLOAT)) AS avg_appointments_per_patient
FROM (
    SELECT p.PatientID, COUNT(a.AppointmentID) AS appointment_count
    FROM Patient p 
    JOIN Appointment a ON p.PatientID = a.PatientID
    WHERE a.AppointmentDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY p.PatientID
) AS sub;


--2. Doctors with highest patient load vs availability

SELECT TOP 10 d.FirstName, d.LastName, d.Specialization, d.Availability,
       COUNT(a.AppointmentID) AS patient_load
FROM Doctor d 
LEFT JOIN Appointment a ON d.DoctorID = a.DoctorID
WHERE a.AppointmentDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY d.DoctorID, d.FirstName, d.LastName, d.Specialization, d.Availability
ORDER BY patient_load DESC;

-- 3. Total revenue by department (past quarter)

SELECT d.DepartmentName, SUM(b.TotalAmount) AS total_revenue
FROM Billing b
JOIN Patient p ON b.PatientID = p.PatientID
JOIN Appointment a ON a.PatientID = p.PatientID
JOIN Department d ON a.DepartmentID = d.DepartmentID
WHERE a.AppointmentDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY d.DepartmentName 
ORDER BY total_revenue DESC;


--4. Top 5 most prescribed medicines (last 3 months)

SELECT TOP 5 
       m.MedicineName, 
       COUNT(pr.PrescriptionID) AS prescription_count
FROM Prescription pr
JOIN MedicalRecords mr ON pr.RecordID = mr.RecordID
JOIN Medicine m ON pr.MedicineID = m.MedicineID
WHERE mr.VisitDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY m.MedicineName 
ORDER BY prescription_count DESC;


--5. Room occupancy percentage by type (last month)

SELECT r.RoomType,
       ROUND(100.0 * COUNT(CASE WHEN ra.DischargeDate IS NULL THEN 1 END) / NULLIF(COUNT(*), 0), 2) AS occupancy_pct
FROM Room r 
LEFT JOIN RoomAssignment ra ON r.RoomID = ra.RoomID
  AND ra.AdmissionDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY r.RoomType;


--6. Patient gender distribution

SELECT p.Gender, 
       COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patient), 2) AS percentage
FROM Patient p 
GROUP BY p.Gender;


--7. Appointments by department (last year)
SELECT d.DepartmentName, COUNT(a.AppointmentID) AS appointments
FROM Appointment a 
JOIN Department d ON a.DepartmentID = d.DepartmentID
WHERE a.AppointmentDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY d.DepartmentName 
ORDER BY appointments DESC;


--8. Top 10 most frequent patients (by medical records)

SELECT TOP 10 
       p.FirstName, 
       p.LastName, 
       COUNT(mr.RecordID) AS visit_count
FROM Patient p 
JOIN MedicalRecords mr ON p.PatientID = mr.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY visit_count DESC;


--9. Average patient age for recent appointments
SELECT ROUND(AVG(CAST(DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS FLOAT)), 1) AS avg_age
FROM Patient p 
JOIN Appointment a ON p.PatientID = a.PatientID
WHERE a.AppointmentDate >= DATEADD(MONTH, -1, GETDATE());


--10 Staff count by role and department

SELECT d.DepartmentName, s.Role, COUNT(s.StaffID) AS staff_count
FROM Staff s 
LEFT JOIN Department d ON s.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName, s.Role 
ORDER BY staff_count DESC;


--11. Doctor workload (appointments last month)
SELECT d.FirstName, 
       d.LastName, 
       COUNT(a.AppointmentID) AS appointments
FROM Doctor d 
LEFT JOIN Appointment a ON d.DoctorID = a.DoctorID 
  AND a.AppointmentDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY d.DoctorID, d.FirstName, d.LastName
ORDER BY appointments DESC;


-- 12. Top 5 most common diagnoses
SELECT TOP 5 
       CAST(mr.Diagnosis AS NVARCHAR(1000)) AS Diagnosis, 
       COUNT(*) AS occurrences
FROM MedicalRecords mr 
JOIN Doctor d ON mr.DoctorID = d.DoctorID
GROUP BY CAST(mr.Diagnosis AS NVARCHAR(1000))
ORDER BY occurrences DESC;


-- 13. Total revenue vs unpaid amount
SELECT 
    SUM(b.TotalAmount) AS total_revenue,
    SUM(CASE WHEN b.PaymentStatus = 'Unpaid' THEN b.TotalAmount ELSE 0 END) AS unpaid_total
FROM Billing b;

-- 14. Patients with unpaid bills + last appointment
SELECT p.FirstName, 
       p.LastName, 
       b.TotalAmount, 
       b.PaymentStatus,
       MAX(a.AppointmentDate) AS last_appointment
FROM Patient p
JOIN Billing b ON p.PatientID = b.PatientID
LEFT JOIN Appointment a ON p.PatientID = a.PatientID
WHERE b.PaymentStatus = 'Unpaid'
GROUP BY p.PatientID, b.BillingID, p.FirstName, p.LastName, b.TotalAmount, b.PaymentStatus
ORDER BY b.TotalAmount DESC;


-- 15. Average hospital stay by room type
SELECT r.RoomType,
       ROUND(AVG(CAST(DATEDIFF(DAY, ra.AdmissionDate, ra.DischargeDate) AS FLOAT)), 1) AS avg_stay_days
FROM RoomAssignment ra
JOIN Room r ON ra.RoomID = r.RoomID
WHERE ra.DischargeDate IS NOT NULL
GROUP BY r.RoomType;