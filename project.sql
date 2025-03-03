-- Project

-- 1) What are the top-paying jobs for my role ?
-- 2) What are the skills required for these top-paying roles ?
-- 3) What are the most in-demand skills for my role ?
-- 4) What are the top skills based on salary for my role ?
-- 5) What are the most optimal skills to learn ? (Optimal : High demand AND high paying)


-- -- -- Top paying jobs
-- 1) What are the top-paying jobs for my role ?
-- -- Identify the top 10 highest-paying Data Analyst roles that are available remotely
-- -- Focuses on job postings with specified salaries (remove nulls)
-- -- Why ? Highlight the top-paying opportunities for Data Analyst

SELECT * FROM job_postings_fact LIMIT 10;

SELECT
    jpf.job_id,
    company_dim.name,
    jpf.salary_year_avg as salary
FROM
    job_postings_fact as jpf
LEFT JOIN company_dim
    ON company_dim.company_id = jpf.company_id 
WHERE
    job_title_short = 'Data Analyst' AND
    job_location = 'Anywhere' AND
    salary_year_avg IS NOT NULL
ORDER BY
    salary DESC
LIMIT 10; 

-- -- -- Top paying job skills
-- 2) What are the skills required for these top-paying roles ?
-- -- Use the top 10 highest-paying Data Analyst jobs from first query
-- -- Add the specific skills required for theses roles

-- Sans CTE
SELECT
    jpf.job_id,
    job_title,
    company_dim.name,
    jpf.salary_year_avg as salary,
    skills.skills
FROM
    job_postings_fact as jpf
LEFT JOIN company_dim ON company_dim.company_id = jpf.company_id 
INNER JOIN skills_job_dim AS skills_job ON skills_job.job_id = jpf.job_id
INNER JOIN skills_dim as skills ON skills.skill_id = skills_job.skill_id 
WHERE
    job_title_short = 'Data Analyst' AND
    job_location = 'Anywhere' AND
    salary_year_avg IS NOT NULL
ORDER BY
    salary DESC
LIMIT 10; 

-- Avec CTE
WITH top_paying_jobs AS (
    SELECT
        jpf.job_id,
        company_dim.name,
        jpf.salary_year_avg as salary
    FROM
        job_postings_fact as jpf
    LEFT JOIN company_dim ON company_dim.company_id = jpf.company_id 
    WHERE
        job_title_short = 'Data Analyst' AND
        job_location = 'Anywhere' AND
        salary_year_avg IS NOT NULL
    ORDER BY
        salary DESC
    LIMIT 10
)
SELECT 
    top_paying_jobs.*,
    skills_dim.skills
FROM top_paying_jobs
INNER JOIN skills_job_dim ON top_paying_jobs.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id  = skills_dim.skill_id 
ORDER BY
    salary DESC
LIMIT 10;

-- -- -- Top demanded skills
-- 3) What are the most in-demand skills for my role ?
-- -- Join job postings to inner join table similar to query 2
-- -- Identify the top 5 in-demand skills for a data analyst
-- -- Focus on all job postings

SELECT
    skills_dim.skills,
    COUNT(job_postings_fact.job_id) as count
FROM job_postings_fact
INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE 
    job_title_short = 'Data Analyst'
GROUP BY
    skills
ORDER BY
    count DESC
LIMIT 5; 


-- -- -- Top paying skills
-- 4) What are the top skills based on salary for my role ?
-- -- Look at the average salary associated with each skill for Data Analyst positions
-- -- Focuses on roles with specified salaries, regardless of location

SELECT
    skills,
    ROUND(AVG(salary_year_avg), 0) as salary
FROM job_postings_fact
INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE 
    job_title_short = 'Data Analyst' AND salary_year_avg IS NOT NULL
GROUP BY
    skills
ORDER BY
    salary desc
LIMIT 25;


-- 5) What are the most optimal skills to learn ? (Optimal : High demand AND high paying)
-- -- Identify skills in high demand and associated with high average salaries for Data analyst roles
-- -- Concentrates on remote positions with specified salaries
WITH skills_demand AS (
    SELECT
        skills_dim.skill_id,
        skills_dim.skills,
        COUNT(job_postings_fact.job_id) as count_demand
    FROM job_postings_fact
    INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
    INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
    WHERE 
        job_title_short = 'Data Analyst' AND
        job_work_from_home = true AND
        job_location = 'Anywhere'
    GROUP BY
        skills_dim.skill_id
), average_salary AS (
    SELECT
        skills_job_dim.skill_id,
        ROUND(AVG(salary_year_avg), 0) as salary
    FROM job_postings_fact
    INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
    INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
    WHERE 
        job_title_short = 'Data Analyst' AND salary_year_avg IS NOT NULL AND job_work_from_home = true
    GROUP BY
        skills_job_dim.skill_id
)
SELECT 
    skills_demand.skill_id,
    skills_demand.skills,
    skills_demand.count_demand,
    average_salary.salary
FROM
    skills_demand
INNER JOIN average_salary ON skills_demand.skill_id = average_salary.skill_id
WHERE
    count_demand > 10
ORDER BY
    salary DESC,
    count_demand DESC
LIMIT 25;


SELECT 
    skills_dim.skill_id,
    skills_dim.skills,
    COUNT(skills_job_dim.job_id) as demand_count,
    ROUND(AVG(job_postings_fact.salary_year_avg), 0) as avg_salary
FROM
    job_postings_fact
INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE
    job_title_short = 'Data Analyst'
    AND salary_year_avg IS NOT NULL
    AND job_work_from_home = TRUE
GROUP BY
    skills_dim.skill_id
HAVING
    COUNT(skills_job_dim.job_id) > 10
ORDER BY
    avg_salary DESC,
    demand_count DESC
LIMIT 25;