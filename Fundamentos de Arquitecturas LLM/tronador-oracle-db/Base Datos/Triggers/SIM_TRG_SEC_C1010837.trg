CREATE OR REPLACE TRIGGER SIM_TRG_SEC_C1010837
  before insert on C1010837
  for each row
declare
  v_secuencia number(17) := 0;
begin

    SELECT NVL(MAX(SECUENCIA), 0) + 1
    INTO v_secuencia
    FROM C1010837;
    :new.secuencia := v_secuencia;

end SIM_TRG_SEC_C1010837;
/
