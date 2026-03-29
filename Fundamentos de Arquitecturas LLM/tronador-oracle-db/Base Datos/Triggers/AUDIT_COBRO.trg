CREATE OR REPLACE TRIGGER audit_cobro
  BEFORE UPDATE OF cod_situacion ON a2990700
  FOR EACH ROW
BEGIN
  DECLARE
    vnumend  NUMBER;
    pnumend  NUMBER := :old.num_end;
    vfechai  DATE;
    vfechaf  DATE;
    vvalor   NUMBER;
    vfactren VARCHAR2(1);
  BEGIN
    --- HENRY LAGUNA  09-MAY-2012  SE ACTUALIZA TABLA DE RELACION MULTICOMPANIA
    IF nvl(:new.secuencia, 0) > 0 THEN  --JULIO ROMANI 22-OCT-2014 MANTIS 30055
      BEGIN
        UPDATE a502_multi_fac
           SET cod_situacion_lider = :new.cod_situacion
         WHERE cod_secc_lider = :old.cod_ramo
           AND cod_ramo_lider = :old.cod_ramo
           AND num_pol1_lider = :old.num_pol1
           AND num_factura_lider = :old.num_factura;
      END;
      BEGIN
        UPDATE a502_multi_fac
           SET cod_situacion_anexa = :new.cod_situacion
         WHERE cod_secc_anexa = :old.cod_ramo
           AND cod_ramo_anexa = :old.cod_ramo
           AND num_pol1_anexa = :old.num_pol1
           AND num_factura_anexa = :old.num_factura;
      END;
    END IF;
    IF :new.cod_situacion = 'CT' THEN
      UPDATE c2990001
         SET fecha_cobro = :new.fec_situ
       WHERE cod_ramo = :old.cod_ramo
         AND num_pol1 = :old.num_pol1
         AND num_factura = :old.num_factura;
      UPDATE c2000258
         SET fecha_factura = nvl(:new.fec_situ, trunc(SYSDATE)),estado = 'R'
       WHERE num_secu_pol = :old.num_secu_pol
         AND num_factura = :old.num_factura
         AND estado = 'P';
      IF SQL%NOTFOUND THEN
        SELECT num_end_ref, fecha_vig_fact, fecha_vto_fact, premio,
               decode(num_end,NULL,'S','N')
          INTO vnumend, vfechai, vfechaf, vvalor, vfactren
          FROM a2000163
         WHERE num_secu_pol = :old.num_secu_pol
           AND num_factura = :old.num_factura
           AND cod_agrup_cont = 'GENERICOS'
           AND tipo_reg = 'T'
           AND rownum <= 1;

        UPDATE c2000258
           SET fecha_factura = nvl(:new.fec_situ, trunc(SYSDATE)),
               estado        = 'R',
               num_factura   = :old.num_factura,
               valor_factura = vvalor
         WHERE num_secu_pol = :old.num_secu_pol
           AND num_end = vnumend
           AND estado = 'P'
           AND num_end_rev IS NULL
           AND nvl(num_factura, 0) = 0;
        IF (SQL%NOTFOUND OR (SQL%FOUND AND vfactren = 'S')) AND
           :old.imp_prima != 0 THEN
          UPDATE c2000258
             SET fecha_factura = nvl(:new.fec_situ, trunc(SYSDATE)),
                 estado        = 'R',
                 num_factura   = :old.num_factura,
                 valor_factura = :old.imp_prima
           WHERE num_secu_pol = :old.num_secu_pol
             AND estado = 'P'
             AND num_end_rev IS NULL
             AND nvl(num_factura, 0) = 0
             AND fecha_vig_end >= vfechai
             AND fecha_vig_end < vfechaf
             AND num_end <= vnumend;
          --ROWNUM <= 1;
        END IF;

      END IF;
    ELSIF :new.cod_situacion = 'EP' THEN
      IF nvl(:old.cod_situacion, 'XX') != 'XX' THEN
        UPDATE c2000258
           SET estado = 'P'
         WHERE num_secu_pol = :old.num_secu_pol
           AND num_factura = :old.num_factura
           AND fecha_liberacion IS NULL;
        IF SQL%NOTFOUND THEN
          INSERT INTO c2000258
            (cod_cia,
             cod_secc,
             cod_ramo,
             num_pol1,
             num_secu_pol,
             num_end,
             cod_agente,
             cod_benef,
             com_normal,
             mca_calculo,
             estado,
             tipo_servicio,
             fecha_equipo,
             num_end_rev,
             num_factura,
             fecha_factura,
             suma_aseg,
             prima_cob,
             mca_provisorio,
             lider,
             porc_part,
             nro_documto,
             tdoc_tercero,
             valor_factura,
             fecha_vig_pol,
             fecha_vig_end)
            SELECT cod_cia, cod_secc, cod_ramo, num_pol1, num_secu_pol, num_end, cod_agente, cod_benef, com_normal * -1, 'C', 'R', tipo_servicio, trunc(SYSDATE), num_end_rev, num_factura, trunc(SYSDATE), suma_aseg, prima_cob,
                   nvl(mca_provisorio,'N'), lider, porc_part, nro_documto, tdoc_tercero, valor_factura, fecha_vig_pol, fecha_vig_end
              FROM c2000258
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_factura = :old.num_factura;
          INSERT INTO c2000258
            (cod_cia,
             cod_secc,
             cod_ramo,
             num_pol1,
             num_secu_pol,
             num_end,
             cod_agente,
             cod_benef,
             com_normal,
             mca_calculo,
             estado,
             tipo_servicio,
             fecha_equipo,
             num_end_rev,
             num_factura,
             suma_aseg,
             prima_cob,
             mca_provisorio,
             lider,
             porc_part,
             nro_documto,
             tdoc_tercero,
             valor_factura,
             fecha_vig_pol,
             fecha_vig_end)
            SELECT cod_cia, cod_secc, cod_ramo, num_pol1, num_secu_pol, num_end, cod_agente, cod_benef, com_normal, 'C', 'P', tipo_servicio, trunc(SYSDATE), num_end_rev, num_factura, suma_aseg, prima_cob,
                   nvl(mca_provisorio,'N'), lider, porc_part, nro_documto, tdoc_tercero, valor_factura, fecha_vig_pol, fecha_vig_end
              FROM c2000258
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_factura = :old.num_factura
               AND estado = 'R';
        END IF;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
END;
/
