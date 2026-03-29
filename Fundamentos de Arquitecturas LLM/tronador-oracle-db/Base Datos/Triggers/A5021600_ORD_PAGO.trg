CREATE OR REPLACE TRIGGER a5021600_ord_pago
before
insert or update on a5021600
for each row
begin
if :new.tipo_actu = 'PV' and  nvl(:new.num_ord_pago,0) between 9999999 and
                              9999999999999 then
        if nvl(:new.num_ord_pago,0) > 99999999999  then
             if substr(:new.num_ord_pago,5,2) not in (97,98,99) then
                raise_application_error(
               -20519,'Error en numeracion de Orden de pago := '||
                to_char(:new.num_ord_pago));
            end if;
        else
        raise_application_error(
         -20519,'Error en numeracion de Orden de pago := '|| to_char(:new.num_ord_pago));
    end if;
end if;
end;
/
