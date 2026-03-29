CREATE OR REPLACE TRIGGER sim_trg_sec_CONDIPOL
  before insert on SIM_CONDICIONES_POLIZA
  for each row
declare
  v_secuencia number(17) := 0;

begin
    SELECT SIM_SEQ_CONDICIONPOL.NEXTVAL
    into v_secuencia FROM DUAL;
    :new.Id_secuencia := v_secuencia;

end sim_trg_sec_CONDIPOL;
/
