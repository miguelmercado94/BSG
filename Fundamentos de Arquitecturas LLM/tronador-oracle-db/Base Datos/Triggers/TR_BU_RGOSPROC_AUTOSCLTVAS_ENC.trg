CREATE OR REPLACE TRIGGER tr_bu_rgosproc_autoscltvas_enc
    BEFORE UPDATE OF rgos_procesados ON sim_x_autos_cltvas_enc
    FOR EACH ROW 
DECLARE
    l_estado_email      sim_x_autos_cltvas_enc.estado_email%TYPE;
    l_error             VARCHAR2(1) := NULL;
    l_es_asincrono      BOOLEAN := FALSE;
    l_cuenta_rgos_no_ok NUMBER;
    l_cuenta_rgos_ok    NUMBER;
    l_arrerrores        sim_typ_array_error;
     CURSOR c_busca_rgos IS
        SELECT orden,placa
          FROM sim_x_autos_cltvas_det_rgo rgo
         WHERE rgo.num_negociacion = :old.num_negociacion
           AND rgo.id_transaccion = :old.id_transaccion
           AND rgo.fecha_baja IS NULL
           AND rgo.mca_procesado = 0
           ORDER BY orden;
BEGIN
    l_arrerrores := NEW sim_typ_array_error();
    
	-- obtener cantidades de riesgos con error y sin error
	BEGIN
		SELECT 
			COUNT(CASE WHEN rgo.mca_procesado = 0 THEN 1 END) as l_cuenta_rgos_no_ok,
			COUNT(CASE WHEN rgo.mca_procesado = 1 THEN 1 END) as l_cuenta_rgos_ok
		INTO 
			l_cuenta_rgos_no_ok,
			l_cuenta_rgos_ok
		FROM sim_x_autos_cltvas_det_rgo rgo
		WHERE rgo.num_negociacion = :old.num_negociacion
			AND rgo.id_transaccion = :old.id_transaccion
			AND rgo.fecha_baja IS NULL;
	EXCEPTION
		WHEN OTHERS THEN
			dbms_output.put_line(SQLCODE || SQLERRM);
	END;
	
    IF :new.rgos_procesados = 0 AND nvl(:old.rgos_procesados, 0) != 0 THEN
        :new.rgos_procesados := :old.rgos_procesados;
    END IF;
    
	--
    l_es_asincrono := :old.cant_registros_rgos > sim_pck_autos_cltvas_servicios.c_limite_sincrono;
    --
	
	-- Escenario Ideal
	IF :new.rgos_procesados = :old.cant_registros_rgos THEN
		IF :old.mca_finalizado = 'P' THEN
			:new.mca_finalizado := 'F';
			l_error             := sim_pck_tipos_generales.c_no;
		END IF;
	--Escenario 2: Procesó todos los riesgos pero algunos con error.
	ELSIF :new.rgos_procesados < :old.cant_registros_rgos AND l_cuenta_rgos_no_ok + l_cuenta_rgos_ok = :old.cant_registros_rgos THEN
		IF :old.mca_finalizado = 'P' THEN
			:new.mca_finalizado := 'F';
			l_error             := sim_pck_tipos_generales.c_si;
		END IF;
	END IF;

	IF l_error IS NOT NULL THEN
		IF l_cuenta_rgos_no_ok > 0 AND l_cuenta_rgos_no_ok <= (:old.cant_registros_rgos * 0.1) THEN
			UPDATE SIM_X_AUTOS_CLTVAS_DET_RGO
               SET MCA_PROCESADO = 1
             WHERE NUM_NEGOCIACION = :old.num_negociacion
               AND ID_TRANSACCION = :old.id_transaccion
               AND MCA_PROCESADO = 0
               AND FECHA_BAJA IS NULL;
			
			--los procesados con error se cambiaron a no error, entoncs procesados ahora es igual al total de registros
			:new.rgos_procesados := :old.cant_registros_rgos;
			
			l_error := sim_pck_tipos_generales.c_no;
		END IF;
		
		IF l_es_asincrono THEN
		
			--09/11/2018 lberbesi: Se incluyen los riesgos en mensaje de error
			IF l_error = sim_pck_tipos_generales.c_si THEN
			   FOR c1 IN c_busca_rgos LOOP
				 l_arrerrores.extend;
				 l_arrerrores(l_arrerrores.count) := sim_typ_error(SQLCODE, 'Riesgo ' || c1.orden || '-' || 'Placa: ' || c1.placa,'E');
			   END LOOP;
			END IF;
		
			sim_pck999_cltvas_autos.proc_envia_email(ip_nronegociacion => :new.num_negociacion --
													,ip_idtransaccion  => :new.id_transaccion
													,ip_error          => l_error
													,ip_paso           => :new.id_paso
													,op_estadoemail    => l_estado_email
													,ip_arrerrores     => l_arrerrores);
			:new.estado_email := l_estado_email;
		END IF;
	END IF;
EXCEPTION
    WHEN OTHERS THEN
        sim_pck_autos_cltvas_servicios.proc_graba_errores(ip_ubicacion       => 'TR_AU_RGOSPROC_AUTOSCLTVAS_ENC'
                                                         ,ip_msg_error       => 'NEGO ' || :new.num_negociacion || 'TX ' || :new.id_transaccion || ' Errores ' || SQLERRM ||
                                                                                dbms_utility.format_error_backtrace()
                                                         ,ip_msg_stack_error => dbms_utility.format_error_stack());
END tr_bu_rgosproc_autoscltvas_enc;
/