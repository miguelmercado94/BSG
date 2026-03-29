CREATE OR REPLACE TRIGGER trg_aiud_r_c9990120 AFTER
    INSERT OR UPDATE OR DELETE ON c9990120
    FOR EACH ROW
DECLARE
    v_ope VARCHAR2(3) := NULL;
BEGIN
    IF deleting THEN
        v_ope := 'DEL';
    ELSIF updating THEN
        v_ope := 'UPD';
    ELSIF inserting THEN
        v_ope := 'INS';
    ELSE
        v_ope := 'ERR';
    END IF;

    IF inserting THEN
        INSERT INTO c9990120_jn (
            jn_operation,
            jn_oracle_user,
            jn_datetime,
            jn_notes,
            jn_appln,
            jn_session,
            id_secuencia,
            cod_producto,
            macroproducto,
            producto,
            subproducto,
            desc_producto,
            clase_cartera,
            cod_macroproducto,
            desc_macroproducto,
            cod_linea_credito,
            estado_impresion
        ) VALUES (
            v_ope,
            user,
            sysdate,
            NULL,
            NULL,
            NULL,
            :new.id_secuencia,
            :new.cod_producto,
            :new.macroproducto,
            :new.producto,
            :new.subproducto,
            :new.desc_producto,
            :new.clase_cartera,
            :new.cod_macroproducto,
            :new.desc_macroproducto,
            :new.cod_linea_credito,
            :new.estado_impresion
        );

    ELSE
        INSERT INTO c9990120_jn (
            jn_operation,
            jn_oracle_user,
            jn_datetime,
            jn_notes,
            jn_appln,
            jn_session,
            id_secuencia,
            cod_producto,
            macroproducto,
            producto,
            subproducto,
            desc_producto,
            clase_cartera,
            cod_macroproducto,
            desc_macroproducto,
            cod_linea_credito,
            estado_impresion
        ) VALUES (
            v_ope,
            user,
            sysdate,
            NULL,
            NULL,
            NULL,
            :old.id_secuencia,
            :old.cod_producto,
            :old.macroproducto,
            :old.producto,
            :old.subproducto,
            :old.desc_producto,
            :old.clase_cartera,
            :old.cod_macroproducto,
            :old.desc_macroproducto,
            :old.cod_linea_credito,
            :old.estado_impresion
        );

    END IF;

END;
/
