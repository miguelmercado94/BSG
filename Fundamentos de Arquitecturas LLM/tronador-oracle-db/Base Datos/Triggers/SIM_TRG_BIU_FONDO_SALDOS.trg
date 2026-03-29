CREATE OR REPLACE TRIGGER sim_trg_biu_fondo_saldos
  before insert on sim_fondo_saldos
  for each row
declare
  -- local variables here
begin
   :new.id_tabla := SEQ_FONDO_SALDO.nextval;
end sim_trg_biu_fondo_saldos;
/
