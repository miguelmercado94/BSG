CREATE OR REPLACE TRIGGER TR_INS_G9999011
  before insert OR update on G9999011
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF INSERTING THEN
    :new.usr_creacion := user;
    :new.fecha_creacion:= sysdate;
    :new.usr_modificacion:=NULL;
    :new.fecha_modificacion:=null;
  END IF;
  IF UPDATING THEN
    :new.usr_modificacion:=user;
    :new.fecha_modificacion:=sysdate;
  END IF;
End TR_INS_G9999011;
/
