CREATE DATABASE COMPANY
USE  COMPANY 

-----------------------------------------------------------

--Create the EMPLOYEE table 
CREATE  TABLE EMPLOYEE (
    Ssn INT PRIMARY KEY,
    Birth_Date DATE,
    Gender VARCHAR(15),
    Lname VARCHAR(50),
    Fname VARCHAR(50),
    DNUM INT,
    supervisor_Ssn INT
    FOREIGN KEY (supervisor_Ssn) REFERENCES EMPLOYEE(Ssn)
	)


	--Create the DEPARTMENT Table 
	CREATE  TABLE DEPARTMENT (
    DNUM INT PRIMARY KEY,
    DName VARCHAR(50),
    hiringDate DATE,
    Ssn INT
    
)

--Add foreign key constraints between table EMPLOYEE , DEPARTMENT
ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_DNUM
FOREIGN KEY (DNUM) REFERENCES DEPARTMENT(DNUM)

--Add foreign key constraints between table DEPARTMENT , EMPLOYEE
ALTER TABLE DEPARTMENT
ADD CONSTRAINT FK_Ssn
FOREIGN KEY (Ssn) REFERENCES EMPLOYEE(Ssn)

--Create the PROJECT table
  CREATE TABLE PROJECT(
   PNumber INT PRIMARY KEY,
    Pname VARCHAR(50),
    Location_City VARCHAR(50),
    DNUM INT
	FOREIGN KEY (DNUM) REFERENCES DEPARTMENT(DNUM)
)


--Create the DEPENDENTS Table
    CREATE TABLE DEPENDENTS (
    Name VARCHAR(50),
    Gender VARCHAR(15),
    Birth_date DATE,
    Ssn INT
	 FOREIGN KEY (Ssn) REFERENCES EMPLOYEE(Ssn)
	)

--Create the WORK Table
    CREATE TABLE Work (
    Ssn INT,
    PNumber INT,
    working_hours INT,
    PRIMARY KEY (Ssn, PNumber),
    FOREIGN KEY (Ssn) REFERENCES EMPLOYEE(Ssn),
    FOREIGN KEY (PNumber) REFERENCES PROJECT(PNumber)
)

--Create the Departments_Locations Table
    CREATE TABLE Departments_Locations (
    location VARCHAR(100),
    DNUM INT,
    FOREIGN KEY (DNUM) REFERENCES DEPARTMENT(DNUM)
)




