CREATE OR REPLACE TRIGGER a5021604_ADA
before
update  on a5021604
for each row
begin
declare



 begin
      if   UPDATING  THEN
    if nvl(:old.cod_cia,0) = 50 then
      if nvl(:new.mca_est_pago,'x') = 'T' then
        begin
           pbd_pagos_bolivar(:old.num_ord_pago,:new.num_cheque, 
                             :new.cod_banco,:old.cod_cia,null);
           EXCEPTION WHEN others THEN
           null;
        end;
      elsif   nvl(:new.mca_est_pago,'x') ='A' then
        begin   
        pbd_anula_pagos_bolivar(:old.num_ord_pago,:old.cod_cia);

        EXCEPTION WHEN others THEN
           null;
        end;
      end if;

     END IF;
      END IF;
end;
end;
/
