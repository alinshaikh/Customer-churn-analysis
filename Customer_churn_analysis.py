# ============================================================
# CUSTOMER CHURN & RETENTION ANALYTICS
# PYTHON ANALYSIS
# ============================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


# ============================================================
# 1. LOAD DATA
# ============================================================

customers = pd.read_csv("../data/customers.csv")
subscriptions = pd.read_csv("../data/subscriptions.csv")
plans = pd.read_csv("../data/plans.csv")
transactions = pd.read_csv("../data/transactions.csv")
usage = pd.read_csv("../data/customer_usage.csv")
tickets = pd.read_csv("../data/support_tickets.csv")


# ============================================================
# 2. DATA OVERVIEW
# ============================================================

print("\n========== DATASET OVERVIEW ==========")

print("\nCustomers:", customers.shape)
print("Subscriptions:", subscriptions.shape)
print("Plans:", plans.shape)
print("Transactions:", transactions.shape)
print("Usage:", usage.shape)
print("Support Tickets:", tickets.shape)

print("\nCustomer columns:")
print(customers.columns.tolist())

print("\nSubscription columns:")
print(subscriptions.columns.tolist())


# ============================================================
# 3. DATA QUALITY CHECK
# ============================================================

print("\n========== DATA QUALITY ==========")

datasets = {
    "Customers": customers,
    "Subscriptions": subscriptions,
    "Plans": plans,
    "Transactions": transactions,
    "Usage": usage,
    "Tickets": tickets
}

for name, df in datasets.items():

    print(f"\n{name}")
    print("Rows:", len(df))
    print("Duplicate rows:", df.duplicated().sum())
    print("Missing values:")
    print(df.isnull().sum())


# ============================================================
# 4. DATE CONVERSION
# ============================================================

customers["signup_date"] = pd.to_datetime(
    customers["signup_date"],
    errors="coerce"
)

subscriptions["start_date"] = pd.to_datetime(
    subscriptions["start_date"],
    errors="coerce"
)

subscriptions["end_date"] = pd.to_datetime(
    subscriptions["end_date"],
    errors="coerce"
)

usage["usage_date"] = pd.to_datetime(
    usage["usage_date"],
    errors="coerce"
)

tickets["ticket_date"] = pd.to_datetime(
    tickets["ticket_date"],
    errors="coerce"
)


# ============================================================
# 5. DATA VALIDATION
# ============================================================

print("\n========== VALIDATION ==========")

print(
    "\nInvalid subscription customers:",
    len(
        subscriptions[
            ~subscriptions["customer_id"].isin(
                customers["customer_id"]
            )
        ]
    )
)

print(
    "Invalid plan IDs:",
    len(
        subscriptions[
            ~subscriptions["plan_id"].isin(
                plans["plan_id"]
            )
        ]
    )
)

print(
    "Invalid usage customers:",
    len(
        usage[
            ~usage["customer_id"].isin(
                customers["customer_id"]
            )
        ]
    )
)

print(
    "Invalid ticket customers:",
    len(
        tickets[
            ~tickets["customer_id"].isin(
                customers["customer_id"]
            )
        ]
    )
)


# ============================================================
# 6. FIX SUBSCRIPTION DATE ISSUE
# ============================================================

subscription_check = subscriptions.merge(
    customers[["customer_id", "signup_date"]],
    on="customer_id",
    how="left"
)

invalid_dates = (
    subscription_check["start_date"]
    < subscription_check["signup_date"]
)

print(
    "\nSubscriptions before customer signup:",
    invalid_dates.sum()
)

subscriptions.loc[
    invalid_dates,
    "start_date"
] = subscription_check.loc[
    invalid_dates,
    "signup_date"
].values


# ============================================================
# 7. CREATE CUSTOMER 360 DATASET
# ============================================================

customer_data = (
    customers
    .merge(
        subscriptions,
        on="customer_id",
        how="left"
    )
    .merge(
        plans,
        on="plan_id",
        how="left"
    )
    .merge(
        usage,
        on="customer_id",
        how="left"
    )
)


# ============================================================
# 8. SUPPORT TICKET SUMMARY
# ============================================================

ticket_summary = (
    tickets
    .groupby("customer_id")
    .agg(
        total_tickets=("ticket_id", "count"),
        avg_resolution_hours=("resolution_hours", "mean"),
        avg_satisfaction=("customer_satisfaction", "mean"),
        high_priority_tickets=(
            "priority",
            lambda x: x.isin(["High", "Urgent"]).sum()
        )
    )
    .reset_index()
)

customer_data = customer_data.merge(
    ticket_summary,
    on="customer_id",
    how="left"
)


