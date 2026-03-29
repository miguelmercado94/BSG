CREATE OR REPLACE TRIGGER a5021604_del
before
delete on a5021604
for each row
begin
  /*RPR 16/03/2011  Ajuste solicitado por Fabian Moreno y
    Leonardo Londono de auditoria */
 if :old.cod_cajero not in ('GAOADE12' ,'GRHASE03') then
 raise_application_error(
 -20500,'Error No puede Borrar Orden de pago := '|| to_char(:old.num_ord_pago));
end if;
end;
/
