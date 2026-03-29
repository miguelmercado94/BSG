CREATE OR REPLACE TRIGGER trg_bIU_g9003301
before
insert ON g9003301 for each row
declare
  wsecuencia number :=0;
begin
  select SEQ_OBJ_FUNC.nextval
    into  wsecuencia
    from dual;
  :new.secuencia:= wsecuencia;
end;
/
