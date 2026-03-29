CREATE OR REPLACE TRIGGER TR_AIUR_CUENTADESTINOORDEN 
AFTER INSERT OR UPDATE ON CUENTA_DESTINO_ESPEC_ORDEN 
FOR EACH ROW
DECLARE 
  l_cant_registros_existentes NUMBER(1);
  l_tdoc_tercero_orden        VARCHAR2(3);
  l_numero_documento_orden    NUMBER(16,0);
  l_usuario_asociacion        VARCHAR2(30);
BEGIN
  l_cant_registros_existentes := 0;

  SELECT COD_BENEF, TDOC_TERCERO
  INTO l_numero_documento_orden, l_tdoc_tercero_orden
  FROM A5021604
  WHERE COD_CIA = :new.cod_cia
  AND NUM_ORD_PAGO = :new.num_ord_pago;

  IF INSERTING THEN
    l_usuario_asociacion := :new.USUARIO_CREACION;
  ELSIF updating THEN
    l_usuario_asociacion := :new.USUARIO_MODIFICACION;
  END IF;

  SELECT COUNT(1)
  INTO l_cant_registros_existentes
  FROM HIST_CUENTAS_ALTERNAS_BENEFIC
  WHERE TDOC_TERCERO = l_tdoc_tercero_orden
  AND NUMERO_DOCUMENTO = l_numero_documento_orden
  AND TIPO_CUENTA_DEST = :new.TIPO_CUENTA_DEST
  AND NRO_CUENTA_DEST = :new.NRO_CUENTA_DEST
  AND COD_BANCO_DEST = :new.COD_BANCO_DEST;
  
  IF l_cant_registros_existentes = 0 THEN
    INSERT INTO HIST_CUENTAS_ALTERNAS_BENEFIC(TDOC_TERCERO,NUMERO_DOCUMENTO,TIPO_CUENTA_DEST,NRO_CUENTA_DEST,COD_BANCO_DEST,FECHA_ASOCIACION,USUARIO_ASOCIACION)
    VALUES(l_tdoc_tercero_orden,l_numero_documento_orden,:new.TIPO_CUENTA_DEST,:new.NRO_CUENTA_DEST,:new.COD_BANCO_DEST,SYSDATE,l_usuario_asociacion);
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    NULL;--si no se puede insertar, no se debe frenar el proceso de modificacion de la orden
END TR_AIUR_CUENTADESTINOORDEN;
/
