CREATE OR REPLACE TRIGGER "TR_BD_LOG_APORTES_PREVENCION"
       before delete
  on aportes_prevencion FOR EACH ROW
declare

begin

  INSERT INTO
  log_aportes_prevencion(cod_cia
                       ,cod_secc
                       ,cod_ramo
                       ,num_pol1
                       ,centro_trab
                       ,numero_factura
                       ,cod_benef
                       ,fech_pago
                       ,fech_equipo
                       ,total_trabaja
                       ,valor_aportes
                       ,valor_pagado
                       ,periodo_pago
                       ,num_planilla
                       ,num_secu_pol
             ,FECHA_APORTE_ELIMINA
                       )
                 VALUES(:OLD.cod_cia
                       ,:OLD.cod_secc
                       ,:OLD.cod_ramo
                       ,:OLD.num_pol1
                       ,:OLD.centro_trab
                       ,:OLD.numero_factura
                       ,:OLD.cod_benef
                       ,:OLD.fech_pago
                       ,:OLD.fech_equipo
                       ,:OLD.total_trabaja
                       ,:OLD.valor_aportes
                       ,:OLD.valor_pagado
                       ,:OLD.periodo_pago
                       ,:OLD.num_planilla
                       ,:OLD.num_secu_pol
             ,sysdate
                       );
end TR_BD_LOG_APORTES_PREVENCION;
/
