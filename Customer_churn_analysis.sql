-- ============================================================
-- CUSTOMER CHURN & RETENTION ANALYTICS
-- SQL ANALYSIS
-- ============================================================

-- ============================================================
-- 1. BASIC DATA OVERVIEW
-- ============================================================

-- Total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- Customers by gender
SELECT gender, COUNT(*) AS customer_count
FROM customers
GROUP BY gender
ORDER BY customer_count DESC;

-- Customers by city
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

-- Customers by acquisition channel
SELECT acquisition_channel, COUNT(*) AS customer_count
FROM customers
GROUP BY acquisition_channel
ORDER BY customer_count DESC;

-- Customers by subscription status
SELECT subscription_status, COUNT(*) AS customer_count
FROM subscriptions
GROUP BY subscription_status;


-- ============================================================
-- 2. CUSTOMER AGE ANALYSIS
-- ============================================================

SELECT
    CASE
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS customer_count
FROM customers
GROUP BY age_group
ORDER BY customer_count DESC;


-- ============================================================
-- 3. PLAN ANALYSIS
-- ============================================================

SELECT
    p.plan_name,
    p.plan_type,
    COUNT(s.customer_id) AS customers
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name, p.plan_type
ORDER BY customers DESC;


-- Customers by plan
SELECT
    p.plan_name,
    COUNT(*) AS customer_count
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY customer_count DESC;


-- Monthly vs Annual subscriptions
SELECT
    p.plan_type,
    COUNT(*) AS customers
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_type;


-- ============================================================
-- 4. CHURN ANALYSIS
-- ============================================================

-- Total churned customers
SELECT COUNT(*) AS churned_customers
FROM subscriptions
WHERE subscription_status = 'Churned';


