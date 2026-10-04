-- ===================================================================== 
-- RedFlag — Fraud Detection Submission 
-- Student: Gaurav Mahesh Bodhe  |  Batch: DA-DS-1 
-- ===================================================================== 
  
USE redflag; 

-- ===================================================================== 
-- PATTERN 1 · VELOCITY FRAUD 
-- What I'm looking for: Users executing 30+ transactions in a single calendar day.
-- Expected suspects: ~45-55
-- ===================================================================== 
SELECT 
    user_id, 
    DATE(txn_time) AS attack_date, 
    COUNT(*) AS daily_txn_count 
FROM transactions 
GROUP BY user_id, DATE(txn_time) 
HAVING COUNT(*) >= 30 
ORDER BY daily_txn_count DESC; 

-- My findings: 50 suspect user-days flagged. 
-- Top 3 fraudsters by transaction count: user 14569 (60 txns on 2024-04-03), 
-- user 14556 (60 txns on 2024-05-28), and user 14564 (59 txns on 2024-02-15).

-- ===================================================================== 
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING 
-- What I'm looking for: Money launderers executing 15+ transactions with exact round numbers (100, 200, 500, etc.).
-- Expected suspects: Exactly 25
-- ===================================================================== 
SELECT 
    user_id, 
    COUNT(*) AS round_txn_count
FROM transactions
WHERE amount IN (100.00, 200.00, 500.00, 1000.00, 2000.00, 5000.00, 10000.00)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_txn_count DESC;

-- My findings: Caught exactly 25 suspects using round numbers for laundering.
-- Specific examples include: users 14533, 14534, and 14535 topped the list 
-- with 30 round-number transactions each.

-- ===================================================================== 
-- PATTERN 3 · CARD TESTING 
-- What I'm looking for: Dark web card testers performing 30+ micro-transactions (under ₹10) in a single day.
-- Expected suspects: Exactly 20
-- ===================================================================== 
SELECT 
    user_id, 
    DATE(txn_time) AS test_date, 
    COUNT(*) AS micro_txn_count
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY micro_txn_count DESC;

-- My findings: Found exactly 20 card testing suspects.
-- Specific examples include: user 14569 did 60 micro-txns on 2024-04-03 and 
-- user 14556 did 60 micro-txns on 2024-05-28.

-- ===================================================================== 
-- PATTERN 4 · FAILED-THEN-SUCCEEDED 
-- What I'm looking for: Fraudsters rapidly retrying cards, specifically 20+ pairs of FAILED then SUCCESS on the same amount within 2 minutes.
-- Expected suspects: Exactly 25
-- ===================================================================== 
SELECT 
    t1.user_id, 
    COUNT(*) AS retry_pairs
FROM transactions t1
JOIN transactions t2 
    ON t1.user_id = t2.user_id
    AND t1.amount = t2.amount
WHERE t1.status = 'FAILED' 
  AND t2.status = 'SUCCESS'
  AND t2.txn_time > t1.txn_time
  AND TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) <= 2
GROUP BY t1.user_id
HAVING COUNT(*) >= 20
ORDER BY retry_pairs DESC;

-- My findings: Got exactly 25 suspects rapidly retrying failed cards.
-- Specific examples include: user 14595 had the highest with 35 retries, 
-- followed by user 14593 with 34 retries.

-- ===================================================================== 
-- PATTERN 5 · ODD-HOUR CONCENTRATION 
-- What I'm looking for: Bot accounts active between 2 AM and 5 AM IST, with 80%+ of their 30+ total txns in this window.
-- Expected suspects: Exactly 20
-- ===================================================================== 
SELECT 
    user_id,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) AS odd_hour_txns,
    (SUM(CASE WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS odd_hour_pct
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30 AND odd_hour_pct >= 80
ORDER BY odd_hour_pct DESC;

-- My findings: Caught exactly 20 bot accounts operating mainly in odd hours.
-- Specific examples include: user 14606 had 52 total txns and 49 of them 
-- were between 2-5 AM (94.23% concentration).

-- ===================================================================== 
-- PATTERN 6 · MULE ACCOUNTS 
-- What I'm looking for: Money mules receiving a CREDIT and moving >=70% of it out via DEBIT within 30 minutes (5+ times).
-- Expected suspects: Exactly 30
-- ===================================================================== 
SELECT 
    t1.user_id, 
    COUNT(*) AS mule_instances
FROM transactions t1
JOIN transactions t2 
    ON t1.user_id = t2.user_id
WHERE t1.txn_type = 'CREDIT'
  AND t2.txn_type = 'DEBIT'
  AND t2.txn_time > t1.txn_time
  AND TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) <= 30
  AND t2.amount >= (0.7 * t1.amount)
GROUP BY t1.user_id
HAVING COUNT(*) >= 5
ORDER BY mule_instances DESC;

-- My findings: Flagged exactly 30 mules.
-- Specific examples include: users 14637, 14640, 14645, and 14643 all 
-- hit the mule signature 15 times each.

-- ===================================================================== 
-- PATTERN 7 · REFUND ABUSE 
-- What I'm looking for: Users with 20+ transactions and a refund rate greater than 40%.
-- Expected suspects: 24-25
-- ===================================================================== 
SELECT 
    user_id,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) AS refund_count,
    (SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS refund_pct
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20 AND refund_pct > 40
ORDER BY refund_pct DESC;

-- My findings: Found 24 suspects abusing the refund system.
-- Specific examples include: user 14662 had 39 total txns with a 64.10% refund rate 
-- and user 14670 had 50 txns with a 64.00% refund rate.

-- ===================================================================== 
-- PATTERN 8 · MERCHANT COLLUSION 
-- What I'm looking for: Colluding merchants where the top 5 users make up >60% of their total transaction volume.
-- Expected suspects: Exactly 15
-- ===================================================================== 
WITH MerchantUserVolume AS (
    SELECT 
        merchant_id, 
        user_id, 
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY merchant_id, user_id
),
RankedUsers AS (
    SELECT 
        merchant_id, 
        user_id, 
        user_volume,
        ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY user_volume DESC) AS rnk
    FROM MerchantUserVolume
),
Top5Volume AS (
    SELECT 
        merchant_id, 
        SUM(user_volume) AS top_5_volume
    FROM RankedUsers
    WHERE rnk <= 5
    GROUP BY merchant_id
),
TotalMerchantVolume AS (
    SELECT 
        merchant_id, 
        SUM(amount) AS merch_total
    FROM transactions
    GROUP BY merchant_id
)
SELECT 
    t.merchant_id, 
    t.top_5_volume, 
    m.merch_total,
    (t.top_5_volume / m.merch_total) * 100 AS top_5_pct
