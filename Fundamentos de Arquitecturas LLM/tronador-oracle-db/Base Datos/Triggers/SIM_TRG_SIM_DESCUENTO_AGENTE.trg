CREATE OR REPLACE TRIGGER SIM_TRG_SIM_DESCUENTO_AGENTE
  before insert on SIM_DESCUENTO_AGENTE
  for each row
declare
  v_cod_descuento number(17) := 0;
begin
   
    SELECT NVL(MAX(cod_descuento), 0) + 1 
    INTO v_cod_descuento
    FROM SIM_DESCUENTO_AGENTE;
    :new.cod_descuento := v_cod_descuento;
    
end SIM_TRG_SIM_DESCUENTO_AGENTE;
/
