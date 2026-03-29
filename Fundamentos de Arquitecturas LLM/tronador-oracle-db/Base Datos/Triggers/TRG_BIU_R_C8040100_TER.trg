CREATE OR REPLACE TRIGGER TRG_BIU_R_C8040100_TER
  BEFORE INSERT OR UPDATE OF COD_BENEF,TDOC_TERCERO_BENEF,SEC_TERCERO_BENEF
  ON C8040100
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
  IF (:NEW.SEC_TERCERO_BENEF IS NULL OR
       :NEW.TDOC_TERCERO_BENEF IS NULL)
  AND (:NEW.COD_BENEF IS NOT NULL) THEN
    BEGIN
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.COD_BENEF,:NEW.TDOC_TERCERO_BENEF,
                  :NEW.SEC_TERCERO_BENEF,V_PrimerA,
                  V_SegundoA,V_PrimerN,V_SegundoN,
                  V_Razon_Social,V_Tipo,V_DescTipo);
    EXCEPTION WHEN OTHERS THEN
         BEGIN
          tercero_doble(:NEW.COD_BENEF,:NEW.TDOC_TERCERO_BENEF,:NEW.SEC_TERCERO_BENEF);
          
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
         
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN
               NULL;
           WHEN OTHERS THEN NULL;
         END;
    END;
  END IF;
ELSE
   DECLARE
    VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO_BENEF, :OLD.TDOC_TERCERO_BENEF);
    VNRO  NUMBER(16) := NVL(:NEW.COD_BENEF, :OLD.COD_BENEF);
    VSEC NUMBER(13) := NVL(:NEW.SEC_TERCERO_BENEF, :OLD.SEC_TERCERO_BENEF);
 BEGIN
     VSEC := NULL;
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,VTIPO,:NEW.SEC_TERCERO_BENEF,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
     :NEW.COD_BENEF := VNRO;
     :NEW.TDOC_TERCERO_BENEF := VTIPO;
     :NEW.SEC_TERCERO_BENEF := VSEC;
    EXCEPTION   WHEN OTHERS THEN
         BEGIN
          tercero_doble(:NEW.COD_BENEF,:NEW.TDOC_TERCERO_BENEF,:NEW.SEC_TERCERO_BENEF);
          
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
         
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN
               NULL;
           WHEN OTHERS THEN NULL;
         END;
    END;
END IF;
EXCEPTION
 WHEN OTHERS THEN
   v_Coderr  := sqlcode;
   v_msgerr := 'Error en el trigger de terceros en la tabla asociada';
end TRG_BIU_R_C8040100_TER;
/
