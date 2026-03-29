CREATE OR REPLACE TRIGGER TR_INS_G9999002
  before insert OR update on G9999002
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF INSERTING THEN
    :new.fecha_creacion := (sysdate);
    :NEW.USR_CREACION := substr(USER,5,8);
  END IF;
  IF UPDATING THEN
    :new.fecha_modificacion := (sysdate);
    :NEW.USR_MODIFICACION := substr(USER,5,8);
  END IF;
End TR_INS_G9999002;
/
