CREATE OR REPLACE TRIGGER bi_sim_inspecciones_log
    BEFORE INSERT ON sim_inspecciones_log
    FOR EACH ROW
BEGIN
    :new.secuencia := sec_sim_inspecciones_log.nextval;
    :new.fecha_creacion := sysdate;
END;
/
