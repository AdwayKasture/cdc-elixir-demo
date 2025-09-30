-- Create a table to demonstrate CDC on
CREATE TABLE IF NOT EXISTS public.products_wal (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);


