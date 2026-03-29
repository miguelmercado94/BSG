CREATE OR REPLACE TRIGGER tr_audi_a2000020_med
  BEFORE DELETE OR INSERT OR UPDATE OF valor_campo, mca_baja_ries ON A2000020 
  FOR EACH ROW
WHEN (new.cod_campo = 'DESC_RIES' OR new.cod_campo = 'COD_BENE' OR new.cod_campo = 'COD_ASEG' OR new.cod_campo = 'COD_DOCUM' OR new.cod_campo = 'TIPO_DOC_ASEG' OR new.cod_campo = 'SEXO' OR
       new.cod_campo = 'FECHA_NACIMIEN' OR new.cod_campo = 'PARENTESCO' OR new.cod_campo = 'FEC_INGRESO' OR new.cod_campo = 'OPCION_POLIZA' OR new.cod_campo = 'MED_CONF_ASEG')
DECLARE
  ---------------------------------------------------------------------------------------------
  -- Objetivo : insertar en la tabla SIM_CARGUE_NOV_TMP (Medico de Confianza)
  --            para actualizar la informacion en CURAM
  -- Autor    : Roxana Paola Capella Bermúdez
  -- Fecha    : Febrero 11 del 2016
  -- Modificado :
  -- 27/01/2017    Roxana Capella B.  Se agrega la función Sim_Pck_Nove_Curam.Fun_ReportaNove
  --                                  para que solo inserte novedades de polizas resportadas a
  --                                  curam.  
  ---------------------------------------------------------------------------------------------
  l_pol1         sim_cargue_nov_tmp_med.num_pol%TYPE;
  l_secc         sim_cargue_nov_tmp_med.cod_secc%TYPE;
  l_ramo         sim_cargue_nov_tmp_med.cod_ramo%TYPE;
  l_numpolflot   sim_cargue_nov_tmp_med.num_pol_flot%TYPE;
  l_coddocum     sim_cargue_nov_tmp_med.cod_docum%TYPE;
  l_codbene      sim_cargue_nov_tmp_med.cod_bene%TYPE;
  l_descries     sim_cargue_nov_tmp_med.desc_ries%TYPE;
  l_sexo         sim_cargue_nov_tmp_med.sexo%TYPE;
  l_fecnac       sim_cargue_nov_tmp_med.fecha_nacimien%TYPE;
  l_parentesco   sim_cargue_nov_tmp_med.parentesco%TYPE;
  l_fecingr      sim_cargue_nov_tmp_med.fec_ingreso%TYPE;
  l_opcpoliza    sim_cargue_nov_tmp_med.opcion_pol%TYPE;
  l_mcabajaries  sim_cargue_nov_tmp_med.mca_baja_ries%TYPE;
  l_fechavencpol a2000030.fecha_venc_pol%TYPE;
  l_error        VARCHAR2(2000);
  l_tiponovedad  VARCHAR2(2);
  l_medconf      VARCHAR2(2);
  l_novedad      VARCHAR2(2);
