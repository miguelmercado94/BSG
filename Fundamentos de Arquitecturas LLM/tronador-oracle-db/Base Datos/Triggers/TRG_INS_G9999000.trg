CREATE OR REPLACE TRIGGER TRG_INS_G9999000
  before insert OR update on G9999000
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
End TRG_INS_G9999000;
/
