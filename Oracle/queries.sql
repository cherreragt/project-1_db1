-- #########################################
-- MariaDB
-- Tabla: tipos de proveedor (Gold, Silver, Bronze, etc.)
CREATE TABLE supplier_type (
                               supplier_type_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               code VARCHAR(30) NOT NULL,                -- ej. GOLD, BRONZE
                               name VARCHAR(100) NOT NULL,
                               description TEXT NULL,
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               PRIMARY KEY (supplier_type_id),
                               UNIQUE KEY ux_supplier_type_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: proveedores (catálogo)
CREATE TABLE supplier (
                          supplier_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                          supplier_type_id TINYINT UNSIGNED NULL,
                          code VARCHAR(50) NULL,                    -- código interno proveedor
                          legal_name VARCHAR(200) NOT NULL,
                          trade_name VARCHAR(200) NULL,
                          tax_id VARCHAR(60) NULL,                  -- NIT/CIF/RUC
                          active BOOLEAN NOT NULL DEFAULT TRUE,
                          default_currency CHAR(3) DEFAULT 'GTQ',
                          payment_terms VARCHAR(100) NULL,          -- "30 días", "Contado"
                          notes TEXT NULL,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
                          PRIMARY KEY (supplier_id),
                          UNIQUE KEY ux_supplier_code (code),
                          INDEX idx_supplier_type (supplier_type_id),
                          CONSTRAINT fk_supplier_supplier_type FOREIGN KEY (supplier_type_id) REFERENCES supplier_type(supplier_type_id)
                              ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: contactos del proveedor (teléfono, email, persona)
CREATE TABLE supplier_contact (
                                  contact_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                  supplier_id BIGINT UNSIGNED NOT NULL,
                                  name VARCHAR(150) NULL,
                                  role VARCHAR(100) NULL,
                                  phone VARCHAR(50) NULL,
                                  mobile VARCHAR(50) NULL,
                                  email VARCHAR(150) NULL,
                                  note TEXT NULL,
                                  primary_contact BOOLEAN DEFAULT FALSE,
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  PRIMARY KEY (contact_id),
                                  INDEX idx_sc_supplier (supplier_id),
                                  CONSTRAINT fk_sc_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
                                      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: direcciones del proveedor
CREATE TABLE supplier_address (
                                  address_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                  supplier_id BIGINT UNSIGNED NOT NULL,
                                  address_line VARCHAR(250) NULL,
                                  city VARCHAR(100) NULL,
                                  state VARCHAR(100) NULL,
                                  postal_code VARCHAR(30) NULL,
                                  country VARCHAR(100) DEFAULT 'Guatemala',
                                  address_type ENUM('Fiscal','Despacho','Otro') DEFAULT 'Fiscal',
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  PRIMARY KEY (address_id),
                                  INDEX idx_sa_supplier (supplier_id),
                                  CONSTRAINT fk_sa_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
                                      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: categorías de producto
CREATE TABLE product_category (
                                  category_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                                  parent_id INT UNSIGNED NULL,
                                  code VARCHAR(60) NULL,
                                  name VARCHAR(120) NOT NULL,
                                  description TEXT NULL,
                                  active BOOLEAN DEFAULT TRUE,
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  PRIMARY KEY (category_id),
                                  INDEX idx_pc_parent (parent_id),
                                  CONSTRAINT fk_pc_parent FOREIGN KEY (parent_id) REFERENCES product_category(category_id)
                                      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: productos (catálogo)
CREATE TABLE product (
                         product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                         sku VARCHAR(100) NULL,                    -- código interno/sku
                         name VARCHAR(255) NOT NULL,
                         category_id INT UNSIGNED NULL,
                         description TEXT NULL,
                         unit VARCHAR(30) DEFAULT 'UND',           -- unidad medida
                         purchase_unit VARCHAR(30) DEFAULT 'UND',  -- unidad de compra si difiere
                         cost DECIMAL(18,4) DEFAULT 0.0,           -- costo promedio / último
                         price DECIMAL(18,4) DEFAULT 0.0,          -- precio de venta sugerido
                         active BOOLEAN DEFAULT TRUE,
                         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         PRIMARY KEY (product_id),
                         UNIQUE KEY ux_product_sku (sku),
                         INDEX idx_product_category (category_id),
                         CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES product_category(category_id)
                             ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: relación proveedor-producto (para precios, lead time, código del proveedor)
CREATE TABLE supplier_product (
                                  supplier_product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                  supplier_id BIGINT UNSIGNED NOT NULL,
                                  product_id BIGINT UNSIGNED NOT NULL,
                                  supplier_sku VARCHAR(120) NULL,           -- código del proveedor para ese producto
                                  lead_time_days SMALLINT UNSIGNED NULL,    -- tiempo estimado de entrega
                                  min_order_qty INT UNSIGNED DEFAULT 1,
                                  price DECIMAL(18,4) DEFAULT 0.0,          -- precio de compra acordado
                                  currency CHAR(3) DEFAULT 'GTQ',
                                  active BOOLEAN DEFAULT TRUE,
                                  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                  PRIMARY KEY (supplier_product_id),
                                  UNIQUE KEY ux_supplier_product (supplier_id, product_id),
                                  INDEX idx_sp_supplier (supplier_id),
                                  INDEX idx_sp_product (product_id),
                                  CONSTRAINT fk_sp_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
                                      ON DELETE CASCADE ON UPDATE CASCADE,
                                  CONSTRAINT fk_sp_product FOREIGN KEY (product_id) REFERENCES product(product_id)
                                      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: ubicaciones físicas (almacenes / bodegas)
CREATE TABLE location (
                          location_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                          code VARCHAR(50) NOT NULL,
                          name VARCHAR(150) NOT NULL,
                          address VARCHAR(250) NULL,
                          active BOOLEAN DEFAULT TRUE,
                          PRIMARY KEY (location_id),
                          UNIQUE KEY ux_location_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: inventario por producto y ubicación (stock actual)
CREATE TABLE inventory (
                           inventory_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                           product_id BIGINT UNSIGNED NOT NULL,
                           location_id INT UNSIGNED NOT NULL,
                           lot_number VARCHAR(120) NULL,
                           quantity DECIMAL(18,4) NOT NULL DEFAULT 0.0,
                           reserved DECIMAL(18,4) NOT NULL DEFAULT 0.0, -- reservado por pedidos
                           last_cost DECIMAL(18,4) DEFAULT 0.0,
                           updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                           PRIMARY KEY (inventory_id),
                           UNIQUE KEY ux_inventory_prod_loc_lot (product_id, location_id, lot_number),
                           INDEX idx_inv_product (product_id),
                           INDEX idx_inv_location (location_id),
                           CONSTRAINT fk_inv_product FOREIGN KEY (product_id) REFERENCES product(product_id)
                               ON DELETE CASCADE ON UPDATE CASCADE,
                           CONSTRAINT fk_inv_location FOREIGN KEY (location_id) REFERENCES location(location_id)
                               ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: movimientos de inventario (entradas/salidas/ajustes)
CREATE TABLE inventory_movement (
                                    movement_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                    movement_type ENUM('IN','OUT','ADJUST','TRANSFER_IN','TRANSFER_OUT','RESERVE','UNRESERVE') NOT NULL,
                                    product_id BIGINT UNSIGNED NOT NULL,
                                    location_id INT UNSIGNED NOT NULL,
                                    related_id VARCHAR(100) NULL,             -- ej. orden_compra_id, factura_id, pedido_id
                                    lot_number VARCHAR(120) NULL,
                                    quantity DECIMAL(18,4) NOT NULL,
                                    unit_cost DECIMAL(18,4) DEFAULT 0.0,
                                    remarks TEXT NULL,
                                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                    created_by VARCHAR(100) NULL,
                                    PRIMARY KEY (movement_id),
                                    INDEX idx_mov_product (product_id),
                                    INDEX idx_mov_location (location_id),
                                    CONSTRAINT fk_mov_product FOREIGN KEY (product_id) REFERENCES product(product_id)
                                        ON DELETE CASCADE ON UPDATE CASCADE,
                                    CONSTRAINT fk_mov_location FOREIGN KEY (location_id) REFERENCES location(location_id)
                                        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: órdenes de compra (PO)
CREATE TABLE purchase_order (
                                po_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                po_number VARCHAR(100) NOT NULL,
                                supplier_id BIGINT UNSIGNED NOT NULL,
                                status ENUM('Draft','Open','Received','PartiallyReceived','Closed','Cancelled') DEFAULT 'Draft',
                                order_date DATE DEFAULT NULL,
                                expected_date DATE NULL,
                                currency CHAR(3) DEFAULT 'GTQ',
                                total_amount DECIMAL(18,4) DEFAULT 0.0,
                                notes TEXT NULL,
                                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                PRIMARY KEY (po_id),
                                UNIQUE KEY ux_po_number (po_number),
                                INDEX idx_po_supplier (supplier_id),
                                CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
                                    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla: líneas de orden de compra
CREATE TABLE purchase_order_line (
                                     pol_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                     po_id BIGINT UNSIGNED NOT NULL,
                                     line_no INT UNSIGNED NOT NULL,
                                     product_id BIGINT UNSIGNED NOT NULL,
                                     description VARCHAR(500) NULL,
                                     qty DECIMAL(18,4) NOT NULL,
                                     unit_price DECIMAL(18,4) NOT NULL,
                                     currency CHAR(3) DEFAULT 'GTQ',
                                     received_qty DECIMAL(18,4) DEFAULT 0.0,
                                     PRIMARY KEY (pol_id),
                                     UNIQUE KEY ux_pol_po_line (po_id, line_no),
                                     INDEX idx_pol_po (po_id),
                                     INDEX idx_pol_product (product_id),
                                     CONSTRAINT fk_pol_po FOREIGN KEY (po_id) REFERENCES purchase_order(po_id)
                                         ON DELETE CASCADE ON UPDATE CASCADE,
                                     CONSTRAINT fk_pol_product FOREIGN KEY (product_id) REFERENCES product(product_id)
                                         ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- VISTA: stock actual total por producto (suma de ubicaciones)
CREATE VIEW vw_product_stock AS
SELECT
    p.product_id,
    p.sku,
    p.name,
    COALESCE(SUM(i.quantity) - SUM(i.reserved), 0) AS available_qty,
    COALESCE(SUM(i.quantity), 0) AS total_qty
FROM product p
         LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.sku, p.name;

-- Índices adicionales sugeridos para consultas frecuentes
CREATE INDEX idx_product_name ON product(name);
CREATE INDEX idx_supplier_name ON supplier(legal_name);

-- Ejemplos: datos iniciales
INSERT INTO supplier_type (code, name, description) VALUES
                                                        ('GOLD','Gold','Proveedor preferente con condiciones preferenciales'),
                                                        ('SILVER','Silver','Proveedor con buen desempeño'),
                                                        ('BRONZE','Bronze','Proveedor estándar');

INSERT INTO location (code, name, address) VALUES
                                               ('WH1', 'Bodega Central', 'Km 12 Carretera Principal'),
                                               ('WH2', 'Bodega Secundaria', 'Zona 5');

INSERT INTO product_category (name) VALUES ('Electrónica'), ('Repuestos'), ('Consumibles');

INSERT INTO product (sku, name, category_id, unit, cost, price) VALUES
                                                                    ('SKU-001','Bujía Modelo X', 2, 'UND', 5.25, 9.50),
                                                                    ('SKU-002','Aceite 1L', 3, 'LT', 3.20, 6.00);

INSERT INTO supplier (supplier_type_id, code, legal_name, trade_name, tax_id, default_currency, payment_terms) VALUES
    (1, 'SUP-ACME','ACME S.A.','ACME','12345678-9','GTQ','30 días');

INSERT INTO supplier_contact (supplier_id, name, role, phone, email, primary_contact) VALUES
    (1, 'Juan Pérez', 'Ventas', '+502-5555-1234', 'ventas@acme.com', TRUE);

-- Relación proveedor-producto y precios
INSERT INTO supplier_product (supplier_id, product_id, supplier_sku, lead_time_days, min_order_qty, price, currency) VALUES
                                                                                                                         (1, 1, 'ACME-SKU-100', 7, 10, 4.90, 'GTQ'),
                                                                                                                         (1, 2, 'ACME-SKU-200', 5, 12, 3.00, 'GTQ');

-- Ejemplo: inicializar inventario
INSERT INTO inventory (product_id, location_id, lot_number, quantity, reserved, last_cost) VALUES
                                                                                               (1, 1, 'LOT-0001', 100, 0, 5.00),
                                                                                               (2, 1, 'LOT-0002', 200, 10, 3.10);

-- Ejemplo: crear una orden de compra
INSERT INTO purchase_order (po_number, supplier_id, status, order_date, expected_date, currency, total_amount) VALUES
    ('PO-2025-0001', 1, 'Open', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'GTQ', 490.00);

INSERT INTO purchase_order_line (po_id, line_no, product_id, qty, unit_price) VALUES
    (LAST_INSERT_ID(), 1, 1, 100, 4.90);






-- #########################################
-- DB2
SET SCHEMA db2inst1;


-- Tabla: departamentos
CREATE TABLE department (
                            department_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
                            name VARCHAR(100) NOT NULL,
                            location VARCHAR(100),
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            PRIMARY KEY (department_id)
);

-- Tabla: puestos
CREATE TABLE position (
                          position_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
                          title VARCHAR(100) NOT NULL,
                          level VARCHAR(50),
                          salary DECIMAL(15,2),
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          PRIMARY KEY (position_id)
);

-- Tabla: empleados
CREATE TABLE employee (
                          employee_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
                          first_name VARCHAR(50) NOT NULL,
                          last_name VARCHAR(50) NOT NULL,
                          birth_date DATE,
                          hire_date DATE DEFAULT CURRENT_DATE,
                          email VARCHAR(100),
                          phone VARCHAR(20),
                          department_id INT,
                          position_id INT,
                          active SMALLINT DEFAULT 1,  -- 1=activo, 0=inactivo
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          PRIMARY KEY (employee_id),
                          FOREIGN KEY (department_id) REFERENCES department(department_id)
                              ON DELETE SET NULL
                              ON UPDATE NO ACTION,
                          FOREIGN KEY (position_id) REFERENCES position(position_id)
                              ON DELETE SET NULL
                              ON UPDATE NO ACTION
);

-- Opcional: tabla de historial de salario
CREATE TABLE salary_history (
                                salary_history_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
                                employee_id INT NOT NULL,
                                old_salary DECIMAL(15,2) NOT NULL,
                                new_salary DECIMAL(15,2) NOT NULL,
                                change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                PRIMARY KEY (salary_history_id),
                                FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
                                    ON DELETE CASCADE
                                    ON UPDATE NO ACTION
);

-- Insertar departamentos
INSERT INTO department (name, location) VALUES
                                            ('Recursos Humanos', 'Edificio Central'),
                                            ('Tecnología', 'Edificio Norte'),
                                            ('Ventas', 'Edificio Sur'),
                                            ('Finanzas', 'Edificio Central');

-- Insertar puestos
INSERT INTO position (title, level, salary) VALUES
                                                ('Gerente', 'Senior', 150000.00),
                                                ('Analista', 'Junior', 50000.00),
                                                ('Desarrollador', 'Intermediate', 70000.00),
                                                ('Asistente', 'Junior', 35000.00),
                                                ('Director', 'Executive', 200000.00);

-- Insertar empleados
INSERT INTO employee (first_name, last_name, birth_date, hire_date, email, phone, department_id, position_id, active) VALUES
                                                                                                                          ('Juan', 'Pérez', '1985-03-15', '2010-05-01', 'juan.perez@example.com', '555-1234', 1, 1, 1),
                                                                                                                          ('María', 'Gómez', '1990-07-22', '2015-09-15', 'maria.gomez@example.com', '555-2345', 2, 3, 1),
                                                                                                                          ('Carlos', 'Ramírez', '1988-11-30', '2012-03-20', 'carlos.ramirez@example.com', '555-3456', 2, 3, 1),
                                                                                                                          ('Ana', 'López', '1995-01-10', '2018-07-05', 'ana.lopez@example.com', '555-4567', 3, 2, 1),
                                                                                                                          ('Luis', 'Martínez', '1978-06-18', '2005-02-28', 'luis.martinez@example.com', '555-5678', 4, 5, 1),
                                                                                                                          ('Sofía', 'Fernández', '1992-12-05', '2017-11-11', 'sofia.fernandez@example.com', '555-6789', 1, 4, 1);

-- Insertar historial de salarios
INSERT INTO salary_history (employee_id, old_salary, new_salary) VALUES
                                                                     (1, 140000.00, 150000.00),
                                                                     (2, 65000.00, 70000.00),
                                                                     (3, 65000.00, 70000.00),
                                                                     (4, 48000.00, 50000.00),
                                                                     (5, 190000.00, 200000.00),
                                                                     (6, 33000.00, 35000.00);






-- #########################################
-- SQL






-- #########################################
-- ORACLE

-- Tabla de clientes
CREATE TABLE CLIENTES (
    CLIENTE_ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NOMBRE VARCHAR2(100) NOT NULL,
    APELLIDO VARCHAR2(100) NOT NULL,
    FECHA_NACIMIENTO DATE,
    EMAIL VARCHAR2(100),
    TELEFONO VARCHAR2(20),
    DIRECCION VARCHAR2(200)
);

-- Tabla de estados de clientes
CREATE TABLE ESTADOS_CLIENTE (
    ESTADO_ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    DESCRIPCION VARCHAR2(50) NOT NULL
);

-- Tabla de crédito otorgado a clientes
CREATE TABLE CREDITO_CLIENTE (
    CREDITO_ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CLIENTE_ID NUMBER NOT NULL,
    MONTO NUMBER(12,2) NOT NULL,
    FECHA_OTORGAMIENTO DATE DEFAULT SYSDATE,
    FECHA_VENCIMIENTO DATE,
    CONSTRAINT FK_CREDITO_CLIENTE FOREIGN KEY (CLIENTE_ID)
        REFERENCES CLIENTES(CLIENTE_ID)
);

-- Tabla de tasas aplicadas a clientes
CREATE TABLE TASAS_CLIENTE (
    TASA_ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CLIENTE_ID NUMBER NOT NULL,
    PORCENTAJE NUMBER(5,2) NOT NULL,
    FECHA_APLICACION DATE DEFAULT SYSDATE,
    CONSTRAINT FK_TASA_CLIENTE FOREIGN KEY (CLIENTE_ID)
        REFERENCES CLIENTES(CLIENTE_ID)
);

-- Relación del estado del cliente (histórico o actual)
CREATE TABLE CLIENTE_ESTADO (
    CLIENTE_ID NUMBER NOT NULL,
    ESTADO_ID NUMBER NOT NULL,
    FECHA_ASIGNACION DATE DEFAULT SYSDATE,
    CONSTRAINT PK_CLIENTE_ESTADO PRIMARY KEY (CLIENTE_ID, ESTADO_ID, FECHA_ASIGNACION),
    CONSTRAINT FK_CLIENTE_ESTADO_CLIENTE FOREIGN KEY (CLIENTE_ID)
        REFERENCES CLIENTES(CLIENTE_ID),
    CONSTRAINT FK_CLIENTE_ESTADO_ESTADO FOREIGN KEY (ESTADO_ID)
        REFERENCES ESTADOS_CLIENTE(ESTADO_ID)
);


-- Insertar estados de clientes
INSERT INTO ESTADOS_CLIENTE (DESCRIPCION) VALUES ('Activo');
INSERT INTO ESTADOS_CLIENTE (DESCRIPCION) VALUES ('Inactivo');
INSERT INTO ESTADOS_CLIENTE (DESCRIPCION) VALUES ('Bloqueado');

-- Insertar clientes
INSERT INTO CLIENTES (NOMBRE, APELLIDO, FECHA_NACIMIENTO, EMAIL, TELEFONO, DIRECCION)
VALUES ('Carlos', 'Pérez', TO_DATE('1985-03-12','YYYY-MM-DD'), 'carlos.perez@email.com', '555-1234', 'Calle 1 #100');

INSERT INTO CLIENTES (NOMBRE, APELLIDO, FECHA_NACIMIENTO, EMAIL, TELEFONO, DIRECCION)
VALUES ('Ana', 'Gómez', TO_DATE('1990-07-25','YYYY-MM-DD'), 'ana.gomez@email.com', '555-5678', 'Avenida 2 #200');

INSERT INTO CLIENTES (NOMBRE, APELLIDO, FECHA_NACIMIENTO, EMAIL, TELEFONO, DIRECCION)
VALUES ('Luis', 'Ramírez', TO_DATE('1978-11-05','YYYY-MM-DD'), 'luis.ramirez@email.com', '555-8765', 'Calle 3 #300');

-- Insertar estados de clientes asignados
INSERT INTO CLIENTE_ESTADO (CLIENTE_ID, ESTADO_ID)
VALUES (1, 1); -- Carlos activo

INSERT INTO CLIENTE_ESTADO (CLIENTE_ID, ESTADO_ID)
VALUES (2, 1); -- Ana activo

INSERT INTO CLIENTE_ESTADO (CLIENTE_ID, ESTADO_ID)
VALUES (3, 3); -- Luis bloqueado

-- Insertar créditos otorgados
INSERT INTO CREDITO_CLIENTE (CLIENTE_ID, MONTO, FECHA_OTORGAMIENTO, FECHA_VENCIMIENTO)
VALUES (1, 5000, TO_DATE('2025-08-01','YYYY-MM-DD'), TO_DATE('2026-08-01','YYYY-MM-DD'));

INSERT INTO CREDITO_CLIENTE (CLIENTE_ID, MONTO, FECHA_OTORGAMIENTO, FECHA_VENCIMIENTO)
VALUES (2, 3000, TO_DATE('2025-07-15','YYYY-MM-DD'), TO_DATE('2026-07-15','YYYY-MM-DD'));

INSERT INTO CREDITO_CLIENTE (CLIENTE_ID, MONTO, FECHA_OTORGAMIENTO, FECHA_VENCIMIENTO)
VALUES (3, 1000, TO_DATE('2025-06-20','YYYY-MM-DD'), TO_DATE('2026-06-20','YYYY-MM-DD'));

-- Insertar tasas aplicadas
INSERT INTO TASAS_CLIENTE (CLIENTE_ID, PORCENTAJE)
VALUES (1, 12.5);

INSERT INTO TASAS_CLIENTE (CLIENTE_ID, PORCENTAJE)
VALUES (2, 10.0);

INSERT INTO TASAS_CLIENTE (CLIENTE_ID, PORCENTAJE)
VALUES (3, 15.0);
