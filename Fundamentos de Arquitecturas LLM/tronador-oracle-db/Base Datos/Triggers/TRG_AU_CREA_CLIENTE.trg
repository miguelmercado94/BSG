CREATE OR REPLACE TRIGGER TRG_AU_CREA_CLIENTE
  AFTER UPDATE OF NUMERO_DOCUMENTO ON EMI_SOLICITUD_POLIZA 
  FOR EACH ROW
DECLARE
  t_sol Pkg_Emi_Cliente.t_solicitud;
BEGIN
  --Cuando es jurídico no se crea el tercero
  t_sol.p_NUMERO_SOLICITUD    := :NEW.NUMERO_SOLICITUD;
  t_sol.p_NUMERO_DOCUMENTO    := :NEW.NUMERO_DOCUMENTO;
  t_sol.p_TIPO_documento      := :NEW.TIPO_DOCUMENTO;
  t_sol.p_fecha_solicitud     := :NEW.FECHA_SOLICITUD;
  t_sol.p_usuario_transaccion := :NEW.USUARIO_TRANSACCION;

  IF :NEW.TIPO_DOCUMENTO <> 'NT' THEN
    --Man 15341  Se realiza cambio para evitar error en cambio de tomador
    IF :OLD.NUMERO_DOCUMENTO <> :NEW.NUMERO_DOCUMENTO AND (:OLD.CAMBIA_TOMADOR <> :NEW.CAMBIA_TOMADOR  AND :NEW.CAMBIA_TOMADOR <> 'S') THEN
      DELETE FROM EMI_CLIENTE
       WHERE NUMERO_DOCUMENTO = :OLD.NUMERO_DOCUMENTO
         AND NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;

      DBMS_OUTPUT.PUT_LINE('  TRG_CREA_CLIENTE :   t_sol.p_usuario_transaccion  ' ||
                           :NEW.USUARIO_TRANSACCION);
      SELECT DECODE(:NEW.TOMADOR_ES_ASEGURADO, 'S', 3, 'N', 0)
        INTO t_sol.p_codigo_riesgo
        FROM dual;

      DBMS_OUTPUT.PUT_LINE('  TRG_CREA_CLIENTE  : Antes de pkg_emi_cliente.emi_crear_cliente(t_sol); ');

      OPS$PUMA.Pkg_Emi_Cliente.emi_crear_cliente(t_sol);

      IF t_sol.P_SQLERR <> 0 THEN
        RAISE_APPLICATION_ERROR(-20522,
                                'Error  ' || t_sol.p_sqlerr || ' Fallo' ||
                                t_sol.p_sqlerrm);
      END IF;
    END IF;
  END IF;
END;
/
