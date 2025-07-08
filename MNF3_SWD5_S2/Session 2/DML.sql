-- Insert sample departments
INSERT INTO DEPARTMENT (DNUM, DName, hiringDate, Ssn)
VALUES 
(101, 'HR', '2020-01-10', 1),         
(102, 'IT', '2019-06-01', 2),
(103, 'Finance', '2021-03-15', 3)

-- Insert sample employees
INSERT INTO EMPLOYEE (Ssn, Birth_Date, Gender,Fname,Lname, DNUM, supervisor_Ssn)
VALUES 
(1, '2004-02-27', 'Male', 'Mohamed', 'Yaser', 101, 2),       
(2, '1985-05-12', 'Female', 'Sara', 'Hassan', 101, 1),
(3, '1992-08-20', 'Male', 'Kareem', 'Mostafa', 102, 1),     
(4, '1988-11-11', 'Female', 'Laila', 'Youssef', 103, 3),    
(5, '1995-09-09', 'Male', 'Omar', 'Nabil', 102, 3)

-- Insert sample project
INSERT INTO PROJECT VALUES (201, 'Payroll System', 'Cairo', 103)
INSERT INTO PROJECT VALUES (202, 'Website Redesign', 'Alexandria', 102)
INSERT INTO PROJECT VALUES (203, 'Employee Training', 'Cairo', 101)

-- Insert sample work
INSERT INTO Work VALUES (1, 203, 10)
INSERT INTO Work VALUES (2, 203, 15)
INSERT INTO Work VALUES (3, 202, 20)

-- Insert sample Departments_Locations
INSERT INTO Departments_Locations VALUES ('Cairo', 101)
INSERT INTO Departments_Locations VALUES ('Alexandria', 102)
INSERT INTO Departments_Locations VALUES ('Giza', 103)

--Insert sample DEPENDENTS
INSERT INTO DEPENDENTS (Name, Gender, Birth_date, Ssn)
VALUES 
('Omar', 'Male', '2015-06-01', 2),        
('Nada', 'Female', '2010-09-10', 3),       
('Hana', 'Female', '2012-04-20', 4),       
('Youssef', 'Male', '2018-12-15', 5)    

---------------------------------------------------------------------------------------

--Update an employee's department
UPDATE EMPLOYEE
SET DNUM = 102
WHERE Ssn = 1

--Delete a dependent record
DELETE FROM DEPENDENTS
WHERE Name = 'Hana'

--Retrieve all employees working in a specific department
SELECT Fname, Lname, DNUM
FROM EMPLOYEE
WHERE DNUM = 102

--Find all employees and their project assignments with working hours
SELECT E.Ssn,E.Fname, E.Lname,
    P.Pname, W.working_hours
FROM EMPLOYEE E, WORK W, PROJECT P
WHERE E.Ssn = W.Ssn
    AND W.PNumber = P.PNumber





