CREATE OR REPLACE TRIGGER SIM_TRG_SEC_C1010819
  before insert on C1010819
  for each row
declare
  v_secuencia number(17) := 0;
begin

    SELECT NVL(MAX(SECUENCIA), 0) + 1
    INTO v_secuencia
    FROM C1010819;
    :new.secuencia := v_secuencia;

end SIM_TRG_SEC_C1010819;
/
