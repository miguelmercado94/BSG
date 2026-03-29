CREATE OR REPLACE TRIGGER sim_trg_bd_a3001700
  BEFORE DELETE OR UPDATE ON a3001700
  FOR EACH ROW
DECLARE

  l_usuario   VARCHAR2(2000);
  v_operacion VARCHAR2(130);
  -------------------------------------------------------------------------------
  -- Objetivo : Auditar el borrado y actualizacion de datos de tuplas en esta tabla
  -- Creado el  20200514 
  --
  ------------------------------------------------------------------------------
BEGIN

  IF deleting OR
     (updating AND
     ((:old.num_liq <> :new.num_liq AND nvl(:old.num_liq, 0) > 0) OR
     (:old.num_ord_pago <> :new.num_ord_pago AND nvl(:old.num_ord_pago, 0) > 0) OR
     (:old.cod_benef <> :new.cod_benef AND nvl(:old.cod_benef, 0) > 0) OR
     (:old.sec_tercero <> :new.sec_tercero AND nvl(:old.sec_tercero, 0) > 0))) THEN

      IF updating THEN
        v_operacion := 'Actualizo';
      ELSE
        v_operacion := 'Borro';
      END IF;
    
      SELECT sys_context('USERENV', 'OS_USER') INTO l_usuario FROM dual;
    
      v_operacion :=  v_operacion || ' - ' || l_usuario;
    
      v_operacion := substr(v_operacion, 1, 30);
    
      INSERT INTO a3001700_jn
        (cod_cia,
         cod_secc,
         num_sini,
         nro_exped,
         num_liq,
         cod_benef,
         cod_act_benef,
         ape_benef,
         nom_benef,
         fec_est_pago,
         cod_pago,
         cod_plan_pago,
         cod_mon_pago,
         cod_mon_liq,
         fecha_factura,
         fecha_liq,
         fecha_pago,
         tc,
         tc_pago,
         cod_concep_rva,
         mca_coaseg,
         imp_coaseg,
         total_bruto_liq,
         observacion,
         retencion,
         cod_causa_anu_liq,
         fecha_anu_liq,
         mca_cl90,
         num_secu_liq,
         mca_transit,
         cod_user_resp,
         num_autoriza,
         fec_autoriza,
         mca_autoriza,
         mca_term_ok,
         cod_user,
         fecha_equipo,
         num_juicio,
         cheq_nombre_de,
         sub_cod_texto,
         mca_impreso,
         mca_imp,
         mca_vuel,
         cod_texto,
         fec_equipo_pago,
         fec_equipo_anu,
         nodo_id,
         mca_transmit,
         iva,
         nro_factura,
         num_ord_pago,
         recibo,
         numero_liq,
         mca_contab,
         mca_cruce,
         vlr_iva_50,
         localida_factura,
         factura_exenta,
         activ_socioeconomica,
         tarifa,
         ica,
         con_iva_sim,
         tdoc_tercero,
         sec_tercero,
         suc_tercero,
         fecha_creacion,
         sim_sistema_origen,
         sim_id_canal,
         sim_usuario_creacion,
         sim_usuario_resp,
         vlr_cree,
         act_ciiu,
         tarifa_cree,
         sim_tipo_pago,
         sim_tdoc_terc_pago,
         sim_tercero_pago,
         sim_sec_tercero_pago,
         sim_suc_tercero_pago,
         num_liq_nv,
         num_ord_pago_nv,
         fecha_aud,
         operacion)
      VALUES
        (:old.cod_cia,
         :old.cod_secc,
         :old.num_sini,
         :old.nro_exped,
         :old.num_liq,
         :old.cod_benef,
         :old.cod_act_benef,
         :old.ape_benef,
         :old.nom_benef,
         :old.fec_est_pago,
         :old.cod_pago,
         :old.cod_plan_pago,
         :old.cod_mon_pago,
         :old.cod_mon_liq,
         :old.fecha_factura,
         :old.fecha_liq,
         :old.fecha_pago,
         :old.tc,
         :old.tc_pago,
         :old.cod_concep_rva,
         :old.mca_coaseg,
         :old.imp_coaseg,
         :old.total_bruto_liq,
         :old.observacion,
         :old.retencion,
         :old.cod_causa_anu_liq,
         :old.fecha_anu_liq,
         :old.mca_cl90,
         :old.num_secu_liq,
         :old.mca_transit,
         :old.cod_user_resp,
         :old.num_autoriza,
         :old.fec_autoriza,
         :old.mca_autoriza,
         :old.mca_term_ok,
         :old.cod_user,
         :old.fecha_equipo,
         :old.num_juicio,
         :old.cheq_nombre_de,
         :old.sub_cod_texto,
         :old.mca_impreso,
         :old.mca_imp,
         :old.mca_vuel,
         :old.cod_texto,
         :old.fec_equipo_pago,
         :old.fec_equipo_anu,
         :old.nodo_id,
         :old.mca_transmit,
         :old.iva,
         :old.nro_factura,
         :old.num_ord_pago,
         :old.recibo,
         :old.numero_liq,
         :old.mca_contab,
         :old.mca_cruce,
         :old.vlr_iva_50,
         :old.localida_factura,
         :old.factura_exenta,
         :old.activ_socioeconomica,
         :old.tarifa,
         :old.ica,
         :old.con_iva_sim,
         :old.tdoc_tercero,
         :old.sec_tercero,
         :old.suc_tercero,
         :old.fecha_creacion,
         :old.sim_sistema_origen,
         :old.sim_id_canal,
         :old.sim_usuario_creacion,
         :old.sim_usuario_resp,
         :old.vlr_cree,
         :old.act_ciiu,
         :old.tarifa_cree,
         :old.sim_tipo_pago,
         :old.sim_tdoc_terc_pago,
         :old.sim_tercero_pago,
         :old.sim_sec_tercero_pago,
         :old.sim_suc_tercero_pago,
         nvl(:new.num_liq,0),
         nvl(:new.num_ord_pago,0),
         SYSDATE,
         v_operacion);
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END sim_trg_bd_a3001700;
/
