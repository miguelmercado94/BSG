CREATE OR REPLACE TRIGGER TR_SEQ_C2390002
  before insert OR update on C2390002
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF INSERTING THEN
    vl_secuencia := SEQ_C2390002.NEXTVAL;
    :new.ID_SECUENCIA := vl_secuencia;
    :new.usuario_creacion := substr(user,5,8);
    :new.fecha_creacion   := trunc(sysdate);
  END IF;
  IF UPDATING THEN
    :new.usuario_modifica:= substr(user,5,8);
    :new.fecha_modifica  := trunc(sysdate);
  END IF;
End TR_SEQ_C2390002;
/
