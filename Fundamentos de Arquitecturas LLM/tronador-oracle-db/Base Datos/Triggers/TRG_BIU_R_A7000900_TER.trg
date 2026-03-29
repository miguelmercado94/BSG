CREATE OR REPLACE TRIGGER TRG_BIU_R_A7000900_TER
  BEFORE INSERT OR UPDATE OF NRO_DOCUMTO, TDOC_TERCERO_TOM,SEC_TERCERO_TOM ON A7000900
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
   IF :NEW.TDOC_TERCERO_TOM IS NULL OR :NEW.SEC_TERCERO_TOM IS NULL THEN
      BEGIN
        INSERTA_C1991300(:NEW.NRO_DOCUMTO,'A7000900','I','10','El programa que genera los datos no esta procesando correctamente la informacion del tercero. ',
        USER,SYSDATE,:NEW.TDOC_TERCERO_TOM,:NEW.SEC_TERCERO_TOM);
       EXCEPTION
        WHEN OTHERS THEN NULL;
        -- RAISE_APPLICATION_ERROR(-20501,'Error insertando el control que los campos estaban nulos.');
      END;
   -- :NEW.SEC_TERCERO_TOM := NULL;
   If :New.Sec_Tercero_Tom Is Null Then
    BEGIN
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.NRO_DOCUMTO,:NEW.TDOC_TERCERO_TOM,:NEW.SEC_TERCERO_TOM,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
          tercero_doble(:NEW.NRO_DOCUMTO,:NEW.TDOC_TERCERO_TOM,:NEW.SEC_TERCERO_TOM);
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN
              NULL;
         END;
    END;
   End If; --Si la secuencia no es nula no hace nada
   END IF;
ELSE
  DECLARE
     VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO_TOM, :OLD.TDOC_TERCERO_TOM);
     VNRO  NUMBER(16) := NVL(:NEW.NRO_DOCUMTO, :OLD.NRO_DOCUMTO);
     VSEC  NUMBER(13) :=  NVL(:NEW.SEC_TERCERO_TOM, :OLD.SEC_TERCERO_TOM);
   BEGIN
   IF VTIPO IS NULL OR VSEC IS NULL THEN
     BEGIN
       VSEC := NULL;

       PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,VTIPO,VSEC,V_PrimerA,
       V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
       :NEW.NRO_DOCUMTO := VNRO;
       :NEW.TDOC_TERCERO_TOM := VTIPO;
       :NEW.SEC_TERCERO_TOM := VSEC;
      EXCEPTION   WHEN OTHERS THEN
          BEGIN
            tercero_doble(:NEW.NRO_DOCUMTO,:NEW.TDOC_TERCERO_TOM,:NEW.SEC_TERCERO_TOM);
            v_Coderr  := sqlcode;
            v_msgErr  := sqlerrm;
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
          v_msgerr  := sqlerrm;
      INSERTA_C1991300(:NEW.NRO_DOCUMTO,'A7000900','T',v_Coderr,V_MsgErr,
         user,SYSDATE,:NEW.TDOC_TERCERO_TOM,:NEW.SEC_TERCERO_TOM);
      EXCEPTION
         WHEN OTHERS THEN NULL;
         --  RAISE_APPLICATION_ERROR(-20501,'Error insertando el control que los campos estaban nulos.');
      END;
END TRG_BIU_R_A7000900_TER;
/
