CREATE OR REPLACE TRIGGER t_a5021604_neg
before
insert  on a5021604
for each row
declare
cantidad number :=0;
begin
   select count(*) into cantidad
from dual
where  nvl(:new.imp_mon_pais,0) < 0;
if cantidad > 0 then
   raise_application_error(
-20500, 'Orden de Pago  con valores negativos  ');
end if;
end;
/
