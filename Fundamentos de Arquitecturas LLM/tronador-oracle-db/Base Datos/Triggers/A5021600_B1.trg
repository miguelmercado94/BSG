CREATE OR REPLACE TRIGGER a5021600_B1
before
insert or update  on a5021600
for each row
begin
if :new.mca_caja_bco = 'B' and :new.cod_cia <> 7 then
begin
    declare
        cantidad number :=0;
    begin
       select count(*) into cantidad
       from a5022600
       where cod_cia = :new.cod_cia
         and  cod_cta_simplif = :new.cod_cta_simplif
         and  cod_cta_ctable =  :new.cod_cta_ctable
         and  mca_caja_bco = 'B'
         and  cod_mon = :new.cod_mon;
       if cantidad < 1 then
          raise_application_error(
          -20500, 'La Cuenta que esta ingresando no es de Bancos');
       end if;
   end;
end;
end if;
end;
/
