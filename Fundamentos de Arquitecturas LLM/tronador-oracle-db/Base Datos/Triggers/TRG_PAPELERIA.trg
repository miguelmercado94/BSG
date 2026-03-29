CREATE OR REPLACE TRIGGER TRG_PAPELERIA
  before insert or update on sim_convenio_seguros  
  for each row
declare
  -- local variables here
begin
  IF :NEW.TIPO_CONVENIO = 12 THEN
     :NEW.STOCK_PAPELERIA  := 30000;
     :NEW.tpo_rotacion_pap := 30;
     :NEW.tpo_inact_papel  := 30;
  END IF;   
  IF :NEW.TIPO_CONVENIO = 15 THEN
     :NEW.STOCK_PAPELERIA  := 1;
     :NEW.tpo_rotacion_pap := 1;
     :NEW.tpo_inact_papel  := 1;
  END IF;   
    
end TRG_PAPELERIA;
/
