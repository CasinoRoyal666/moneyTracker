CREATE SCHEMA IF NOT EXISTS finance;
SET search_path TO finance;

CREATE DOMAIN money_amount AS NUMERIC(10,2)
    CHECK ( VALUE >= 0 );

CREATE DOMAIN quantity_nat AS NUMERIC(10,3)
    CHECK ( VALUE > 0 );

--CATEGORIES TABLE
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description text
);

-- STORES TABLE
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

-- ITEMS TABLE
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category_id INT NOT NULL REFERENCES  categories(id) ON UPDATE CASCADE
);

CREATE INDEX  idx_items_category ON items(category_id);

-- PURCHASES TABLE
CREATE TABLE purchases (
    id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES items(id) ON UPDATE CASCADE ,
    store_id INT REFERENCES stores(id) ON UPDATE CASCADE ,
    price money_amount NOT NULL,
    quantity quantity_nat NOT NULL DEFAULT 1,
    total_amount money_amount GENERATED ALWAYS AS ( price * quantity ) STORED,
    purchase_date DATE NOT NULL,
    created_ad TIMESTAMP NOT NULL DEFAULT NOW()
);

--BUDGETS TABLE (PERIOD)
CREATE TABLE budgets(
    id SERIAL PRIMARY KEY ,
    name TEXT NOT NULL ,
    amount money_amount NOT NULL ,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_ad TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK ( end_date >= start_date )
);

--TABLE OF PURCHASES RELATED TO THE BUDGET
CREATE TABLE purchases_to_budgets (
    id SERIAL PRIMARY KEY ,
    budget_id INT NOT NULL REFERENCES budgets(id) ON UPDATE CASCADE ON DELETE CASCADE ,
    purchase_id INT NOT NULL REFERENCES purchases(id) ON UPDATE CASCADE ON DELETE CASCADE ,
    UNIQUE (budget_id, purchase_id)
);

CREATE INDEX idx_p2b_budget ON purchases_to_budgets(budget_id);
CREATE INDEX idx_p2p_purchase ON purchases_to_budgets(purchase_id);

--ACCOUNTS TABLE
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY ,
    name TEXT NOT NULL UNIQUE
);

--PURCHASES ARE LINKED TO AN ACCOUNT (future field)
ALTER TABLE purchases
    ADD COLUMN account_id INT REFERENCES accounts(id) ON UPDATE CASCADE;

CREATE INDEX idx_purchases_account ON purchases(account_id);

--INCOMES TABLE
CREATE TABLE incomes (
    id SERIAL PRIMARY KEY ,
    amount money_amount NOT NULL,
    source TEXT,
    received_date DATE NOT NULL,
    account_id INT REFERENCES accounts(id) ON UPDATE CASCADE ,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_incomes_date ON incomes(received_date);

-- RECURRING OPERATIONS TABLE
CREATE TABLE recurring_operations (
    id SERIAL PRIMARY KEY ,
    name TEXT NOT NULL,
    amount money_amount NOT NULL ,
    category_id INT REFERENCES categories(id),
    account_id INT REFERENCES accounts(id),
    cron_pattern TEXT NOT NULL ,
    operation_type TEXT NOT NULL CHECK (operation_type IN ('expense', 'income')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recurring_category ON recurring_operations(category_id);
CREATE INDEX idx_recurring_account ON recurring_operations(account_id);