-- Overall churn rate
SELECT
    ROUND(
        100.0 * SUM(
            CASE
                WHEN subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate_percentage
FROM subscriptions;


-- Active vs churned percentage
SELECT
    subscription_status,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM subscriptions
GROUP BY subscription_status;


-- ============================================================
-- 5. CHURN BY PLAN
-- ============================================================

SELECT
    p.plan_name,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY churn_rate DESC;


-- ============================================================
-- 6. CHURN BY MONTHLY VS ANNUAL PLAN
-- ============================================================

SELECT
    p.plan_type,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_type
ORDER BY churn_rate DESC;


-- ============================================================
-- 7. CHURN BY GENDER
-- ============================================================

SELECT
    c.gender,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY c.gender
ORDER BY churn_rate DESC;


-- ============================================================
-- 8. CHURN BY ACQUISITION CHANNEL
-- ============================================================

SELECT
    c.acquisition_channel,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY c.acquisition_channel
ORDER BY churn_rate DESC;


-- ============================================================
-- 9. CHURN BY CITY
-- ============================================================

SELECT
    c.city,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY c.city
HAVING COUNT(*) >= 5
ORDER BY churn_rate DESC;


-- ============================================================
-- 10. CHURN BY AGE GROUP
-- ============================================================

SELECT
    CASE
        WHEN c.age < 25 THEN '18-24'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN s.subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY age_group
ORDER BY churn_rate DESC;


-- ============================================================
-- 11. AUTO-RENEWAL VS CHURN
-- ============================================================

SELECT
    auto_renew,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions
GROUP BY auto_renew
ORDER BY churn_rate DESC;


-- ============================================================
-- 12. DISCOUNT VS CHURN
-- ============================================================

SELECT
    discount_pct,
    COUNT(*) AS customers,
    SUM(
        CASE
            WHEN subscription_status = 'Churned' THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN subscription_status = 'Churned' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions
GROUP BY discount_pct
ORDER BY discount_pct;


-- ============================================================
-- 13. REVENUE ANALYSIS
-- ============================================================

-- Estimated monthly recurring revenue
SELECT
    ROUND(
        SUM(
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price * (1 - s.discount_pct / 100.0)

                WHEN p.plan_type = 'Annual'
                THEN (p.annual_price / 12.0) *
                     (1 - s.discount_pct / 100.0)
            END
        ),
        2
    ) AS monthly_recurring_revenue
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Active';


-- Revenue by plan
SELECT
    p.plan_name,
    ROUND(
        SUM(
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price * (1 - s.discount_pct / 100.0)
                ELSE (p.annual_price / 12.0) *
                     (1 - s.discount_pct / 100.0)
            END
        ),
        2
    ) AS estimated_monthly_revenue
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Active'
GROUP BY p.plan_name
ORDER BY estimated_monthly_revenue DESC;


-- ============================================================
-- 14. REVENUE AT RISK FROM CHURNED CUSTOMERS
-- ============================================================

SELECT
    ROUND(
        SUM(
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price * (1 - s.discount_pct / 100.0)
                ELSE (p.annual_price / 12.0) *
                     (1 - s.discount_pct / 100.0)
            END
        ),
        2
    ) AS monthly_revenue_at_risk
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Churned';


-- Revenue at risk by plan
SELECT
    p.plan_name,
    COUNT(*) AS churned_customers,
    ROUND(
        SUM(
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price * (1 - s.discount_pct / 100.0)
                ELSE (p.annual_price / 12.0) *
                     (1 - s.discount_pct / 100.0)
            END
        ),
        2
    ) AS revenue_at_risk
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Churned'
GROUP BY p.plan_name
ORDER BY revenue_at_risk DESC;


-- ============================================================
-- 15. CUSTOMER LIFETIME VALUE
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    p.plan_name,
    ROUND(
        CASE
            WHEN p.plan_type = 'Monthly'
            THEN p.monthly_price * (1 - s.discount_pct / 100.0)
            ELSE (p.annual_price / 12.0) *
                 (1 - s.discount_pct / 100.0)
        END,
        2
    ) AS monthly_revenue,
    GREATEST(
        1,
        COALESCE(
            DATEDIFF(
                COALESCE(s.end_date, CURRENT_DATE),
                s.start_date
            ) / 30,
            1
        )
    ) AS estimated_months,
    ROUND(
        (
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price * (1 - s.discount_pct / 100.0)
                ELSE (p.annual_price / 12.0) *
                     (1 - s.discount_pct / 100.0)
            END
        ) *
        GREATEST(
            1,
            COALESCE(
                DATEDIFF(
                    COALESCE(s.end_date, CURRENT_DATE),
                    s.start_date
                ) / 30,
                1
            )
        ),
        2
    ) AS estimated_ltv
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
ORDER BY estimated_ltv DESC;


-- ============================================================
-- 16. TOP 20 HIGH-VALUE CUSTOMERS
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    p.plan_name,
    p.plan_type,
    ROUND(
        CASE
            WHEN p.plan_type = 'Monthly'
            THEN p.monthly_price * (1 - s.discount_pct / 100.0)
            ELSE (p.annual_price / 12.0) *
                 (1 - s.discount_pct / 100.0)
        END,
        2
    ) AS monthly_value
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
ORDER BY monthly_value DESC
LIMIT 20;


-- ============================================================
-- 17. USAGE ANALYSIS
-- ============================================================

SELECT
    ROUND(AVG(login_count), 2) AS avg_logins,
    ROUND(AVG(session_minutes), 2) AS avg_session_minutes,
    ROUND(AVG(files_uploaded), 2) AS avg_files_uploaded,
    ROUND(AVG(files_downloaded), 2) AS avg_files_downloaded,
    ROUND(AVG(storage_used_gb), 2) AS avg_storage_used,
    ROUND(AVG(feature_usage_count), 2) AS avg_feature_usage
FROM customer_usage;


-- Usage by churn status
SELECT
    s.subscription_status,
    ROUND(AVG(u.login_count), 2) AS avg_logins,
    ROUND(AVG(u.session_minutes), 2) AS avg_session_minutes,
    ROUND(AVG(u.files_uploaded), 2) AS avg_files_uploaded,
    ROUND(AVG(u.files_downloaded), 2) AS avg_files_downloaded,
    ROUND(AVG(u.feature_usage_count), 2) AS avg_feature_usage
FROM customer_usage u
JOIN subscriptions s
    ON u.customer_id = s.customer_id
GROUP BY s.subscription_status;


-- ============================================================
-- 18. LOW-USAGE CUSTOMERS
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    s.subscription_status,
    u.login_count,
    u.session_minutes,
    u.feature_usage_count
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN customer_usage u
    ON c.customer_id = u.customer_id
WHERE u.login_count <= 3
   OR u.session_minutes < 30
   OR u.feature_usage_count <= 2
ORDER BY u.login_count ASC;


-- ============================================================
-- 19. SUPPORT TICKET ANALYSIS
-- ============================================================

-- Tickets by category
SELECT
    issue_category,
    COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY issue_category
ORDER BY ticket_count DESC;


-- Tickets by priority
SELECT
    priority,
    COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY priority
ORDER BY ticket_count DESC;


-- Average resolution time
SELECT
    issue_category,
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours
FROM support_tickets
GROUP BY issue_category
ORDER BY avg_resolution_hours DESC;


-- Average customer satisfaction
SELECT
    issue_category,
    ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction
FROM support_tickets
GROUP BY issue_category
ORDER BY avg_satisfaction ASC;


-- ============================================================
-- 20. SUPPORT TICKETS VS CHURN
-- ============================================================

SELECT
    s.subscription_status,
    COUNT(t.ticket_id) AS total_tickets,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hours,
    ROUND(AVG(t.customer_satisfaction), 2) AS avg_satisfaction
FROM support_tickets t
JOIN subscriptions s
    ON t.customer_id = s.customer_id
GROUP BY s.subscription_status;


-- High-priority tickets vs churn
SELECT
    t.priority,
    s.subscription_status,
    COUNT(*) AS ticket_count
FROM support_tickets t
JOIN subscriptions s
    ON t.customer_id = s.customer_id
WHERE t.priority IN ('High', 'Urgent')
GROUP BY t.priority, s.subscription_status
ORDER BY t.priority, ticket_count DESC;


-- ============================================================
-- 21. CUSTOMERS WITH MANY SUPPORT TICKETS
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    s.subscription_status,
    COUNT(t.ticket_id) AS total_tickets,
    ROUND(AVG(t.customer_satisfaction), 2) AS avg_satisfaction
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN support_tickets t
    ON c.customer_id = t.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    s.subscription_status
HAVING COUNT(t.ticket_id) >= 3
ORDER BY total_tickets DESC;


-- ============================================================
-- 22. CTE - CUSTOMER 360 VIEW
-- ============================================================

WITH customer_usage_summary AS (
    SELECT
        customer_id,
        SUM(login_count) AS total_logins,
        SUM(session_minutes) AS total_session_minutes,
        SUM(files_uploaded) AS total_uploads,
        SUM(files_downloaded) AS total_downloads,
        SUM(feature_usage_count) AS total_feature_usage
    FROM customer_usage
    GROUP BY customer_id
),
ticket_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS total_tickets,
        AVG(customer_satisfaction) AS avg_satisfaction
    FROM support_tickets
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    s.subscription_status,
    p.plan_name,
    u.total_logins,
    u.total_session_minutes,
    u.total_uploads,
    u.total_downloads,
    u.total_feature_usage,
    COALESCE(t.total_tickets, 0) AS total_tickets,
    ROUND(COALESCE(t.avg_satisfaction, 0), 2) AS avg_satisfaction
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
LEFT JOIN customer_usage_summary u
    ON c.customer_id = u.customer_id
LEFT JOIN ticket_summary t
    ON c.customer_id = t.customer_id;


-- ============================================================
-- 23. CUSTOMER SEGMENTATION
-- ============================================================

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        s.subscription_status,
        p.plan_name,
        CASE
            WHEN p.plan_type = 'Monthly'
            THEN p.monthly_price
            ELSE p.annual_price / 12
        END AS monthly_value,
        COALESCE(u.login_count, 0) AS login_count,
        COALESCE(u.session_minutes, 0) AS session_minutes
    FROM customers c
    JOIN subscriptions s
        ON c.customer_id = s.customer_id
    JOIN plans p
        ON s.plan_id = p.plan_id
    LEFT JOIN customer_usage u
        ON c.customer_id = u.customer_id
)
SELECT
    customer_id,
    subscription_status,
    plan_name,
    monthly_value,
    login_count,
    session_minutes,
    CASE
        WHEN monthly_value >= 50
             AND login_count >= 10
            THEN 'High Value - Highly Engaged'

        WHEN monthly_value >= 50
             AND login_count < 10
            THEN 'High Value - At Risk'

        WHEN monthly_value < 50
             AND login_count >= 10
            THEN 'Low Value - Highly Engaged'

        ELSE 'Low Value - At Risk'
    END AS customer_segment
FROM customer_metrics;


-- ============================================================
-- 24. CHURN RISK SCORE
-- ============================================================

WITH customer_risk AS (
    SELECT
        c.customer_id,
        s.subscription_status,
        s.auto_renew,
        p.plan_type,
        COALESCE(u.login_count, 0) AS login_count,
        COALESCE(u.session_minutes, 0) AS session_minutes,
        COALESCE(t.total_tickets, 0) AS total_tickets,
        COALESCE(t.avg_satisfaction, 5) AS avg_satisfaction
    FROM customers c
    JOIN subscriptions s
        ON c.customer_id = s.customer_id
    JOIN plans p
        ON s.plan_id = p.plan_id
    LEFT JOIN customer_usage u
        ON c.customer_id = u.customer_id
    LEFT JOIN (
        SELECT
            customer_id,
            COUNT(*) AS total_tickets,
            AVG(customer_satisfaction) AS avg_satisfaction
        FROM support_tickets
        GROUP BY customer_id
    ) t
        ON c.customer_id = t.customer_id
)
SELECT
    customer_id,
    subscription_status,
    (
        CASE
            WHEN login_count <= 3 THEN 2
            WHEN login_count <= 6 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN session_minutes < 30 THEN 2
            WHEN session_minutes < 60 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN total_tickets >= 4 THEN 2
            WHEN total_tickets >= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN avg_satisfaction <= 2 THEN 2
            WHEN avg_satisfaction <= 3 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN auto_renew = 'No' THEN 2
            ELSE 0
        END
    ) AS churn_risk_score
FROM customer_risk
ORDER BY churn_risk_score DESC;


-- ============================================================
-- 25. CHURN RISK CATEGORY
-- ============================================================

WITH risk_scores AS (
    SELECT
        c.customer_id,
        s.subscription_status,
        (
            CASE
                WHEN COALESCE(u.login_count, 0) <= 3 THEN 2
                WHEN COALESCE(u.login_count, 0) <= 6 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN COALESCE(u.session_minutes, 0) < 30 THEN 2
                WHEN COALESCE(u.session_minutes, 0) < 60 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN COALESCE(t.total_tickets, 0) >= 4 THEN 2
                WHEN COALESCE(t.total_tickets, 0) >= 2 THEN 1
                ELSE 0
            END
        ) AS risk_score
    FROM customers c
    JOIN subscriptions s
        ON c.customer_id = s.customer_id
    LEFT JOIN customer_usage u
        ON c.customer_id = u.customer_id
    LEFT JOIN (
        SELECT
            customer_id,
            COUNT(*) AS total_tickets
        FROM support_tickets
        GROUP BY customer_id
    ) t
        ON c.customer_id = t.customer_id
)
SELECT
    customer_id,
    subscription_status,
    risk_score,
    CASE
        WHEN risk_score >= 5 THEN 'High Risk'
        WHEN risk_score >= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM risk_scores
ORDER BY risk_score DESC;


-- ============================================================
-- 26. WINDOW FUNCTION - CUSTOMER RANKING
-- ============================================================

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        p.plan_name,
        CASE
            WHEN p.plan_type = 'Monthly'
            THEN p.monthly_price * (1 - s.discount_pct / 100.0)
            ELSE (p.annual_price / 12) *
                 (1 - s.discount_pct / 100.0)
        END AS monthly_value
    FROM customers c
    JOIN subscriptions s
        ON c.customer_id = s.customer_id
    JOIN plans p
        ON s.plan_id = p.plan_id
)
SELECT
    customer_id,
    first_name,
    last_name,
    plan_name,
    ROUND(monthly_value, 2) AS monthly_value,
    RANK() OVER (
        ORDER BY monthly_value DESC
    ) AS revenue_rank
FROM customer_revenue;


-- ============================================================
-- 27. PLAN RANKING BY CHURN RATE
-- ============================================================

WITH plan_churn AS (
    SELECT
        p.plan_name,
        COUNT(*) AS total_customers,
        SUM(
            CASE
                WHEN s.subscription_status = 'Churned'
                THEN 1 ELSE 0
            END
        ) AS churned_customers
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    GROUP BY p.plan_name
)
SELECT
    plan_name,
    total_customers,
    churned_customers,
    ROUND(
        100.0 * churned_customers / total_customers,
        2
    ) AS churn_rate,
    RANK() OVER (
        ORDER BY
        100.0 * churned_customers / total_customers DESC
    ) AS churn_rank
FROM plan_churn;


-- ============================================================
-- 28. MONTHLY SIGNUP TREND
-- ============================================================

SELECT
    YEAR(signup_date) AS signup_year,
    MONTH(signup_date) AS signup_month,
    COUNT(*) AS new_customers
FROM customers
GROUP BY
    YEAR(signup_date),
    MONTH(signup_date)
ORDER BY signup_year, signup_month;


-- ============================================================
-- 29. MONTHLY CHURN TREND
-- ============================================================

SELECT
    YEAR(end_date) AS churn_year,
    MONTH(end_date) AS churn_month,
    COUNT(*) AS churned_customers
FROM subscriptions
WHERE subscription_status = 'Churned'
GROUP BY
    YEAR(end_date),
    MONTH(end_date)
ORDER BY churn_year, churn_month;


-- ============================================================
-- 30. CUSTOMER TENURE
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    s.subscription_status,
    s.start_date,
    s.end_date,
    DATEDIFF(
        COALESCE(s.end_date, CURRENT_DATE),
        s.start_date
    ) AS tenure_days
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
ORDER BY tenure_days DESC;


-- ============================================================
-- 31. AVERAGE TENURE BY CHURN STATUS
-- ============================================================

SELECT
    subscription_status,
    ROUND(
        AVG(
            DATEDIFF(
                COALESCE(end_date, CURRENT_DATE),
                start_date
            )
        ),
        2
    ) AS avg_tenure_days
FROM subscriptions
GROUP BY subscription_status;


-- ============================================================
-- 32. SHORT-TENURE CHURNED CUSTOMERS
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    s.start_date,
    s.end_date,
    DATEDIFF(s.end_date, s.start_date) AS tenure_days
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
WHERE s.subscription_status = 'Churned'
  AND DATEDIFF(s.end_date, s.start_date) < 180
ORDER BY tenure_days ASC;


-- ============================================================
-- 33. SUBQUERY - CUSTOMERS ABOVE AVERAGE USAGE
-- ============================================================

SELECT
    customer_id,
    login_count,
    session_minutes,
    feature_usage_count
FROM customer_usage
WHERE login_count > (
    SELECT AVG(login_count)
    FROM customer_usage
)
ORDER BY login_count DESC;


-- ============================================================
-- 34. CUSTOMERS WITH ABOVE-AVERAGE SUPPORT TICKETS
-- ============================================================

SELECT
    customer_id,
    COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY customer_id
HAVING COUNT(*) > (
    SELECT AVG(ticket_count)
    FROM (
        SELECT
            customer_id,
            COUNT(*) AS ticket_count
        FROM support_tickets
        GROUP BY customer_id
    ) x
)
ORDER BY ticket_count DESC;


-- ============================================================
-- 35. CHURNED CUSTOMERS WITH HIGH USAGE
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    u.login_count,
    u.session_minutes,
    u.feature_usage_count,
    s.subscription_status
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN customer_usage u
    ON c.customer_id = u.customer_id
WHERE s.subscription_status = 'Churned'
  AND u.login_count >
      (SELECT AVG(login_count) FROM customer_usage)
ORDER BY u.login_count DESC;


-- ============================================================
-- 36. HIGH-VALUE CUSTOMERS WHO CHURNED
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    p.plan_name,
    p.plan_type,
    s.subscription_status,
    CASE
        WHEN p.plan_type = 'Monthly'
        THEN p.monthly_price
        ELSE p.annual_price / 12
    END AS monthly_value
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Churned'
ORDER BY monthly_value DESC;


-- ============================================================
-- 37. CUSTOMER 360 + CHURN FLAG
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.age,
    c.gender,
    c.city,
    c.acquisition_channel,
    p.plan_name,
    p.plan_type,
    s.auto_renew,
    s.discount_pct,
    s.subscription_status,
    COALESCE(u.login_count, 0) AS login_count,
    COALESCE(u.session_minutes, 0) AS session_minutes,
    COALESCE(u.feature_usage_count, 0) AS feature_usage_count,
    COALESCE(t.ticket_count, 0) AS ticket_count,
    CASE
        WHEN s.subscription_status = 'Churned'
        THEN 1
        ELSE 0
    END AS churn_flag
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
LEFT JOIN customer_usage u
    ON c.customer_id = u.customer_id
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS ticket_count
    FROM support_tickets
    GROUP BY customer_id
) t
    ON c.customer_id = t.customer_id;


