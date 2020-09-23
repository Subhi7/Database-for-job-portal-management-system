-- Creating 22 tables as per the entities in our ER Diagram
CREATE TABLE dbo.Login_Details(
  UserID int NOT NULL Primary Key,
  Password varchar(20) NOT NULL, --Encrypted using Randomized Encryption Type 
  DateOfCreation date NOT NULL
);

CREATE TABLE dbo.User_Demographics (
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  FirstName varchar(30) NOT NULL,
  LastName varchar(30) NOT NULL,
  DateOfBirth DATE,
  Age AS dbo.CalculateAge(DateOfBirth), --Computed Column Age
  Gender varchar(30) NOT NULL,
  EmailID varchar(30) NOT NULL
  CONSTRAINT PKUser_Demographics PRIMARY KEY CLUSTERED
  (UserID)
);

CREATE TABLE dbo.Community_Types (
  CommunityID int NOT NULL Primary Key,
  CommunityType varchar(50) NOT NULL
);

CREATE TABLE dbo.Communities (
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  CommunityID int NOT NULL
  REFERENCES dbo.Community_Types(CommunityID)
  CONSTRAINT PKCommunities PRIMARY KEY CLUSTERED
  (UserID,CommunityID)
);

CREATE TABLE dbo.Connections_with_people (
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  ConnectionID int NOT NULL
  REFERENCES dbo.Login_Details(UserID)
  CONSTRAINT PKConnections_with_people PRIMARY KEY CLUSTERED
  (UserID,ConnectionID)
);

CREATE TABLE dbo.Activites(
  ActivityID int NOT NULL Primary Key,
  ActivityType int  NOT NULL,
  Description varchar(100)
);

CREATE TABLE dbo.UserActivity(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  ActivityID int NOT NULL
  REFERENCES dbo.Activites(ActivityID)
  CONSTRAINT PKUserActivity PRIMARY KEY CLUSTERED
  (UserID, ActivityID)
);

CREATE TABLE dbo.JobType(
  JobTypeID int NOT NULL Primary Key,
  JobTypeName varchar(30)
);

CREATE TABLE dbo.Area_Of_Interest(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  JobTypeID int NOT NULL
  REFERENCES dbo.JobType(JobTypeID)
  CONSTRAINT PKArea_Of_Interest PRIMARY KEY CLUSTERED
  (UserID,JobTypeID)
);

CREATE TABLE dbo.Courses(
  CourseID int NOT NULL Primary Key,
  CourseName varchar(30) NOT NULL,
  JobTypeID int NOT NULL
  REFERENCES dbo.JobType(JobTypeID)
);

CREATE TABLE dbo.IndustryTypes(
  IndustryID int NOT NULL Primary Key,
  IndustryName varchar(50) NOT NULL
);

CREATE TABLE dbo.EmployerDetails(
  EmployerID int NOT NULL Primary Key
  REFERENCES dbo.Login_Details(UserID),
  EmployerName varchar(30) NOT NULL,
  ProfileDescription varchar(50),
  IndustryID int NOT NULL
  REFERENCES dbo.IndustryTypes(IndustryID),
  EstablishedDate date,
  WebsiteURL nvarchar(max)
);

CREATE TABLE dbo.JobPost(
  JobPostID int NOT NULL Primary Key,
  JobTypeID int NOT NULL
  REFERENCES dbo.JobType(JobTypeID),
  PostDate date,
  EmployerID int NOT NULL
  REFERENCES dbo.EmployerDetails(EmployerID),
  JobLocationID int NOT NULL
  REFERENCES dbo.JobLocation(JobLocationID),
  IsActive int
 
);

CREATE TABLE dbo.JobPostActivity(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  JobPostID int NOT NULL
  REFERENCES dbo.JobPost(JobPostID),
  ApplyDate date
);

CREATE TABLE dbo.JobLocation(
  JobLocationID int NOT NULL Primary Key ,
  StreetAddress varchar(max),
  City varchar(50),
  State varchar(50),
  Country varchar(50),
  Zip varchar(5)
);

CREATE TABLE dbo.Candidateprofile(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  FirstName varchar(30) NOT NULL,
  LastName varchar(30) NOT NULL
  CONSTRAINT PKCandidateprofile PRIMARY KEY CLUSTERED
  (UserID)
);

CREATE TABLE dbo.ResumeDetails(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  Resume varchar(30)
  CONSTRAINT PKResumeDetails PRIMARY KEY CLUSTERED
  (UserID)
);

CREATE TABLE dbo.CandidateEducationDetails(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  Degree varchar(100) ,
  Major varchar(70) ,
  UniversityName varchar(30),
  CGPA int Not Null
  CONSTRAINT PKCandidateEducationDetails PRIMARY KEY CLUSTERED
  (UserID,Degree,Major)
);

CREATE TABLE dbo.CandidateExperience(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  StartDate datetime NOT NULL,
  EndDate datetime NOT NULL,
  JobTitle varchar(100),
  CompanyName varchar(50),
  Salary int
  CONSTRAINT PKCandidate_Exp PRIMARY KEY CLUSTERED
  (UserID,StartDate, EndDate)
);


CREATE TABLE dbo.Skillset(
  SkillsetID int NOT NULL Primary Key,
  SkillsetName varchar(50)
);

CREATE TABLE dbo.CandidateSkillSet(
  UserID int NOT NULL
  REFERENCES dbo.Login_Details(UserID),
  SkillsetID int  NOT NULL
  REFERENCES dbo.Skillset(SkillsetID)
  CONSTRAINT PKCandidateSkillSet PRIMARY KEY CLUSTERED
  (UserID,SkillsetID)
);

