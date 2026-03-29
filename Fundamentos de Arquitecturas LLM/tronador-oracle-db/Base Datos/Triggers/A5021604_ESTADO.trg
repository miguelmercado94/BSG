CREATE OR REPLACE TRIGGER a5021604_estado
BEFORE UPDATE ON a5021604
FOR EACH ROW
BEGIN
    DECLARE
        nuevo                  NUMBER(1) := 0;
        v_estado_transferencia NUMBER(1);
    BEGIN
        IF NOT UPDATING THEN
            RETURN;
        END IF;

        IF nvl(:new.mca_est_pago, 'x') = 'A' THEN
            IF nvl(:old.mca_est_pago, 'x') = 'T' THEN -- Terminada
                raise_application_error(-20100, 'Error: No se puede anular una orden de pago en estado ' || :old.mca_est_pago);

            ELSIF nvl(:old.for_pago, -1) IN(1, 2) THEN -- Davivienda Transferencia/ACH
                BEGIN
                    SELECT a.estado_transferencia
                      INTO v_estado_transferencia
                      FROM a5021104 a
                     WHERE a.cod_cia = :old.cod_cia
                       AND a.num_ord_pago = :old.num_ord_pago;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_estado_transferencia := -1;
                END;

            ELSIF nvl(:old.for_pago, -1) = 3 THEN -- Daviplata
                BEGIN
                    SELECT a.estado_transferencia
                      INTO v_estado_transferencia
                      FROM a5031107 a
                     WHERE a.cod_cia = :old.cod_cia
                       AND a.num_ord_pago = :old.num_ord_pago;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_estado_transferencia := -1;
                END;

            ELSIF nvl(:old.for_pago, -1) = 5 THEN -- Ventanilla Bancolombia
                BEGIN
                    SELECT decode(nvl(a.mca_enviado,'N'), 'N', 2, 'S', decode(nvl(a.mca_exitoso,'N'), 'N', 3, 'S', 5), 9)
                      INTO v_estado_transferencia
                      FROM a502_pago_bancos a
                     WHERE a.cod_cia = :old.cod_cia
                       AND a.num_ord_pago = :old.num_ord_pago;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_estado_transferencia := -1;
                END;

            ELSIF nvl(:old.for_pago, -1) = 6 THEN -- Transferencia Bancolombia
                BEGIN
                    SELECT a.estado_transferencia
                      INTO v_estado_transferencia
                      FROM a502_pago_bancos_t a
                     WHERE a.cod_cia = :old.cod_cia
                       AND a.num_ord_pago = :old.num_ord_pago;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_estado_transferencia := -1;
                END;

            ELSIF nvl(:old.for_pago, -1) = 7 THEN -- Davivienda Corresponsal
                BEGIN
                    SELECT a.estado_transferencia
                      INTO v_estado_transferencia
                      FROM corresponsales_ordenes_pago a
                     WHERE a.cod_cia = :old.cod_cia
                       AND a.num_ord_pago = :old.num_ord_pago;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_estado_transferencia := -1;
                END;

            END IF;
        END IF;

        IF nvl(v_estado_transferencia, -1) = 3 THEN -- En proceso de pago
            raise_application_error(-20100, 'Error: No se puede anular una orden de pago en estado ' ||
                 :old.mca_est_pago || ' y estado de transferencia ' ||
                 v_estado_transferencia || '-Enviado a pago');

        END IF;

    END;
END;
/
