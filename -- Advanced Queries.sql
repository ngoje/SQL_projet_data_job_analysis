-- Advanced Queries

-- Extract month in date
SELECT 
    COUNT(job_id) as job_posted_count,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    month
ORDER BY
    job_posted_count DESC;

-- Training
-- 1)
-- Write a query to find the average salary both (salary_year_avg) and hourly (salary_hourly_avg) for job postings that were posted after 
-- June 1, 2023. Group the results by job schedule type

SELECT 
    *
FROM    
    job_postings_fact
LIMIT 10
    ;

SELECT 
    AVG(salary_year_avg),
    AVG(salary_hour_avg),
    job_schedule_type
FROM
    job_postings_fact
WHERE
    job_posted_date > '2023-06-01'
GROUP BY
    job_schedule_type;


-- PRACTICE PROBLEM 6
-- Create tables from other tables
-- Create three tables :
-- -- Jan 2023 jobs
-- -- Feb 2023 jobs
-- -- Mar 2023 jobs
-- Hints : -Use CREATE TABLE table_name AS syntax to create your table
--         -Look at a way to filter out only specific months (EXTRACT)

-- Jan
CREATE TABLE Jan_jobs AS 
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;
-- Feb
CREATE TABLE Feb_jobs AS 
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;
-- Mar
CREATE TABLE Mar_jobs AS 
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

SELECT *
FROM Mar_jobs;


-- CASE Expression
SELECT
    COUNT(job_id) as number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END as location_category
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;

-- Training
-- I want to categorize the salaries from each job posting. To see if it fits in my desired salary range
-- -- Put salary into differents buckets
-- -- Define what's a high, standard, or low salary with our own conditinos
-- -- Only data analyst roles
-- -- Order from highest to lowest
SELECT
    job_id,
    salary_year_avg,
    CASE
        WHEN salary_year_avg < 50000 THEN 'low'
        WHEN salary_year_avg >= 50000 AND salary_year_avg < 100000 THEN 'standard'
        ELSE 'high'
    END as salary_category
FROM job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
    AND salary_year_avg IS NOT NULL
ORDER BY
    salary_year_avg DESC;

-- Subqueries and CTEs

-- Subqueries
SELECT *
FROM (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH from job_posted_date) = 1
    ) AS JAN_jobs;

-- CTEs
WITH Jan_jobs AS (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH from job_posted_date) = 1
)
SELECT *
FROM Jan_jobs;

-- Exemple
-- Subquery
SELECT 
    company_id,
    name
FROM company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE
        job_no_degree_mention = true
    ORDER BY
        company_id
);


-- Exemple
-- CTEs

WITH company_job_count AS (
SELECT
    company_id,
    COUNT(*) as total_job
FROM
    job_postings_fact
GROUP BY   
    company_id
)
SELECT 
    company_dim.name,
    company_job_count.total_job
FROM 
    company_dim
LEFT JOIN company_job_count ON company_job_count.company_id = company_dim.company_id
ORDER BY
    total_job DESC;

-- Training
-- Identify the top 5 skills that are most frequently mentioned in job postings.
-- Use a subquery to find the skills IDs with the highest counts in the skills_job_dim table
-- and then join this result with the skills_dim table to get the skill names
/*
SELECT *
FROM skills_job_dim

SELECT
    COUNT(skill_id) AS count_skills
FROM
    skills_job_dim
WHERE skill_id IN(
    SELECT
        skill_id
    FROM
        skills_dim
    GROUP BY
        skills 
    ORDER BY
        count_skills DESC
    LIMIT 5
);
*/

SELECT 
    s.skill_id, 
    s.skills, 
    skill_count
FROM skills_dim s
JOIN (
    -- Subquery to count occurrences of each skill in job postings
    SELECT 
        skill_id, 
        COUNT(*) AS skill_count
    FROM skills_job_dim
    GROUP BY skill_id
    ORDER BY skill_count DESC
    LIMIT 5
) top_skills
ON s.skill_id = top_skills.skill_id
ORDER BY skill_count DESC;


-- PRACTICE PROBLEM 7 CTEs
-- Find the count of the number of remote job postings per skill
-- -- Display the top 5 skills by their demand in remote jobs
-- -- Include skill ID, name, and count of postings requiring the skill



WITH remote_job_skills AS (

    SELECT
        skill_id,
        COUNT(*) AS skill_count
    FROM
        skills_job_dim
    INNER JOIN job_postings_fact ON job_postings_fact.job_id = skills_job_dim.job_id
    WHERE
        job_postings_fact.job_work_from_home = true AND job_title_short = 'Data Analyst'
    GROUP BY
        skill_id
)
SELECT
    skills_dim.skill_id,
    skills_dim.skills,
    skill_count
FROM remote_job_skills
INNER JOIN skills_dim ON skills_dim.skill_id = remote_job_skills.skill_id 
ORDER BY
    skill_count DESC
LIMIT 5;


-- UNION

SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    Jan_jobs

UNION

SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    Feb_jobs

UNION

SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    Mar_jobs


-- PRACTICE Problem 8
-- Find job postings from the first quarter that have a salary greater than 70k
-- -- Combine job posting tables from the first quarter of 2023
-- -- Get job postings with an average yrealy salary > 70k

SELECT 
    job_location,
    job_via,
    job_posted_date::DATE,
    salary_year_avg
FROM (
    SELECT *
    FROM Jan_jobs
    UNION ALL
    SELECT *
    FROM Feb_jobs
    UNION ALL
    SELECT *
    FROM Mar_jobs
) AS q1_job_postings
WHERE
    salary_year_avg > 70000
    AND job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC;