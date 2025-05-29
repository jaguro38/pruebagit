-- Crear Tablas 

CREATE TABLE clientes (
    clienteid NUMBER PRIMARY KEY,
    nombre    VARCHAR2(100)
);
        
-- Tabla de productos con precio y stock

CREATE TABLE productos (
    producto_id NUMBER PRIMARY KEY,
    nombre      VARCHAR2(100),
    precio      NUMBER(10, 2),
    stock       NUMBER
);
                
-- Tabla de pedidos, relacionada con clientes

CREATE TABLE pedidos (
    pedido_id NUMBER PRIMARY KEY,
    clienteid NUMBER,
    fecha     DATE DEFAULT sysdate,
    FOREIGN KEY ( clienteid )
        REFERENCES clientes ( clienteid )
);
        
-- Detalles del pedido: productos y cantidades por pedido

CREATE TABLE detalle_pedido (
    detalle_id  NUMBER PRIMARY KEY,
    pedido_id   NUMBER,
    producto_id NUMBER,
    cantidad    NUMBER,
    FOREIGN KEY ( pedido_id )
        REFERENCES pedidos ( pedido_id ),
    FOREIGN KEY ( producto_id )
        REFERENCES productos ( producto_id )
);
        
-- Las secuencias generan valores únicos automáticamente        
CREATE SEQUENCE pedidos_seq START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE detalle_pedido_seq START WITH 1 INCREMENT BY 1;

-- Crear Pedido 

CREATE OR REPLACE PROCEDURE crear_pedido (
    p_clienteid    IN NUMBER,                      --Cliente que hace el pedido
    p_producto_ids IN sys.odcinumberlist,       --Lista de IDs de productos
    p_cantidades   IN sys.odcinumberlist          -- Lista de cantidades para cada producto
) IS
    v_pedido_id NUMBER;
BEGIN    
-- obtener nuevo ID de pedido

    SELECT
        pedidos_seq.NEXTVAL
    INTO v_pedido_id
    FROM
        dual;

-- insertar el pedido principal

    INSERT INTO pedidos (
        pedido_id,
        clienteid,
        fecha
    ) VALUES ( v_pedido_id,
               p_clienteid,
               sysdate );
    
-- Insertar cada línea de detalle (producto y cantidad)
    FOR i IN 1..p_producto_ids.count LOOP
        INSERT INTO detalle_pedido (
            detalle_id,
            pedido_id,
            producto_id,
            cantidad
        ) VALUES ( detalle_pedido_seq.NEXTVAL,
                   v_pedido_id,
                   p_producto_ids(i),
                   p_cantidades(i) );

    END LOOP;

    COMMIT;
END;
/

CREATE OR REPLACE TRIGGER actualizar_inventario AFTER
    INSERT ON detalle_pedido
    FOR EACH ROW
BEGIN
-- Disminuye el stock del producto según la cantidad vendida
    UPDATE productos
    SET
        stock = stock - :new.cantidad
    WHERE
        producto_id = :new.producto_id;

END;
/

CREATE OR REPLACE FUNCTION calcular_total_pedido (
    p_pedido_id IN NUMBER
) RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT
        SUM(dp.cantidad * pr.precio)
    INTO v_total
    FROM
             detalle_pedido dp
        JOIN productos pr ON dp.producto_id = pr.producto_id
    WHERE
        dp.pedido_id = p_pedido_id;

    RETURN v_total;
END;
/

INSERT INTO clientes VALUES ( 1,
                              'Juan Pérez' );

INSERT INTO clientes VALUES ( 2,
                              'Ana Gómez' );
-- Productos de ejemplo
INSERT INTO productos VALUES ( 101,
                               'Teclado',
                               25.50,
                               100 );

INSERT INTO productos VALUES ( 102,
                               'Mouse',
                               15.00,
                               200 );

INSERT INTO productos VALUES ( 103,
                               'Monitor',
                               150.00,
                               50 );

COMMIT;

BEGIN
    crear_pedido(
        p_clienteid    => 1,
        p_producto_ids => sys.odcinumberlist(101, 102, 103),
        p_cantidades   => sys.odcinumberlist(2, 3, 1)
    );
END;
/

SELECT
    *
FROM
    productos;
-- Verificar los pedidos registrados
SELECT
    *
FROM
    pedidos;
-- Verificar los detalles del pedido
SELECT
    *
FROM
    detalle_pedido;
-- Calcular el total del pedido
SELECT
    calcular_total_pedido(pedido_id) AS total
FROM
    pedidos
WHERE
    clienteid = 1;