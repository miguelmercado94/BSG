CREATE OR REPLACE TRIGGER TR_SEQ_c2990018 before insert on c2990018
  for each row
Declare
  vl_secuencia number := 0;
Begin
  vl_secuencia := SEQ_c2990018.NEXTVAL;
  :new.ID_SECUENCIA := vl_secuencia;
End TR_SEQ_c2990018;
/
