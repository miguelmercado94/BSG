CREATE OR REPLACE TRIGGER TR_SEQ_rgospolizacargue_cltv
  before insert OR update on SIM_RIESGOSPOLIZASCARGUE_CLTV
  for each row
Declare
  vl_secuencia number := 0;
Begin
  IF INSERTING THEN
    vl_secuencia := SEQ_RSGOSPOLIZACARGUE_CLTV.NEXTVAL;
    :new.Id_Riesgopolizac := vl_secuencia;
    :new.usuario_creacion := substr(user,5,8);
    :new.fecha_creacion   := trunc(sysdate);
  END IF;
  IF UPDATING THEN
    :new.usuario_modificacion:= substr(user,5,8);
    :new.fecha_modificacion  := trunc(sysdate);
  END IF;
End TR_SEQ_rgospolizacargue_cltv;
/
