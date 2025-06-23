-- 1. Create a staging Table named hr_emp. This contains the complete raw data.

CREATE TABLE hr_emp (
	employee_number				INTEGER,
    age                       INTEGER,
    attrition                 VARCHAR(3),  -- 'Yes' or 'No'
    businessTravel            VARCHAR(50),
    dailyRate                 INTEGER,     -- not always present; skip if not in your file
    department                VARCHAR(50),
    distancefromhome          INTEGER,
    education                 INTEGER,     -- ordinal 1-5
    educationField            VARCHAR(50),
    employee_count             INTEGER,     -- constant: usually dropped
    environment_satisfaction   INTEGER,     -- ordinal 1-4
    gender                    VARCHAR(10),
    hourly_rate                INTEGER,
    job_involvement            INTEGER,     -- ordinal 1-4
    job_level                  INTEGER,
    job_role                   VARCHAR(50),
    job_satisfaction           INTEGER,     -- ordinal 1-4
    marital_status             VARCHAR(20),
    monthly_income             INTEGER,
    monthly_rate               INTEGER,
    num_companies_worked        INTEGER,
    over18                    CHAR(1),     -- constant: usually 'Y'
    over_time                  VARCHAR(3),  -- 'Yes' or 'No'
    percent_salary_hike         INTEGER,
    performance_rating         INTEGER,     -- ordinal 1-4
    relationship_satisfaction  INTEGER,     -- ordinal 1-4
    standard_hours             INTEGER,     -- constant: usually 80
    stock_option_level          INTEGER,
    total_working_years         INTEGER,
    training_times_lastYear     INTEGER,
    work_life_balance           INTEGER,     -- ordinal 1-4
    years_at_company            INTEGER,
    years_in_current_role        INTEGER,
    years_since_last_promotion   INTEGER,
    years_with_curr_mgr			 INTEGER);

-- 2. To create employees table
CREATE TABLE employees (
    employee_id              SERIAL PRIMARY KEY,
    employee_number          INTEGER UNIQUE NOT NULL,
    age                      INTEGER,
    gender                   VARCHAR(10),
    marital_status           VARCHAR(20),
    distance_from_home       INTEGER,
    num_companies_worked     INTEGER,
    over_time                BOOLEAN,
    total_working_years      INTEGER,
    training_times_last_year INTEGER,
    years_at_company         INTEGER,
    years_in_current_role    INTEGER,
    years_since_last_promotion INTEGER,
    years_with_curr_manager  INTEGER,
    monthly_income           INTEGER,
    monthly_rate             INTEGER,
    hourly_rate              INTEGER,
    percent_salary_hike      INTEGER,
    attrition BOOLEAN
);

-- 3. To populate my employees table from my staging table(hr_emp)
INSERT INTO employees (
    employee_number,
    age,
    gender,
    marital_status,
    distance_from_home,
    num_companies_worked,
    over_time,
    total_working_years,
    training_times_last_year,
    years_at_company,
    years_in_current_role,
    years_since_last_promotion,
    years_with_curr_manager,
    monthly_income,
    monthly_rate,
    hourly_rate,
    percent_salary_hike,
    attrition
)
SELECT
    employee_number,
    age,
    gender,
    marital_status,
    distancefromhome,
    num_companies_worked,
    CASE WHEN over_time = 'Yes' THEN TRUE ELSE FALSE END,
    total_working_years,
    training_times_lastYear,
    years_at_company,
    years_in_current_role,
    years_since_last_promotion,
    years_with_curr_mgr,
    monthly_income,
    monthly_rate,
    hourly_rate,
    percent_salary_hike,
    CASE WHEN attrition = 'Yes' THEN TRUE ELSE FALSE END
FROM hr_emp;

-- 4. To populate the lookup/reference tables
------ A. Create the departments Table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE
);

------ B. Populate the departments Table from hr_emp table
INSERT INTO departments (department_name)
SELECT DISTINCT department
FROM hr_emp
WHERE department IS NOT NULL;

-- 5. Create and Populate the job_roles Table
----- A. Create job_roles table
CREATE TABLE job_roles (
    job_role_id SERIAL PRIMARY KEY,
    job_role_name VARCHAR(100) UNIQUE
);

----- B. Populate job_roles table from hr_emp
INSERT INTO job_roles (job_role_name)
SELECT DISTINCT job_role
FROM hr_emp
WHERE job_role IS NOT NULL;

-- 6. Create and Populate the job_details Table
----- A. Create job_details Table
CREATE TABLE job_details (
    job_detail_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    department_id INTEGER REFERENCES departments(department_id),
    job_role_id INTEGER REFERENCES job_roles(job_role_id),
    job_level INTEGER,
    job_involvement INTEGER,
    performance_rating INTEGER
);

----- B. Populate job_details Table.
---------Join employees with hr_emp, departments, and job_roles.
INSERT INTO job_details (
    employee_id,
    department_id,
    job_role_id,
    job_level,
    job_involvement,
    performance_rating
)
SELECT
    e.employee_id,
    d.department_id,
    j.job_role_id,
    h.job_level,
    h.job_involvement,
    h.performance_rating
FROM hr_emp h
JOIN employees e ON h.employee_number = e.employee_number
JOIN departments d ON h.department = d.department_name
JOIN job_roles j ON h.job_role = j.job_role_name;

-- Total number of employees who left, grouped by Department
SELECT d.department_name, COUNT(*) employees_who_left
FROM employees e
JOIN job_details jd ON e.employee_id = jd.employee_id
JOIN departments d ON jd.department_id = d.department_id
WHERE e.attrition = TRUE
GROUP BY d.department_name
ORDER BY employees_who_left DESC;


-- Average monthly income by Job Role
SELECT jr.job_role_name, ROUND(AVG(e.monthly_income), 2) avg_monthly_income
FROM employees e
JOIN job_details jd ON e.employee_id = jd.employee_id
JOIN job_roles jr ON jd.job_role_id = jr.job_role_id
GROUP BY jr.job_role_name
ORDER BY avg_monthly_income DESC;

-- Percentage of employees who left, grouped by Age range buckets
SELECT age_range, 
ROUND(COUNT(*) FILTER (WHERE attrition = TRUE) * 100.0 / COUNT(*), 2) percent_left
FROM (
    SELECT employee_id, attrition,
        CASE 
            WHEN age < 30 THEN '<30'
            WHEN age BETWEEN 30 AND 40 THEN '30-40'
            ELSE '>40'
        END AS age_range
    FROM employees
) sub
GROUP BY age_range
ORDER BY age_range;

-- Number of employees with OverTime = 'Yes' and JobSatisfaction < 3
SELECT COUNT(*) AS low_satisfaction_overtime_employees
FROM employees e
JOIN hr_emp h ON e.employee_number = h.employee_number
WHERE e.over_time = TRUE
  AND h.job_satisfaction < 3;




SELECT * FROM employees

