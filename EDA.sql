-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2; 

SELECT MAX(total_laid_off) 'Max total laid off', 
	MIN(total_laid_off)'Min total laid off', 
    MAX(percentage_laid_off) 'Max percentage laid off', 
    MIN(percentage_laid_off) 'Min percentage laid off'
FROM layoffs_staging2;

-- There are many companies with a 100% laid off, take a look

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Companies with the highest total amount of total laid off
SELECT company, SUM(total_laid_off) total_tlo
FROM layoffs_staging2
GROUP BY company
ORDER BY total_tlo DESC;

-- Period of time of the records in the dataset
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- Industries with the highest total amount of total laid off

SELECT industry, SUM(total_laid_off) total_tlo
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_tlo DESC;

SELECT *
FROM layoffs_staging2; 

-- Countries with the highest total amount of total laid off

SELECT country, SUM(total_laid_off) total_tlo
FROM layoffs_staging2
GROUP BY country
ORDER BY total_tlo DESC;

-- Check the total amount of total laid off for one specific country of interest

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
WHERE country like "Argentina%"
GROUP BY country;

-- List of total amount of total laid off grouped by year

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- List of total amount of total laid off grouped by stage of the company

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- List of companies with their 'percentage laid off ' averages grouped by the company

SELECT company, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Rolling sum: the progression of total_laid_off

SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7)  IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC; # sum of total_laid_off grouped by year-month, the rolling sum will be based on this query


WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS sum_tlo
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7)  IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC
)
SELECT `MONTH`, sum_tlo,
SUM(sum_tlo) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

--  Ranking of companies with the highest total laid off per year

SELECT company, YEAR(`date`) AS years, SUM(total_laid_off)
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, years
ORDER BY 3 DESC;

WITH Company_Year (company, years, sum_tlo) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY sum_tlo DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;

-- All time ranking for the top 5 companies of every year

WITH Company_Year (company, years, sum_tlo) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY sum_tlo DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *, DENSE_RANK() OVER(ORDER BY sum_tlo DESC) AS all_time_ranking
FROM Company_Year_Rank
WHERE ranking <= 5;