BEGIN
  BEGIN
    SELECT a.num_pol1, a.cod_secc, a.cod_ramo, a.num_pol_flot, a.fecha_venc_pol
      INTO l_pol1, l_secc, l_ramo, l_numpolflot, l_fechavencpol
      FROM a2000030 a
     WHERE num_secu_pol = :new.num_secu_pol
       AND cod_secc = 34
       AND num_end = (SELECT MAX(num_end) FROM a2000030 b WHERE b.num_secu_pol = a.num_secu_pol);
  EXCEPTION
    WHEN OTHERS THEN
      l_pol1 := NULL;
      l_secc := NULL;
  END;
  IF (inserting OR updating) AND l_secc = 34 THEN
  
    DELETE sim_cargue_nov_tmp_med d
     WHERE d.num_secu_pol = :new.num_secu_pol
       AND d.cod_ries = nvl(:new.cod_ries, 0)
       AND d.num_end < :new.num_end
       AND d.estado = 'PE';
  
    l_coddocum    := NULL;
    l_codbene     := NULL;
    l_descries    := NULL;
    l_sexo        := NULL;
    l_fecnac      := NULL;
    l_parentesco  := NULL;
    l_fecingr     := NULL;
    l_opcpoliza   := NULL;
    l_mcabajaries := NULL;
    /*rcb: Se agrega la función Sim_Pck_Nove_Curam.Fun_ReportaNove para que solo inserte novedades de polizas
    resportadas a curam.*/
    l_novedad := sim_pck_nove_curam.fun_reportanove(:new.num_secu_pol);
  
    --DBMS_OUTPUT.PUT_LINE('VALOR COD_CAMPO:'|| :NEW.COD_CAMPO||' - '||:NEW.VALOR_CAMPO);
    CASE :new.cod_campo
      WHEN 'DESC_RIES' THEN
        l_descries := :new.valor_campo;
      WHEN 'COD_BENE' THEN
        l_codbene := :new.valor_campo;
      WHEN 'COD_ASEG' THEN
        l_codbene := :new.valor_campo;
      WHEN 'COD_DOCUM' THEN
        l_coddocum := :new.valor_campo;
      WHEN 'TIPO_DOC_ASEG' THEN
        l_coddocum := :new.valor_campo;
      WHEN 'SEXO' THEN
        l_sexo := :new.valor_campo;
      WHEN 'FECHA_NACIMIEN' THEN
        l_fecnac := :new.valor_campo;
      WHEN 'PARENTESCO' THEN
        l_parentesco := :new.valor_campo;
      WHEN 'FEC_INGRESO' THEN
        l_fecingr := :new.valor_campo;
      WHEN 'OPCION_POLIZA' THEN
        l_opcpoliza := :new.valor_campo;
      WHEN 'MED_CONF_ASEG' THEN
        l_medconf := :new.valor_campo;
    END CASE;
    IF nvl(l_novedad, 'N') != 'S' AND (l_ramo = 88 AND :new.cod_campo = 'MED_CONF_ASEG' AND :new.valor_campo = 'S') THEN
      l_tiponovedad := 'T'; --pendiente de validar tesoreria
    ELSIF nvl(l_novedad, 'N') = 'S' AND :new.cod_nivel = 1 THEN
      l_tiponovedad := 'P';
    ELSIF l_novedad = 'S' THEN
      l_tiponovedad := 'N';
    ELSE
      l_tiponovedad := 'X'; --Pendiente de validar novedad
    END IF;
  
    IF nvl(:new.mca_baja_ries, 'N') != nvl(:old.mca_baja_ries, 'N') AND :new.cod_campo = 'MED_CONF_ASEG' THEN
      l_mcabajaries := nvl(:new.mca_baja_ries, 'N');
    ELSIF :new.cod_campo = 'MED_CONF_ASEG' AND :new.valor_campo = 'N' THEN
      l_tiponovedad := 'X'; --Pendiente de validar novedad
      l_mcabajaries := 'S';
    ELSE
      l_mcabajaries := 'N';
    END IF;
  
    UPDATE sim_cargue_nov_tmp_med d
       SET cod_docum      = nvl(l_coddocum, cod_docum),
           cod_bene       = nvl(l_codbene, cod_bene),
           desc_ries      = nvl(l_descries, desc_ries),
           sexo           = nvl(l_sexo, sexo),
           fecha_nacimien = nvl(l_fecnac, fecha_nacimien),
           parentesco     = nvl(l_parentesco, parentesco),
           fec_ingreso    = nvl(l_fecingr, fec_ingreso),
           opcion_pol     = nvl(l_opcpoliza, opcion_pol),
           mca_baja_ries  = nvl(l_mcabajaries, mca_baja_ries),
           tipo_novedad   = decode(tipo_novedad,'T',tipo_novedad,l_tiponovedad),
           fecha_novedad  = SYSDATE
     WHERE d.num_secu_pol = :new.num_secu_pol
       AND d.cod_ries = nvl(:new.cod_ries, 0)
       AND d.num_end = :new.num_end
       AND d.estado = 'PE';
  
    IF SQL%ROWCOUNT = 0 THEN
    
      IF (l_pol1 IS NOT NULL AND l_novedad = 'S') OR (l_ramo = 88 AND :new.cod_campo = 'MED_CONF_ASEG') THEN
      
        IF ((:new.cod_campo = 'DESC_RIES') OR (:new.cod_campo = 'COD_BENE') OR (:new.cod_campo = 'COD_ASEG') OR (:new.cod_campo = 'COD_DOCUM') OR (:new.cod_campo = 'TIPO_DOC_ASEG') OR (:new.cod_campo = 'SEXO') OR
           (:new.cod_campo = 'FECHA_NACIMIEN') OR (:new.cod_campo = 'PARENTESCO') OR (:new.cod_campo = 'FEC_INGRESO') OR (:new.cod_campo = 'OPCION_POLIZA') OR (:new.cod_campo = 'MED_CONF_ASEG')) THEN
        
          BEGIN
          
            INSERT INTO sim_cargue_nov_tmp_med
              (secuencia,
               num_secu_pol,
               cod_ries,
               num_end,
               cod_docum,
               cod_bene,
               desc_ries,
               sexo,
               fecha_nacimien,
               parentesco,
               fec_ingreso,
               opcion_pol,
               mca_baja_ries,
               num_pol,
               cod_secc,
               cod_ramo,
               estado,
               num_pol_flot,
               fecha_novedad,
               fecha_venc_pol,
               tipo_novedad)
            VALUES
              (sim_seq_notmed.nextval,
               :new.num_secu_pol,
               nvl(:new.cod_ries, 0),
               :new.num_end,
               l_coddocum,
               l_codbene,
               l_descries,
               l_sexo,
               l_fecnac,
               l_parentesco,
               l_fecingr,
               l_opcpoliza,
               l_mcabajaries,
               l_pol1,
               l_secc,
               l_ramo,
               'PE',
               l_numpolflot,
               SYSDATE,
               l_fechavencpol,
               l_tiponovedad);
          
          EXCEPTION
            WHEN OTHERS THEN
              l_error := 'TRIGGER A2000020 - ' || SQLERRM;
              INSERT INTO sim_error_med
                (secuencia, nombre_archivo, linea, fec_archivo, tipo_error, cod_ramo, num_pol, tipo_documto, nro_documto, cod_riesgo, error, usr_creacion, fec_cargue, origen, filtro)
              VALUES
                (sim_seq_errmed.nextval, NULL, NULL, trunc(SYSDATE), 'T', l_ramo, l_pol1, l_coddocum, l_codbene, nvl(:new.cod_ries, 0), substr(l_error, 1, 2000), USER, NULL, 'BOL', 'NOV');
          END;
        END IF;
      END IF;
    END IF;
  ELSIF deleting THEN
    BEGIN
      DELETE sim_cargue_nov_tmp_med
       WHERE num_secu_pol = :old.num_secu_pol
         AND num_end = :old.num_end
         AND estado = 'PE';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;
END tr_audi_a2000020_med;
/
