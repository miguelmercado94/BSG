CREATE OR REPLACE TRIGGER TR_SEQ_C9990120 before insert on C9990120
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SEQ_C9990120.NEXTVAL;
  :new.ID_SECUENCIA := vl_secuencia;
End TR_SEQ_C9990120;
/