FROM Top5Volume t
JOIN TotalMerchantVolume m ON t.merchant_id = m.merchant_id
WHERE (t.top_5_volume / m.merch_total) * 100 > 60
ORDER BY top_5_pct DESC;

-- My findings: Caught exactly 15 colluding merchants.
-- Specific examples include: Merchant 12 was the most obvious with 99.91% 
-- of their volume coming from just 5 users, followed by merchant 8 (99.87%).

-- ===================================================================== 
-- PATTERN 9 · JUST-UNDER-THRESHOLD (STRUCTURING) 
-- What I'm looking for: Users transacting exactly at ₹9,999 to evade 10k KYC checks (10+ times).
-- Expected suspects: Exactly 20
-- ===================================================================== 
SELECT 
    user_id, 
    COUNT(*) AS threshold_evasion_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_evasion_count DESC;

-- My findings: Caught exactly 20 users doing KYC structuring.
-- Specific examples include: users 14680 and 14690 with 25 threshold evasion 
-- transactions each.

-- ===================================================================== 
-- PATTERN 10 · DORMANT-THEN-ACTIVE 
-- What I'm looking for: Account takeovers indicated by 90+ days of inactivity followed by a burst of 15+ txns.
-- Expected suspects: 25-27
-- ===================================================================== 
WITH Gaps AS (
    SELECT 
        user_id, 
        txn_time,
        LAG(txn_time) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_txn_time
    FROM transactions
),
DormantUsers AS (
    SELECT 
        user_id, 
        txn_time AS wakeup_time
    FROM Gaps
    WHERE TIMESTAMPDIFF(DAY, prev_txn_time, txn_time) >= 90
)
SELECT 
    d.user_id, 
    COUNT(t.txn_id) AS post_dormancy_txns
FROM DormantUsers d
JOIN transactions t 
    ON d.user_id = t.user_id 
    AND t.txn_time >= d.wakeup_time
GROUP BY d.user_id, d.wakeup_time
HAVING COUNT(t.txn_id) >= 15
ORDER BY post_dormancy_txns DESC;

-- My findings: Flagged 26 hijacked accounts.
-- Specific examples include: user 14526 woke up after a 90+ day gap and 
-- immediately executed 55 transactions.

-- ===================================================================== 
-- PATTERN 11 · VELOCITY SPIKE 
-- What I'm looking for: Users whose peak monthly transaction count is >= 5x their 6-month true average (peak >= 20).
-- Expected suspects: 35-45
-- ===================================================================== 
WITH MonthlyCounts AS (
    SELECT 
        user_id, 
        DATE_FORMAT(txn_time, '%Y-%m') AS txn_month, 
        COUNT(*) AS monthly_txns
    FROM transactions
    GROUP BY user_id, DATE_FORMAT(txn_time, '%Y-%m')
),
UserAggregates AS (
    SELECT 
        user_id,
        (SUM(monthly_txns) / 6.0) AS avg_monthly_txns,
        MAX(monthly_txns) AS peak_monthly_txns
    FROM MonthlyCounts
    GROUP BY user_id
)
SELECT 
    user_id, 
    avg_monthly_txns, 
    peak_monthly_txns,
    (peak_monthly_txns / avg_monthly_txns) AS spike_ratio
FROM UserAggregates
WHERE peak_monthly_txns >= 20
  AND (peak_monthly_txns / avg_monthly_txns) >= 5
ORDER BY spike_ratio DESC;

-- My findings: Caught 42 suspect users with massive velocity spikes over the threshold.
-- Specific examples include: user 14517 spiked to 41 txns (5.12x their average) 
-- and user 14504 spiked to 45 txns (5.09x their average).

-- ===================================================================== 
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY 
-- What I'm looking for: The same user transacting in two different Indian cities within 60 minutes.
-- Expected suspects: Exactly 15
-- ===================================================================== 
WITH LocationTracker AS (
    SELECT 
        user_id, 
        txn_time, 
        city,
        LAG(city) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_city,
        LAG(txn_time) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_txn_time
    FROM transactions
)
SELECT DISTINCT 
    user_id
FROM LocationTracker
WHERE prev_city IS NOT NULL
  AND city != prev_city
  AND TIMESTAMPDIFF(MINUTE, prev_txn_time, txn_time) <= 60;

-- My findings: Flagged exactly 15 accounts transacting from impossible geographic locations.
-- Specific examples include: users 14741, 14742, and 14743 transacting from different cities within 60 minutes.