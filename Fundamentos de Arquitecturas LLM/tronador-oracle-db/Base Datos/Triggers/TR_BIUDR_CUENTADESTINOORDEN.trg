CREATE OR REPLACE TRIGGER TR_BIUDR_CUENTADESTINOORDEN 
BEFORE DELETE OR INSERT OR UPDATE ON CUENTA_DESTINO_ESPEC_ORDEN 
FOR EACH ROW
DECLARE
  v_Tabla     AUDIT_TESO.Tabla%TYPE := 'CUENTA_DESTINO_ESPEC_ORDEN';
  l_usuario   AUDIT_TESO.usuario%TYPE;
  v_campo     AUDIT_TESO.Campo%TYPE;
  v_evento    AUDIT_TESO.evento%TYPE;
  v_Vlr_Anterior AUDIT_TESO.Vlr_Anterior%TYPE;
  v_Vlr_Nuevo AUDIT_TESO.Vlr_Nuevo%TYPE;
BEGIN
   IF INSERTING THEN
      v_evento    := 'Crear';
      l_usuario   := NVL(:new.USUARIO_CREACION,USER);
      v_Vlr_Anterior := NULL;
      
      v_campo := 'TIPO_CUENTA_DEST';
      v_Vlr_Nuevo := :new.TIPO_CUENTA_DEST;
      INSERT INTO AUDIT_TESO(
        Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
        Tabla, Campo, Evento, Usuario, Fecha)
      VALUES(
        :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
        v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      
      v_campo := 'NRO_CUENTA_DEST';
      v_Vlr_Nuevo := :new.NRO_CUENTA_DEST;
      INSERT INTO AUDIT_TESO(
        Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
        Tabla, Campo, Evento, Usuario, Fecha)
      VALUES(
        :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
        v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      
      v_campo := 'COD_BANCO_DEST';
      v_Vlr_Nuevo := :new.COD_BANCO_DEST;
      INSERT INTO AUDIT_TESO(
        Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
        Tabla, Campo, Evento, Usuario, Fecha)
      VALUES(
        :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
        v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      
      v_campo := 'MARCA_ESTADO';
      v_Vlr_Nuevo := :new.MARCA_ESTADO;
      INSERT INTO AUDIT_TESO(
        Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
        Tabla, Campo, Evento, Usuario, Fecha)
      VALUES(
        :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
        v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      
    ELSIF updating THEN
      v_evento    := 'Actualizar';
      l_usuario   := NVL(:new.USUARIO_MODIFICACION,USER);
      
      IF NVL(:new.TIPO_CUENTA_DEST,'-1') <> NVL(:old.TIPO_CUENTA_DEST,'-1') THEN
        v_campo := 'TIPO_CUENTA_DEST';
        v_Vlr_Anterior := :old.TIPO_CUENTA_DEST;
        v_Vlr_Nuevo := :new.TIPO_CUENTA_DEST;
        INSERT INTO AUDIT_TESO(
          Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
          Tabla, Campo, Evento, Usuario, Fecha)
        VALUES(
          :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
          v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      END IF;

      IF NVL(:new.NRO_CUENTA_DEST,'-1') <> NVL(:old.NRO_CUENTA_DEST,'-1') THEN
        v_campo := 'NRO_CUENTA_DEST';
        v_Vlr_Anterior := :old.NRO_CUENTA_DEST;
        v_Vlr_Nuevo := :new.NRO_CUENTA_DEST;
        INSERT INTO AUDIT_TESO(
          Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
          Tabla, Campo, Evento, Usuario, Fecha)
        VALUES(
          :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
          v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      END IF;

      IF NVL(:new.COD_BANCO_DEST,'-1') <> NVL(:old.COD_BANCO_DEST,'-1') THEN
        v_campo := 'COD_BANCO_DEST';
        v_Vlr_Anterior := :old.COD_BANCO_DEST;
        v_Vlr_Nuevo := :new.COD_BANCO_DEST;
        INSERT INTO AUDIT_TESO(
          Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
          Tabla, Campo, Evento, Usuario, Fecha)
        VALUES(
          :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
          v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      END IF;

      IF NVL(:new.MARCA_ESTADO,'-1') <> NVL(:old.MARCA_ESTADO,'-1') THEN
        v_campo := 'MARCA_ESTADO';
        v_Vlr_Anterior := :old.MARCA_ESTADO;
        v_Vlr_Nuevo := :new.MARCA_ESTADO;
        INSERT INTO AUDIT_TESO(
          Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
          Tabla, Campo, Evento, Usuario, Fecha)
        VALUES(
          :new.num_ord_pago, :new.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
          v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
      END IF;

    ELSE
      v_evento        := 'Borrar';
      l_usuario       := USER;
      v_campo         := 'num_ord_pago';
      v_Vlr_Anterior  := :old.num_ord_pago;
      v_Vlr_Nuevo     := null;
      INSERT INTO AUDIT_TESO(
        Num_Ord_Pago, Cod_Cia, Vlr_Anterior, Vlr_Nuevo,
        Tabla, Campo, Evento, Usuario, Fecha)
      VALUES(
        :old.num_ord_pago, :old.cod_cia, v_Vlr_Anterior, v_Vlr_Nuevo,
        v_Tabla, v_campo, v_evento, l_usuario, SYSDATE);
    END IF;
  
END TR_BIUDR_CUENTADESTINOORDEN;
/
