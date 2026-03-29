CREATE OR REPLACE TRIGGER SIM_TRG_SEC_SIM_CIRUGIA
  before insert on SIM_CIRUGIA
  for each row
declare
  v_secuencia number(17) := 0;
begin
   
    SELECT NVL(MAX(SECUENCIA), 0) + 1 
    INTO v_secuencia
    FROM SIM_CIRUGIA;
    :new.secuencia := v_secuencia;
    
end SIM_TRG_SEC_SIM_CIRUGIA;
/
