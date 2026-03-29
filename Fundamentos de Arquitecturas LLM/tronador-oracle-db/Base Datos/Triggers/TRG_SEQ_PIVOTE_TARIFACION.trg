CREATE OR REPLACE TRIGGER trg_seq_pivote_tarifacion
    BEFORE INSERT ON sim_pivote_tarifacion
    FOR EACH ROW
DECLARE
    -- local variables here
    v_secuencia NUMBER(17) := 0;
BEGIN
    BEGIN
        SELECT seq_pivote_tarifacion.nextval
          INTO v_secuencia
          FROM dual;
    END;

    :new.id_pivote_tarif := v_secuencia;

END trg_seq_pivote_tarifacion;
/
