CREATE OR REPLACE TRIGGER cepag_trg_biu_cuentas_origen 
    BEFORE INSERT OR UPDATE OR DELETE 
    ON cepag_cuentas_origen
    FOR EACH ROW
DECLARE
    v_tipo_movimiento VARCHAR2(1);
BEGIN
    IF inserting THEN
        v_tipo_movimiento := 'I';
        IF :NEW.usuario_creacion IS NULL THEN
            :NEW.usuario_creacion := SUBSTR(USER, 5, 10);
        END IF;
        :NEW.fecha_creacion := SYSDATE;
        BEGIN
            INSERT INTO cepag_cuentas_origen_hist(
                id_cuenta_origen,
                cod_cia,
                sub_cod_cia,
                cod_concepto,
                cod_banco_cuenta,
                tipo_cuenta,
                nro_cuenta,
                marca_estado,
                cuenta_pasiva,
                tipo_egreso,
                categoria_cuenta,
                rubro_presupuestal,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :NEW.id_cuenta_origen,
                :NEW.cod_cia,
                :NEW.sub_cod_cia,
                :NEW.cod_concepto,
                :NEW.cod_banco_cuenta,
                :NEW.tipo_cuenta,
                :NEW.nro_cuenta,
                :NEW.marca_estado,
                :NEW.cuenta_pasiva,
                :NEW.tipo_egreso,
                :NEW.categoria_cuenta,
                :NEW.rubro_presupuestal,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    ELSIF updating THEN
        v_tipo_movimiento := 'U';
        IF :NEW.usuario_modificacion IS NULL THEN
            :NEW.usuario_modificacion := SUBSTR(USER, 5, 10);
        END IF;
        :NEW.fecha_modificacion := SYSDATE;
        BEGIN
            INSERT INTO cepag_cuentas_origen_hist(
                id_cuenta_origen,
                cod_cia,
                sub_cod_cia,
                cod_concepto,
                cod_banco_cuenta,
                tipo_cuenta,
                nro_cuenta,
                marca_estado,
                cuenta_pasiva,
                tipo_egreso,
                categoria_cuenta,
                rubro_presupuestal,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :NEW.id_cuenta_origen,
                :NEW.cod_cia,
                :NEW.sub_cod_cia,
                :NEW.cod_concepto,
                :NEW.cod_banco_cuenta,
                :NEW.tipo_cuenta,
                :NEW.nro_cuenta,
                :NEW.marca_estado,
                :NEW.cuenta_pasiva,
                :NEW.tipo_egreso,
                :NEW.categoria_cuenta,
                :NEW.rubro_presupuestal,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    ELSIF deleting THEN
        v_tipo_movimiento := 'D';
        BEGIN
            INSERT INTO cepag_cuentas_origen_hist(
                id_cuenta_origen,
                cod_cia,
                sub_cod_cia,
                cod_concepto,
                cod_banco_cuenta,
                tipo_cuenta,
                nro_cuenta,
                marca_estado,
                cuenta_pasiva,
                tipo_egreso,
                categoria_cuenta,
                rubro_presupuestal,
                tipo_movimiento,
                fecha_cambio,
                cod_user
            )VALUES (
                :OLD.id_cuenta_origen,
                :OLD.cod_cia,
                :OLD.sub_cod_cia,
                :OLD.cod_concepto,
                :OLD.cod_banco_cuenta,
                :OLD.tipo_cuenta,
                :OLD.nro_cuenta,
                :OLD.marca_estado,
                :OLD.cuenta_pasiva,
                :OLD.tipo_egreso,
                :OLD.categoria_cuenta,
                :OLD.rubro_presupuestal,
                v_tipo_movimiento,
                SYSDATE,
                USER
            );
        END;
    END IF;
END;
/
