SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'raw_data';

SELECT customer_first_name, customer_last_name, COUNT(customer_pet_type)
FROM raw_data
GROUP BY customer_first_name, customer_last_name
HAVING COUNT(customer_pet_type) > 1;

SELECT * FROM raw_data
WHERE customer_first_name = 'Kippy' AND customer_last_name = 'McCurry';

SELECT product_brand, store_name, supplier_name
FROM raw_data
WHERE store_name = product_brand;

SELECT product_brand, store_name, supplier_name
FROM raw_data
WHERE supplier_name = product_brand;

SELECT product_brand, store_name, supplier_name
FROM raw_data
ORDER BY product_brand;

SELECT customer_pet_type, customer_pet_breed, pet_category ry
FROM raw_data
WHERE NOT(customer_pet_type ILIKE pet_category);

SELECT * FROM raw_data
WHERE supplier_country IS NULL OR supplier_country = '';

SELECT * FROM raw_data
WHERE product_quantity > 10;
