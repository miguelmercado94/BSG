CREATE OR REPLACE TRIGGER TRG_INC_A2000163
  after INSERT OR UPDATE OR DELETE
  on A2000163
  for each row
DISABLE
begin
  if INSERTING then 
    PCK_INC_A2000163.procesa_trigger (:new.ROWID, 'INS');
  elsif UPDATING then
    PCK_INC_A2000163.procesa_trigger (:old.ROWID, 'UPD');
  elsif DELETING then
    PCK_INC_A2000163.procesa_trigger (:old.ROWID, 'DEL');
  end if; 
EXCEPTION
  WHEN OTHERS THEN
    null;
end TRG_INC_A2000163
;
/
