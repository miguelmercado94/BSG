CREATE OR REPLACE TRIGGER sim_cu_trg_registra_tiempo
    BEFORE INSERT OR UPDATE OF nivel_aut ON a2000220
    FOR EACH ROW
DECLARE
    l_cons_temp NUMBER;
    c_cod_cia  CONSTANT NUMBER(3) := 3;
    c_cod_secc CONSTANT NUMBER(3) := 4;
BEGIN
    CASE
        WHEN inserting THEN
            -- 1. como se crea el control téncico, entonces insertamos sobre la tabla.
            IF :new.cod_cia = c_cod_cia AND :new.nivel_aut BETWEEN 41 AND 47 THEN
                INSERT INTO sim_cu_bitacora_tiempos_ma
                    (id_bitacora
                    ,cons_tiempo
                    ,cod_cia
                    ,cod_secc
                    ,num_secu_pol
                    ,num_end
                    ,cod_nivel_pre
                    ,cod_error_pre
                    ,cod_rechazo_pre
                    ,dsnivel_pre
                    ,cod_sist_pre
                    ,tiempo_inicio)
                VALUES
                    (sim_cu_seq_bitacora_ma.nextval
                    ,fcn999_cons_tiempo_ma(ip_num_secu_pol => :new.num_secu_pol,
                                           ip_num_end      => :new.num_orden,
                                           ip_cod_error    => :new.cod_error)
                    ,:new.cod_cia
                    ,c_cod_secc
                    ,:new.num_secu_pol
                    ,:new.num_orden
                    ,:new.nivel_aut
                    ,:new.cod_error
                    ,:new.cod_rechazo
                    ,:new.dsnivel
                    ,:new.cod_sist
                    ,SYSDATE);
            END IF;
        WHEN updating THEN
            -- 1. Cuando se escala el control técnico
            -- 1.1. Actualización de control técnico anterior.
            IF :new.cod_cia = c_cod_cia AND :new.nivel_aut BETWEEN 41 AND 47 THEN
                DECLARE
                    l_aux          DATE;
                    l_tiempo_ahora DATE := SYSDATE;
                BEGIN
                    SELECT ma.tiempo_inicio
                          ,ma.cons_tiempo
                      INTO l_aux
                          ,l_cons_temp
                      FROM sim_cu_bitacora_tiempos_ma ma
                     WHERE ma.cod_cia = :old.cod_cia
                       AND ma.cod_secc = c_cod_secc
                       AND ma.num_secu_pol = :old.num_secu_pol
                       AND ma.num_end = :old.num_orden
                       AND ma.cod_nivel_pre = :old.nivel_aut
                       AND ma.cod_error_pre = :old.cod_error
                       AND ma.cod_rechazo_pre = :old.cod_rechazo
                       AND ma.dsnivel_pre = :old.dsnivel
                       AND ma.cod_sist_pre = :old.cod_sist
                       AND ma.tiempo_fin IS NULL;
                    --
                    UPDATE sim_cu_bitacora_tiempos_ma b
                       SET b.cod_nivel_post   = :new.nivel_aut
                          ,b.cod_error_post   = :new.cod_error
                          ,b.cod_rechazo_post = :new.cod_rechazo
                          ,b.dsnivel_post     = :new.dsnivel
                          ,b.cod_sist_post    = :new.cod_sist
                          ,b.tiempo_fin       = l_tiempo_ahora
                          ,b.tiempo_total_min = fcn999_t_entre_fechas(ip_fecha_desde => l_aux,
                                                                      ip_fecha_hasta => l_tiempo_ahora)
                          ,b.cod_nivel_post   = :new.nivel_aut
                     WHERE b.cod_cia = :old.cod_cia
                       AND b.cod_secc = c_cod_secc
                       AND b.cod_nivel_pre = :old.nivel_aut
                       AND b.num_secu_pol = :old.num_secu_pol
                       AND b.num_end = :old.num_orden
                       AND b.cod_nivel_pre = :old.nivel_aut
                       AND b.cod_error_pre = :old.cod_error
                       AND b.cod_rechazo_pre = :old.cod_rechazo
                       AND b.dsnivel_pre = :old.dsnivel
                       AND b.cod_sist_pre = :old.cod_sist
                       AND b.tiempo_inicio = l_aux;

                    -- Nuevo registro
                    INSERT INTO sim_cu_bitacora_tiempos_ma
                        (id_bitacora
                        ,cons_tiempo
                        ,cod_cia
                        ,cod_secc
                        ,num_secu_pol
                        ,num_end
                        ,cod_nivel_pre
                        ,cod_error_pre
                        ,cod_rechazo_pre
                        ,dsnivel_pre
                        ,cod_sist_pre
                        ,tiempo_inicio)
                    VALUES
                        (sim_cu_seq_bitacora_ma.nextval
                        ,fcn999_cons_tiempo_ma(ip_num_secu_pol => :new.num_secu_pol,
                                               ip_num_end      => :new.num_orden,
                                               ip_cod_error    => :new.cod_error)
                        ,:new.cod_cia
                        ,c_cod_secc
                        ,:new.num_secu_pol
                        ,:new.num_orden
                        ,:new.nivel_aut
                        ,:new.cod_error
                        ,:new.cod_rechazo
                        ,:new.dsnivel
                        ,:new.cod_sist
                        ,l_tiempo_ahora);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END IF;
    END CASE;
    --COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la línea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END;
/
