CREATE OR REPLACE TRIGGER TRG_BIUD_C2700100_PAGOS
BEFORE DELETE OR INSERT OR UPDATE
ON C2700100 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  /******************************************************************************
     NAME:       TRG_BIUD_C2700100_PAGOS
     PURPOSE:

     REVISIONS:
     VER        DATE        AUTHOR           DESCRIPTION
     ---------  ----------  ---------------  ------------------------------------
     1.0        12/07/2012      INTASI32     1. CREATED THIS TRIGGER.

     NOTES:

     AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
        OBJECT NAME:     TRG_BIUD_C2700100_PAGOS
        SYSDATE:         12/07/2012
        DATE AND TIME:   12/07/2012, 02:12:52 P.M., AND 12/07/2012 02:12:52 P.M.
        USERNAME:        INTASI32 (SET IN TOAD OPTIONS, PROC TEMPLATES)
        TABLE NAME:      C2700100 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
        TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
  ******************************************************************************/

  Vexist_Pag  NUMBER( 5 ) := 0;
BEGIN
  IF INSERTING THEN
    BEGIN
      /****************************************************************************************************************************************************/
      /* DESCRIPTION: SE CONTROLA QUE NO SE INSERTEN PAGO DOBLES                                       DATE:12/07/2012  MNTS:007125 REQUIREMENT:SRS000671 */
      /****************************************************************************************************************************************************/

      BEGIN
        SELECT /*+ ALL_ROWS */
              COUNT( 1 )
          INTO Vexist_Pag
          FROM C2700100 A
         WHERE A.Cod_Cia = :NEW.Cod_Cia
           AND A.Cod_Secc = :NEW.Cod_Secc
           AND A.Cod_Ramo = :NEW.Cod_Ramo
           AND A.Num_Pol1 = :NEW.Num_Pol1
           AND A.Numero_Factura = :NEW.Numero_Factura
           AND A.Centro_Trab = :NEW.Centro_Trab
           AND A.Cod_Benef = :NEW.Cod_Benef
           AND A.Fech_Pago = :NEW.Fech_Pago
           AND A.Total_Trabaja = :NEW.Total_Trabaja
           AND A.Valor_Aportes = :NEW.Valor_Aportes
           AND A.Valor_Siniestros = :NEW.Valor_Siniestros
           AND A.Valor_Otros_Riesgos = :NEW.Valor_Otros_Riesgos
           AND A.Valor_Neto = :NEW.Valor_Neto
           AND A.Valor_Mora = :NEW.Valor_Mora
           AND A.Valor_Mora_Aport = :NEW.Valor_Mora_Aport
           AND A.Periodo_Pago = :NEW.Periodo_Pago
           AND A.Num_Planilla = :NEW.Num_Planilla
           AND ROWNUM < 2;
      END;

      IF Vexist_Pag > 0 THEN
        RAISE_APPLICATION_ERROR( -20001, ' ERROR : YA SE ENCUENTRA REGISTRADO UN PAGO SIMILAR ' );
      END IF;
    END;
  END IF;
END Trg_Biud_C2700100_Pagos;
/
