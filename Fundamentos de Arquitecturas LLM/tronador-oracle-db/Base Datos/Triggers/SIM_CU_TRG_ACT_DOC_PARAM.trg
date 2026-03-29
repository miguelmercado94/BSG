CREATE OR REPLACE TRIGGER sim_cu_trg_act_doc_param
    AFTER UPDATE OF id_documento, nombre_doc, tipo_docum ON sim_cu_cargue_doc_param
    FOR EACH ROW
BEGIN
    UPDATE sim_cu_cargue_doc_reg x
       SET x.param_id_docum     = :new.id_documento
          ,x.param_nombre_docum = :new.nombre_doc
          ,x.param_tipo_docum   = :new.tipo_docum
     WHERE x.param_id_docum = :old.id_documento
       AND x.param_nombre_docum = :old.nombre_doc
       AND x.param_tipo_docum = :old.tipo_docum;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la linea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END;
/
