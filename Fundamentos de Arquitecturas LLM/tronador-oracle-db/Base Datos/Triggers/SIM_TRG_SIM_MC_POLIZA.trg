CREATE OR REPLACE TRIGGER SIM_TRG_sim_mc_poliza
  before insert on Sim_Mc_Poliza
  for each row
declare
  V_secuencia number(17) := 0;
begin
   :new.secuencia := SIM_SEQ_SEG_CTRL_TECNICO.Nextval;
end SIM_TRG_sim_mc_poliza;
/
