-- Firebird 2.5.9, SQL dialect 3. Execute uma unica vez em um banco vazio.
-- Conecte ao banco antes de executar; este script nao cria o arquivo FDB.
CREATE SEQUENCE product_id_seq;
CREATE SEQUENCE customer_id_seq;
CREATE SEQUENCE item_id_seq;

CREATE TABLE products (
    id INTEGER NOT NULL PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    price_cents BIGINT NOT NULL CHECK (price_cents >= 0),
    stock INTEGER DEFAULT 0 NOT NULL CHECK (stock >= 0)
);
CREATE TABLE customers (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    document VARCHAR(32),
    phone VARCHAR(40)
);
CREATE SEQUENCE sale_id_seq;
CREATE TABLE sales (
    id BIGINT NOT NULL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    customer_id INTEGER REFERENCES customers(id),
    total_cents BIGINT NOT NULL CHECK (total_cents >= 0)
);
CREATE TABLE sale_items (
    id BIGINT NOT NULL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES sales(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    name VARCHAR(200) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cents BIGINT NOT NULL CHECK (unit_cents >= 0)
);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_items_sale ON sale_items(sale_id);
CREATE INDEX idx_items_product ON sale_items(product_id);
-- Execute no editor de scripts (ISQL ou Script Executive do IBExpert).
-- SET TERM e uma diretiva do cliente, nao um comando enviado ao servidor.
SET TERM ^ ;
CREATE TRIGGER products_bi FOR products
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = NEXT VALUE FOR product_id_seq;
END^

CREATE TRIGGER customers_bi FOR customers
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = NEXT VALUE FOR customer_id_seq;
END^

CREATE TRIGGER sale_items_bi FOR sale_items
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = NEXT VALUE FOR item_id_seq;
END^
SET TERM ; ^
COMMIT;
