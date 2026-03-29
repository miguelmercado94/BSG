CREATE OR REPLACE TRIGGER sim_cu_trgbu_condminfechacrea
    BEFORE UPDATE OF fecha_ult_mod ON sim_cu_cond_minima_enc
    FOR EACH ROW
DISABLE
DECLARE
    -- Variables
    l_fecha_proceso  DATE;
    l_fecha_creacion DATE;
    l_cons           sim_cu_cond_minima_det.cons_cond_minima%TYPE;
    -- Types
    TYPE t_arr_cond_minima_det IS TABLE OF sim_cu_cond_minima_det%ROWTYPE;
    l_arr_cond_minima_det t_arr_cond_minima_det;
    -- Constantes
    c_cod_cia         CONSTANT NUMBER(1) := 3;
    c_cod_secc        CONSTANT NUMBER(1) := 4;
    -- NOTA: Este trigger será el encargado de gestionar las transacciones entre las tablas
    --       Encabezado y Detalle de Condiciones Mínimas.
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

    -- 1. Extraemos la fecha de vigencia MAX(fecha_creacion, fecha_ult_mod)
    l_fecha_proceso := :old.fecha_creacion;
    IF :old.fecha_ult_mod IS NOT NULL THEN
        l_fecha_proceso := :old.fecha_ult_mod;
    END IF;

    -- 2. Generamos el array de condiciones para la extracción de los valores
    --    del detalle, modificando únicamente, la fecha de creación y modificación
    --    con base en la nueva fecha creada.

    l_fecha_creacion := :new.fecha_creacion;
    IF :new.fecha_ult_mod > l_fecha_creacion THEN
        l_fecha_creacion := :new.fecha_ult_mod;
    END IF;

    SELECT id_cond_minima
          ,cod_cia
          ,cod_secc
          ,tipo_documnto
          ,num_doc
          ,cod_ramo
          ,cod_cob
          ,tasa_cob
          ,l_fecha_creacion AS fecha_creacion
          ,cod_user         AS cod_user
          ,l_fecha_creacion AS fecha_ult_mod
          ,NULL             AS fecha_baja
          ,NULL             AS cons_cond_minima
      BULK COLLECT
      INTO l_arr_cond_minima_det
      FROM sim_cu_cond_minima_det det
     WHERE det.cod_cia = c_cod_cia
       AND det.cod_secc = c_cod_secc
       AND det.fecha_creacion = l_fecha_proceso
       AND det.fecha_baja IS NULL;

    -- 3. Procedemos a ajustar los datos del array y preparar la tabla para la inserción.
    IF l_arr_cond_minima_det.count() > 0 THEN
        -- 3.1. Extraemos el máximo valor del consecutvo de Condiciones Mínimas
        SELECT MAX(cons_cond_minima) --
          INTO l_cons
          FROM sim_cu_cond_minima_det;

        -- 3.2. Actualizamos el valor del campo consecutivo en el Array a insertar.
        FOR i IN l_arr_cond_minima_det.first .. l_arr_cond_minima_det.last
        LOOP
            l_arr_cond_minima_det(i).cons_cond_minima := l_cons + i;
        END LOOP;

        -- 3.3. Damos de baja, con la misma fecha de vigencia rescatada a todas las condiciones
        --      previas que aún no están dadas de baja.
        UPDATE sim_cu_cond_minima_det det --
           SET det.fecha_baja = l_fecha_creacion
         WHERE det.fecha_creacion = l_fecha_proceso;

        -- 3.4. Procedemos a realizar el INSERT sobre la tabla de Detalle
        --      NOTA: esta sección desencadena también el trigger
        FOR i IN l_arr_cond_minima_det.first .. l_arr_cond_minima_det.last
        LOOP
            INSERT INTO sim_cu_cond_minima_det
                (id_cond_minima
                ,cod_cia
                ,cod_secc
                ,tipo_documnto
                ,num_doc
                ,cod_ramo
                ,cod_cob
                ,tasa_cob
                ,fecha_creacion
                ,cod_user
                ,fecha_ult_mod
                ,fecha_baja
                ,cons_cond_minima)
            VALUES
                (l_arr_cond_minima_det(i).id_cond_minima
                ,l_arr_cond_minima_det(i).cod_cia
                ,l_arr_cond_minima_det(i).cod_secc
                ,l_arr_cond_minima_det(i).tipo_documnto
                ,l_arr_cond_minima_det(i).num_doc
                ,l_arr_cond_minima_det(i).cod_ramo
                ,l_arr_cond_minima_det(i).cod_cob
                ,l_arr_cond_minima_det(i).tasa_cob
                ,l_arr_cond_minima_det(i).fecha_creacion
                ,l_arr_cond_minima_det(i).cod_user
                ,l_arr_cond_minima_det(i).fecha_ult_mod
                ,l_arr_cond_minima_det(i).fecha_baja
                ,l_arr_cond_minima_det(i).cons_cond_minima);
            COMMIT;
        END LOOP;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la línea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END sim_cu_trgbu_condminfechacrea;
/
