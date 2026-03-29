CREATE OR REPLACE TRIGGER TRG_SEC_CTAS_ORIGEN BEFORE
    INSERT ON cepag_cuentas_origen
    FOR EACH ROW
BEGIN
    SELECT seq_cepag_cuentas_origen.NEXTVAL
    INTO :new.id_cuenta_origen
    FROM dual;
END;
/
