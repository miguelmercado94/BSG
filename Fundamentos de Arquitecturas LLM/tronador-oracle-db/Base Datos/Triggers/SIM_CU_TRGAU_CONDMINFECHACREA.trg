CREATE OR REPLACE TRIGGER sim_cu_trgau_condminfechacrea
    BEFORE UPDATE OF fecha_ult_mod ON sim_cu_cond_minima_enc
DISABLE
DECLARE
    -- Variables
    l_fecha_creacion_det DATE;
    l_fecha_creacion_enc DATE;
    l_fecha_ult_mod_enc  DATE;

    -- Constantes
    c_cod_cia         CONSTANT NUMBER(1) := 3;
    c_cod_secc        CONSTANT NUMBER(1) := 4;
    -- NOTA: Este trigger será el encargado de gestionar las transacciones entre las tablas
    --       Encabezado y Detalle de Condiciones Mínimas.
BEGIN
    -- 1. Extraemos las fechas de creación y última modificación.
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

    UPDATE sim_cu_cond_minima_det det
       SET det.fecha_creacion = l_fecha_creacion_det
     WHERE det.cod_cia = c_cod_cia
       AND det.cod_secc = c_cod_secc
       AND det.fecha_creacion <> l_fecha_creacion_det
       AND det.fecha_baja IS NULL;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la línea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END sim_cu_trgbu_condminfechacrea;
/