# ============================================================
# 9. TRANSACTION SUMMARY
# ============================================================

transaction_summary = (
    transactions
    .groupby("customer_id")
    .agg(
        total_transactions=("customer_id", "count")
    )
    .reset_index()
)

customer_data = customer_data.merge(
    transaction_summary,
    on="customer_id",
    how="left"
)

customer_data["total_transactions"] = (
    customer_data["total_transactions"]
    .fillna(0)
)


# ============================================================
# 10. HANDLE MISSING VALUES
# ============================================================

numeric_columns = [
    "login_count",
    "session_minutes",
    "files_uploaded",
    "files_downloaded",
    "storage_used_gb",
    "feature_usage_count",
    "total_tickets",
    "avg_resolution_hours",
    "avg_satisfaction"
]

for column in numeric_columns:

    if column in customer_data.columns:

        customer_data[column] = (
            customer_data[column]
            .fillna(0)
        )


# ============================================================
# 11. CHURN FLAG
# ============================================================

customer_data["churn_flag"] = np.where(
    customer_data["subscription_status"] == "Churned",
    1,
    0
)


# ============================================================
# 12. MONTHLY REVENUE
# ============================================================

customer_data["monthly_revenue"] = np.where(
    customer_data["plan_type"] == "Monthly",

    customer_data["monthly_price"]
    * (1 - customer_data["discount_pct"] / 100),

    (customer_data["annual_price"] / 12)
    * (1 - customer_data["discount_pct"] / 100)
)


# ============================================================
# 13. TENURE
# ============================================================

customer_data["tenure_days"] = (
    customer_data["end_date"].fillna(
        pd.Timestamp.today()
    )
    - customer_data["start_date"]
).dt.days

customer_data["tenure_months"] = (
    customer_data["tenure_days"] / 30
).clip(lower=1)


# ============================================================
# 14. ESTIMATED CUSTOMER LTV
# ============================================================

customer_data["estimated_ltv"] = (
    customer_data["monthly_revenue"]
    * customer_data["tenure_months"]
)


# ============================================================
# 15. BASIC BUSINESS KPIs
# ============================================================

total_customers = len(customer_data)

active_customers = (
    customer_data["subscription_status"]
    == "Active"
).sum()

churned_customers = (
    customer_data["subscription_status"]
    == "Churned"
).sum()

churn_rate = (
    churned_customers / total_customers * 100
)

active_revenue = customer_data.loc[
    customer_data["subscription_status"] == "Active",
    "monthly_revenue"
].sum()

revenue_at_risk = customer_data.loc[
    customer_data["subscription_status"] == "Churned",
    "monthly_revenue"
].sum()


print("\n========== BUSINESS KPIs ==========")

print("Total Customers:", total_customers)
print("Active Customers:", active_customers)
print("Churned Customers:", churned_customers)
print("Churn Rate:", round(churn_rate, 2), "%")
print(
    "Monthly Recurring Revenue:",
    round(active_revenue, 2)
)
print(
    "Revenue At Risk:",
    round(revenue_at_risk, 2)
)


# ============================================================
# 16. CHURN BY PLAN
# ============================================================

