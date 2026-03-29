CREATE OR REPLACE TRIGGER sim_trg_biu_fondo_cuentas
  before insert on sim_fondo_cuentas
  for each row
declare
  -- local variables here
begin
  :new.id_tabla := SEQ_FONDO_SALDO.nextval;
  :NEW.FECHA:= SYSDATE;
  :NEW.USUARIO := USER;
end sim_trg_biu_fondo_cuentas;
/
