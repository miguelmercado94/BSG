CREATE OR REPLACE TRIGGER TRG_BIU_R_A1001304_TER
  BEFORE INSERT OR UPDATE OF COD_BENEF,TDOC_TERCERO,SEC_TERCERO
     ON A1001304
  FOR EACH ROW
DECLARE
  V_PrimerA      Naturales.primer_apellido%type;
  V_SegundoA     Naturales.segundo_apellido%type;
  V_PrimerN      Naturales.primer_nombre%type;
  V_SegundoN     Naturales.segundo_nombre%type;
  V_Razon_Social Juridicos.razon_social%type;
  V_Tipo         Varchar2(1);
  V_DescTipo     Varchar2(200);
  V_Coderr       C1991300.Cod_Error%type;
  V_MsgErr       C1991300.MSG_ERROR%type;
BEGIN
IF INSERTING THEN
  IF (:NEW.TDOC_TERCERO IS NULL OR :NEW.SEC_TERCERO IS NULL) AND (:NEW.COD_BENEF IS NOT NULL) THEN
      BEGIN
        INSERTA_C1991300(:NEW.COD_BENEF,'A1001304','I',10,'El programa que genera los datos no esta procesando correctamente la informacion del tercero. ',
        USER,SYSDATE,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO);
       EXCEPTION
        WHEN OTHERS THEN NULL;
        -- RAISE_APPLICATION_ERROR(-20501,'Error insertando el control que los campos estaban nulos.');
      END;
    BEGIN
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.COD_BENEF,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);

    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
          tercero_doble(:NEW.COD_BENEF,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO);
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN
               NULL;
         END;
    END;
  END IF;
ELSE
  DECLARE
     VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO, :OLD.TDOC_TERCERO);
     VNRO  NUMBER(16) := NVL(:NEW.COD_BENEF, :OLD.COD_BENEF);
     VSEC  NUMBER(13) :=  NVL(:NEW.SEC_TERCERO, :OLD.SEC_TERCERO);
  BEGIN
    IF VTIPO IS NULL OR VSEC IS NULL THEN
      BEGIN
       VSEC := NULL;
       PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,VTIPO,VSEC,V_PrimerA,
       V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
       :NEW.COD_BENEF := VNRO;
       :NEW.TDOC_TERCERO := VTIPO;
       :NEW.SEC_TERCERO := VSEC;
     EXCEPTION   WHEN OTHERS THEN
         BEGIN
           v_Coderr  := sqlcode;
           v_msgErr  := sqlerrm;
           tercero_doble(:NEW.COD_BENEF,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
          END;
      END;
    END IF;
   END;
  END IF;
EXCEPTION
 WHEN OTHERS THEN
      BEGIN
         v_Coderr  := sqlcode;
         v_msgerr := sqlerrm;
         INSERTA_C1991300(:NEW.COD_BENEF,'A1001304','T',v_Coderr,V_MsgErr,
         user,SYSDATE,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO);
      EXCEPTION
         WHEN OTHERS THEN NULL;
         --  RAISE_APPLICATION_ERROR(-20502,'Error insertando el control que los campos estaban nulos.');
      END;
end TRG_BIU_R_A1001304_TER;
/
