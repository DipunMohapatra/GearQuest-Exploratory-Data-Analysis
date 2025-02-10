# GearQuest Exploratory Data Analysis

## Table of Contents
- [Business Problem](#business-problem)
- [Executive Summary](#executive-summary)
- [Insights Deep-Dive](#insights-deep-dive)
  - [Sales Trends and Growth Rates](#sales-trends-and-growth-rates)
  - [Key Product Performance](#key-product-performance)
  - [Logistics Performance](#logistics-performance)
  - [Sales & Marketing Channel Performance](#sales--marketing-channel-performance)
  - [Refund Trends](#refund-trends)
- [Recommendations](#recommendations)
- [Clarifying Questions, Assumptions, and Caveats](#clarifying-questions-assumptions-and-caveats)
  - [Questions for Stakeholders Prior to Project Advancement](#questions-for-stakeholders-prior-to-project-advancement)
  - [Assumptions and Caveats](#assumptions-and-caveats)

## Business Problem
GearQuest, a global e-commerce company founded in 2018, specialises in selling high-performance gaming PCs, laptops, and peripherals from top brands such as ASUS, Razer, and Logitech. Partnering with the Head of Operations, I aim to extract actionable insights and deliver data-driven recommendations to enhance performance across sales, product development, and marketing teams.

## Executive Summary
An analysis of 1.5 million sales records from 2021 to 2024 reveals that GearQuest generates an average annual revenue of $58 million, with Asia and Europe contributing 60% of total sales. Gaming laptops remain the company’s dominant category, accounting for 49% of revenue, yet also experiencing the highest refund rates, raising concerns about product reliability and customer satisfaction. Order processing takes 3 days, and shipping to delivery averages 9 days, leading to missed SLAs and potential customer churn. A 2.33% YoY increase in refunds, particularly in gaming laptops and peripherals, suggests a need for enhanced quality control and improved return policies. While email marketing remains the top-performing channel, search engine ads underperformed, warranting a review of digital marketing investments.

## Insights Deep-Dive
![Entity Relationship Diagram](https://github.com/DipunMohapatra/GearQuest-Exploratory-Data-Analysis/blob/6d432f2c9770d5bcf2e156d4a164417f0521e55c/Visuals/ERD.png)
###### ERD

### Sales Trends and Growth Rates
- GearQuest generated $587.7 million in sales in 2024, reflecting a 0.19% decline compared to the previous year.
- The company processed 372,473 orders in 2024, with a 0.34% decrease in comparison to the prior year.
- GearQuest shows seasonality, with peak sales in August and October, and lower sales in February and June.
- Asia and Europe contribute 60% of sales.
- Asia remained the top-performing region, contributing $179.18 million in sales, with a 0.42% increase YoY. However, the region also recorded a 10.30% decline in total orders.
- Sales in India, United Kingdom, Canada, USA, and Argentina declined by an average of 1.5% in 2024. Argentina saw the steepest decline, at 3.09%.
- Korea, Denmark, and France have experienced positive sales growth in both 2023 and 2024.

### Key Product Performance
- Gaming laptops dominated sales, accounting for 49% of total revenue ($289 million) with 124,000 orders.
- The top three gaming laptops—MSI Titan GT77, Alienware X17 R2, and Razer Blade 18—collectively generated $84.1 million (14% of total revenue in 2024).
- Custom PCs ranked second in revenue at $257 million, followed by gaming monitors ($29 million) and gaming peripherals ($9 million).
- Despite gaming peripherals having higher order volume (98,000) than gaming monitors (55,000), the latter generated more revenue due to higher price points.

### Logistics Performance
- Average order fulfilment time is 9 days, exceeding the promised SLA by 2 days.
  - 75% of deliveries exceed 7 days, with only 2% meeting the 5–7 day commitment.
- Average order processing time: 3 days; Average transit time: 6 days.
  - 60% of orders take over 2 days to process, and 60% exceed 5 days in transit.
- Japan, Denmark, and France saw increases in late deliveries by 2.19%, 2.05%, and 0.78%, respectively.
- Processing times improved in South America (4.54%), followed by the UK (2.42%), India (1.81%), and Brazil (0.17%).
- Denmark recorded a 4.45% increase in processing delays, signaling a need for urgent improvements.
- Logistics inefficiencies need to be addressed, particularly through better order processing workflows, improved supply chain management, and stronger logistics partnerships.

### Sales & Marketing Channel Performance
- Email marketing led in sales, generating $100.94 million (+0.19% YoY) and recording the highest order volume (63,981 orders, -0.44% YoY).
- Search Engine Ads and Instagram Ads experienced declines in both sales and order volume:
  - Search Engine Ads: -2.70% sales, -2.19% orders
  - Instagram Ads: -1.07% sales, -0.48% orders
- Twitch Ads and Twitter showed fluctuating performance across different years.
- Mobile app sales increased to $294.65 million (+0.17% YoY), maintaining a consistent upward trend.
- Website sales and orders declined, indicating a clear shift in customer preference toward mobile purchases.
- The mobile app remains the strongest digital channel, reinforcing the importance of mobile-first strategies.

### Refund Trends
- 37,295 orders were refunded in 2024 (+2.33% YoY).
- Gaming laptops had the highest refunds (12,508 units, +2.65% YoY).
- Gaming peripherals refunds surged (+2.18%), with notable returns for:
  - Razer Basilisk V3 (7.49%)
  - Logitech G213 Prodigy (10.53%)
  - Corsair Katar Pro XT (6.90%)
- Gaming monitors refunds increased, particularly for:
  - Samsung Odyssey G3 (6.06%)
  - Acer Nitro XV240Y (9.78%)
  - ViewSonic Elite XG270 (5.82%)
- Custom PCs registered high refund rates, with major contributors:
  - Competitive Gaming Build - Ryzen 9, RTX 4080 (12.43%)
  - Entry-Level RTX PC - Ryzen 5, RTX 4060 Ti (10.22%)
  - Hardcore Gamer PC - Intel i7, RTX 4070 (9.12%)
- Refund trends showed no seasonality, but overall returns increased in 2024 compared to 2023, particularly for gaming peripherals.

## Recommendations
- **Improve Logistics Operations:** Addressing order processing and delivery inefficiencies should be a priority, particularly in regions with rising delays such as Denmark and France.
- **Reassess Marketing Spend:** The decline in Search Engine Ads performance suggests a need to optimise digital marketing strategies and explore alternative channels.
- **Product Quality Assurance:** Given the high refund rates for gaming laptops, gaming peripherals, and custom PCs, improved quality control measures and better customer support could reduce returns.
- **Enhance Customer Experience:** Addressing late deliveries and improving order processing times would help retain customers and sustain revenue growth.
- **Investigate Rising Refund Rates:** The increasing refunds for gaming peripherals and monitors suggest potential issues in product durability or misleading marketing claims. Further analysis should be conducted on customer complaints and defect rates.

## Clarifying Questions, Assumptions, and Caveats

### Questions for Stakeholders Prior to Project Advancement
- **Unmatched `customer_id` Records:**
  - Which table should be the primary source for `customer_id` to maintain data consistency across analyses?
- **`marketing_channel` and `account_creation_method` in the Customers Table:**
  - How is this data recorded, and what does it specifically represent?
  - What factors contribute to their deterministic relationship?
  - Does `marketing_channel` capture the initial account creation touchpoint, or does it represent the origin of each individual purchase (which is more relevant for tracking sales)?

### Assumptions and Caveats
- Refunds unexpectedly surged starting **January 2021**, which is an anomaly warranting further investigation.
- Each `marketing_channel` is uniquely linked to one `account_creation_method`, indicating a **one-to-one mapping**. This lack of variation may require attention from the **data engineering team** to confirm intended relationships.
