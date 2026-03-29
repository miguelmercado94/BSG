CREATE OR REPLACE TRIGGER TRG_SEQ_SIMAPI_CTRL_PKS_DOCS
  before insert on SIMAPI_CTRL_PKS_DOCS
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEQ_SIMAPI_CONTROL_COB.Nextval
     Into   V_secuencia
     from   dual;
  End;  

  :new.ID_SECUENCIA := V_secuencia;
  
end TRG_SEQ_SIMAPI_CTRL_PKS_DOCS;
/
