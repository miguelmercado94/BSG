CREATE OR REPLACE TRIGGER TR_AIUS_SIM_PAGOS_MASI_DIFMAX
/*
    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Agosto 13 de 2018 - Mantis 55555
    Desc : Creación del trigger. Auditar tabla SIM_PAGOS_MASIVOS_DIFMAX,
           cuando se inserte un registro.
*/
  AFTER INSERT OR UPDATE ON SIM_PAGOS_MASIVOS_DIFMAX
Begin
  dbms_output.put_line('Prc_Validar_Solapes');
  SIM_PCK_CONFIG_VAL_DIF_MAX.Prc_Validar_Solapes;
End TR_AIUS_SIM_PAGOS_MASI_DIFMAX;
/
