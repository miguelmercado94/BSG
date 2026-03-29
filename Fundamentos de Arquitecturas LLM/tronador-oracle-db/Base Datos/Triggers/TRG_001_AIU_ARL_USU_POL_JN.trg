CREATE OR REPLACE TRIGGER Trg_001_Aiu_ARL_USU_POL_Jn
AFTER UPDATE
ON ARL_USUARIO_POLIZA 
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
  Tmpvar            NUMBER;
  /******************************************************************************
     NAME:       Trg_001_Aiu_ARL_USU_POL_Jn
     PURPOSE:

     REVISIONS:
     Ver        Date        Author                              Description
     ---------  ----------  ----------------------------------  ------------------------------------
     1.0        14/07/2015  ANDRÉS VELANDIA                        1. Created this trigger.
     1.0.1      14/07/2015  ANDRÉS VELANDIA                        1. GUARDA LOS MOVIMIENTOS DE LA TABLA ARL_USUARIO_POLIZA

     NOTES:

     Automatically available Auto Replace Keywords:
        Object Name:     Trg_001_Aiu_ARL_USU_POL_Jn
        Sysdate:         03/12/2014
        Date and Time:   03/12/2014, 03:45:41 p.m., and 03/12/2014 03:45:41 p.m.
        Username:        79704401 (set in TOAD Options, Proc Templates)
        Table Name:      ARL_USUARIO_POLIZA (set in the "New PL/SQL Object" dialog)
        Trigger Options:  (set in the "New PL/SQL Object" dialog)
  ******************************************************************************/
  V_Operacion       CHAR (1);

BEGIN

  IF UPDATING
  THEN
    V_Operacion   := 'M';
  END IF;

  BEGIN
    INSERT INTO ARL_USUARIO_POLIZA_AUD ( JN_TIPO_OPERACION, JN_FECHA, JN_USUARIO,
                          ID_USU_POLIZA, TIPO_DOC_EMP_POLIZA, NUM_DOC_EMP_POLIZA, TIPO_DOCUMENTO_USUARIO  
                          ,NUM_DOCUMENTO_USUARIO, NOMBRES, CORREO, TELEFONO, VER_SALARIO, ESTADO, 
                          USUARIO_CREACION, FECHA_CREACION, USUARIO_TRANSACCION, FECHA_TRANSACCION, 
                          CODIGO_PERFIL, ID_PERFIL_APLIC
                          )
         VALUES ( V_Operacion, SYSDATE, :OLD.USUARIO_TRANSACCION,
                 :OLD.ID_USU_POLIZA, :OLD.TIPO_DOC_EMP_POLIZA, :OLD.NUM_DOC_EMP_POLIZA, :OLD.TIPO_DOCUMENTO_USUARIO,
                 :OLD.NUM_DOCUMENTO_USUARIO, :OLD.NOMBRES, :OLD.CORREO, :OLD.TELEFONO,:OLD.VER_SALARIO, :OLD.ESTADO, 
                 :OLD.USUARIO_CREACION, :OLD.FECHA_CREACION,:OLD.USUARIO_TRANSACCION, :OLD.FECHA_TRANSACCION, 
                 :OLD.CODIGO_PERFIL, :OLD.ID_PERFIL_APLIC);
            
  END;
END Trg_001_Aiu_ARL_USU_POL_Jn;
/
