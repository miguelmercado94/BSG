CREATE OR REPLACE TRIGGER trg_a5020301
before
insert  on a5020301
for each row
declare
cantidad number :=0;
begin
if :new.recibo =   4652294 then
  raise_application_error(
-20600, '(Error al insertar en tabla a5020301) llamar urgente a Marco Aponte');
end if;

end;
/
