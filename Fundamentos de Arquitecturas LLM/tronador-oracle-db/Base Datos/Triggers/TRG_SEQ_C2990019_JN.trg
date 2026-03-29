CREATE OR REPLACE TRIGGER TRG_SEQ_C2990019_JN before insert on C2990019_JN
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SEQ_C2990019_JN.NEXTVAL;
  :new.ID_C2990019_JN := vl_secuencia;
End TRG_SEQ_C2990019_JN;
/
