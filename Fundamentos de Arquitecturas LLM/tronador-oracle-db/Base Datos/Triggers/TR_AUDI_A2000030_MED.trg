CREATE OR REPLACE TRIGGER tr_audi_a2000030_med
  AFTER DELETE OR UPDATE OR INSERT ON A2000030 
  FOR EACH ROW
WHEN (((old.cod_cia = 2) AND (old.cod_secc = 34))OR  ((new.cod_cia = 2) AND (new.cod_secc = 34)))
DECLARE
  -------------------------------------------------------------------------------
  -- Objetivo : insertar en la tabla SIM_CARGUE_NOV_TMP (Medico de Confianza)
  --            para actualizar la informacion en CURAM
  -- Autor    : Roxana Paola Capella Bermúdez
  -- Fecha    : Febrero 11 del 2016
  -- Modificado :
  -- 27/01/2017    Roxana Capella B.  Se agrega la función Sim_Pck_Nove_Curam.Fun_ReportaNove
  --                                  para que solo inserte novedades de polizas resportadas a
  --                                  curam.
  -------------------------------------------------------------------------------
  l_tipo_novedad sim_cargue_nov_tmp_med.tipo_novedad%TYPE;
  l_error        VARCHAR2(2000);
  l_anula        VARCHAR2(2);
BEGIN

  IF :new.cod_ramo = 88 THEN
    l_tipo_novedad := 'T';
  ELSE
    l_tipo_novedad := 'X'; --Pendiente de validar novedad
  END IF;

  IF inserting OR updating THEN
    IF ((:new.cod_cia = 2) AND (:new.cod_secc = 34)) THEN

      IF :new.num_pol1 IS NOT NULL THEN
        IF nvl(:new.mca_anu_pol, 'N') = 'S' THEN
          l_anula := 'S';
        ELSIF nvl(:new.tipo_end, '-1') = 'RE' THEN
          l_anula := 'R';
        ELSE
          l_anula := 'N';
        END IF;
        BEGIN

          UPDATE ops$puma.sim_cargue_nov_tmp_med
             SET mca_anu_pol    = l_anula,
                 fecha_vig_end  = nvl(:new.fecha_vig_end, fecha_vig_end),
                 fecha_venc_pol = nvl(:new.fecha_venc_pol, fecha_venc_pol),
                 tipo_documento = nvl(:new.tdoc_tercero, tipo_documento),
                 nro_documento  = nvl(:new.nro_documto, nro_documento),
                 num_pol        = nvl(:new.num_pol1, num_pol),
                 cod_ramo       = nvl(:new.cod_ramo, cod_ramo),
                 num_pol_flot   = nvl(:new.num_pol_flot, num_pol_flot),
                 cod_secc       = nvl(:new.cod_secc, cod_secc),
                 fec_anu_pol    = nvl(to_char(:new.fec_anu_pol,'dd/mm/yyyy'), fec_anu_pol),
                 fecha_novedad  = SYSDATE
           WHERE num_secu_pol = :new.num_secu_pol
             AND num_end = :new.num_end
             AND estado = 'PE';

          IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO ops$puma.sim_cargue_nov_tmp_med
              (secuencia,
               num_secu_pol,
               num_end,
               mca_anu_pol,
               fecha_vig_end,
               fecha_venc_pol,
               tipo_documento,
               nro_documento,
               num_pol,
               cod_ramo,
               num_pol_flot,
               tipo_novedad,
               cod_secc,
               cod_ries,
               estado,
               fec_anu_pol,
               fecha_novedad)
            VALUES
              (sim_seq_notmed.nextval,
               :new.num_secu_pol,
               :new.num_end,
               l_anula,
               :new.fecha_vig_end,
               :new.fecha_venc_pol,
               :new.tdoc_tercero,
               :new.nro_documto,
               :new.num_pol1,
               :new.cod_ramo,
               :new.num_pol_flot,
               l_tipo_novedad,
               :new.cod_secc,
               1,
               'PE',
               to_char(:new.fec_anu_pol,'dd/mm/yyyy'),
               SYSDATE);
          END IF;
          IF :new.num_pol_ant IS NOT NULL THEN
            DELETE sim_cargue_nov_tmp_med d
             WHERE d.num_pol = :new.num_pol_ant
               AND d.cod_secc = :new.cod_secc
               AND d.cod_ramo = :new.cod_ramo
               AND d.estado = 'PE';
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            l_error := 'TRIGGER A2000030 - ' || SQLERRM;
            INSERT INTO sim_error_med
              (secuencia, nombre_archivo, linea, fec_archivo, tipo_error, cod_ramo, num_pol, tipo_documto, nro_documto, cod_riesgo, error, usr_creacion, fec_cargue, origen, filtro)
            VALUES
              (sim_seq_errmed.nextval, NULL, NULL, trunc(SYSDATE), 'T', :new.cod_ramo, :new.num_pol1, :new.tdoc_tercero, :new.nro_documto, NULL, substr(l_error, 1, 2000), USER, NULL, 'BOL', 'NOV');
        END;

      END IF;
    END IF;
  ELSIF deleting THEN
    IF ((:old.cod_cia = 2) AND (:old.cod_secc = 34)) THEN
      sim_proc_log('ANTES prueba_a2000030', 'antes del if - numpol: ' || :old.num_pol1);
      IF ((:old.cod_secc = 34) AND (:old.num_pol1 IS NOT NULL)) THEN
        BEGIN
          DELETE sim_cargue_nov_tmp_med
           WHERE num_secu_pol = :old.num_secu_pol
             AND num_end = :old.num_end
             AND estado = 'PE';
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

        BEGIN
          sim_proc_log('ANTES prueba_a2000030', 'numpol: ' || :old.num_pol1);
          INSERT INTO sim_delend_med
            (num_pol, cod_ramo, cod_secc, num_end, cod_end, subcod_end, fecha_endoso, fecha_borrado, usuario)
          VALUES
            (:old.num_pol1, :old.cod_ramo, :old.cod_secc, :old.num_end, :old.cod_end, :old.sub_cod_end, :old.fecha_emi, SYSDATE, USER);
          sim_proc_log('despues prueba_a2000030', 'numpol: ' || :old.num_pol1);
        EXCEPTION
          WHEN OTHERS THEN
            sim_proc_log('prueba_a2000030', 'exception - numpol: ' || :old.num_pol1 || ' sqlerrm: ' || SQLERRM);
            NULL;
        END;
      END IF;
    END IF;
  END IF;
END tr_audi_a2000030_med;
/
