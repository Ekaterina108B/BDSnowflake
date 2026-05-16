-- Снежинка
DROP TABLE IF EXISTS dim_breed;
DROP TABLE IF EXISTS dim_pet_type;
DROP TABLE IF EXISTS dim_product_category;
DROP TABLE IF EXISTS dim_product_color;
DROP TABLE IF EXISTS dim_product_size;
DROP TABLE IF EXISTS dim_product_brand;
DROP TABLE IF EXISTS dim_product_material;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_seller;
DROP TABLE IF EXISTS dim_store_location;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_supplier_location;
DROP TABLE IF EXISTS dim_supplier_contact;
DROP TABLE IF EXISTS dim_supplier;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS fact_sales;

-- Sub-dimensions (нормализованные справочники)
CREATE TABLE dim_breed (
	id 	SERIAL PRIMARY KEY,
	name	VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_pet_type (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE dim_product_category (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_color (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dim_product_size (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE dim_product_brand (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_material (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(100) NOT NULL UNIQUE
);


-- Dimensions (измерения)
CREATE TABLE dim_customer (
	id 		SERIAL PRIMARY KEY,
	first_name 	VARCHAR(100) NOT NULL,
	last_name 	VARCHAR(100) NOT NULL,
	age 		INTEGER CHECK(age >= 0 AND age < 150),
	email 		VARCHAR(200) NOT NULL UNIQUE,
	country 	VARCHAR(100) NOT NULL,
	postal_code 	VARCHAR(50),
	pet_name 	VARCHAR(100) NOT NULL,
	pet_type_id 	INTEGER REFERENCES dim_pet_type(id) ON DELETE CASCADE,
	pet_breed_id 	INTEGER REFERENCES dim_breed(id) ON DELETE CASCADE
);

CREATE TABLE dim_seller (
	id 		SERIAL PRIMARY KEY,
	first_name 	VARCHAR(100) NOT NULL,
	last_name 	VARCHAR(100) NOT NULL,
	email 		VARCHAR(200) NOT NULL UNIQUE,
	country 	VARCHAR(100) NOT NULL,
	postal_code 	VARCHAR(50)
);

CREATE TABLE dim_store_location (
	id 	SERIAL PRIMARY KEY,
	country VARCHAR(100) NOT NULL,
	state 	VARCHAR(100),
	city 	VARCHAR(100) NOT NULL,
	address VARCHAR(100) NOT NULL
);

CREATE TABLE dim_store (
	id 		SERIAL PRIMARY KEY,
	name 		VARCHAR(200) NOT NULL,
	phone 		VARCHAR(50) NOT NULL UNIQUE,
	email 		VARCHAR(200) NOT NULL UNIQUE,
	location_id 	INTEGER REFERENCES dim_store_location(id) ON DELETE SET NULL
);

CREATE TABLE dim_supplier_location (
	id 	SERIAL PRIMARY KEY,
	country VARCHAR(100) NOT NULL,
	city 	VARCHAR(100) NOT NULL,
	address VARCHAR(100) NOT NULL
);

CREATE TABLE dim_supplier_contact (
	id 	SERIAL PRIMARY KEY,
	name 	VARCHAR(100) NOT NULL,
	email 	VARCHAR(200) NOT NULL UNIQUE,
	phone 	VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dim_supplier (
	id 		SERIAL PRIMARY KEY,
	name 		VARCHAR(200) NOT NULL UNIQUE,
	contact_id 	INTEGER REFERENCES dim_supplier_contact(id) ON DELETE SET NULL,
	location_id 	INTEGER REFERENCES dim_supplier_location(id) ON DELETE SET NULL
);

CREATE TABLE dim_product (
	id 		SERIAL PRIMARY KEY,
	name 		VARCHAR(100) NOT NULL,
	category_id 	INTEGER REFERENCES dim_product_category(id) ON DELETE SET NULL,
	prices 		DECIMAL(10,2) CHECK (prices >= 0),
	quantity 	INTEGER CHECK (quantity >= 0),
	weight 		DECIMAL(10,2) CHECK (weight > 0),
	color_id 	INTEGER REFERENCES dim_product_color(id) ON DELETE SET NULL,
	size_id 	INTEGER REFERENCES dim_product_size(id) ON DELETE SET NULL,
	brand_id 	INTEGER REFERENCES dim_product_brand(id) ON DELETE SET NULL,
	material_id 	INTEGER REFERENCES dim_product_material(id) ON DELETE SET NULL,
	description 	TEXT,
	rating 		DECIMAL(10,2) CHECK (rating >= 0),
	reviews 	INTEGER CHECK (reviews >= 0),
	release_date 	DATE NOT NULL,
	expiry_date 	DATE NOT NULL,
	supplier_id 	INTEGER REFERENCES dim_supplier(id) ON DELETE SET NULL
);

-- Fact table (таблица фактов)
CREATE TABLE fact_sales (
	id SERIAL PRIMARY KEY,
	customer_id INTEGER REFERENCES dim_customer(id) ON DELETE CASCADE,
	seller_id INTEGER REFERENCES dim_seller(id) ON DELETE CASCADE,
	product_id INTEGER REFERENCES dim_product(id) ON DELETE CASCADE,
	store_id INTEGER REFERENCES dim_store(id) ON DELETE CASCADE,
	quantity INTEGER CHECK (quantity >= 0),
	total_price DECIMAL(10,2) CHECK (total_price >= 0),
	sale_date DATE NOT NULL
);
