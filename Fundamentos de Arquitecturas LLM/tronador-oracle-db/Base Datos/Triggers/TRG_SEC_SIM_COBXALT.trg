CREATE OR REPLACE TRIGGER TRG_SEC_SIM_COBXALT
  before insert on SIM_COBXALT
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEC_SIM_COBXALT.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.secuencia := V_secuencia;

end TRG_SEC_SIM_COBXALT;
/
