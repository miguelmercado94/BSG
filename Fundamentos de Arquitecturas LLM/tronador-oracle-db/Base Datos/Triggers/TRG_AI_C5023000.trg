CREATE OR REPLACE TRIGGER TRG_AI_C5023000
AFTER INSERT
ON C5023000 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  Tmpvar         NUMBER;
  Vgen_Tipomvto  C5023000.Gen_Tipomvto%TYPE;
/*********************************************************************************************************************************
   NAME:       TRG_AI_C5023000
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ---------------------------------------------------------------------------------------
   1.0        28/01/2011  INTASI32         1. MUEVE LOS REGISTROS QUE SE INSERTAN A LA TABLA C5023000_HIST.
   1.0.1      06/03/2013  INTASI32         1. CONTROL TIPO MOVIMIENTO 200 SECCION 310.

   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AI_C5023000
      SYSDATE:         28/01/2011
      DATE AND TIME:   28/01/2011, 03:06:47 P.M., AND 28/01/2011 03:06:47 P.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C5023000 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
**********************************************************************************************************************************/
BEGIN
  IF :NEW.Gen_Codcia = 3
 AND :NEW.Gen_Tipomvto = 200
 AND :NEW.Gen_Seccion = 310 THEN
    Vgen_Tipomvto := 410;
  ELSE
    Vgen_Tipomvto := :NEW.Gen_Tipomvto;
  END IF;

  BEGIN
    INSERT INTO C5023000_HIST(Histgen_Fechapro, Histgen_Numeropro, Histgen_Codcia, Histgen_Tiponov, Histgen_Tipomvto
                 ,Histgen_Valormvto, Histgen_Estado, Histgen_Usuario, Histgen_Secuencia, Histgen_Nitage
                 ,Histgen_Codagente, Histgen_Seccion, Histgen_Codramo, Histgen_Opcion, Histgen_Nropoliza
                 ,Histgen_End, Histgen_Descmvto, Histgen_Fechamvto, Histgen_Valorprima, Histgen_Valorrecau
                 ,Histgen_Altura, Histgen_Participa, Histgen_Certifica, Histgen_Ppal, Histfech_Creacion )
         VALUES ( :NEW.Gen_Fechapro, :NEW.Gen_Numeropro, :NEW.Gen_Codcia, :NEW.Gen_Tiponov, Vgen_Tipomvto
                 ,:NEW.Gen_Valormvto, :NEW.Gen_Estado, :NEW.Gen_Usuario, :NEW.Gen_Secuencia, :NEW.Gen_Nitage
                 ,:NEW.Gen_Codagente, :NEW.Gen_Seccion, :NEW.Gen_Codramo, :NEW.Gen_Opcion, :NEW.Gen_Nropoliza
                 ,:NEW.Gen_End, :NEW.Gen_Descmvto, :NEW.Gen_Fechamvto, :NEW.Gen_Valorprima, :NEW.Gen_Valorrecau
                 ,:NEW.Gen_Altura, :NEW.Gen_Participa, :NEW.Gen_Certifica, :NEW.Gen_Ppal, SYSDATE );

    COMMIT;
  END;
EXCEPTION
  WHEN OTHERS THEN
    -- CONSIDER LOGGING THE ERROR AND THEN RE-RAISE
    NULL;
END Trg_Ai_C5023000;
/
