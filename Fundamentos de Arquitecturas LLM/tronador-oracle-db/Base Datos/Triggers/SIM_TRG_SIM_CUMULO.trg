CREATE OR REPLACE TRIGGER SIM_TRG_SIM_CUMULO
  before insert on SIM_CUMULO
  for each row
declare
  v_cod_cumulo number(17) := 0;
begin
   
    SELECT NVL(MAX(cod_cumulo), 0) + 1 
    INTO v_cod_cumulo
    FROM SIM_CUMULO;
    :new.cod_cumulo := v_cod_cumulo;
    
end SIM_TRG_SIM_CUMULO;
/