-- ============================================================
-- 38. TOP CITIES BY REVENUE
-- ============================================================

SELECT
    c.city,
    COUNT(*) AS customers,
    ROUND(
        SUM(
            CASE
                WHEN p.plan_type = 'Monthly'
                THEN p.monthly_price
                ELSE p.annual_price / 12
            END
        ),
        2
    ) AS estimated_monthly_revenue
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.subscription_status = 'Active'
GROUP BY c.city
ORDER BY estimated_monthly_revenue DESC;


-- ============================================================
-- 39. HIGH-VALUE CUSTOMERS AT CHURN RISK
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    p.plan_name,
    p.monthly_price,
    s.auto_renew,
    u.login_count,
    u.session_minutes
FROM customers c
JOIN subscriptions s
    ON c.customer_id = s.customer_id
JOIN plans p
    ON s.plan_id = p.plan_id
LEFT JOIN customer_usage u
    ON c.customer_id = u.customer_id
WHERE s.subscription_status = 'Active'
  AND p.monthly_price >= 30
  AND (
      u.login_count <= 3
      OR u.session_minutes < 30
      OR s.auto_renew = 'No'
  )
ORDER BY p.monthly_price DESC;


-- ============================================================
-- 40. FINAL EXECUTIVE KPI SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN subscription_status = 'Active'
            THEN 1 ELSE 0
        END
    ) AS active_customers,

    SUM(
        CASE
            WHEN subscription_status = 'Churned'
            THEN 1 ELSE 0
        END
    ) AS churned_customers,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN subscription_status = 'Churned'
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions;


-- ============================================================
-- END OF CUSTOMER CHURN ANALYTICS
-- ============================================================
