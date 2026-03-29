CREATE OR REPLACE TRIGGER TR_SEQ_C1340300 before insert on C1340300
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SEQ_C1340300.NEXTVAL;
  :new.ID_SECUENCIA := vl_secuencia;
End TR_SEQ_C1340300;
/
