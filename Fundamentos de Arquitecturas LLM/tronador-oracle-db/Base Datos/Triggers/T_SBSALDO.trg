CREATE OR REPLACE TRIGGER T_SBSALDO
before update  on sb_recaudo
for each row
begin
if :old.tipo_recaudo = 'REX'  and :old.estado_registro = 'RET'
      and :new.estado_registro = 'ANU' then
    begin
      update sb_saldo set  sumatoria_recaudos_periodo =
               nvl(sumatoria_recaudos_periodo,0) - :old.valor_total_recaudado
     where numero_poliza = :old.numero_poliza
      and nit_compania = :old.compania
     and seccion = :old.seccion
      and nvl(sumatoria_recaudos_periodo,0) > 0;
   end;
end if;
end;
/
