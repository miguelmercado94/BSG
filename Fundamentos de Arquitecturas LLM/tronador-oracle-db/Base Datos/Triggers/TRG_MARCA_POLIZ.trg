CREATE OR REPLACE TRIGGER TRG_MARCA_POLIZ
  before insert on sim_conecta_marca_cotiz  
  for each row
begin
  :new.id_marca_cotiz := seq_id_marca_cotiz.nextval;
  :new.fecha_insercion := sysdate;  
end TRG_MARCA_POLIZ;
/