CREATE TABLE dbo.Job_Post_Skill_Set(
  SkillsetID int NOT NULL
  REFERENCES dbo.Skillset(SkillsetID),
  JobPostID int NOT NULL  
  REFERENCES dbo.JobPost(JobPostID),
  SkillLevel varchar(30)
  CONSTRAINT PKJob_Post_Skill_Set PRIMARY KEY CLUSTERED
  (SkillsetID,JobPostID)
);

-- Adding some constraints 

-- Setting Default Datestamp for Date of creation 
ALTER TABLE Login_Details
ADD CONSTRAINT df_Date
DEFAULT Current_Timestamp FOR DateOfCreation;

-- Checking that the zipcode lies between the range of 0-9
ALTER TABLE dbo.JobLocation 
ADD CONSTRAINT chk_ZipCode 
CHECK (Zip LIKE '[0-9][0-9][0-9][0-9][0-9]');

-- Adding a constraint such that the start date is less than End Date
ALTER TABLE dbo.CandidateExperience 
ADD CONSTRAINT chk_St_End_Date
CHECK (StartDate<=EndDate);

-- Function to populate Computed column Age . Calculating the age of the candidate from thier Date Of Birth .
CREATE FUNCTION CalculateAge(@DateOfBirth Date)
RETURNS INT
AS
BEGIN
DECLARE @Age INT
SET @Age = DATEDIFF(Year, @DateOfBirth ,GETDATE()) -
CASE
WHEN DATEADD(Year, DATEDIFF(Year,@DateOfBirth , GETDATE()) , @DateOfBirth) > GetDate()
THEN 1
ELSE 0
END
RETURN @Age
END


-- Views Created

-- Creating a view to analysize which companies candidates are associated with 
CREATE VIEW vwCandidateInfo AS
(SELECT ce.UserID , FirstName, LastName, JobTitle, CompanyName
FROM dbo.Candidateprofile cp
INNER JOIN dbo.CandidateExperience ce
ON cp.UserID = ce.UserID);

-- Creating a view to understand the behaviour of user activity 
CREATE VIEW vwUserActivity
AS
SELECT ua.UserID , ac.Activity_Type
FROM dbo.UserActivity ua
INNER JOIN dbo.Activities ac
ON ua.ActivityID = ac.Activity_Id;

-- Insert Queries
INSERT dbo.Login_Details VALUES  ('101','abc','2020-03-10')
INSERT dbo.Login_Details VALUES  ('102','xyz','2019-04-10')
INSERT dbo.Login_Details VALUES ('103','ab12','2015-05-16')
INSERT dbo.Login_Details VALUES ('104','qwer','2012-08-20')
INSERT dbo.Login_Details VALUES ('105','uio','2008-10-17')
INSERT dbo.Login_Details VALUES ('106','zxcv','2020-06-01')
INSERT dbo.Login_Details VALUES ('107','asdf','2010-04-09')
INSERT dbo.Login_Details VALUES ('108','poiu','2020-02-24')
INSERT dbo.Login_Details VALUES ('109','lkjh','2018-01-30')
INSERT dbo.Login_Details VALUES ('110','mnb','2019-05-13')
INSERT dbo.Login_Details VALUES  ('111','abce','2020-03-11')
INSERT dbo.Login_Details VALUES  ('112','xyze','2019-04-12')
INSERT dbo.Login_Details VALUES ('113','ab12e','2015-05-16')
INSERT dbo.Login_Details VALUES ('114','qwere','2012-08-22')
INSERT dbo.Login_Details VALUES ('115','uioe','2008-10-10')
INSERT dbo.Login_Details VALUES ('116','zxcve','2020-06-11')
INSERT dbo.Login_Details VALUES ('117','asdfe','2010-04-06')
INSERT dbo.Login_Details VALUES ('118','poiue','2020-02-21')
INSERT dbo.Login_Details VALUES ('119','lkjhe','2018-01-11')
INSERT dbo.Login_Details VALUES ('120','mnbe','2019-05-15')

INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 300,1902,'2007-03-04',118,2005,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 301,1900,'2006-03-04',111,2001,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 302,1903,'2007-02-04',114,2010,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 303,1904,'2008-03-04',115,2001,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 304,1905,'2008-03-04',117,2009,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 305,1906,'2018-03-04',114,2006,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 307,1907,'2017-06-04',119,2008,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 308,1912,'2019-12-04',114,2009,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 309,1913,'2008-03-04',112,2010,1)
INSERT INTO JobPost(JobPostID,JobTypeID,PostDate,EmployerID,JobLocationID,IsActive)
VALUES( 310,1910,'2016-03-04',116,2005,1)

INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(101,300,'2007-03-04')

Insert into Job_Post_Skill_Set(SkillsetID,JobPostID,SkillLevel)
VALUES(9010,306,'Beginner')

INSERT INTO User_Demographics(UserID, FirstName, LastName,Gender,EmailID,DateOfBirth)
VALUES(102,'Oindee','Choudhury','F','oindee@gmail.com',03/25/1995)

INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(101,300,'2007-03-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(102,301,'2006-03-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(103,301,'2006-03-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(104,302,'2008-03-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(105,303,'2018-04-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(106,303,'2017-07-04')
INSERT INTO JobPostActivity(UserID,JobPostID,ApplyDate)
VALUES(107,301,'2019-04-04')

/* 
	Rest Data is added using import Wizard
*/

