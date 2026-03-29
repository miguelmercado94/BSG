CREATE OR REPLACE TRIGGER sim_cu_trg_cmp_i_fechacreacion
    FOR INSERT ON sim_cu_cond_minima_det
DISABLE
COMPOUND TRIGGER
    /*
    * Descripcion: Trigger para el manejo correcto de fechas en las condiciones minimas
    * Autor: Ing. Lic. Stephen Guseph Pinto Morato - sgpinto@asesoftware.com
    * Version: 1.0
    * Proyecto: SIMON
    * Modulo:   Redise?o Cumplimiento
    *
    * Contol de cambios
    * Fecha       - Autor                        - Rev.    - Cambios
    * ----------------------------------------------------------------------------------------------
    * 20/12/2015  - Stephen Pinto (Asesoftware)  - 1.0     - Creacion.
    */

    -- Variables de Sesion del Trigger
    l_fecha_creacion_det DATE;
    l_fecha_creacion_enc DATE;
    l_fecha_ult_mod_enc  DATE;
    l_fecha_ult_mod_det  DATE;

    -- BEFORE STATEMENT: Extrae la fecha de vigencia del Encabezado.
    -- Proposito: Evitar manejo de Tabla Mutante, y recuperar el MAX(fecha_creacion, fecha_ult_mod)
    BEFORE STATEMENT IS
    BEGIN
        -- 1. Extraemos las fechas de creacion y ultima modificacion.
        SELECT e.fecha_creacion
              ,e.fecha_ult_mod
          INTO l_fecha_creacion_enc
              ,l_fecha_ult_mod_enc
          FROM sim_cu_cond_minima_enc e
         WHERE e.fecha_baja IS NULL;
        -- 2. Calculamos la fecha de vigencia.
        IF l_fecha_creacion_enc IS NOT NULL THEN
            l_fecha_creacion_det := l_fecha_creacion_enc;
            IF l_fecha_ult_mod_enc IS NOT NULL THEN
                l_fecha_creacion_det := l_fecha_ult_mod_enc;
            END IF;
        END IF;
    END BEFORE STATEMENT;

    -- BEFORE EACH ROW: Realiza el SWAP entre las fechas de Creacion y Modificacion en Detalle
    -- Proposito: Evitar manejo de Tabla Mutante, e intercambiar fecha_creacion y fecha_ult_mod
    --            en la tabla Detalle.
    BEFORE EACH ROW IS
    BEGIN
        -- Realizamos el SWAP
        l_fecha_ult_mod_det := :new.fecha_creacion; -- Fecha que viene en la actualizacion.
        :new.fecha_creacion := l_fecha_creacion_det;
        :new.fecha_ult_mod  := l_fecha_ult_mod_det;
    END BEFORE EACH ROW;

    -- AFTER STATEMENT: Actualiza fechas de creacion inconsistentes.
    -- Proposito: Una vez realizada la operacion del trigger de Encabezado, actualizar
    --            las posibles fechas de creacion que hayan quedado inconsistentes, respecto
    --            de la fecha de vigencia.
    AFTER STATEMENT IS
    BEGIN
        -- 1. Extraemos las fechas de creacion y ultima modificacion.
        SELECT e.fecha_creacion
              ,e.fecha_ult_mod
          INTO l_fecha_creacion_enc
              ,l_fecha_ult_mod_enc
          FROM sim_cu_cond_minima_enc e
         WHERE e.fecha_baja IS NULL;
        -- 2. Calculamos la fecha de vigencia.
        IF l_fecha_creacion_enc IS NOT NULL THEN
            l_fecha_creacion_det := l_fecha_creacion_enc;
            IF l_fecha_ult_mod_enc IS NOT NULL THEN
                l_fecha_creacion_det := l_fecha_ult_mod_enc;
            END IF;
        END IF;
        -- 3. Actualizamos inconsistencias.
        UPDATE sim_cu_cond_minima_det d
           SET d.fecha_creacion = d.fecha_ult_mod
         WHERE d.fecha_baja IS NULL
           AND d.fecha_creacion <> l_fecha_creacion_det;
    END AFTER STATEMENT;

END sim_cu_trg_cmp_i_fechacreacion;
/
