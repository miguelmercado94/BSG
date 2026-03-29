CREATE OR REPLACE TRIGGER TRG_BI_C2700021
BEFORE INSERT
ON C2700021 
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
  Tmpvar  NUMBER;
/************************************************************************************
   NAME:       TRG_BI_C2700021
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ----------  -----------------------------------------------
   1.0        01/12/2009  INTASI32    1.ESTE TRIGGER FUE CREADO A FIN DE ACTUALIZAR
                                         EL CAMPO NUM_POL_CLI.
   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_BI_C2700021
      SYSDATE:         01/12/2009
      DATE AND TIME:   01/12/2009, 10:42:04 A.M., AND 01/12/2009 10:42:04 A.M.
      USERNAME:         (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C2700021 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
*************************************************************************************/
BEGIN
  Tmpvar            := 0;

  --
  :NEW.Num_Pol_Cli  := SUBSTR(:NEW.Num_Pol1, 5, 7);
--
END Trg_Bi_C2700021;
/
