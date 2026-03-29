CREATE OR REPLACE TRIGGER TRG_BI_C8040100
  before insert on C8040100
  for each row
WHEN (new.cod_secc = 4)
declare
 Vconta number;
  -- local variables here
begin
 begin
  select count(*) into Vconta
   from c8040100
  where cod_secc = :new.cod_secc and
        cod_benef = :new.cod_benef;
 Exception when others then
     raise_application_error (-20010, 'No puede duplicar Registro C8040100');
 end;
 If Vconta > 0 then
     raise_application_error (-20020, 'No puede duplicar Registro C8040100');
 end if;
end TRG_BI_C8040100;
/
