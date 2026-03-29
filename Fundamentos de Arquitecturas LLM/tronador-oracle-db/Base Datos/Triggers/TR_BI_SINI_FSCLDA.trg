CREATE OR REPLACE TRIGGER tr_bi_sini_fsclda
    BEFORE INSERT ON sim_autos_cltvas_sini_fsclda
    FOR EACH ROW
BEGIN
    SELECT seq_sim_autoscltvas_sinifsclda.nextval --
      INTO :new.id_sini_fasecolda
      FROM dual;
END tr_bi_sini_fsclda;
/
