# CDC Elixir Demo: Change Data Capture in PostgreSQL

This repository provides a demo for implementing **Change Data Capture (CDC)** in PostgreSQL using **Elixir**. It showcases two common approaches: **Write-Ahead Log (WAL) streaming** and **database triggers**.

 write up: https://medium.com/@adwaykasture00/the-two-paths-to-cdc-in-postgres-decoding-the-wal-or-pulling-the-trigger-1b5fd3421d52

-----

## 1\. Requirements

To run this demo, you need to have the following installed:

  * **Docker**
  * **Docker Compose** (or Docker Compose V2 included with Docker Desktop)
  * **Elixir** (version 1.18 or compatible)

-----

## 2\. Demos

This project includes two separate, self-contained CDC demos. Follow the instructions for the specific method you want to explore.

### 2.1. 1️⃣ WAL Streaming Demo (Recommended for Production)

This demo uses **PostgreSQL's logical decoding** feature to stream changes from the Write-Ahead Log (WAL) to the Elixir application.

#### **To Run:**

1.  Start the PostgreSQL and application containers for the WAL profile:
    ```bash
    docker compose --profile wal up -d
    ```
2.  Navigate to the Elixir application directory:
    ```bash
    cd cdc_wal
    ```
3.  Install dependencies, compile, and start the application in an interactive shell:
    ```bash
    mix deps.get
    mix compile
    iex -S mix run
    ```
    *(Note: The `-S mix run` will start the application supervisor, which should connect to the database and begin listening for changes.)*

#### **Testing:**

While in the Elixir IEx session, or from another connection to the PostgreSQL container, you can perform database operations.

  * **From IEx:** Call the included functions to manage records.

    ```elixir
    # Create a new product record
    CdcWal.Schema.Product.insert_record()

    # Create and update it
    CdcWal.Schema.Product.update_record()

    # Create and delete it
    CdcWal.Schema.Product.delete_record()
    ```

    The application will print output in the IEx console as it captures the changes.

  * **From an external PostgreSQL client:** Insert, update, or delete records in the `products` table of the running container's database. The changes will be immediately reflected and logged in the Elixir application console.

    ```bash
        docker exec -it wal_postgres_db psql -U postgres -d cdc_db
    ```
    ```sql
        cdc_db=# INSERT INTO products_wal (name, price) VALUES ('Monitor', 350.00);
        cdc_db=# UPDATE products_wal SET name = '4K Monitor' WHERE name = 'Monitor';
        cdc_db=# DELETE FROM products_wal WHERE price < 500.00;
    ```
-----

### 2.2. 2️⃣ Trigger Demo

This demo uses traditional **database triggers** to write change events to a separate "change log" table, which the Elixir application polls or subscribes to.

#### **To Run:**

1.  Start the PostgreSQL and application containers for the trigger profile:
    ```bash
    docker compose --profile trigger up -d
    ```
2.  Navigate to the Elixir application directory:
    ```bash
    cd cdc_trigger
    ```
3.  Install dependencies, compile, and start the application in an interactive shell:
    ```bash
    mix deps.get
    mix compile
    iex -S mix run
    ```

#### **Testing:**

Similar to the WAL demo, you can test by creating, updating, or deleting records.

  * **From IEx:**

    ```elixir
    # Create a new product record
    CdcTrigger.Schema.Product.insert_record()

    # Create and update it
    CdcTrigger.Schema.Product.update_record()

    # Create and delete it
    CdcTrigger.Schema.Product.delete_record()
    ```

    The Elixir application will process the changes from the log table and display output in the IEx console.

  * **From an external PostgreSQL client:** Perform operations on the `products` table. The changes will be captured by the triggers and logged in the Elixir application console.

    ```bash
        docker exec -it trigger_postgres_db psql -U postgres -d cdc_db
    ```
    ```sql
        cdc_db=# INSERT INTO products_wal (name, price) VALUES ('Monitor', 350.00);
        cdc_db=# UPDATE products_wal SET name = '4K Monitor' WHERE name = 'Monitor';
        cdc_db=# DELETE FROM products_wal WHERE price < 500.00;
    ```

