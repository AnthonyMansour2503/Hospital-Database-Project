USE HospitalDB;
GO

-- Delete all data
DELETE FROM RoomAssignment;
DELETE FROM Prescription;
DELETE FROM MedicalRecords;
DELETE FROM Appointment;
DELETE FROM Billing;
DELETE FROM Room;
DELETE FROM Staff;
DELETE FROM Doctor;
DELETE FROM Patient;
DELETE FROM Department;
DELETE FROM Medicine;
GO

-- Reset all identity columns
DBCC CHECKIDENT ('Department', RESEED, 0);
DBCC CHECKIDENT ('Patient', RESEED, 0);
DBCC CHECKIDENT ('Doctor', RESEED, 0);
DBCC CHECKIDENT ('Staff', RESEED, 0);
DBCC CHECKIDENT ('Room', RESEED, 0);
DBCC CHECKIDENT ('Medicine', RESEED, 0);
DBCC CHECKIDENT ('Appointment', RESEED, 0);
DBCC CHECKIDENT ('MedicalRecords', RESEED, 0);
DBCC CHECKIDENT ('Prescription', RESEED, 0);
DBCC CHECKIDENT ('Billing', RESEED, 0);
DBCC CHECKIDENT ('RoomAssignment', RESEED, 0);
GO

PRINT 'Database cleaned successfully. Ready for fresh data insert.';
GO