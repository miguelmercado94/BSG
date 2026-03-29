CREATE OR REPLACE TRIGGER t_a5021604
before
insert  on a5021604
for each row
declare
cantidad number :=0;
begin
   select count(*) into cantidad
from dual
where 0 = nvl(:new.num_ord_pago,0);
if cantidad > 0 then
   raise_application_error(
-20500, 'Numero de Orden de Pago en Cero       ');
end if;
end;
/
