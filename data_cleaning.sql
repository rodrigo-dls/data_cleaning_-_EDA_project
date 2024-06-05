-- Data Cleaning
-- The following code cleans the data for dataset that will be used for further EDA analysis

SELECT *
FROM layoffs;

-- Steps
-- 1. Remove Duplicates
-- 2. Standarize the Data
-- 3. Null Values or blank values
-- 4. Remove Any Columns

-- Create a copy of the original 'raw table' named 'staging table'

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging; # Check that columns have been created properly

INSERT layoffs_staging
SELECT *
FROM layoffs; # Insert all the rows from the original table

SELECT *
FROM layoffs_staging; # Check that Insert was done as expected

-- From now on, work is with 'layoffs_staging' for Data Cleaning

-- 1. Remove duplicates

-- First, identify duplicates. Number rows to see if any row > 1
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Create CTE to find the duplicates by filtering the row_num column
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Duplicate rows have been found, now analyse and understand best way to handle them
SELECT *
FROM layoffs_staging
WHERE company = 'Oda'; # There are no duplicates in this case, the CTE must have PARTITION BY by every single column

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1; # There are 5 duplicates to explore

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Only one row of every duplicate must be deleted (it can't be done by deleting through the CTE)
-- It can be done by
			-- i. creating a new table that has the 'row_num' column
            -- ii. deleting the duplicates
            -- iii. deleting the 'row_num' column
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging; # populate new table with the previous CTE

SELECT *
FROM layoffs_staging2
WHERE row_num > 1; # identify and valid what's going to be deleted next

DELETE
FROM layoffs_staging2
WHERE row_num > 1; # delete duplicates

SELECT *
FROM layoffs_staging2
WHERE row_num > 1; # validate delete has been done properly

-- 2. Standarize the Data

-- Find issues and fix them

-- standarize column 'company'
SELECT company, TRIM(company)
FROM layoffs_staging2; # validate TRIM has been done properly

UPDATE layoffs_staging2
SET company = TRIM(company); # apply the change to the actual column

-- standarize column 'industry'
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry; # noticed repetition of rows by similar spelling (Crypto..),
				   # NULL values and blanc values

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
ORDER BY industry; # spot the potential wrong values
				   # three rows seem to be different

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry like 'Crypto%'; # standarize them to a same value

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry; # validate changes have been done properly

-- standarize 'location'
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1; # take a look at the column, looks fine

-- standarize 'country'
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; # take a look at the column, there is a value that needs to be standarized ('United States')

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'; # looks that the right value is "United States" not "United States."

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1; # validate that it fixes the error

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; # standarize them to a same value

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; # validate changes has been done properly

-- standarize 'date'
SELECT *
FROM layoffs_staging2; # 'date' type column must be date type

SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y') # `date` is wrapped by backticks in this case as it's keyword of SQL as well
FROM layoffs_staging2; # check that changes work properly

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); # can't convert due to one row having the text value "NULL"

UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` LIKE 'NULL'; # convert the text value to NULL value

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); # convert values to date format

SELECT `date`
FROM layoffs_staging2; # check that changes work properly

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; # gives `date` column DATE type

-- standarize 'total_laid_off' and 'percentage_laid_off' columns data type
ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off INT,
MODIFY COLUMN percentage_laid_off INT;

-- standarize 'funds_raised_millions' column data type

SELECT *
FROM layoffs_staging2
WHERE funds_raised_millions = 'NULL';

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'NULL'; # convert 'NULL' string values to NULL values

SELECT *
FROM layoffs_staging2
WHERE funds_raised_millions IS NULL; # changes were done properly. Now column data type can be changed

ALTER TABLE layoffs_staging2
MODIFY COLUMN funds_raised_millions INT;

-- 3. Null Values or Blank Values

-- check total_laid_off and percentage_laid_off columns
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
OR percentage_laid_off IS NULL; # returns 0 rows

SELECT *
FROM layoffs_staging2
WHERE total_laid_off LIKE 'NULL' 
OR percentage_laid_off LIKE 'NULL'; # due to pre-conversion to JSON file, NULL values have been imported as 'NULL' string values

UPDATE layoffs_staging2
SET 
	total_laid_off = CASE
						WHEN total_laid_off = 'NULL' THEN NULL
                        ELSE total_laid_off
					END,
	percentage_laid_off = CASE
							WHEN percentage_laid_off = 'NULL' THEN NULL
                            ELSE percentage_laid_off
						END; # convert 'NULL' string values to NULL values

SELECT COUNT(*)
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
OR percentage_laid_off IS NULL; # check that changes work properly. Returns 1162

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; # NULLs are left as they are as there is not data enough to populate them
								# they won't be useful for further analisys hence decided to be deleted

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; # delete all the rows with NULL values in both columns simultaneously

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; # changes have been done properly. Returns 0 rows

-- check industry column 
SELECT industry
FROM layoffs_staging2
WHERE industry IS NULL
OR industry LIKE 'NULL'
OR industry = ''; # check blanks and NULLs. Again the issue from the JSON file conversion

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry LIKE 'NULL'; # convert 'NULL' values to NULL

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry LIKE ''; # look for NULLs and blanks

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Airbnb'; # look at one of the cases to understand better the problem
							# there are blank values where its company has industry correct values assigned in other rows.

-- populate the blank values by using 'company' and 'location' as reference to find the right values
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry = '' OR t1.industry IS NULL)
AND (t2.industry <> '' AND t2.industry IS NOT NULL); # gives the values to create the UPDATE query

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry = '' OR t1.industry IS NULL)
AND (t2.industry <> '' AND t2.industry IS NOT NULL); # update blank values for 'industry' with its related values for 'company'

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry LIKE ''; # check changes have been done. One row remains as NULL

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'; # it doesn't have a related 'company' value

-- 4. Remove Any Columns

-- remove row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2; # check changes have been done properly