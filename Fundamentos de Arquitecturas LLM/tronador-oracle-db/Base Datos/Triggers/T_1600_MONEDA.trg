CREATE OR REPLACE TRIGGER t_1600_moneda
before
insert on a5021600
for each row
declare
cantidad number :=0;
begin
   if nvl(:new.cod_mon,0)   < 1 then

   raise_application_error(
-205001,'Moneda en cero');

  end if;
end;
/
