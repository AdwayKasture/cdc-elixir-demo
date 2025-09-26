-- Create a table to demonstrate CDC on
CREATE TABLE IF NOT EXISTS public.products_wal (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Create a publication to publish all changes (INSERT, UPDATE, DELETE)
-- from the 'products_wal' table.
CREATE PUBLICATION products_wal_pub FOR TABLE public.products_wal;

-- Create a logical replication slot. The `pgoutput` plugin is a built-in
-- logical decoding output plugin used for streaming changes.
SELECT * FROM pg_create_logical_replication_slot('products_wal_slot', 'pgoutput');

