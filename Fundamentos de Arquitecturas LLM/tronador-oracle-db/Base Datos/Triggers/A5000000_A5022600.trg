CREATE OR REPLACE TRIGGER a5000000_a5022600
before
update  of cod_cta_ctable on a5000000
for each row
declare
cantidad number :=0;
begin
   select count(*) into cantidad
from a5022600
where cod_cta_ctable = :new.cod_cta_ctable
and mca_banco = 'S';
if :new.cod_cta_ctable is not null then
  if cantidad < 1 then
     raise_application_error(
     -20500, 'Cuenta Contable no EXISTE o No es de Bancos');
  end if;
end if;
end;
/
