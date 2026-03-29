CREATE OR REPLACE TRIGGER TRG_AUDIT_COTIZ
  before insert on sim_conecta_audit_cotiz  
  for each row
begin
  :new.id_audit_cotiz := seq_id_audit_cotiz.nextval;
  :new.fecha_ejecucion := sysdate;  
end TRG_AUDIT_COTIZ;
/
