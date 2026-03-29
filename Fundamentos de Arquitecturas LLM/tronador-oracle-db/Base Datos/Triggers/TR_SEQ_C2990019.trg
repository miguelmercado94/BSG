CREATE OR REPLACE TRIGGER TR_SEQ_c2990019 before insert on c2990019
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF :new.ID_SECUENCIA IS NULL THEN
    vl_secuencia := SEQ_c2990019.NEXTVAL;
    :new.ID_SECUENCIA := vl_secuencia;
  END IF;
End TR_SEQ_c2990019;
/
