CREATE OR REPLACE TRIGGER TRG_BIU_R_A3001700_SAI
  BEFORE INSERT OR UPDATE OF FECHA_PAGO
    ON A3001700
  FOR EACH ROW
BEGIN
  IF :NEW.COD_SECC = 33 THEN
    DECLARE
      V_RAMO  A7000900.COD_RAMO%TYPE;
    BEGIN
      SELECT MIN(S.COD_RAMO)
      INTO   V_RAMO
      FROM   A7000900 S
      WHERE  S.COD_CIA = :NEW.COD_CIA
      AND    S.COD_SECC = :NEW.COD_SECC
      AND    S.NUM_SINI = :NEW.NUM_SINI;
      IF V_RAMO = 506 THEN
        IF INSERTING THEN
          SIM_PCK_PROCESO_LIQUIDACION.Proc_INS_LIQ_SAI(
                                              IP_COD_CIA => :NEW.COD_CIA,
                                              IP_COD_SECC => :NEW.COD_SECC,
                                              IP_NUM_SINI => :NEW.NUM_SINI,
                                              IP_NUM_LIQ => :NEW.NUM_LIQ,
                                              IP_TOTAL_BRUTO_LIQ => :NEW.TOTAL_BRUTO_LIQ,
                                              IP_NRO_CUOTA => :NEW.OBSERVACION,
                                              IP_FECHA_PAGO => NULL,
                                              IP_ESTADO_SIMON => 'P' );
        ELSE
          IF :NEW.FECHA_PAGO IS NOT NULL THEN
            SIM_PCK_PROCESO_LIQUIDACION.Proc_INS_LIQ_SAI(

                                              IP_COD_CIA => :NEW.COD_CIA,
                                              IP_COD_SECC => :NEW.COD_SECC,
                                              IP_NUM_SINI => :NEW.NUM_SINI,
                                              IP_NUM_LIQ => :NEW.NUM_LIQ,
                                              IP_TOTAL_BRUTO_LIQ => :NEW.TOTAL_BRUTO_LIQ,
                                              IP_NRO_CUOTA => :NEW.OBSERVACION,
                                              IP_FECHA_PAGO => :NEW.FECHA_PAGO,
                                              IP_ESTADO_SIMON => 'T' );
          END IF;
        END IF;
        SIM_PCK_PROCESO_LIQUIDACION.Proc_Exporta_SAI;
      END IF;
    END;
  END IF;
END TRG_BIU_R_A3001700_TER;
/
