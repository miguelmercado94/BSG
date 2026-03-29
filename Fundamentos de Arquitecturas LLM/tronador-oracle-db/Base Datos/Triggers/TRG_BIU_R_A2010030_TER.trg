CREATE OR REPLACE TRIGGER TRG_BIU_R_A2010030_TER
  BEFORE INSERT OR UPDATE OF NRO_DOCUMTO, TDOC_TERCERO, SEC_TERCERO ON A2010030
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  V_PRIMERA      NATURALES.PRIMER_APELLIDO%TYPE;
  V_SEGUNDOA     NATURALES.SEGUNDO_APELLIDO%TYPE;
  V_PRIMERN      NATURALES.PRIMER_NOMBRE%TYPE;
  V_SEGUNDON     NATURALES.SEGUNDO_NOMBRE%TYPE;
  V_RAZON_SOCIAL JURIDICOS.RAZON_SOCIAL%TYPE;
  V_TIPO         VARCHAR2(1);
  V_DESCTIPO     VARCHAR2(200);
  V_CODERR       C1991300.COD_ERROR%TYPE;
  V_MSGERR       C1991300.MSG_ERROR%TYPE;
  L_Secuencia    NUMBER := :new.Sec_Tercero;
BEGIN
  IF INSERTING THEN
    :new.Sec_Tercero := NULL;
    IF :NEW.NRO_DOCUMTO IS NOT NULL AND :NEW.TDOC_TERCERO IS NOT NULL THEN
      BEGIN
        PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.NRO_DOCUMTO,
                                           :NEW.TDOC_TERCERO,
                                           :NEW.SEC_TERCERO,
                                           V_PRIMERA,
                                           V_SEGUNDOA,
                                           V_PRIMERN,
                                           V_SEGUNDON,
                                           V_RAZON_SOCIAL,
                                           V_TIPO,
                                           V_DESCTIPO);
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            :new.Sec_Tercero := l_secuencia;
            V_CODERR         := SQLCODE;
            V_MSGERR         := SQLERRM;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
      END;
    ELSE
      IF :NEW.TDOC_TERCERO IS NULL OR :NEW.SEC_TERCERO IS NULL THEN
        BEGIN
          :NEW.SEC_TERCERO := NULL;
          PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.NRO_DOCUMTO,
                                             :NEW.TDOC_TERCERO,
                                             :NEW.SEC_TERCERO,
                                             V_PRIMERA,
                                             V_SEGUNDOA,
                                             V_PRIMERN,
                                             V_SEGUNDON,
                                             V_RAZON_SOCIAL,
                                             V_TIPO,
                                             V_DESCTIPO);
        EXCEPTION
          WHEN OTHERS THEN
            BEGIN
              :new.Sec_Tercero := l_secuencia;
              V_CODERR         := SQLCODE;
              V_MSGERR         := SQLERRM;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
        END;
      END IF;
    END IF;
  ELSE
    DECLARE
      VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO, :OLD.TDOC_TERCERO);
      VNRO  NUMBER(16) := NVL(:NEW.NRO_DOCUMTO, :OLD.NRO_DOCUMTO);
      VSEC  NUMBER(13) := NVL(:NEW.SEC_TERCERO, :OLD.SEC_TERCERO);
    BEGIN
      VSEC := NULL;
      PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,
                                         VTIPO,
                                         VSEC,
                                         V_PRIMERA,
                                         V_SEGUNDOA,
                                         V_PRIMERN,
                                         V_SEGUNDON,
                                         V_RAZON_SOCIAL,
                                         V_TIPO,
                                         V_DESCTIPO);
      :NEW.NRO_DOCUMTO  := VNRO;
      :NEW.TDOC_TERCERO := VTIPO;
      :NEW.SEC_TERCERO  := VSEC;
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          :new.Sec_Tercero := l_secuencia;
          V_CODERR         := SQLCODE;
          V_MSGERR         := SQLERRM;
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;
    END;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    :new.Sec_Tercero := l_secuencia;
    V_CODERR         := SQLCODE;
    V_MSGERR         := SQLERRM;
end TRG_BIU_R_A2010030_TER;
/
