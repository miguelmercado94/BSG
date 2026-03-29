CREATE OR REPLACE TRIGGER TRG_SEQ_SIMAPI_PARAM_EST
  before insert on simapi_parametros_estrategia
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEQ_SIMAPI_PARAM_EST.Nextval
     Into   V_secuencia
     from   dual;
  End;  

  :new.secuencia := V_secuencia;
  
end TRG_SEQ_SIMAPI_PARAM_EST;
/
