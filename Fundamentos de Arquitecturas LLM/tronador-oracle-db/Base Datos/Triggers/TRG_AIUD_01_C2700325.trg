CREATE OR REPLACE TRIGGER Trg_Aiud_01_C2700325
AFTER DELETE OR INSERT OR UPDATE
ON C2700325 
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
  V_Ope  VARCHAR2( 3 ) := NULL;
/******************************************************************************
   NAME:       TRG_AIUD_01_C2700325
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/06/2014      79704401       1. CREATED THIS TRIGGER.
                                             2.SRTO[105-2014]ARLMNTSNO7812

   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AIUD_01_C2700325
      SYSDATE:         10/06/2014
      DATE AND TIME:   10/06/2014, 11:08:57 A.M., AND 10/06/2014 11:08:57 A.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C2700325 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)

******************************************************************************/
BEGIN
  IF DELETING THEN
    V_Ope  := 'DEL';
  ELSIF UPDATING THEN
    V_Ope  := 'UPD';
  ELSIF INSERTING THEN
    V_Ope  := 'INS';
  ELSE
    V_Ope  := 'ERR';
  END IF;

  IF UPDATING
  OR INSERTING THEN
    INSERT INTO C2700325_JN( Jn_Operation, Jn_Oracle_User, Jn_Datetime
                            ,Jn_Notes, USUARIO, Activo
                            ,Pagos, NOVEDADES, Fecha_Creacion
                            ,Usuario_Creacion )
         VALUES ( V_Ope, USER, SYSDATE
                 ,NULL, :NEW.USUARIO, :NEW.Activo
                 ,:NEW.Pagos, :NEW.NOVEDADES, :NEW.Fecha_Creacion
                 ,:NEW.Usuario_Creacion );
  ELSIF DELETING THEN
    INSERT INTO C2700325_JN( Jn_Operation, Jn_Oracle_User, Jn_Datetime
                            ,Jn_Notes, USUARIO, Activo
                            ,Pagos, NOVEDADES, Fecha_Creacion
                            ,Usuario_Creacion )
         VALUES ( V_Ope, USER, SYSDATE
                 ,NULL, :OLD.USUARIO, :OLD.Activo
                 ,:OLD.Pagos, :OLD.NOVEDADES, :OLD.Fecha_Creacion
                 ,:OLD.Usuario_Creacion );
  END IF;
END Trg_Aiud_01_C2700325;
/
