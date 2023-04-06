/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
**Query #1**

    SELECT s.customer_id, SUM(price) AS total_sales
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.menu AS m
       ON s.product_id = m.product_id
    GROUP BY customer_id
    order by total_sales desc;

| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

---

-- 2. How many days has each customer visited the restaurant?
**Query #2**

    SELECT customer_id, COUNT(DISTINCT(order_date)) AS visit_count
    FROM dannys_diner.sales
    GROUP BY customer_id
    order by visit_count desc;

| customer_id | visit_count |
| ----------- | ----------- |
| B           | 6           |
| A           | 4           |
| C           | 2           |

---



-- 3. What was the first item from the menu purchased by each customer?
**Query #3**

    WITH ordered_sales_cte AS
    (
       SELECT customer_id, order_date, product_name,
          DENSE_RANK() OVER(PARTITION BY s.customer_id
          ORDER BY s.order_date) AS rank
       FROM dannys_diner.sales AS s
       JOIN dannys_diner.menu AS m
          ON s.product_id = m.product_id
    )
    
    SELECT customer_id, product_name
    FROM ordered_sales_cte
    WHERE rank = 1
    GROUP BY customer_id, product_name;

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

---



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
**Query #4**

    SELECT  (COUNT(s.product_id)) AS most_purchased, product_name
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.menu AS m
       ON s.product_id = m.product_id
    GROUP BY s.product_id, product_name
    ORDER BY most_purchased DESC
    limit 1;

| most_purchased | product_name |
| -------------- | ------------ |
| 8              | ramen        |

---


-- 5. Which item was the most popular for each customer?
**Query #5**

    WITH fav_item_cte AS
    (
       SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS order_count,
          DENSE_RANK() OVER(PARTITION BY s.customer_id
          ORDER BY COUNT(s.customer_id) DESC) AS rank
       FROM dannys_diner.menu AS m
       JOIN dannys_diner.sales AS s
          ON m.product_id = s.product_id
       GROUP BY s.customer_id, m.product_name
    )
    
    SELECT customer_id, product_name, order_count
    FROM fav_item_cte 
    WHERE rank = 1;

| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | ramen        | 2           |
| B           | curry        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

---


-- 6. Which item was purchased first by the customer after they became a member?
**Query #6**

    WITH member_sales_cte AS 
    (
       SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
          DENSE_RANK() OVER(PARTITION BY s.customer_id
          ORDER BY s.order_date) AS rank
       FROM dannys_diner.sales AS s
       JOIN dannys_diner.members AS m
          ON s.customer_id = m.customer_id
       WHERE s.order_date >= m.join_date
    )
    
    SELECT s.customer_id, s.order_date, m2.product_name 
    FROM member_sales_cte AS s
    JOIN dannys_diner.menu AS m2
       ON s.product_id = m2.product_id
    WHERE rank = 1;

| customer_id | order_date               | product_name |
| ----------- | ------------------------ | ------------ |
| B           | 2021-01-11T00:00:00.000Z | sushi        |
| A           | 2021-01-07T00:00:00.000Z | curry        |

---


-- 7. Which item was purchased just before the customer became a member?
**Query #7**

    WITH prior_member_purchased_cte AS 
    (
       SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
             DENSE_RANK() OVER(PARTITION BY s.customer_id
             ORDER BY s.order_date DESC) AS rank
       FROM dannys_diner.sales AS s
       JOIN dannys_diner.members AS m
          ON s.customer_id = m.customer_id
       WHERE s.order_date < m.join_date
    )
    
    SELECT s.customer_id, s.order_date, m2.product_name 
    FROM prior_member_purchased_cte AS s
    JOIN dannys_diner.menu AS m2
       ON s.product_id = m2.product_id
    WHERE rank = 1;

| customer_id | order_date               | product_name |
| ----------- | ------------------------ | ------------ |
| B           | 2021-01-04T00:00:00.000Z | sushi        |
| A           | 2021-01-01T00:00:00.000Z | sushi        |
| A           | 2021-01-01T00:00:00.000Z | curry        |

---



-- 8. What is the total items and amount spent for each member before they became a member?
**Query #8**

    SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_menu_item, 
       SUM(mm.price) AS total_sales
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.members AS m
       ON s.customer_id = m.customer_id
    JOIN dannys_diner.menu AS mm
       ON s.product_id = mm.product_id
    WHERE s.order_date < m.join_date
    GROUP BY s.customer_id;

| customer_id | unique_menu_item | total_sales |
| ----------- | ---------------- | ----------- |
| A           | 2                | 25          |
| B           | 2                | 40          |

---


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
**Query #9**

 WITH price_points AS
(
   SELECT *, 
      CASE
         WHEN product_id = 1 THEN price * 20
         ELSE price * 10
      END AS points
   FROM dannys_diner.menu
)

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points_cte AS p
JOIN dannys_diner.sales AS s
   ON p.product_id = s.product_id
GROUP BY s.customer_id

| customer_id | points |
| ----------- | ------ |
| B           | 940    |
| A           | 860    |
| C           | 360    |

---





-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 
 **Query #10**
 WITH dates_cte AS 
(
   SELECT *, 
      DATEADD(DAY, 6, join_date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM dannys_diner.members AS m
)

SELECT d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price,
   SUM(CASE
      WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
      WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
      ELSE 10 * m.price
      END) AS points
FROM dates_cte AS d
JOIN dannys_diner.sales AS s
   ON d.customer_id = s.customer_id
JOIN dannys_diner.menu AS m
   ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price


/* --------------------
  Bonus Questions
   --------------------*/
   

    SELECT s.customer_id, s.order_date, m.product_name, m.price,
       CASE
          WHEN mm.join_date > s.order_date THEN 'N'
          WHEN mm.join_date <= s.order_date THEN 'Y'
          ELSE 'N'
          END AS member
    FROM dannys_diner.sales AS s
    LEFT JOIN dannys_diner.menu AS m
       ON s.product_id = m.product_id
    LEFT JOIN dannys_diner.members AS mm
       ON s.customer_id = mm.customer_id;

| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |

---
   
 **Query #2**

    WITH summary_cte AS 
    (
       SELECT s.customer_id, s.order_date, m.product_name, m.price,
          CASE
          WHEN mm.join_date > s.order_date THEN 'N'
          WHEN mm.join_date <= s.order_date THEN 'Y'
          ELSE 'N' END AS member
       FROM dannys_diner.sales AS s
       LEFT JOIN dannys_diner.menu AS m
          ON s.product_id = m.product_id
       LEFT JOIN dannys_diner.members AS mm
          ON s.customer_id = mm.customer_id
    )
    
    SELECT *, CASE
       WHEN member = 'N' then NULL
       ELSE
          RANK () OVER(PARTITION BY customer_id, member
          ORDER BY order_date) END AS ranking
    FROM summary_cte;

| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |         |

---  
   
   
   
   
   
   
   
   
   