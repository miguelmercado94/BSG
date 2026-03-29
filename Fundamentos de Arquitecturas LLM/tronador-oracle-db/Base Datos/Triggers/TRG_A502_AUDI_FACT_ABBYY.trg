CREATE OR REPLACE TRIGGER TRG_A502_AUDI_FACT_ABBYY
  before insert or update or delete on "ABBYY"."A502_FACTURA_ABBYY"
  FOR EACH ROW
DECLARE

  CURSOR cur_generar_id IS
    SELECT TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3') ||
           DBMS_RANDOM.STRING('U', 3)
      FROM DUAL;

  vca_comando      VARCHAR2(20);
  vca_valor_old    VARCHAR2(100);
  vca_valor_new    VARCHAR2(100);
  vca_sql          VARCHAR2(32767);
  vnu_id_factura   NUMBER;
  vca_id_auditoria VARCHAR2(20);
  vda_fecha        DATE;
  vca_columna      VARCHAR2(100);
  vna_factura      VARCHAR2(30);
  vna_usuario      VARCHAR2(30);
  vno_factura      VARCHAR2(30);
  vno_usuario      VARCHAR2(30);
  vca_secuencia    NUMBER(15);

BEGIN

  vda_fecha := SYSDATE;

  --Inserta en la tabla auditoria al momento que se agrega un registro sobre la tabla A502_FACTURA_ABBYY
  IF (INSERTING) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vca_comando    := 'INSERT';
    vnu_id_factura := :NEW.SECUENCIA;
    vna_factura    := :NEW.numero_factura;
    vna_usuario    := :new.usuario;

    vca_sql := 'secuencia = ' || :new.secuencia || ',numero_factura = ' ||
               :new.numero_factura || ',nit_compania_adquiriente = ' ||
               :new.nit_compania_adquiriente || ',tipo_documento_pago = ' ||
               :new.tipo_documento_pago || ',fecha_emision_factura = ' ||
               :new.fecha_emision_factura || ',ciudad_emision_factura = ' ||
               :new.ciudad_emision_factura ||
               ',tipo_documento_proveedor = ' ||
               :new.tipo_documento_proveedor ||
               ',numero_documento_proveedor = ' ||
               :new.numero_documento_proveedor || ',nombre_proveedor = ' ||
               :new.nombre_proveedor || ',codigo_moneda = ' ||
               :new.codigo_moneda || ',valor_factura = ' ||
               :new.valor_factura || ',valor_antes_impuestos = ' ||
               :new.valor_antes_impuestos || ',valor_iva = ' ||
               :new.valor_iva || ',valor_tipo_consumo = ' ||
               :new.valor_tipo_consumo || ',valor_ica = ' || :new.valor_ica ||
               ',actividad_economica = ' || :new.actividad_economica ||
               ',fecha_creacion = ' || :new.fecha_creacion ||
               ',fecha_modificacion = ' || :new.fecha_modificacion ||
               ',num_intentos = ' || :new.num_intentos || ',desc_error = ' ||
               :new.desc_error || ',archivo = ' || --:new.archivo ||
               ',usuario = ' || :new.usuario || ',id_filenet = ' ||
               :new.id_filenet || ',maca_filenet = ' || :new.maca_filenet ||
               ',maca_fac = ' || :new.maca_fac || ',num_plantilla = ' ||
               :new.num_plantilla || ',info1 = ' || :new.info1 ||
               ',info2 = ' || :new.info2 || ',info3 = ' || :new.info3 ||
               ',info4 = ' || :new.info4 || ',info5  = ' || :new.info5;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vna_factura,
       vca_comando,
       null,
       vnu_id_factura,
       vna_usuario,
       vda_fecha,
       'SECUENCIA',
       substr(vca_sql, 1, 4000));
  END IF;


  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  MACA_FAC
  IF (UPDATING('MACA_FAC')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'MACA_FAC';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.MACA_FAC;
    vca_valor_new := :NEW.MACA_FAC;
  vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET MACA_FAC = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  SECUENCIA

  IF (UPDATING('NUM_INTENTOS')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NUM_INTENTOS';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NUM_INTENTOS;
    vca_valor_new := :NEW.NUM_INTENTOS;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NUM_INTENTOS = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;
  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  SECUENCIA

  IF (UPDATING('SECUENCIA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'SECUENCIA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.SECUENCIA;
    vca_valor_new := :NEW.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET SECUENCIA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' ||
                     vca_valor_old;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  NUMERO_FACTURA

  IF (UPDATING('NUMERO_FACTURA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NUMERO_FACTURA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NUMERO_FACTURA;
    vca_valor_new := :NEW.NUMERO_FACTURA;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NUMERO_FACTURA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  NIT_COMPANIA_ADQUIRIENTE

  IF (UPDATING('NIT_COMPANIA_ADQUIRIENTE')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NIT_COMPANIA_ADQUIRIENTE';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NIT_COMPANIA_ADQUIRIENTE;
    vca_valor_new := :NEW.NIT_COMPANIA_ADQUIRIENTE;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NIT_COMPANIA_ADQUIRIENTE = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  TIPO_DOCUMENTO_PAGO

  IF (UPDATING('TIPO_DOCUMENTO_PAGO')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'TIPO_DOCUMENTO_PAGO';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.TIPO_DOCUMENTO_PAGO;
    vca_valor_new := :NEW.TIPO_DOCUMENTO_PAGO;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET TIPO_DOCUMENTO_PAGO = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  FECHA_EMISION_FACTURA

  IF (UPDATING('FECHA_EMISION_FACTURA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'FECHA_EMISION_FACTURA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.FECHA_EMISION_FACTURA;
    vca_valor_new := :NEW.FECHA_EMISION_FACTURA;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET FECHA_EMISION_FACTURA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  CIUDAD_EMISION_FACTURA

  IF (UPDATING('CIUDAD_EMISION_FACTURA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'CIUDAD_EMISION_FACTURA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.CIUDAD_EMISION_FACTURA;
    vca_valor_new := :NEW.CIUDAD_EMISION_FACTURA;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET CIUDAD_EMISION_FACTURA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  TIPO_DOCUMENTO_PROVEEDOR

  IF (UPDATING('TIPO_DOCUMENTO_PROVEEDOR')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'TIPO_DOCUMENTO_PROVEEDOR';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.TIPO_DOCUMENTO_PROVEEDOR;
    vca_valor_new := :NEW.TIPO_DOCUMENTO_PROVEEDOR;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET TIPO_DOCUMENTO_PROVEEDOR = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  NUMERO_DOCUMENTO_PROVEEDOR

  IF (UPDATING('NUMERO_DOCUMENTO_PROVEEDOR')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NUMERO_DOCUMENTO_PROVEEDOR';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NUMERO_DOCUMENTO_PROVEEDOR;
    vca_valor_new := :NEW.NUMERO_DOCUMENTO_PROVEEDOR;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NUMERO_DOCUMENTO_PROVEEDOR = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  NOMBRE_PROVEEDOR

  IF (UPDATING('NOMBRE_PROVEEDOR')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NOMBRE_PROVEEDOR';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NOMBRE_PROVEEDOR;
    vca_valor_new := :NEW.NOMBRE_PROVEEDOR;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NOMBRE_PROVEEDOR = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  CODIGO_MONEDA

  IF (UPDATING('CODIGO_MONEDA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'CODIGO_MONEDA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.CODIGO_MONEDA;
    vca_valor_new := :NEW.CODIGO_MONEDA;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET CODIGO_MONEDA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  VALOR_FACTURA

  IF (UPDATING('VALOR_FACTURA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'VALOR_FACTURA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.VALOR_FACTURA;
    vca_valor_new := :NEW.VALOR_FACTURA;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET VALOR_FACTURA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  VALOR_ANTES_IMPUESTOS
  IF (UPDATING('VALOR_ANTES_IMPUESTOS')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'VALOR_ANTES_IMPUESTOS';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.VALOR_ANTES_IMPUESTOS;
    vca_valor_new := :NEW.VALOR_ANTES_IMPUESTOS;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET VALOR_ANTES_IMPUESTOS = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  VALOR_IVA

  IF (UPDATING('VALOR_IVA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'VALOR_IVA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.VALOR_IVA;
    vca_valor_new := :NEW.VALOR_IVA;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET VALOR_IVA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  VALOR_TIPO_CONSUMO

  IF (UPDATING('VALOR_TIPO_CONSUMO')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'VALOR_TIPO_CONSUMO';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.VALOR_TIPO_CONSUMO;
    vca_valor_new := :NEW.VALOR_TIPO_CONSUMO;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET VALOR_TIPO_CONSUMO = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  VALOR_ICA

  IF (UPDATING('VALOR_ICA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'VALOR_ICA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.VALOR_ICA;
    vca_valor_new := :NEW.VALOR_ICA;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET VALOR_ICA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  ACTIVIDAD_ECONOMICA

  IF (UPDATING('ACTIVIDAD_ECONOMICA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'ACTIVIDAD_ECONOMICA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.ACTIVIDAD_ECONOMICA;
    vca_valor_new := :NEW.ACTIVIDAD_ECONOMICA;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET ACTIVIDAD_ECONOMICA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  FECHA_CREACION

  IF (UPDATING('FECHA_CREACION')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'FECHA_CREACION';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.FECHA_CREACION;
    vca_valor_new := :NEW.FECHA_CREACION;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET FECHA_CREACION = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  FECHA_MODIFICACION

  IF (UPDATING('FECHA_MODIFICACION')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'FECHA_MODIFICACION';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.FECHA_MODIFICACION;
    vca_valor_new := :NEW.FECHA_MODIFICACION;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET FECHA_MODIFICACION = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  - NUM_INTENTOS

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  DESC_ERROR

  IF (UPDATING('DESC_ERROR')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'DESC_ERROR';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.DESC_ERROR;
    vca_valor_new := :NEW.DESC_ERROR;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET DESC_ERROR = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  ARCHIVO

  IF (UPDATING('ARCHIVO')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'ARCHIVO';
    vca_comando   := 'UPDATE';
    --vca_valor_old := :OLD.ARCHIVO;
    --vca_valor_new := :NEW.ARCHIVO;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET ARCHIVO = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  USUARIO

  IF (UPDATING('USUARIO')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'USUARIO';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.USUARIO;
    vca_valor_new := :NEW.USUARIO;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET USUARIO = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  ID_FILENET

  IF (UPDATING('ID_FILENET')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'ID_FILENET';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.ID_FILENET;
    vca_valor_new := :NEW.ID_FILENET;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET ID_FILENET = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  MACA_FILENET

  IF (UPDATING('MACA_FILENET')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'MACA_FILENET';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.MACA_FILENET;
    vca_valor_new := :NEW.MACA_FILENET;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET MACA_FILENET = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  NUM_PLANTILLA
  IF (UPDATING('NUM_PLANTILLA')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'NUM_PLANTILLA';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.NUM_PLANTILLA;
    vca_valor_new := :NEW.NUM_PLANTILLA;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET NUM_PLANTILLA = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  INFO1
  IF (UPDATING('INFO1')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'INFO1';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.INFO1;
    vca_valor_new := :NEW.INFO1;
     vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET INFO1 = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  INFO2

  IF (UPDATING('INFO2')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'INFO2';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.INFO2;
    vca_valor_new := :NEW.INFO2;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET INFO2 = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  INFO3

  IF (UPDATING('INFO3')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'INFO3';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.INFO3;
    vca_valor_new := :NEW.INFO3;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET INFO3 = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  INFO4

  IF (UPDATING('INFO4')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'INFO4';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.INFO4;
    vca_valor_new := :NEW.INFO4;
   vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET INFO4 = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;

  --Inserci?n en la tabla de auditor?a cuando se presenta una actualizaci?n en el campo  INFO5

  IF (UPDATING('INFO5')) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura   := :OLD.numero_factura;
    vno_usuario   := :OLD.usuario;
    vca_columna   := 'INFO5';
    vca_comando   := 'UPDATE';
    vca_valor_old := :OLD.INFO5;
    vca_valor_new := :NEW.INFO5;
    vca_secuencia := :OLD.SECUENCIA;
    vca_sql       := 'UPDATE A502_FACTURA_ABBYY SET INFO5 = ' ||
                     vca_valor_new || ' WHERE SECUENCIA = ' || vca_secuencia;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vca_valor_old,
       vca_valor_new,
       vno_usuario,
       vda_fecha,
       vca_columna,
       vca_sql);
  END IF;


--Inserta en la tabla audiria al momento que se elimina un registro sobre la tabla A502_FACTURA_ABBYY
  IF (DELETING) THEN

    OPEN cur_generar_id;
    FETCH cur_generar_id
      INTO vca_id_auditoria;
    CLOSE cur_generar_id;

    vno_factura    := :OLD.numero_factura;
    vno_usuario    := :OLD.usuario;
    vca_comando    := 'DELETE';
    vnu_id_factura := :OLD.SECUENCIA;

    vca_sql := 'secuencia = ' || :OLD.secuencia || ',numero_factura = ' ||
               :OLD.numero_factura || ',nit_compania_adquiriente = ' ||
               :OLD.nit_compania_adquiriente || ',tipo_documento_pago = ' ||
               :OLD.tipo_documento_pago || ',fecha_emision_factura = ' ||
               :OLD.fecha_emision_factura || ',ciudad_emision_factura = ' ||
               :OLD.ciudad_emision_factura ||
               ',tipo_documento_proveedor = ' ||
               :OLD.tipo_documento_proveedor ||
               ',numero_documento_proveedor = ' ||
               :OLD.numero_documento_proveedor || ',nombre_proveedor = ' ||
               :OLD.nombre_proveedor || ',codigo_moneda = ' ||
               :OLD.codigo_moneda || ',valor_factura = ' ||
               :OLD.valor_factura || ',valor_antes_impuestos = ' ||
               :OLD.valor_antes_impuestos || ',valor_iva = ' ||
               :OLD.valor_iva || ',valor_tipo_consumo = ' ||
               :OLD.valor_tipo_consumo || ',valor_ica = ' || :OLD.valor_ica ||
               ',actividad_economica = ' || :OLD.actividad_economica ||
               ',fecha_creacion = ' || :OLD.fecha_creacion ||
               ',fecha_modificacion = ' || :OLD.fecha_modificacion ||
               ',num_intentos = ' || :OLD.num_intentos || ',desc_error = ' ||
               :OLD.desc_error || ',archivo = ' || --:OLD.archivo ||
               ',usuario = ' || :OLD.usuario || ',id_filenet = ' ||
               :OLD.id_filenet || ',maca_filenet = ' || :OLD.maca_filenet ||
               ',maca_fac = ' || :OLD.maca_fac || ',num_plantilla = ' ||
               :OLD.num_plantilla || ',info1 = ' || :OLD.info1 ||
               ',info2 = ' || :OLD.info2 || ',info3 = ' || :OLD.info3 ||
               ',info4 = ' || :OLD.info4 || ',info5  = ' || :OLD.info5;

    INSERT INTO A502_AUDITORIA_FACTURA_ABBYY
      (ID_AUDITORIA,
       ID_FACTURA,
       COMANDO,
       VALOR_OLD,
       VALOR_NEW,
       USUARIO,
       FECHA,
       COLUMNA,
       SQL)
    VALUES
      (vca_id_auditoria,
       vno_factura,
       vca_comando,
       vnu_id_factura,
       null,
       vno_usuario,
       vda_fecha,
       'SECUENCIA',
       substr(vca_sql, 1, 4000));
  END IF;

end TRG_A502_AUDI_FACT_ABBYY;
/
