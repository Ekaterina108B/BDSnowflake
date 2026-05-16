CREATE OR REPLACE PROCEDURE process_csv_file(file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	EXECUTE format('COPY raw_data FROM %L DELIMITER '','' CSV HEADER;', file_path);
	
	-- Sub-dimensions (нормализованные справочники)
	INSERT INTO dim_breed (name)
	SELECT DISTINCT customer_pet_breed
	FROM raw_data
	WHERE customer_pet_breed IS NOT NULL AND customer_pet_breed <> ''
	ORDER BY customer_pet_breed
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_pet_type (name)
	SELECT DISTINCT customer_pet_type
	FROM raw_data
	WHERE customer_pet_type IS NOT NULL AND customer_pet_type <> ''
	ORDER BY customer_pet_type
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_product_category (name)
	SELECT DISTINCT product_category
	FROM raw_data
	WHERE product_category IS NOT NULL AND product_category <> ''
	ORDER BY product_category
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_product_color (name)
	SELECT DISTINCT product_color
	FROM raw_data
	WHERE product_color IS NOT NULL AND product_color <> ''
	ORDER BY product_color
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_product_size (name)
	SELECT DISTINCT product_size
	FROM raw_data
	WHERE product_size IS NOT NULL AND product_size <> ''
	ORDER BY product_size
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_product_brand (name)
	SELECT DISTINCT product_brand
	FROM raw_data
	WHERE product_brand IS NOT NULL AND product_brand <> ''
	ORDER BY product_brand
	ON CONFLICT (name) DO NOTHING;

	INSERT INTO dim_product_material (name)
	SELECT DISTINCT product_material
	FROM raw_data
	WHERE product_material IS NOT NULL AND product_material <> ''
	ORDER BY product_material
	ON CONFLICT (name) DO NOTHING;


	-- Dimensions (измерения)
	INSERT INTO dim_customer (first_name, last_name, age, email, country, postal_code, pet_name, pet_type_id, pet_breed_id)
	SELECT DISTINCT
		r.customer_first_name,
		r.customer_last_name,
		r.customer_age,
		r.customer_email,
		r.customer_country,
		r.customer_postal_code,
		r.customer_pet_name,
		dt.id,
		db.id
	FROM raw_data r
	LEFT JOIN dim_pet_type dt ON dt.name = r.customer_pet_type
	LEFT JOIN dim_breed db ON db.name = r.customer_pet_breed
	WHERE r.customer_first_name IS NOT NULL
		AND r.customer_last_name IS NOT NULL
		AND r.customer_age >= 0
		AND r.customer_age < 150
		AND r.customer_email IS NOT NULL
		AND r.customer_country IS NOT NULL
		AND r.customer_pet_name IS NOT NULL
	ON CONFLICT (email) DO NOTHING;


	INSERT INTO dim_seller (first_name, last_name, email, country, postal_code)
	SELECT DISTINCT
		seller_first_name,
		seller_last_name,
		seller_email,
		seller_country,
		seller_postal_code
	FROM raw_data
	WHERE seller_first_name IS NOT NULL
		AND seller_last_name IS NOT NULL
		AND seller_email IS NOT NULL
		AND seller_country IS NOT NULL
	ON CONFLICT (email) DO NOTHING;


	INSERT INTO dim_store_location (country, state, city, address)
	SELECT DISTINCT
		store_country,
		store_state,
		store_city,
		store_location
	FROM raw_data
	WHERE store_country IS NOT NULL
		AND store_city IS NOT NULL
		AND store_location IS NOT NULL;


	INSERT INTO dim_store (name, phone, email, location_id)
	SELECT DISTINCT
		r.store_name,
		r.store_phone,
		r.store_email,
		d.id
	FROM raw_data r
	LEFT JOIN dim_store_location d
		ON d.country = r.store_country
		AND (d.state = r.store_state OR (d.state IS NULL AND r.store_state IS NULL))
		AND d.city = r.store_city
		AND d.address = r.store_location
	WHERE r.store_name IS NOT NULL
		AND r.store_phone IS NOT NULL
		AND r.store_email IS NOT NULL
	ON CONFLICT (email) DO NOTHING;


	INSERT INTO dim_supplier_location (country, city, address)
	SELECT DISTINCT
		supplier_country,
		supplier_city,
		supplier_address
	FROM raw_data
	WHERE supplier_country IS NOT NULL
		AND supplier_city IS NOT NULL
		AND supplier_address IS NOT NULL;


	INSERT INTO dim_supplier_contact (name, email, phone)
	SELECT DISTINCT
		supplier_contact,
		supplier_email,
		supplier_phone
	FROM raw_data
	WHERE supplier_name IS NOT NULL
		AND supplier_email IS NOT NULL
		AND supplier_phone IS NOT NULL
	ON CONFLICT (email) DO NOTHING;


	INSERT INTO dim_supplier (name, contact_id, location_id)
	SELECT DISTINCT
		r.supplier_name,
		dc.id,
		dl.id
	FROM raw_data r
	LEFT JOIN dim_supplier_contact dc
		ON dc.name = r.supplier_contact
		AND dc.email = r.supplier_email
		AND dc.phone = r.supplier_phone
	LEFT JOIN dim_supplier_location dl
		ON dl.country = r.supplier_country
		AND dl.city = r.supplier_city
		AND dl.address = r.supplier_address
	WHERE r.supplier_name IS NOT NULL
	ON CONFLICT (name) DO NOTHING;


	INSERT INTO dim_product (name, category_id, prices, quantity, weight, color_id, size_id, brand_id, material_id, description, rating, reviews, release_date, expiry_date, supplier_id)
	SELECT DISTINCT
		r.product_name,
		dcat.id,
		r.product_price,
		r.product_quantity,
		r.product_weight,
		dcolor.id,
		dsize.id,
		db.id,
		dm.id,
		r.product_description,
		r.product_rating,
		r.product_reviews,
		r.product_release_date,
		r.product_expiry_date,
		dsup.id
	FROM raw_data r
	LEFT JOIN dim_product_category dcat ON dcat.name = r.product_category
	LEFT JOIN dim_product_color dcolor ON dcolor.name = r.product_color
	LEFT JOIN dim_product_size dsize ON dsize.name = r.product_size
	LEFT JOIN dim_product_brand db ON db.name = r.product_brand
	LEFT JOIN dim_product_material dm ON dm.name = r.product_material
	LEFT JOIN dim_supplier dsup ON dsup.name = r.supplier_name
	WHERE r.product_name IS NOT NULL
		AND r.product_price >= 0
		AND r.product_quantity >= 0
		AND r.product_weight > 0
		AND r.product_rating >= 0
		AND r.product_reviews >= 0
		AND r.product_release_date IS NOT NULL
		AND r.product_expiry_date IS NOT NULL;


	-- Fact table (таблица фактов)
	WITH temp_customers AS (
	SELECT DISTINCT r.id AS raw_id, dc.id AS cust_id
	FROM raw_data r
	LEFT JOIN dim_customer dc ON dc.email = r.customer_email
	),
	temp_sellers AS (
	SELECT DISTINCT r.id AS raw_id, ds.id AS sel_id
	FROM raw_data r
	LEFT JOIN dim_seller ds ON ds.email = r.seller_email
	),
	temp_products AS (
	SELECT DISTINCT r.id AS raw_id, dp.id AS prod_id
	FROM raw_data r
	LEFT JOIN dim_product_category dcat  ON dcat.name  = r.product_category
	LEFT JOIN dim_product_color    dcolor ON dcolor.name = r.product_color
	LEFT JOIN dim_product_size     dsize  ON dsize.name  = r.product_size
	LEFT JOIN dim_product_brand    dbrand ON dbrand.name = r.product_brand
	LEFT JOIN dim_product_material dm     ON dm.name     = r.product_material
	LEFT JOIN dim_supplier         dsup   ON dsup.name   = r.supplier_name
	LEFT JOIN dim_product dp
	    ON  dp.name         = r.product_name
	    AND dp.prices       = r.product_price
	    AND dp.quantity     = r.product_quantity
	    AND dp.weight       = r.product_weight
	    AND dp.description  = r.product_description
	    AND dp.rating       = r.product_rating
	    AND dp.reviews      = r.product_reviews
	    AND dp.release_date = r.product_release_date
	    AND dp.expiry_date  = r.product_expiry_date
	    AND (dp.category_id = dcat.id   OR (dp.category_id IS NULL AND dcat.id   IS NULL))
	    AND (dp.color_id    = dcolor.id OR (dp.color_id    IS NULL AND dcolor.id IS NULL))
	    AND (dp.size_id     = dsize.id  OR (dp.size_id     IS NULL AND dsize.id  IS NULL))
	    AND (dp.brand_id    = dbrand.id OR (dp.brand_id    IS NULL AND dbrand.id IS NULL))
	    AND (dp.material_id = dm.id     OR (dp.material_id IS NULL AND dm.id     IS NULL))
	    AND (dp.supplier_id = dsup.id   OR (dp.supplier_id IS NULL AND dsup.id   IS NULL))
	 )
	INSERT INTO fact_sales (customer_id, seller_id, product_id, store_id, quantity, total_price, sale_date)
	SELECT DISTINCT 
		tc.cust_id,
		ts.sel_id,
		tp.prod_id,
		dstore.id,
		r.sale_quantity,
		r.sale_total_price,
		r.sale_date
	FROM raw_data r
	LEFT JOIN temp_customers tc ON tc.raw_id = r.sale_customer_id
	LEFT JOIN temp_sellers ts ON ts.raw_id = r.sale_seller_id
	LEFT JOIN temp_products tp ON tp.raw_id = r.sale_product_id
	LEFT JOIN dim_store dstore ON dstore.email = r.store_email
	WHERE r.sale_quantity >= 0
		AND r.sale_total_price >=0
		AND r.sale_date IS NOT NULL;
	
	RAISE NOTICE 'Файл % обработан', file_path;
	TRUNCATE raw_data;
END;
$$;


DO $$
DECLARE
    files TEXT[] := ARRAY[
        '/csv_data/MOCK_DATA.csv',
        '/csv_data/MOCK_DATA (1).csv',
        '/csv_data/MOCK_DATA (2).csv',
        '/csv_data/MOCK_DATA (3).csv',
        '/csv_data/MOCK_DATA (4).csv',
        '/csv_data/MOCK_DATA (5).csv',
        '/csv_data/MOCK_DATA (6).csv',
        '/csv_data/MOCK_DATA (7).csv',
        '/csv_data/MOCK_DATA (8).csv',
        '/csv_data/MOCK_DATA (9).csv'
    ];
BEGIN
    FOR i IN 1..array_length(files, 1) LOOP
        CALL process_csv_file(files[i]);
    END LOOP;
    RAISE NOTICE 'Готово! В fact_sales: % строк', (SELECT COUNT(*) FROM fact_sales);
END $$;
