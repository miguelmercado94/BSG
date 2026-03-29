CREATE OR REPLACE TRIGGER trg_ai_autoscltvas_cond_grales
    AFTER INSERT ON sim_autos_cltvas_cond_grales
    FOR EACH ROW
BEGIN
    IF :new.num_negociacion IS NOT NULL THEN
        UPDATE sim_terceros s
           SET s.num_secu_pol = :new.num_negociacion
         WHERE s.num_secu_pol = :new.num_documento
           AND s.num_secu_pol = s.numero_documento;
    END IF;
END trg_ai_autoscltvas_cond_grales;
/