plan_churn = (
    customer_data
    .groupby("plan_name")
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

plan_churn["churn_rate"] = (
    plan_churn["churned"]
    / plan_churn["customers"]
    * 100
)

print("\n========== CHURN BY PLAN ==========")
print(
    plan_churn
    .sort_values("churn_rate", ascending=False)
)


# ============================================================
# 17. CHURN BY PLAN TYPE
# ============================================================

plan_type_churn = (
    customer_data
    .groupby("plan_type")
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

plan_type_churn["churn_rate"] = (
    plan_type_churn["churned"]
    / plan_type_churn["customers"]
    * 100
)

print("\n========== MONTHLY VS ANNUAL ==========")
print(plan_type_churn)


# ============================================================
# 18. CHURN BY ACQUISITION CHANNEL
# ============================================================

channel_churn = (
    customer_data
    .groupby("acquisition_channel")
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

channel_churn["churn_rate"] = (
    channel_churn["churned"]
    / channel_churn["customers"]
    * 100
)

print("\n========== CHURN BY ACQUISITION ==========")
print(
    channel_churn
    .sort_values("churn_rate", ascending=False)
)


# ============================================================
# 19. CHURN BY CITY
# ============================================================

city_churn = (
    customer_data
    .groupby("city")
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

city_churn["churn_rate"] = (
    city_churn["churned"]
    / city_churn["customers"]
    * 100
)

print("\n========== CHURN BY CITY ==========")
print(
    city_churn
    .sort_values("churn_rate", ascending=False)
)


# ============================================================
# 20. CHURN BY AGE GROUP
# ============================================================

customer_data["age_group"] = pd.cut(
    customer_data["age"],
    bins=[0, 24, 34, 44, 54, 100],
    labels=[
        "18-24",
        "25-34",
        "35-44",
        "45-54",
        "55+"
    ]
)

age_churn = (
    customer_data
    .groupby(
        "age_group",
        observed=True
    )
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

age_churn["churn_rate"] = (
    age_churn["churned"]
    / age_churn["customers"]
    * 100
)

print("\n========== CHURN BY AGE ==========")
print(age_churn)


# ============================================================
# 21. AUTO-RENEWAL ANALYSIS
# ============================================================

renewal_churn = (
    customer_data
    .groupby("auto_renew")
    .agg(
        customers=("customer_id", "count"),
        churned=("churn_flag", "sum")
    )
)

renewal_churn["churn_rate"] = (
    renewal_churn["churned"]
    / renewal_churn["customers"]
    * 100
)

print("\n========== AUTO RENEWAL ==========")
print(renewal_churn)


# ============================================================
# 22. USAGE ANALYSIS
# ============================================================

usage_by_churn = (
    customer_data
    .groupby("subscription_status")
    .agg(
        avg_logins=("login_count", "mean"),
        avg_session_minutes=("session_minutes", "mean"),
        avg_uploads=("files_uploaded", "mean"),
        avg_downloads=("files_downloaded", "mean"),
        avg_feature_usage=("feature_usage_count", "mean")
    )
)

print("\n========== USAGE VS CHURN ==========")
print(
    usage_by_churn.round(2)
)


# ============================================================
# 23. SUPPORT VS CHURN
# ============================================================

support_by_churn = (
    customer_data
    .groupby("subscription_status")
    .agg(
        avg_tickets=("total_tickets", "mean"),
        avg_resolution_hours=(
            "avg_resolution_hours",
            "mean"
        ),
        avg_satisfaction=(
            "avg_satisfaction",
            "mean"
        ),
        avg_high_priority_tickets=(
            "high_priority_tickets",
            "mean"
        )
    )
)

print("\n========== SUPPORT VS CHURN ==========")
print(
    support_by_churn.round(2)
)


# ============================================================
# 24. LOW ENGAGEMENT CUSTOMERS
# ============================================================

low_engagement = customer_data[
    (
        customer_data["login_count"] <= 3
    )
    |
    (
        customer_data["session_minutes"] < 30
    )
    |
    (
        customer_data["feature_usage_count"] <= 2
    )
]

print(
    "\nLow engagement customers:",
    len(low_engagement)
)


# ============================================================
# 25. HIGH-VALUE CHURNED CUSTOMERS
# ============================================================

high_value_churn = customer_data[
    (
        customer_data["subscription_status"]
        == "Churned"
    )
].sort_values(
    "monthly_revenue",
    ascending=False
)

print(
    "\n========== HIGH VALUE CHURNED CUSTOMERS =========="
)

print(
    high_value_churn[
        [
            "customer_id",
            "plan_name",
            "monthly_revenue",
            "estimated_ltv"
        ]
    ].head(20)
)


# ============================================================
# 26. CUSTOMER SEGMENTATION
# ============================================================

customer_data["customer_segment"] = np.select(

    [
        (
            (customer_data["monthly_revenue"] >= 50)
            &
            (customer_data["login_count"] >= 10)
        ),

        (
            (customer_data["monthly_revenue"] >= 50)
            &
            (customer_data["login_count"] < 10)
        ),

        (
            (customer_data["monthly_revenue"] < 50)
            &
            (customer_data["login_count"] >= 10)
        )
    ],

    [
        "High Value - Highly Engaged",
        "High Value - At Risk",
        "Low Value - Highly Engaged"
    ],

    default="Low Value - At Risk"
)


print("\n========== CUSTOMER SEGMENTS ==========")

print(
    customer_data["customer_segment"]
    .value_counts()
)


# ============================================================
# 27. CHURN RISK SCORE
# ============================================================

customer_data["risk_score"] = 0

customer_data.loc[
    customer_data["login_count"] <= 3,
    "risk_score"
] += 2

customer_data.loc[
    (
        (customer_data["login_count"] > 3)
        &
        (customer_data["login_count"] <= 6)
    ),
    "risk_score"
] += 1

customer_data.loc[
    customer_data["session_minutes"] < 30,
    "risk_score"
] += 2

customer_data.loc[
    (
        (customer_data["session_minutes"] >= 30)
        &
        (customer_data["session_minutes"] < 60)
    ),
    "risk_score"
] += 1

customer_data.loc[
    customer_data["total_tickets"] >= 4,
    "risk_score"
] += 2

customer_data.loc[
    (
        (customer_data["total_tickets"] >= 2)
        &
        (customer_data["total_tickets"] < 4)
    ),
    "risk_score"
] += 1

customer_data.loc[
    customer_data["avg_satisfaction"] <= 2,
    "risk_score"
] += 2

customer_data.loc[
    (
        (customer_data["avg_satisfaction"] > 2)
        &
        (customer_data["avg_satisfaction"] <= 3)
    ),
    "risk_score"
] += 1

customer_data.loc[
    customer_data["auto_renew"] == "No",
    "risk_score"
] += 2


# ============================================================
# 28. RISK CATEGORY
# ============================================================

customer_data["risk_category"] = np.select(

    [
        customer_data["risk_score"] >= 7,
        customer_data["risk_score"] >= 4
    ],

    [
        "High Risk",
        "Medium Risk"
    ],

    default="Low Risk"
)


print("\n========== RISK CATEGORIES ==========")

print(
    customer_data["risk_category"]
    .value_counts()
)


# ============================================================
# 29. HIGH-RISK ACTIVE CUSTOMERS
# ============================================================

high_risk = customer_data[
    (
        customer_data["subscription_status"]
        == "Active"
    )
    &
    (
        customer_data["risk_category"]
        == "High Risk"
    )
].sort_values(
    "monthly_revenue",
    ascending=False
)

print(
    "\n========== HIGH RISK ACTIVE CUSTOMERS =========="
)

print(
    high_risk[
        [
            "customer_id",
            "plan_name",
            "monthly_revenue",
            "risk_score",
            "risk_category"
        ]
    ].head(20)
)


# ============================================================
# 30. REVENUE AT RISK BY PLAN
# ============================================================

revenue_risk = (
    customer_data[
        customer_data["subscription_status"]
        == "Churned"
    ]
    .groupby("plan_name")
    .agg(
        churned_customers=("customer_id", "count"),
        revenue_at_risk=("monthly_revenue", "sum")
    )
    .sort_values(
        "revenue_at_risk",
        ascending=False
    )
)

print(
    "\n========== REVENUE AT RISK =========="
)

print(
    revenue_risk.round(2)
)


# ============================================================
# 31. MONTHLY SIGNUP TREND
# ============================================================

signup_trend = (
    customers
    .assign(
        signup_month=customers["signup_date"]
        .dt.to_period("M")
    )
    .groupby("signup_month")
    .size()
)


# ============================================================
# 32. MONTHLY CHURN TREND
# ============================================================

churn_trend = (
    subscriptions[
        subscriptions["subscription_status"]
        == "Churned"
    ]
    .assign(
        churn_month=subscriptions["end_date"]
        .dt.to_period("M")
    )
    .groupby("churn_month")
    .size()
)


# ============================================================
# 33. VISUALIZATION 1 - CHURN RATE BY PLAN
# ============================================================

plt.figure(figsize=(10, 6))

plan_churn["churn_rate"].sort_values().plot(
    kind="barh"
)

plt.title("Churn Rate by Plan")
plt.xlabel("Churn Rate (%)")
plt.ylabel("Plan")

plt.tight_layout()
plt.show()


# ============================================================
# 34. VISUALIZATION 2 - MONTHLY VS ANNUAL CHURN
# ============================================================

plt.figure(figsize=(8, 5))

plan_type_churn["churn_rate"].plot(
    kind="bar"
)

plt.title("Churn Rate: Monthly vs Annual")
plt.xlabel("Plan Type")
plt.ylabel("Churn Rate (%)")
plt.xticks(rotation=0)

plt.tight_layout()
plt.show()


# ============================================================
# 35. VISUALIZATION 3 - CHURN BY ACQUISITION CHANNEL
# ============================================================

plt.figure(figsize=(10, 6))

channel_churn["churn_rate"].sort_values().plot(
    kind="barh"
)

plt.title("Churn Rate by Acquisition Channel")
plt.xlabel("Churn Rate (%)")
plt.ylabel("Acquisition Channel")

plt.tight_layout()
plt.show()


# ============================================================
# 36. VISUALIZATION 4 - USAGE VS CHURN
# ============================================================

usage_by_churn[
    [
        "avg_logins",
        "avg_session_minutes",
        "avg_feature_usage"
    ]
].plot(
    kind="bar",
    figsize=(10, 6)
)

plt.title("Customer Usage by Churn Status")
plt.xlabel("Subscription Status")
plt.ylabel("Average Value")
plt.xticks(rotation=0)

plt.tight_layout()
plt.show()


# ============================================================
# 37. VISUALIZATION 5 - SUPPORT VS CHURN
# ============================================================

support_by_churn[
    [
        "avg_tickets",
        "avg_high_priority_tickets"
    ]
].plot(
    kind="bar",
    figsize=(9, 6)
)

plt.title("Support Activity by Churn Status")
plt.xlabel("Subscription Status")
plt.ylabel("Average")
plt.xticks(rotation=0)

plt.tight_layout()
plt.show()


# ============================================================
# 38. VISUALIZATION 6 - REVENUE AT RISK
# ============================================================

plt.figure(figsize=(10, 6))

revenue_risk["revenue_at_risk"].sort_values().plot(
    kind="barh"
)

plt.title("Monthly Revenue at Risk by Plan")
plt.xlabel("Revenue at Risk")
plt.ylabel("Plan")

plt.tight_layout()
plt.show()


# ============================================================
# 39. VISUALIZATION 7 - CUSTOMER SEGMENTS
# ============================================================

customer_data[
    "customer_segment"
].value_counts().plot(
    kind="bar",
    figsize=(11, 6)
)

plt.title("Customer Segmentation")
plt.xlabel("Customer Segment")
plt.ylabel("Number of Customers")
plt.xticks(rotation=30, ha="right")

plt.tight_layout()
plt.show()


# ============================================================
# 40. VISUALIZATION 8 - RISK DISTRIBUTION
# ============================================================

customer_data[
    "risk_category"
].value_counts().plot(
    kind="bar",
    figsize=(8, 5)
)

plt.title("Customer Churn Risk Distribution")
plt.xlabel("Risk Category")
plt.ylabel("Customers")
plt.xticks(rotation=0)

plt.tight_layout()
plt.show()


# ============================================================
# 41. VISUALIZATION 9 - AGE GROUP CHURN
# ============================================================

age_churn["churn_rate"].plot(
    kind="bar",
    figsize=(9, 6)
)

plt.title("Churn Rate by Age Group")
plt.xlabel("Age Group")
plt.ylabel("Churn Rate (%)")
plt.xticks(rotation=0)

plt.tight_layout()
plt.show()


# ============================================================
# 42. VISUALIZATION 10 - SIGNUP TREND
# ============================================================

plt.figure(figsize=(12, 6))

signup_trend.plot(
    kind="line",
    marker="o"
)

plt.title("Customer Signup Trend")
plt.xlabel("Month")
plt.ylabel("New Customers")

plt.tight_layout()
plt.show()


# ============================================================
# 43. FINAL BUSINESS INSIGHTS
# ============================================================

highest_churn_plan = (
    plan_churn["churn_rate"]
    .idxmax()
)

highest_churn_channel = (
    channel_churn["churn_rate"]
    .idxmax()
)

highest_revenue_risk_plan = (
    revenue_risk["revenue_at_risk"]
    .idxmax()
)

print("\n")
print("=" * 60)
print("FINAL BUSINESS INSIGHTS")
print("=" * 60)

print(
    "\n1. Overall churn rate:",
    round(churn_rate, 2),
    "%"
)

print(
    "\n2. Plan with highest churn rate:",
    highest_churn_plan,
    "-",
    round(
        plan_churn.loc[
            highest_churn_plan,
            "churn_rate"
        ],
        2
    ),
    "%"
)

print(
    "\n3. Acquisition channel with highest churn:",
    highest_churn_channel,
    "-",
    round(
        channel_churn.loc[
            highest_churn_channel,
            "churn_rate"
        ],
        2
    ),
    "%"
)

print(
    "\n4. Monthly revenue currently at risk:",
    round(revenue_at_risk, 2)
)

print(
    "\n5. Plan contributing the most revenue at risk:",
    highest_revenue_risk_plan
)

print(
    "\n6. High-risk active customers:",
    len(high_risk)
)

print(
    "\n7. Low-engagement customers:",
    len(low_engagement)
)

print(
    "\n8. Highest-risk customers should be prioritized",
    "for retention campaigns."
)

print(
    "\n9. Usage, support activity, auto-renewal and",
    "plan type can be investigated as potential churn drivers."
)

print(
    "\n10. Revenue-at-risk analysis helps prioritize",
    "high-value customers instead of treating all churn equally."
)


# ============================================================
# 44. EXPORT FINAL CUSTOMER 360 DATASET
# ============================================================

customer_data.to_csv(
    "../data/customer_360_analysis.csv",
    index=False
)

print(
    "\nCustomer 360 dataset exported successfully."
)

print("\n========== ANALYSIS COMPLETE ==========")
