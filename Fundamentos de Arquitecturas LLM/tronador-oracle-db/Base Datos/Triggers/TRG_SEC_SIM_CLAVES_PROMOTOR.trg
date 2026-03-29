CREATE OR REPLACE TRIGGER TRG_SEC_SIM_CLAVES_PROMOTOR
  before insert on SIM_CLAVES_PROMOTOR
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEC_SIM_CLAVES_PROMOTOR.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.secuencia := V_secuencia;

end TRG_SEC_SIM_CLAVES_PROMOTOR;
/
