CREATE OR REPLACE TRIGGER tr_bi_sini_amparos_fsclda
    BEFORE INSERT ON sim_autoscltvas_siniamp_fsclda
    FOR EACH ROW
BEGIN
    SELECT seq_sim_autoscltvas_amparos.nextval --
      INTO :new.id_amparo
      FROM dual;
END tr_bi_sini_fsclda;
/
