CREATE OR REPLACE TRIGGER SIM_TRG_A2000220
  before insert on A2000220
  for each row
declare
  V_secuencia number(17) := 0;
begin
   :new.secuencia := SIM_SEQ_SEG_CTRL_TECNICO.Nextval;
end SIM_TRG_A2000220;
/
