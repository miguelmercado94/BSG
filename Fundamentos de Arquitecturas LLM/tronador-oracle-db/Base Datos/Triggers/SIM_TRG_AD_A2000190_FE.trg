CREATE OR REPLACE TRIGGER sim_trg_ad_a2000190_fe
  AFTER DELETE ON A2000190 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  l_datos_fe  sim_typ_polizas_borradas_fe;
  l_resultado number(1);

  --***************************************************************************
  --Fecha: 28-08-2020
  --Autor: Sheila Uhia
  --Propósito: Guardar los datos de los impuestos totales borrados
  --            para uso de Facturación Electrónica
  --Proyecto: Facturación Electrónica
  --***************************************************************************
BEGIN

  if :old.tipo_reg = 'T' then

    l_datos_fe := new sim_typ_polizas_borradas_fe();

    l_datos_fe.num_secu_pol     := :old.num_secu_pol;
    l_datos_fe.num_end          := :old.num_end;
    l_datos_fe.cod_impuesto     := :old.cod_impuesto;
    l_datos_fe.imp_impuesto     := :old.imp_impuesto;
    l_datos_fe.imp_impuesto_e   := :old.imp_impuesto_e;
    l_datos_fe.prima_prov       := :old.prima_prov;
    l_datos_fe.prima_prov_e     := :old.prima_prov_e;
    l_datos_fe.tasa_impuesto    := :old.tasa_impuesto;
    l_datos_fe.tasa_impuest_e   := :old.tasa_impuest_e;
    l_datos_fe.prima_prov_anu   := :old.prima_prov_anu;
    l_datos_fe.prima_prov_anu_e := :old.prima_prov_anu_e;
    l_datos_fe.tipo_reg         := :old.tipo_reg;
    l_datos_fe.usuario_creacion := 'PROC_AUTOMATICO';

    sim_pck_factura_electronica.prc_insertar_impt_borrados(l_datos_fe,
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
