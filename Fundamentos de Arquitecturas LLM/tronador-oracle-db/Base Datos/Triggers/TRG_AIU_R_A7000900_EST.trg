CREATE OR REPLACE TRIGGER trg_aiu_r_a7000900_est 
    AFTER INSERT OR UPDATE OF sim_ult_est_sini ON A7000900 
    FOR EACH ROW
DECLARE
    -------------------------------------------------------------------------------
    -- Objetivo : Insertar en la tabla de historico de estados de siniestros
    -- Autor    : Carlos Eduardo Mayorga R.
    -- Fecha    : 28/05/2018
    -- Cuando se inserta en A7000900 puede ser la creacion del siniestro o una modificación
    -- de datos variables.
    -- Cuando se actualiza puede ser por modificaciones en la reserva que cambian el estado de
    -- la reserva, o por cambios de estado del siniestro
    -------------------------------------------------------------------------------
    v_movimiento       NUMBER := 0;
    lv_tipo_causa      NUMBER(3);
    lv_cod_cau_mod_est NUMBER(3);
BEGIN
    -- ESTCORE-6453
    -- DHERRERA: SE AGREGA TIPO CAUSA AL TRIGGER 
    BEGIN
        SELECT a.tipo_causa
          INTO lv_tipo_causa
          FROM sim_estados_sini a
         WHERE a.cod_estado = :new.sim_ult_est_sini;
    EXCEPTION
        WHEN OTHERS THEN
            lv_tipo_causa := 3;
    END;
    IF inserting THEN
        BEGIN
            INSERT INTO sim_hist_estados_sini
                (id_histestsini
                ,num_secu_sini
                ,nro_orden_sini
                ,cod_estado
                ,cod_cau_mod_est
                ,usuario_creacion
                ,fecha_creacion
                ,observacion
                ,tipo_causa
                ,cod_cia)
            VALUES
                (sim_seq_hist_estados_sini.nextval
                ,:new.num_secu_sini
                ,:new.nro_orden_sini
                ,:new.sim_ult_est_sini
                ,nvl(:new.cod_causa_modi, nvl(:new.cod_causa_sini, 1))
                ,:new.cod_user
                ,SYSDATE
                ,decode(:new.cod_causa_modi, NULL, 'CREACION SINIESTRO', 'MODIFICACION SINIESTRO')
                ,decode(:new.cod_causa_modi, NULL, 1, 3)
                ,:new.cod_cia);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    ELSE
        BEGIN
            -- ESTCORE-6453
            -- DHERRERA: SE AGREGA BLOQUE CAMBIO DE ESTADOS para cod_cau_mod_est
            IF :new.sim_ult_est_sini = 'RE' THEN
                lv_cod_cau_mod_est := :new.cod_causa_reap;
            ELSIF :new.sim_ult_est_sini = 'AN' THEN
                lv_cod_cau_mod_est := :new.cod_causa_baja;
            ELSE
                lv_cod_cau_mod_est := :new.cod_causa_modi;
            END IF;
        
            INSERT INTO sim_hist_estados_sini
                (id_histestsini
                ,num_secu_sini
                ,nro_orden_sini
                ,cod_estado
                ,cod_cau_mod_est
                ,usuario_creacion
                ,fecha_creacion
                ,observacion
                ,tipo_causa
                ,cod_cia)
            VALUES
                (sim_seq_hist_estados_sini.nextval
                ,:new.num_secu_sini
                ,:new.nro_orden_sini
                ,:new.sim_ult_est_sini
                 --,nvl(:new.cod_causa_baja, nvl(:new.cod_causa_reap, nvl(:new.cod_causa_modi, 1)))
                ,lv_cod_cau_mod_est
                ,:new.cod_user
                ,SYSDATE
                ,decode(:new.cod_causa_modi, NULL, 'CAMBIO EXPEDIENTES', 'CAMBIO SINIESTRO')
                ,lv_tipo_causa
                ,:new.cod_cia);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END IF;
END trg_aiu_r_a7000900_est;
/
