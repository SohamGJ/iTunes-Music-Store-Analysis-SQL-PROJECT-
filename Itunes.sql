CREATE DATABASE Itunes;
use itunes;

#----Joining album_utf8 and artist column ------
CREATE TABLE artist_album_info AS
Select a.artist_id ,a.name,al.album_id,al.title 
From album_utf8 al
Left join artist a
on a.artist_id = al.artist_id;

#----Joining playlist,playlist_track, ------
CREATE TABLE playlist_track_ID AS
Select p.playlist_id ,p.name,pt.track_id
From playlist p
Left Join playlist_track pt
on p.playlist_id=pt.playlist_id;

SELECT * FROM itunes.customer;
Select count(*)
FROM customer
WHERE state ="";
# Overall 29 missing values we have in state column
Select *
FROM customer
WHERE fax="";
# Overall 47 missing values we have in fax column
Select *
FROM customer
WHERE company="";
# Overall 49 missing values we have in company column

#Hence we are dropping state,fax,and company column 
ALTER TABLE customer DROP COLUMN state;
ALTER TABLE customer DROP COLUMN fax;
ALTER TABLE customer DROP COLUMN company;

SELECT * FROM itunes.artist_album_info;

#1. Customer Analytics
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which customers have spent the most money on music?
SELECT c.full_name, c.customer_id, 
SUM(i.total) AS total_spent
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent desc;
#--------------------------------------------------------------------------------------------------------------------------#
#●	What is the average customer lifetime value?
SELECT 
    AVG(customer_lifetime_value) AS avg_clv
FROM (
    SELECT 
        c.customer_id,
        SUM(i.total) AS customer_lifetime_value
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
) AS customer_totals;
#--------------------------------------------------------------------------------------------------------------------------#
#●	How many customers have made repeat purchases versus one-time purchases?
SELECT 
  customer_id,
  COUNT(*) AS purchase_count
FROM invoice
GROUP BY customer_id
ORDER BY customer_id DESC;
#all the customer made repeat purchase no one was one time purchaser.
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which country generates the most revenue per customer?
SELECT 
  country,
  SUM(total_spent) / COUNT(DISTINCT customer_id) AS avg_revenue_per_customer
FROM (
    SELECT 
      c.customer_id,
      c.country,
      SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country
) AS customer_totals
GROUP BY country
ORDER BY avg_revenue_per_customer DESC;

#Czech Republic genrates more revenue per customer.
#--------------------------------------------------------------------------------------------------------------------------#
SELECT 
    c.customer_id,
    c.full_name,
    MAX(i.invoice_date) AS last_purchase_date
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.full_name
HAVING MAX(i.invoice_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
   OR MAX(i.invoice_date) IS NULL
order by last_purchase_date;
#--------------------------------------------------------------------------------------------------------------------------#
#2. Sales & Revenue Analysis
#--------------------------------------------------------------------------------------------------------------------------#
#●	What are the monthly revenue trends for the last two years?
SELECT MAX(invoice_date), MIN(invoice_date) FROM invoice;
SELECT 
  DATE_FORMAT(invoice_date, '%Y-%m') AS month,
  SUM(total) AS monthly_revenue
FROM invoice
Where invoice_date>='2018-12-31 00:00:00'
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY month;
#--------------------------------------------------------------------------------------------------------------------------#
#●	What is the average value of an invoice (purchase)?
Select avg(total) as avg_purchase from invoice;
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which payment methods are used most frequently?
#--------------------------------------------------------------------------------------------------------------------------#
#●	How much revenue does each sales representative contribute?
SELECT 
  e.first_name,
  e.last_name,
  SUM(i.total) AS total_revenue
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue DESC;
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which months or quarters have peak music sales
SELECT 
  DATE_FORMAT(i.invoice_date, '%Y-%m') AS month,
  SUM(il.unit_price * il.quantity) AS music_sales
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
GROUP BY DATE_FORMAT(i.invoice_date, '%Y-%m')
ORDER BY music_sales DESC
LIMIT 5;
#--------------------------------------------------------------------------------------------------------------------------#
#3. Product & Content Analysis
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which tracks generated the most revenue?
select track_id,sum(unit_price*quantity) as total_revenue
from invoice_line
group by track_id
order by total_revenue desc;
#--------------------------------------------------------------------------------------------------------------------------#
#Employee & Operational Efficiency
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which employees (support representatives) are managing the highest-spending customers?
SELECT 
    e.employee_id,
    e.first_name  AS support_rep_name,
    SUM(i.total) AS total_customer_spending
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
JOIN 
    employee e ON c.support_rep_id = e.employee_id
GROUP BY 
    e.employee_id, e.first_name, e.last_name
ORDER BY 
    total_customer_spending DESC;
    
#Jane is managing the highest-spending customers
#--------------------------------------------------------------------------------------------------------------------------#
#●	What is the average number of customers per employee?
SELECT 
    AVG(customer_count) AS avg_customers_per_employee
FROM (
    SELECT 
        support_rep_id,
        COUNT(customer_id) AS customer_count
    FROM 
        customer
    GROUP BY 
        support_rep_id
) AS rep_customer_counts;

#--------------------------------------------------------------------------------------------------------------------------#
#●	Which employee regions bring in the most revenue?
SELECT 
    e.country AS employee_region,
    SUM(i.total) AS total_revenue
FROM 
    employee e
JOIN 
    customer c ON e.employee_id = c.support_rep_id
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    e.country
ORDER BY 
    total_revenue DESC;
    
#--------------------------------------------------------------------------------------------------------------------------#
#Geographic Trends
#--------------------------------------------------------------------------------------------------------------------------#
#●	Which countries or cities have the highest number of customers?
SELECT country, count(customer_id) as total_customer
FROM customer
GROUP BY country 
ORDER BY total_customer DESC;
#--------------------------------------------------------------------------------------------------------------------------#
# How does revenue vary by region?
SELECT 
    c.country AS customer_region,
    SUM(i.total) AS total_revenue
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.country
ORDER BY 
    total_revenue DESC;
    
#--------------------------------------------------------------------------------------------------------------------------#
#Are there any underserved regions (high users, low sales)?
SELECT 
    c.country AS region,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(i.total) AS total_revenue,
    ROUND(SUM(i.total) / COUNT(DISTINCT c.customer_id), 2) AS avg_revenue_per_customer
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.country
ORDER BY 
    avg_revenue_per_customer ASC;
    
    #--------------------------------------------------------------------------------------------------------------------------#
    #Customer Retention & Purchase Patterns
    #--------------------------------------------------------------------------------------------------------------------------#
    #What is the distribution of purchase frequency per customer?
    SELECT 
    c.customer_id,
    c.full_name AS customer_name,
    COUNT(i.invoice_id) AS purchase_count
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id, customer_name
ORDER BY 
    purchase_count DESC;
    
#--------------------------------------------------------------------------------------------------------------------------#
