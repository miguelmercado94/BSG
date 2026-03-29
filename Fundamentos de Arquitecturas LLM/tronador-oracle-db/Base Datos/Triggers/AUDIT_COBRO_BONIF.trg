CREATE OR REPLACE TRIGGER audit_cobro_Bonif
  BEFORE UPDATE OF cod_situacion ON a2990700
  FOR EACH ROW
BEGIN
  /*Proyecto Optimizacion de Bonificaciones 19/07/2016 Stiven Benavides*/
  DECLARE
    vnumend  NUMBER;
    pnumend  NUMBER := :old.num_end;
    vfechai  DATE;
    vfechaf  DATE;
    vvalor   NUMBER;
    vfactren VARCHAR2(1);
    VL_ESQUEMA   VARCHAR(1); 
    Vl_NSP number;
  BEGIN
          SELECT num_end_ref, fecha_vig_fact, fecha_vto_fact, premio,
               decode(num_end,NULL,'S','N'),num_secu_pol
          INTO vnumend, vfechai, vfechaf, vvalor, vfactren,Vl_NSP
          FROM a2000163
         WHERE num_secu_pol = :old.num_secu_pol
           AND num_factura = :old.num_factura
           AND cod_agrup_cont = 'GENERICOS'
           AND tipo_reg = 'T'
           AND rownum <= 1;
       IF :new.cod_situacion = 'CT' THEN
     
            UPDATE c2000358
               SET fecha_pago_factura = nvl(:new.fec_situ, trunc(SYSDATE)),
                   estado = decode(tipo_pago,2,'R',estado)
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_factura = :old.num_factura
               AND ((estado = 'P' AND tipo_pago = 2) OR (tipo_pago = 1));
          IF SQL%NOTFOUND THEN
               UPDATE c2000358
               SET fecha_pago_factura = nvl(:new.fec_situ, trunc(SYSDATE)),
                   estado = decode(tipo_pago,2,'R',estado),
                   num_factura   = :old.num_factura
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_end = vnumend
               AND nvl(num_factura, 0) = 0
               AND ((estado = 'P' AND tipo_pago = 2) OR (tipo_pago = 1));
               
             IF SQL%NOTFOUND THEN
               UPDATE c2000358
               SET fecha_pago_factura = nvl(fecha_pago_factura, nvl(:new.fec_situ, trunc(SYSDATE))),
                  num_factura   = :old.num_factura
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_end = vnumend
               AND nvl(num_factura, 0) = 0
               AND estado = 'R' AND tipo_pago = 2;     
               
           IF (SQL%NOTFOUND OR (SQL%FOUND AND vfactren = 'S')) AND
               :old.imp_prima != 0 THEN
                 UPDATE c2000358
                 SET fecha_pago_factura = nvl(:new.fec_situ, trunc(SYSDATE)),
                     estado = decode(tipo_pago,2,'R',estado),
                     num_factura   = :old.num_factura
               WHERE num_secu_pol = :old.num_secu_pol
                 AND nvl(num_factura, 0) = 0
                 AND fecha_inicio_vig_bon >= vfechai
                 AND fecha_inicio_vig_bon < vfechaf
                 AND num_end <= vnumend
                 AND ((estado = 'P' AND tipo_pago = 2) OR (tipo_pago = 1));
              --ROWNUM <= 1;
           END IF;
         END IF;
      END IF;
    ELSIF :new.cod_situacion = 'EP' THEN
      IF nvl(:old.cod_situacion, 'XX') != 'XX' THEN
            UPDATE c2000358
               SET estado = decode(tipo_pago,2,'P', estado)
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_factura = :old.num_factura
               AND fecha_liberacion IS NULL;
           IF SQL%NOTFOUND THEN
                   INSERT INTO c2000358
                  (cod_cia,--1
                    cod_secc,--2
                    cod_ramo,--3
                    num_pol1,--4
                    num_secu_pol,--5
                    num_end,--6
                    cod_agente,--7
                    cod_benef,--8
                    con_normal,--9
                    --mca_calculo,--10
                    estado,--11
                    tipo_servicio,--12
                    fecha_equipo,--13
                    num_end_anterior,--14
                    num_pol_ant,
                    num_factura,--15
                    fecha_pago_nomina,--16
                    fecha_pago_factura,
                    prima_anu,--17
                    prima_endoso,--18
                    mca_provisorio,--19
                    lider,--20
                    porc_participacion,--21
                    --nro_documto,--22
                    tdoc_tercero,--23
                    fecha_inicio_vig_bon,--24
                    fecha_fin_vig_bon )--25
                    SELECT a.cod_cia,--1
                         a.cod_secc,--2
                         a.cod_ramo,--3
                         a.num_pol1,--4
                         a.num_secu_pol,--5
                         a.num_end,--6
                         a.cod_agente,--7
                         a.cod_benef,--8
                         a.con_normal * -1,--9
                  --       'C',--10
                         'R' estado,--11
                         tipo_servicio,--12
                         trunc(SYSDATE) fecha_equipo,--13
                         a.num_end_anterior,--14
                         a.num_pol_ant,
                         num_factura,--15
                         null,--16
                         a.fecha_pago_factura,
                         a.prima_anu,--17
                         a.prima_endoso,--18
                         nvl(mca_provisorio, 'N') mca_provisorio,--19
                         a.lider,--20
                         a.porc_participacion,--21
                        --a.cod_benef,--22
                         a.tdoc_tercero,--23
                         fecha_inicio_vig_bon,--24
                         fecha_fin_vig_bon--25
                  FROM c2000358 a
                  WHERE num_pol1 = :old.num_secu_pol
                        AND num_factura = :old.num_factura
                        AND tipo_pago = 2;

                        INSERT INTO c2000358
                          (cod_cia,--1
                           cod_secc,--2
                           cod_ramo,--3
                           num_pol1,--4
                           num_secu_pol,--5
                           num_end,--6
                           cod_agente,--7
                           cod_benef,--8
                           con_normal,--9
                           --mca_calculo,--10
                           estado,--11
                           tipo_servicio,--12
                           fecha_equipo,--13
                           num_end_anterior,--14
                           num_pol_ant,
                           num_factura,--15
                           prima_anu,--16
                           --prima_cob,--17
                           mca_provisorio,--18
                           lider,--19
                           porc_participacion,--20
                           --nro_documto,--21
                           tdoc_tercero,--22
                           --valor_factura,--23
                           fecha_inicio_vig_bon,--24
                           fecha_fin_vig_bon)--25
                          SELECT b.cod_cia,--1
                                 b.cod_secc,--2
                                 b.cod_ramo,--3
                                 b.num_pol1,--4
                                 b.num_secu_pol,--5
                                 b.num_end,--6
                                 b.cod_agente,--7
                                 b.cod_benef,--8
                                 b.con_normal,--9
                                 --'C',--10
                                 'P',--11
                                 b.tipo_servicio,--12
                                 trunc(SYSDATE)fecha_equipo,--13
                                 b.num_end_anterior,--14
                                 b.num_pol_ant,
                                 b.num_factura,--15
                                 b.prima_anu,--16
                                 --prima_cob,--17
                                 nvl(b.mca_provisorio, 'N')mca_provisorio,--18
                                 b.lider,--19
                                 b.porc_participacion,--20
                                 --b.nro_documto,--21
                                 b.tdoc_tercero,--22
                                 --valor_factura,--23
                                 b.fecha_inicio_vig_bon ,--24
                                 b.fecha_fin_vig_bon--25
                          FROM c2000358 b
                          WHERE num_secu_pol = :old.num_secu_pol
                                AND num_factura = :old.num_factura
                                AND estado = 'R'
                                AND tipo_pago = 2;
        END IF;
      ELSIF nvl(:old.cod_situacion, 'XX') = 'XX' THEN
        UPDATE c2000358
               SET  num_factura   = :new.num_factura
             WHERE num_secu_pol = :old.num_secu_pol
               AND num_end = vnumend
               AND nvl(num_factura,0) = 0;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
END;
/
