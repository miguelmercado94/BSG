CREATE OR REPLACE TRIGGER borra_sb
before
 delete on  a5021600
for each row
declare
cantidad number :=0;
begin
 if :old.cod_cia = 2  then
     begin
        select count(*)  into cantidad
        from a5020037
        where cod_cia = 2
        and nvl(mca_estado ,'A') = 'A';
     end;
     IF cantidad > 0  and :old.concepto  = '102'  then
        update sb_recaudo set
          valor_total_recaudado=  null,
                   estado_registro = 'OFD',
                   fecha_recaudo   =  null,
                   numero_recibo   = null
      where compania  = :old.cod_cia
      and numero_recibo = :old.recibo
       and estado_registro = 'RET'
     -- and tipo_recaudo in ('RPR','REX');
     and tipo_recaudo in ('RPR')
     and consecutivo = to_number(nvl(:old.dato_variable,consecutivo));
  end if;
  end if;
  end;
/
