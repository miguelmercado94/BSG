CREATE OR REPLACE TRIGGER sim_trg_ad_factura_e
  AFTER DELETE ON A2000191 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  l_datos_fe  sim_typ_polizas_borradas_fe;
  l_resultado number(1);

  --***************************************************************************
  --Fecha: 11-08-2020
  --Autor: Sheila Uhia
  --Propósito: Guardar los datos de los impuestos borrados
  --            para uso de Facturación Electrónica
  --Proyecto: Facturación Electrónica
  --***************************************************************************
BEGIN

  if :old.tipo_reg = 'T' and :old.cod_agrup_cont = 'GENERICOS' then

    l_datos_fe                  := new sim_typ_polizas_borradas_fe();
    l_datos_fe.num_secu_pol     := :old.num_secu_pol;
    l_datos_fe.num_end          := :old.num_end;
    l_datos_fe.num_factura      := :old.num_factura;
    l_datos_fe.prima_prov       := :old.prima_prov;
    l_datos_fe.cod_impuesto     := :old.cod_impuesto;
    l_datos_fe.imp_impuesto     := :old.imp_impuesto;
    l_datos_fe.tasa_impuesto    := :old.tasa_impuesto;
    l_datos_fe.cod_agrup_cont   := :old.cod_agrup_cont;
    l_datos_fe.tipo_reg         := :old.tipo_reg;
    l_datos_fe.usuario_creacion := 'PROC_AUTOMATICO';

    sim_pck_factura_electronica.prc_insertar_imp_borrados(l_datos_fe,
                                                          'TRG',
                                                          l_resultado);

  end if;

  --Fin Facturación Electrónica
  --*************************************************
exception
  when others then
    null;
END;
/
