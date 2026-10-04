# RedFlag: Fraud Detection Engine

## Project Description
RedFlag is a robust fraud detection engine built entirely using pure SQL. The project analyzes a dataset of 200,000 transactions over a six-month period from PayFast, a simulated Indian payment aggregator (Razorpay-style)[cite: 23]. The objective was to uncover hidden fraudulent activities without the use of Python, machine learning algorithms, or external APIs[cite: 23]. Instead, this project relies on advanced SQL querying techniques—including Common Table Expressions (CTEs), window functions (`LAG()`, `ROW_NUMBER()`), correlated subqueries, and complex aggregations—to successfully identify 12 distinct, real-world fraud patterns[cite: 23]. 

## Tech Stack
* **Database / Language:** MySQL[cite: 23, 28]

## Fraud Patterns Detected
This engine successfully identifies the following 12 fraud signatures[cite: 23, 28]:
1. **Velocity Fraud:** Automated bot scripts executing 30+ transactions per user per day.
2. **Round-Amount Clustering:** Money laundering networks transacting exclusively in exact round numbers.
3. **Card Testing:** Dark web syndicates performing 30+ micro-transactions (under ₹10) in a single day to validate stolen credit cards.
4. **Failed-Then-Succeeded Pairs:** Fraudsters rapidly retrying failed cards within 2-minute windows.
5. **Odd-Hour Concentration:** Bot accounts executing 80%+ of their transactions between 2 AM and 5 AM IST.
6. **Mule Accounts:** Human ATMs receiving credits and rapidly moving ≥70% of funds out via debits within 30 minutes.
7. **Refund Abuse:** Users exploiting merchant loopholes with refund rates exceeding 40%.
8. **Merchant Collusion:** Laundering rings where the top 5 users account for >60% of a merchant's total volume.
9. **Structuring (KYC Evasion):** Smurfing schemes maintaining transactions at exactly ₹9,999 to evade the ₹10,000 reporting threshold.
10. **Dormant-Then-Active (Account Takeover):** Hijacked accounts suddenly waking up with 15+ transactions after 90+ days of total inactivity.
11. **Velocity Spikes:** Compromised accounts exhibiting a peak transaction rate ≥ 5x their 6-month historical average.
12. **Geographic Impossibility:** Superman fraud where the same account transacts in two different physical cities within 60 minutes.

## Query Results Showcase
*(Note: Below is a sample output of the Merchant Collusion detection query.)*

<img width="422" height="367" alt="Screenshot 2026-10-05 002817" src="https://github.com/user-attachments/assets/49f1f46b-ba09-4647-83bc-14e52d5786e7" />
<img width="378" height="343" alt="Screenshot 2026-10-05 002804" src="https://github.com/user-attachments/assets/cd0806ed-0d37-40e5-9c24-e5062fb03d90" />
<img width="335" height="367" alt="Screenshot 2026-10-05 002751" src="https://github.com/user-attachments/assets/280d227b-22d7-4dec-8d8e-ad2ff15d85d8" />
<img width="362" height="370" alt="Screenshot 2026-10-05 002735" src="https://github.com/user-attachments/assets/3e2046e4-1c05-46ce-889f-661cb68ae0ff" />


## Dataset Note
The raw dataset (`redflag_transactions.sql`) consists of 200,000 rows and is roughly 18 MB in size[cite: 24]. To keep this repository clean, the raw data file has not been pushed to GitHub[cite: 24, 28]. If you are a recruiter or hiring manager who would like to test these queries locally, please reach out and I will gladly provide the dataset file[cite: 24, 28].
