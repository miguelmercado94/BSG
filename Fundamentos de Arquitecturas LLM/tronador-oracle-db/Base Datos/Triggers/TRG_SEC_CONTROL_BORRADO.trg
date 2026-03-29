CREATE OR REPLACE TRIGGER TRG_SEC_CONTROL_BORRADO
  before insert on SIM_BORRADO_AUTOMATICO
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEC_CONTROL_BORRADO.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.id_control := V_secuencia;

end TRG_SEC_CONTROL_BORRADO;
/
