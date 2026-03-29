CREATE OR REPLACE TRIGGER "TR_INS_G9999010"
  before insert OR update on G9999010
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF INSERTING THEN
    IF :new.ID_TRANSACCION IS NULL THEN
      vl_secuencia := SEQ_G9999010.NEXTVAL;
      :new.ID_TRANSACCION := vl_secuencia;
    END IF;
    :new.usr_creacion := user;
    :new.fecha_creacion   := sysdate;
    :new.usr_modificacion:= NULL;
    :new.fecha_modificacion:= null;
    :new.usr_modifica_ESTADO:= NULL;
    :new.fecha_modifica_ESTADO:= null;
  END IF;
  IF UPDATING THEN
    :new.usr_modificacion:= user;
    :new.fecha_modificacion:= sysdate;
  END IF;
End TR_INS_G9999010;
/
