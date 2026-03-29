CREATE OR REPLACE TRIGGER SIM_TRG_SEC_SIM_OCUPACION
  before insert on SIM_OCUPACION
  for each row
declare
  v_secuencia number(17) := 0;
begin
   
    SELECT NVL(MAX(SECUENCIA), 0) + 1 
    INTO v_secuencia
    FROM SIM_OCUPACION;
    :new.secuencia := v_secuencia;
    
end SIM_TRG_SEC_SIM_OCUPACION;
/
