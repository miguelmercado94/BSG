CREATE OR REPLACE TRIGGER tr_sec_autos_cltvas_no_sini
    BEFORE INSERT ON sim_autoscltvas_no_siniestros
    FOR EACH ROW
BEGIN
    SELECT seq_autos_cltvas_no_siniestros.nextval --
      INTO :new.id_sin_siniestro
      FROM dual;
END tr_sec_autos_cltvas_no_sini;
/
