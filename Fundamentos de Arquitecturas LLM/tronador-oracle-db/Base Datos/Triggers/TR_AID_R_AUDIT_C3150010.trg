CREATE OR REPLACE TRIGGER TR_AID_R_Audit_C3150010
  AFTER INSERT OR UPDATE OR DELETE ON C3150010
    FOR EACH ROW
DECLARE
    Time_now DATE;
    V_IPADDRESS VARCHAR2(20);
    V_HOST VARCHAR2(20);
    V_OPERACION VARCHAR2(1);
    V_USUARIO   VARCHAR2(20);
    V_FECHA_PROC VARCHAR2(25);
  BEGIN
    -- Get current time, & terminal of user:
   SELECT user, sys_context('userenv','ip_address') IP_ADDRESS, sys_context('userenv','host') HOST
   INTO V_USUARIO, V_IPADDRESS, V_HOST  from dual;
   select to_char(sysdate,'dd/mm/yyyy hh:mm:ss')
   INTO V_FECHA_PROC from dual;

    -- Record new employee primary key:
    IF INSERTING THEN
      INSERT INTO C3150010_JOURNAL
      ( cod_cia,
        cod_ramo,
        cod_cob,
        num_secu,
        porcentaje,
        limite,
        cod_usr,
        fecha_equipo,
        fecha_baja,
        fecha_vigencia,
        OPERACION,
        usuario,
        IP_ADDRESS,
        HOST,
        FECHA_PROCESO)
         VALUES
       (:NEW.COD_CIA,
        :NEW.COD_RAMO,
        :NEW.COD_COB,
        :NEW.NUM_SECU,
        :NEW.PORCENTAJE,
        :NEW.LIMITE,
        :NEW.COD_USR,
        :NEW.FECHA_EQUIPO,
        :NEW.FECHA_BAJA,
        :NEW.FECHA_VIGENCIA,
        'INSERT',
        V_USUARIO, 
        V_IPADDRESS, 
        V_HOST,
        V_FECHA_PROC
      );


      -- Record primary key of deleted row:
      ELSIF DELETING THEN
             INSERT INTO C3150010_JOURNAL
      ( cod_cia,
        cod_ramo,
        cod_cob,
        num_secu,
        porcentaje,
        limite,
        cod_usr,
        fecha_equipo,
        fecha_baja,
        fecha_vigencia,
        OPERACION,
        usuario,
        IP_ADDRESS,
        HOST,
        FECHA_PROCESO)
         VALUES
       (:OLD.COD_CIA,
        :OLD.COD_RAMO,
        :OLD.COD_COB,
        :OLD.NUM_SECU,
        :OLD.PORCENTAJE,
        :OLD.LIMITE,
        :OLD.COD_USR,
        :OLD.FECHA_EQUIPO,
        :OLD.FECHA_BAJA,
        :OLD.FECHA_VIGENCIA,
        'DELETE',
        V_USUARIO, 
        V_IPADDRESS, 
        V_HOST,
        V_FECHA_PROC
      );

      -- For updates, record primary key of row being updated:
      ELSE
       INSERT INTO C3150010_JOURNAL
      ( cod_cia,
        cod_ramo,
        cod_cob,
        num_secu,
        porcentaje,
        limite,
        cod_usr,
        fecha_equipo,
        fecha_baja,
        fecha_vigencia,
        OPERACION,
        usuario,
        IP_ADDRESS,
        HOST,
        FECHA_PROCESO)
         VALUES
       (:OLD.COD_CIA,
        :OLD.COD_RAMO,
        :OLD.COD_COB,
        :OLD.NUM_SECU,
        :OLD.PORCENTAJE,
        :OLD.LIMITE,
        :OLD.COD_USR,
        :OLD.FECHA_EQUIPO,
        :OLD.FECHA_BAJA,
        :OLD.FECHA_VIGENCIA,
        'UPDATE_OLD',
        V_USUARIO, 
        V_IPADDRESS, 
        V_HOST,
        V_FECHA_PROC
      );
      INSERT INTO C3150010_JOURNAL
      ( cod_cia,
        cod_ramo,
        cod_cob,
        num_secu,
        porcentaje,
        limite,
        cod_usr,
        fecha_equipo,
        fecha_baja,
        fecha_vigencia,
        OPERACION,
        usuario,
        IP_ADDRESS,
        HOST,
        FECHA_PROCESO)
         VALUES
       (:NEW.COD_CIA,
        :NEW.COD_RAMO,
        :NEW.COD_COB,
        :NEW.NUM_SECU,
        :NEW.PORCENTAJE,
        :NEW.LIMITE,
        :NEW.COD_USR,
        :NEW.FECHA_EQUIPO,
        :NEW.FECHA_BAJA,
        :NEW.FECHA_VIGENCIA,
        'UPDATE NEW',
        V_USUARIO, 
        V_IPADDRESS, 
        V_HOST,
        V_FECHA_PROC
      );
     END IF;
END;
/
