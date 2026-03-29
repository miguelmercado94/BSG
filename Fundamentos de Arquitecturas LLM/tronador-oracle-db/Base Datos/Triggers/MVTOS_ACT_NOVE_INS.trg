CREATE OR REPLACE TRIGGER mvtos_act_nove_ins
after update
of clase_cartera
on mvtos_consolidados
for each row
begin
   if     :old.clase_cartera        <> :new.clase_cartera
   then sisgie.insenove (
     user                   ,:old.codigo_compania   ,:old.loc_radicacion      ,
    :old.abrev_aplicacion   ,:old.nro_identificacion,:old.negocio             ,
    'CLASE_CARTERA'         ,:old.clase_cartera     ,:new.clase_cartera       ,
    :old.certificado        ,:old.numero_factura    ,:old.tipo_garantia       );
   end if;
end;
/
