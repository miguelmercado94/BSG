CREATE OR REPLACE TRIGGER TRG_BIU_R_A2001300_TER
  BEFORE INSERT OR UPDATE OF COD_ASEG,TDOC_TERCERO ON A2001300   FOR EACH ROW
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
  IF (:NEW.TDOC_TERCERO IS NULL OR :NEW.SEC_TERCERO IS NULL) AND (:NEW.COD_ASEG IS NOT NULL) THEN
    BEGIN
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.COD_ASEG,:NEW.TDOC_TERCERO,:NEW.SEC_TERCERO,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN


               NULL;
         END;
    END;
  END IF;
ELSE
    Begin
      UPdate a2000020
       set valor_campo = :new.cod_aseg
      where num_Secu_pol = :old.num_secu_pol
        and nvl(cod_ries,0) = nvl(:old.cod_ries,0)
        and valor_campo = to_char(:old.cod_aseg)
        and cod_campo = 'COD_ASEG';
    --Margie Orellano Asesoftware, debe actualizar el tipo de documento
      UPdate a2000020
       set valor_campo = :new.Tdoc_Tercero
      where num_Secu_pol = :old.num_secu_pol
        and nvl(cod_ries,0) = nvl(:old.Cod_Ries,0)
        and valor_campo = to_char(:old.Tdoc_Tercero)
        and cod_campo = 'TIPO_DOC_ASEG';
    Exception when others then null;
    End;

   DECLARE
     VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO, :OLD.TDOC_TERCERO);
     VNRO  NUMBER(16) := NVL(:NEW.COD_ASEG, :OLD.COD_ASEG);
     VSEC  NUMBER(13) := NVL(:NEW.SEC_TERCERO, :OLD.SEC_TERCERO);
    BEGIN
      VSEC := NULL;
      PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,VTIPO,VSEC,V_PrimerA,
      V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
      :NEW.COD_ASEG := VNRO;
      :NEW.TDOC_TERCERO := VTIPO;
      :NEW.SEC_TERCERO := VSEC;

     EXCEPTION   WHEN OTHERS THEN
         BEGIN
           v_Coderr  := sqlcode;
           v_msgErr  := sqlerrm;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
          END;
   END;

END IF;
EXCEPTION
 WHEN OTHERS THEN
  v_Coderr  := sqlcode;
  v_msgerr := 'Error en el trigger de terceros en la tabla asociada';
end TRG_BIU_R_A2001300_TER;
/
