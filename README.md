# Global Layoffs Analysis: Data Cleaning and Exploratory Data Analysis with SQL

## Introduction

This project is part of my data analysis portfolio, where I use **SQL** to conduct a comprehensive process of *Data Cleaning* and *Exploratory Data Analysis (EDA)*. The dataset contains information on mass layoffs across various companies worldwide, covering different industries and countries.

The main goal of this analysis is to demonstrate my SQL skills, from cleaning and transforming data to extracting actionable insights about the impact of layoffs on the global business landscape.

## Dataset

The dataset is stored in a **MySQL** database and contains the following columns:

- `company`: Name of the company.
- `location`: Location of the company.
- `industry`: Industry to which the company belongs.
- `total_laid_off`: Total number of layoffs.
- `percentage_laid_off`: Percentage of employees laid off.
- `date`: Date of the layoffs.
- `stage_of_the_company`: Stage of the company (Startup, Growth, etc.).
- `country`: Country where the company operates.
- `funds_raised_millions`: Funds raised by the company (in millions of dollars).

## Phase 1: Data Cleaning

The data cleaning process is crucial to ensure that the analysis is based on accurate and consistent information. In this phase, I followed a structured approach to prepare the dataset for analysis.

### **Steps:**

1. **Remove duplicates**
2. **Standardize the data**
3. **Handle null or blank values**
4. **Remove unnecessary columns**

### Step 1: Remove duplicates

The first task was to identify and remove duplicate records. I used the `ROW_NUMBER()` function to detect duplicates based on key columns, followed by deleting the unnecessary rows.

```sql
-- Insert data into a new table, adding row_num to identify duplicates
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```

#### Explanation

This code creates a temporary table with a row_num column to flag duplicate rows based on several key columns. The subsequent DELETE query removes any rows where row_num is greater than 1, ensuring that duplicates are eliminated while preserving unique data.

### Step 2: Standardize the data

Standardizing the data, especially in the `date` column, is vital for accurate analysis. Here, I ensured that all date values were properly formatted and converted the `date` column to the correct SQL data type.

```sql
-- Check that date conversions work correctly
SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Attempt to convert date values
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); 

-- Correct the row that contains the text "NULL"
UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` LIKE 'NULL';

-- Convert the values again
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modify the 'date' column to the DATE type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

#### Explanation

In this example, I first check that the date conversions are working properly using `STR_TO_DATE()`. After correcting a problematic entry where the date was incorrectly stored as the string "NULL", the entire column is converted to a valid date format. Finally, I change the column type to `DATE` to ensure that it stores the values correctly.

### Step 3: Handle null or blank values

Handling missing data is essential for ensuring data consistency. I filled in missing or blank values using related data from other rows where appropriate.

```sql
-- Find null or blank values in the 'industry' column
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry LIKE '';

-- Inspect a specific case to better understand the problem
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Airbnb';

-- Populate the blank values based on 'company' and 'location'
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry = '' OR t1.industry IS NULL)
AND (t2.industry <> '' AND t2.industry IS NOT NULL);

-- Update blank 'industry' values with the correct related values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry = '' OR t1.industry IS NULL)
AND (t2.industry <> '' AND t2.industry IS NOT NULL);
```

#### Explanation

In this step, I first identify rows with missing or blank values in the `industry` column. After inspecting a specific case (Airbnb), I use a join operation to find and fill in the missing values using related rows based on the company and location. This ensures that the dataset is complete and ready for analysis.

### Step 4: Remove unnecessary columns

In this final step of the data cleaning process, I removed columns that were not necessary for the analysis. 

## Phase 2: Exploratory Data Analysis (EDA)

After cleaning the data, I conducted an exploratory data analysis (EDA) to identify key patterns and trends within the dataset. Below are three examples of SQL queries that provide insight into layoffs worldwide.

### Example 1: Total layoffs by year

This query groups the total number of layoffs by year, offering a clear view of the layoffs' evolution over time.

```sql
-- List of total layoffs grouped by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
```

#### Explanation

This query uses the `YEAR()` function to extract the year from the `date` column, grouping the layoffs by year. By summing the `total_laid_off` for each year, this query highlights the overall yearly trends in layoffs, showing which years saw the most significant workforce reductions.

### Example 2: Rolling sum of total layoffs

This query calculates the monthly sum of layoffs and then computes a rolling total, allowing us to observe how layoffs have accumulated over time.

```sql
-- Rolling sum: the progression of total layoffs
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS sum_tlo
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC
)
SELECT `MONTH`, sum_tlo,
SUM(sum_tlo) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;
```

#### Explanation

In this example, the `SUBSTRING()` function is used to extract the year and month from the `date` column, creating a monthly view of layoffs. The `WITH` clause creates a temporary result set that calculates the monthly sum of `total_laid_off`. Then, the `SUM() OVER()` function is applied to compute the cumulative total of layoffs over time, offering a dynamic perspective on how layoffs have progressed month by month.

### Example 3: Company ranking by layoffs per year

This example ranks companies based on the total number of layoffs they have conducted each year. Additionally, a historical ranking shows the top companies for all time based on total layoffs.

```sql
-- Ranking of companies with the highest total layoffs per year
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

-- All-time ranking for the top 5 companies across every year
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
```

#### Explanation

This query ranks companies by the number of layoffs they’ve carried out each year. It first calculates the total layoffs per company for each year using a `WITH` clause. Then, the `DENSE_RANK()` function is applied to rank companies by their total layoffs within each year (`PARTITION BY years`). The second part of the query ranks companies across all years, identifying the top 5 companies that have conducted the most layoffs in history.

## Conclusions

This project demonstrates how SQL can be effectively used to conduct a complete data analysis process, from data cleaning to exploratory analysis. Through this analysis, valuable insights were uncovered about global layoffs, such as yearly trends, monthly progressions, and the companies most affected. This project highlights the versatility of SQL in handling large datasets and providing meaningful insights for business analysis.

## Conclusions

This project demonstrates how SQL can be effectively used to conduct a complete data analysis process, from data cleaning to exploratory analysis. Through this analysis, valuable insights were uncovered about global layoffs, such as yearly trends, monthly progressions, and the companies most affected. This project highlights the versatility of SQL in handling large datasets and providing meaningful insights for business analysis.

