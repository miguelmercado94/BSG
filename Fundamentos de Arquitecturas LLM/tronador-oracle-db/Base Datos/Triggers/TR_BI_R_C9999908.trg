CREATE OR REPLACE TRIGGER "TR_BI_R_C9999908" before insert on C9999908
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SIM_SEQ_ERROR_CARGUES_MASIVOS.NEXTVAL;
  :new.SIM_SECUENCIA := vl_secuencia;
End TR_BI_R_C9999908;
/
