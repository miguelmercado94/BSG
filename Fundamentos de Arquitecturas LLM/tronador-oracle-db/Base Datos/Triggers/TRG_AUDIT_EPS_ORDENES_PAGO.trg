CREATE OR REPLACE TRIGGER "TRG_AUDIT_EPS_ORDENES_PAGO" BEFORE
  UPDATE OR INSERT OR DELETE ON eps_ordenes_pago
  FOR EACH ROW
DECLARE
  v_tabla                 audit_teso.tabla%TYPE := 'EPS_ORDENES_PAGO';
  v_vlr_anterior          audit_teso.vlr_anterior%TYPE;
  v_vlr_nuevo             audit_teso.vlr_nuevo%TYPE;
  v_campo                 audit_teso.campo%TYPE;
BEGIN
  IF inserting THEN
    v_campo := 'ESTADO_TRANSFERENCIA';    
    v_vlr_anterior := NULL;
    v_vlr_nuevo := :new.estado_transferencia;
    INSERT INTO audit_teso (
      num_ord_pago, cod_cia, vlr_anterior, vlr_nuevo,
      tabla, campo, evento, usuario, fecha
    ) VALUES (
      :new.num_ord_pago, :new.cod_cia, v_vlr_anterior, v_vlr_nuevo,
      v_tabla, v_campo, 'Crear', user, sysdate
    );
  ELSIF deleting THEN
    v_campo := 'ESTADO_TRANSFERENCIA';
    v_vlr_anterior := :old.estado_transferencia;
    v_vlr_nuevo := NULL;
    INSERT INTO audit_teso (
      num_ord_pago, cod_cia, vlr_anterior, vlr_nuevo,
      tabla, campo, evento, usuario, fecha
    ) VALUES (
      :old.num_ord_pago, :old.cod_cia, v_vlr_anterior, v_vlr_nuevo,
      v_tabla, v_campo, 'Borrar', user, sysdate
    );
  ELSE
    
    IF nvl(:new.estado_transferencia, '-1') <> nvl(:old.estado_transferencia, '-1') THEN
      v_campo := 'ESTADO_TRANSFERENCIA';
      v_vlr_anterior := :old.estado_transferencia;
      v_vlr_nuevo := :new.estado_transferencia;
      INSERT INTO audit_teso (
        num_ord_pago, cod_cia, vlr_anterior, vlr_nuevo,
        tabla, campo, evento, usuario, fecha
      ) VALUES (
        :new.num_ord_pago, :new.cod_cia, v_vlr_anterior, v_vlr_nuevo,
        v_tabla, v_campo, 'Actualizar', user, sysdate
      );
    END IF;
    
    IF nvl(:new.numero_agrupa, '-1') <> nvl(:old.numero_agrupa, '-1') THEN
      v_campo := 'NUMERO_AGRUPA';
      v_vlr_anterior := :old.numero_agrupa;
      v_vlr_nuevo := :new.numero_agrupa;
      INSERT INTO audit_teso (
        num_ord_pago, cod_cia, vlr_anterior, vlr_nuevo,
        tabla, campo, evento, usuario, fecha
      ) VALUES (
        :new.num_ord_pago, :new.cod_cia, v_vlr_anterior, v_vlr_nuevo,
        v_tabla, v_campo, 'Actualizar', user, sysdate
      );
    END IF;
    
  END IF;
END;
/
