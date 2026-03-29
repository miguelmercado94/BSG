CREATE OR REPLACE TRIGGER TRG_SEQ_SEC_G7000026
  before insert on G7000026
  for each row
declare
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEC_G7000026.Nextval
     Into   V_secuencia
     from   dual;
  End;  

  :new.NUM_SECU := V_secuencia;
  
end TRG_SEQ_SEC_G7000026;
/
