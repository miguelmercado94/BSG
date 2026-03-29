CREATE OR REPLACE TRIGGER a5021103_a5021104b
before update on a5021103
for each row
declare
cantidad number :=0;

cursor op_tercero is
Select cod_cia,num_ord_pago
from A5021604
Where cod_benef = :old.numero_documento
and nvl(mca_est_pago,'X') = 'P';

begin

    for i in op_tercero loop

       update a5021104
       set tipo_documento = :new.tipo_documento,
           cod_entidad_destino = :new.cod_entidad_destino,
           numero_cta_destino = :new.numero_cta_destino,
           tipo_cta  = :new.tipo_cta,
           tdoc_tercero = :new.tdoc_tercero
       where cod_cia = i.cod_cia
       and num_ord_pago = i.num_ord_pago
	   and estado_transferencia not in (3);
                      
    end loop;
end;
/
