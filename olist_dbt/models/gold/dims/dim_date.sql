WITH date_spine AS (
    SELECT
        DATEADD(day, seq4(), '2016-01-01') AS full_date
    FROM TABLE(GENERATOR(ROWCOUNT => 4380)) 
),

enriched AS (
    SELECT
        TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD')) AS date_key,
        full_date,
        YEAR(full_date)                            AS year,
        'Q' || QUARTER(full_date)                   AS quarter,
        'FY' || CASE WHEN MONTH(full_date) >= 4
             THEN YEAR(full_date) + 1
             ELSE YEAR(full_date)
        END                                          AS fiscal_year,
        'Q' || (FLOOR(MOD(MONTH(full_date) - 4 + 12, 12) / 3) + 1) AS fiscal_quarter,
        MONTH(full_date)                            AS month,
        MONTHNAME(full_date)                        AS month_name,
        DAY(full_date)                              AS day_of_month,
        WEEKOFYEAR(full_date)                       AS week_of_year,
        DAYOFWEEK(full_date)                        AS day_of_week,
        DAYNAME(full_date)                          AS day_name,
        CASE WHEN DAYOFWEEK(full_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
    FROM date_spine
)

SELECT * FROM enriched