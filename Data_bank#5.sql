💵 Case Study #4 - Data Bank
🏦 Solution - A. Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?

**Query #1**

    SELECT 
      COUNT(DISTINCT node_id)
    FROM data_bank.customer_nodes;

| count |
| ----- |
| 5     |

---

2. What is the number of nodes per region?
**Query #2**

    SELECT 
      r.region_id, 
      r.region_name, 
      COUNT(*) AS node_count
    FROM data_bank.regions r
    JOIN data_bank.customer_nodes n
      ON r.region_id = n.region_id
    GROUP BY r.region_id, r.region_name
    ORDER BY region_id;

| region_id | region_name | node_count |
| --------- | ----------- | ---------- |
| 1         | Australia   | 770        |
| 2         | America     | 735        |
| 3         | Africa      | 714        |
| 4         | Asia        | 665        |
| 5         | Europe      | 616        |

---


3. How many customers are allocated to each region?
**Query #3**

    SELECT 
      region_id, 
      COUNT(customer_id) AS customer_count
    FROM data_bank.customer_nodes
    GROUP BY region_id
    ORDER BY region_id;

| region_id | customer_count |
| --------- | -------------- |
| 1         | 770            |
| 2         | 735            |
| 3         | 714            |
| 4         | 665            |
| 5         | 616            |

---
4. How many days on average are customers reallocated to a different node?
**Query #4**

    WITH node_diff AS (
      SELECT 
        customer_id, node_id, start_date, end_date,
        end_date - start_date AS diff
      FROM data_bank.customer_nodes
      WHERE end_date != '9999-12-31'
      GROUP BY customer_id, node_id, start_date, end_date
      ORDER BY customer_id, node_id
      ),
    sum_diff_cte AS (
      SELECT 
        customer_id, node_id, SUM(diff) AS sum_diff
      FROM node_diff
      GROUP BY customer_id, node_id)
    
    SELECT 
      ROUND(AVG(sum_diff),2) AS avg_reallocation_days
    FROM sum_diff_cte;

| avg_reallocation_days |
| --------------------- |
| 23.57                 |

---







5. What is the percentage of customers who increase their closing balance by more than 5%?
**Query #5**

    WITH node_diff AS (
      SELECT 
        customer_id, node_id, region_name, start_date, end_date,
        end_date - start_date AS diff
      FROM data_bank.customer_nodes as c
      left join data_bank.regions as r
      on c.region_id = r.region_id
      WHERE end_date != '9999-12-31'
      GROUP BY customer_id, node_id, region_name, start_date, end_date
    ),
    sum_diff_cte AS (
      SELECT 
        customer_id, node_id, region_name, SUM(diff) AS sum_diff
      FROM node_diff
      GROUP BY customer_id, node_id, region_name
    )
    
    SELECT 
      region_name,
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_diff) AS median_reallocation_days,
      PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY sum_diff) AS p80_reallocation_days,
      PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sum_diff) AS p95_reallocation_days
    FROM sum_diff_cte
    GROUP BY region_name;

| region_name | median_reallocation_days | p80_reallocation_days | p95_reallocation_days |
| ----------- | ------------------------ | --------------------- | --------------------- |
| Africa      | 22                       | 35                    | 54                    |
| America     | 22                       | 34                    | 53.69999999999999     |
| Asia        | 22                       | 34.60000000000002     | 52                    |
| Australia   | 21                       | 34                    | 51                    |
| Europe      | 23                       | 34                    | 51.39999999999998     |