CREATE OR REPLACE TRIGGER sim_cu_trg_dar_baja_cond_min
    AFTER UPDATE OF fecha_baja ON sim_cu_cond_minima_enc
    FOR EACH ROW
BEGIN
    UPDATE sim_cu_cond_minima_det x
       SET x.fecha_baja    = :new.fecha_baja
     WHERE x.id_cond_minima = :old.id_cond_minima
       AND x.cod_cia = :old.cod_cia
       AND x.cod_secc = :old.cod_secc
       AND x.tipo_documnto = :old.tipo_documnto
       AND x.num_doc = :old.num_doc;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la línea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END;
/
