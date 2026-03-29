CREATE OR REPLACE TRIGGER TR_SEQ_C1340301 before insert on C1340301
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SEQ_C1340301.NEXTVAL;
  :new.ID_SECUENCIA := vl_secuencia;
End TR_SEQ_C1340301;
/
