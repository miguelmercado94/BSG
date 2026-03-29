CREATE OR REPLACE TRIGGER TRG_INC_C2701000
  after INSERT OR UPDATE OR DELETE
  on C2701000
  for each row
begin
  if INSERTING then 
    PCK_INC_C2701000.procesa_trigger (:new.ROWID, 'INS');
  elsif UPDATING then
    PCK_INC_C2701000.procesa_trigger (:old.ROWID, 'UPD');
  elsif DELETING then
    PCK_INC_C2701000.procesa_trigger (:old.ROWID, 'DEL');
  end if; 
EXCEPTION
  WHEN OTHERS THEN
    null;
end TRG_INC_C2701000
;
/
