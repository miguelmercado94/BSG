CREATE OR REPLACE TRIGGER a5021600_a1000702
before
delete on a1000702
for each row
declare
cantidad number :=0;
begin
   select count(*) into cantidad
from a5021600
where cod_ofic_contab = :old.cod_agencia
or cod_ofic_cial = :old.cod_agencia
or cod_ofic_imput  = :old.cod_agencia;
if cantidad >  0 then
     raise_application_error( -20501,
     'Agencia con movimiento en a5021600 ');
end if;
end;
/
