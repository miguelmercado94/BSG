CREATE OR REPLACE TRIGGER TRG_BI_R_C8040200_TER
  BEFORE INSERT ON C8040200
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
  TDOC_TER       Naturales.TIPDOC_CODIGO%type;
BEGIN
  IF (:NEW.SEC_TERCERO IS NULL) AND (:NEW.COD_BENEF IS NOT NULL) THEN
     PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.COD_BENEF,TDOC_TER,:NEW.SEC_TERCERO,V_PrimerA,
     V_SegundoA,V_PrimerN,V_SegundoN,V_Razon_Social,V_Tipo,V_DescTipo);
  END IF;
    EXCEPTION
      WHEN OTHERS THEN
      BEGIN
          tercero_doble(:NEW.COD_BENEF,TDOC_TER,:NEW.SEC_TERCERO);
          
          v_Coderr  := sqlcode;
          v_msgErr  := sqlerrm;
         
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX THEN
               NULL;
           WHEN OTHERS THEN NULL;
         END;
end TRG_BIU_R_C8040200_TER;
/
