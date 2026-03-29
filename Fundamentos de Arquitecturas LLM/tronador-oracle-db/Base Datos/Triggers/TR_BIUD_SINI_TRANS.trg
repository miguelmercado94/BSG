CREATE OR REPLACE TRIGGER TR_BIUD_SINI_TRANS
    BEFORE INSERT OR UPDATE OR DELETE ON SIM_SINIESTROS_TRANSFERENCIAS 
    FOR EACH ROW
DECLARE
    /*********************************************************************************************************************************
     NOMBRE:      TRIGGER TR_BUD_SINI_TRANS
     PROPOSITO:   TRIGGER DE HISTORICOS DE LA TABLA SIM_SINIESTROS_TRANSFERENCIAS
     REVISIONS:
     VERSION    FECHA       AUTOR            DESCRIPCION
     ---------  ----------  ---------------  ------------------------------------
     1.0        23/07/2016  Carlos Mayorga   CREACION DEL TRIGGER
     1.1        18/01/2018  Carlos Mayorga   ADICION DE COLUMNAS TIPO Y COD_AGEN

    *********************************************************************************************************************************/
    l_operacion VARCHAR2(1);
BEGIN
   IF INSERTING THEN
      :NEW.USUARIO_CREACION := USER;
      :NEW.FECHA_CREACION := SYSDATE;
      :NEW.USUARIO_MODIFICACION := NULL;
      :NEW.FECHA_MODIFICACION := NULL;
   ELSE
      IF UPDATING THEN
         l_operacion := 'A';
         :NEW.USUARIO_MODIFICACION := USER;
         :NEW.FECHA_MODIFICACION := SYSDATE;
      END IF;
      IF DELETING THEN
         l_operacion := 'B';
      END IF;
      INSERT INTO SIM_SINIESTROS_TRANS_JN (COD_CIA, TIPO, COD_SECC,
         COD_RAMO, COD_USER, TIPO_DOCUMENTO,
         NUMERO_DOCUMENTO, TOPE_AUTORIZACION, MARCA_TESORERIA,
         ESTADO, COD_AGEN, USUARIO_CREACION,
         FECHA_CREACION, USUARIO_MODIFICACION, FECHA_MODIFICACION,
         OPERACION, USUARIO_OPERACION, FECHA_OPERACION)
      VALUES(:OLD.COD_CIA, :OLD.TIPO, :OLD.COD_SECC,
         :OLD.COD_RAMO, :OLD.COD_USER, :OLD.TIPO_DOCUMENTO,
         :OLD.NUMERO_DOCUMENTO, :OLD.TOPE_AUTORIZACION, :OLD.MARCA_TESORERIA,
         :OLD.ESTADO, :OLD.COD_AGEN, :OLD.USUARIO_CREACION,
         :OLD.FECHA_CREACION, :OLD.USUARIO_MODIFICACION, :OLD.FECHA_MODIFICACION,
         l_operacion, USER, SYSDATE);
   END IF;
END TR_BUD_SINI_TRANS;
/
