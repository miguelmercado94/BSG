CREATE OR REPLACE TRIGGER cepag_trg_biu_compania_contab 
    BEFORE INSERT OR UPDATE OR DELETE 
    ON PARAM_COMPANIAS_CONTABILIDAD
    FOR EACH ROW
DECLARE
    v_tipo_movimiento VARCHAR2(1);
BEGIN
    IF inserting THEN
        v_tipo_movimiento := 'I';
        IF :NEW.usuario_creacion IS NULL THEN
            :NEW.usuario_creacion := USER;
        END IF;
        :NEW.fecha_creacion := SYSDATE;
        BEGIN
            INSERT INTO param_companias_contab_hist(
                cod_cia,
                mca_tipo_ord,
                aplica_contabilidad,
                estado,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :NEW.cod_cia,
                :NEW.mca_tipo_ord,
                :NEW.aplica_contabilidad,
                :NEW.estado,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    ELSIF updating THEN
        v_tipo_movimiento := 'U';
        IF :NEW.usuario_modificacion IS NULL THEN
            :NEW.usuario_modificacion := USER;
        END IF;
        :NEW.fecha_modificacion := SYSDATE;
        BEGIN
            INSERT INTO param_companias_contab_hist(
                cod_cia,
                mca_tipo_ord,
                aplica_contabilidad,
                estado,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :NEW.cod_cia,
                :NEW.mca_tipo_ord,
                :NEW.aplica_contabilidad,
                :NEW.estado,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    ELSIF deleting THEN
        v_tipo_movimiento := 'D';
        BEGIN
            INSERT INTO param_companias_contab_hist(
                cod_cia,
                mca_tipo_ord,
                aplica_contabilidad,
                estado,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :OLD.cod_cia,
                :OLD.mca_tipo_ord,
                :OLD.aplica_contabilidad,
                :OLD.estado,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    END IF;
END;
/
