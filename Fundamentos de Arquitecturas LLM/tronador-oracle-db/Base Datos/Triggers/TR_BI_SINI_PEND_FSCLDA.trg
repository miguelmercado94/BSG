CREATE OR REPLACE TRIGGER tr_bi_sini_pend_fsclda
    BEFORE INSERT ON sim_autos_cltvas_sini_pend
    FOR EACH ROW
BEGIN

    SELECT seq_sini_pendientes_fsclda.nextval --
      INTO :new.consecutivo
      FROM dual;
END tr_bi_sini_pend_fsclda;
/
