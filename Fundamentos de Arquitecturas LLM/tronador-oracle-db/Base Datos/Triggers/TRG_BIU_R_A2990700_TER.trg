CREATE OR REPLACE TRIGGER TRG_BIU_R_A2990700_TER
  BEFORE  UPDATE OF NRO_DOCUMTO,TDOC_TERCERO,SEC_TERCERO ON A2990700
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
 DECLARE
    VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO, :OLD.TDOC_TERCERO);
    VNRO  NUMBER(16) := NVL(:NEW.NRO_DOCUMTO, :OLD.NRO_DOCUMTO);
    VSEC  NUMBER(13) := NVL(:NEW.SEC_TERCERO, :OLD.SEC_TERCERO);
 BEGIN
     VSEC := NULL;
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,VTIPO,VSEC,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
     :NEW.NRO_DOCUMTO := VNRO;
     :NEW.TDOC_TERCERO := VTIPO;
     :NEW.SEC_TERCERO := VSEC;

    EXCEPTION   WHEN OTHERS THEN
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
    END;
EXCEPTION
 WHEN OTHERS THEN
    v_Coderr  := sqlcode;
    v_msgerr := 'Error en el trigger de terceros en la tabla asociada';
end TRG_BIU_R_A2990700_TER;
/
