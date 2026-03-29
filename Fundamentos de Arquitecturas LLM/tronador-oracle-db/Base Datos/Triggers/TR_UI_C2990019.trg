CREATE OR REPLACE TRIGGER TR_UI_c2990019 BEFORE insert or update on c2990019
  for each row
Declare
  vl_secuencia number := 0;
Begin
   IF INSERTING  THEN
     :NEW.USUARIO_CREACION := substr(user,5,8);
     :NEW.FECHA_CREACION := sysdate;
   END IF;
   IF  UPDATING THEN
     :NEW.USUARIO_MODIFICA := substr(user,5,8);
     :NEW.FECHA_MODIFICA := sysdate;
   END IF;
End TR_UI_c2990019;
/
