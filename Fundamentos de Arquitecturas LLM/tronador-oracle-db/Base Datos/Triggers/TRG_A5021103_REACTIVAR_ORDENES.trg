CREATE OR REPLACE TRIGGER TRG_A5021103_REACTIVAR_ORDENES
BEFORE UPDATE OR INSERT ON A5021103
FOR EACH ROW
FOLLOWS TRG_AUDIT_A5021103
DECLARE

  v_actualizar_ordenes	BOOLEAN := FALSE;

BEGIN

  IF INSERTING THEN
	IF NVL(:NEW.estado, 0) = 1 THEN
	  v_actualizar_ordenes := TRUE;
	END IF;
  ELSE
	IF NVL(:NEW.estado, 0) = 1 THEN
	  IF NVL(:OLD.estado, 0) <> NVL(:NEW.estado, 0) 
		OR :OLD.cod_entidad_destino <> :NEW.cod_entidad_destino
		OR :OLD.numero_cta_destino <> :NEW.numero_cta_destino
		OR :OLD.tipo_cta <> :NEW.tipo_cta
	  THEN
	    v_actualizar_ordenes := TRUE;
	  END IF;	
	END IF;
  END IF;
  
  IF v_actualizar_ordenes = TRUE THEN
    --1.1 delete de las tablas hijas por cambio de cuenta
	--a5021104
	DELETE FROM A5021104 a
	WHERE a.numero_documento = :NEW.numero_documento
	AND a.tdoc_tercero = :NEW.tdoc_tercero
	AND NVL(a.estado_transferencia, 0) in (2,4)--mejora: si cta es 7 o dpt, si tomar los 0 y 1
	AND (NVL(a.estado_transferencia, 0) <> 2 OR a.cod_entidad_destino <> :NEW.cod_entidad_destino OR a.numero_cta_destino <> :NEW.numero_cta_destino OR a.tipo_cta <> :NEW.tipo_cta)
	AND (a.cod_cia, a.num_ord_pago) IN
				  (SELECT b.cod_cia, b.num_ord_pago
				  FROM A5021604 b 
				  WHERE b.cod_benef = :NEW.numero_documento
				  AND b.tdoc_tercero = :NEW.tdoc_tercero
				  AND NVL(b.mca_est_pago, 'X') = 'P'
				  AND NVL(b.for_pago, 9) = 1
				  AND NVL(b.MCA_TIPO_ORD, 'T') <> '3' --EPS Davinci
				  AND (NVL(b.MCA_TIPO_ORD, 'T') <> 'S' OR NVL(b.SUB_TIPO_ORD, 'T') <> '0') --Corresponsal
				  AND b.fec_asiento >= TO_DATE('01012021','DDMMYYYY')
				  AND b.fecha_pago >= TO_DATE('01012021','DDMMYYYY')
				  AND (NVL(b.causal_rechazo, 1) <> 9999 OR NVL(a.estado_transferencia, 0) <> 4)
				  AND NOT EXISTS (SELECT NULL FROM EXCLUSION_OFICINAS_REACT_AUTO o WHERE o.cod_agen_pago = b.cod_agen_pago)
				  ) 
	AND NOT EXISTS (SELECT NULL 
					FROM cuenta_destino_espec_orden c 
					WHERE c.cod_cia = a.cod_cia 
					AND c.num_ord_pago = a.num_ord_pago 
					AND c.marca_estado = 'A');

    --a5031107
	DELETE FROM A5031107 a
	WHERE a.numero_documento = :NEW.numero_documento
	AND a.tdoc_tercero = :NEW.tdoc_tercero
	AND NVL(a.estado_transferencia, 0) in (2,4)
	AND (a.cod_cia, a.num_ord_pago) IN
				  (SELECT b.cod_cia, b.num_ord_pago
				  FROM A5021604 b 
				  WHERE b.cod_benef = :NEW.numero_documento
				  AND b.tdoc_tercero = :NEW.tdoc_tercero
				  AND NVL(b.mca_est_pago, 'X') = 'P'
				  AND NVL(b.for_pago, 9) = 3
				  AND NVL(b.MCA_TIPO_ORD, 'T') <> '3' --EPS Davinci
				  AND (NVL(b.MCA_TIPO_ORD, 'T') <> 'S' OR NVL(b.SUB_TIPO_ORD, 'T') <> '0') --Corresponsal
				  AND b.fec_asiento >= TO_DATE('01012021','DDMMYYYY')
				  AND b.fecha_pago >= TO_DATE('01012021','DDMMYYYY')
				  AND (NVL(b.causal_rechazo, 1) <> 9999 OR NVL(a.estado_transferencia, 0) <> 4) --orden duplicada
				  AND NOT EXISTS (SELECT NULL FROM EXCLUSION_OFICINAS_REACT_AUTO o WHERE o.cod_agen_pago = b.cod_agen_pago)
				  ) 
	AND NOT EXISTS (SELECT NULL 
					FROM cuenta_destino_espec_orden c 
					WHERE c.cod_cia = a.cod_cia 
					AND c.num_ord_pago = a.num_ord_pago 
					AND c.marca_estado = 'A');
	
	--a502_pago_bancos_t 
	DELETE FROM a502_pago_bancos_t a
	WHERE a.nit_beneficiario = :NEW.numero_documento
	AND NVL(a.estado_transferencia, 0) in (2,4)
	AND (a.cod_cia, a.num_ord_pago) IN 
				  (SELECT b.cod_cia, b.num_ord_pago
				  FROM A5021604 b 
				  WHERE b.cod_benef = :NEW.numero_documento
				  AND b.tdoc_tercero = :NEW.tdoc_tercero
				  AND NVL(b.mca_est_pago, 'X') = 'O'
				  AND NVL(b.for_pago, 9) = 6
				  AND NVL(b.MCA_TIPO_ORD, 'T') <> '3' --EPS Davinci
				  AND (NVL(b.MCA_TIPO_ORD, 'T') <> 'S' OR NVL(b.SUB_TIPO_ORD, 'T') <> '0') --Corresponsal
				  AND b.fec_asiento >= TO_DATE('01012021','DDMMYYYY')
				  AND b.fecha_pago >= TO_DATE('01012021','DDMMYYYY')
				  AND (NVL(b.causal_rechazo, 1) <> 9999 OR NVL(a.estado_transferencia, 0) <> 4)
				  AND NOT EXISTS (SELECT NULL FROM EXCLUSION_OFICINAS_REACT_AUTO o WHERE o.cod_agen_pago = b.cod_agen_pago)
				  ) 
	AND NOT EXISTS (SELECT NULL 
					FROM cuenta_destino_espec_orden c 
					WHERE c.cod_cia = a.cod_cia 
					AND c.num_ord_pago = a.num_ord_pago 
					AND c.marca_estado = 'A');
	
	--a502_pago_bancos
  	DELETE FROM a502_pago_bancos a
	WHERE a.nit_beneficiario = :NEW.numero_documento
	AND NVL(a.mca_enviado, 'N') = 'N'
	AND (a.cod_cia, a.num_ord_pago) IN
				  (SELECT b.cod_cia, b.num_ord_pago
				  FROM A5021604 b 
				  WHERE b.cod_benef = :NEW.numero_documento
				  AND b.tdoc_tercero = :NEW.tdoc_tercero
				  AND NVL(b.mca_est_pago, 'X') = 'M'
				  AND NVL(b.for_pago, 9) = 5
				  AND NVL(b.MCA_TIPO_ORD, 'T') <> '3' --EPS Davinci
				  AND (NVL(b.MCA_TIPO_ORD, 'T') <> 'S' OR NVL(b.SUB_TIPO_ORD, 'T') <> '0') --Corresponsal
				  AND b.fec_asiento >= TO_DATE('01012021','DDMMYYYY')
				  AND b.fecha_pago >= TO_DATE('01012021','DDMMYYYY')
				  AND (NVL(b.causal_rechazo, 1) <> 9999 OR NVL(a.mca_exitoso, 'N') <> 'D') --orden duplicada
				  AND NOT EXISTS (SELECT NULL FROM EXCLUSION_OFICINAS_REACT_AUTO o WHERE o.cod_agen_pago = b.cod_agen_pago)
				  ) 
	AND NOT EXISTS (SELECT NULL 
					FROM cuenta_destino_espec_orden c 
					WHERE c.cod_cia = a.cod_cia 
					AND c.num_ord_pago = a.num_ord_pago 
					AND c.marca_estado = 'A');

    --1.2 update mca_est_pago = null y for_pago = 8
	UPDATE A5021604 a
	SET a.FOR_PAGO = 8,
		a.MCA_EST_PAGO = NULL,
		a.fecha_pago = CASE 
						WHEN (a.fecha_pago < TRUNC(sysdate -300)) THEN SYSDATE
						ELSE a.fecha_pago
						END
	WHERE a.cod_benef = :NEW.numero_documento
	AND a.tdoc_tercero = :NEW.tdoc_tercero
	AND NVL(a.MCA_EST_PAGO, 'P') IN ('M','O','P')
	AND NVL(a.FOR_PAGO, 1) IN (1,3,5,6)
	AND NVL(a.MCA_TIPO_ORD, 'T') <> '3' --EPS Davinci
	AND (NVL(a.MCA_TIPO_ORD, 'T') <> 'S' OR NVL(a.SUB_TIPO_ORD, 'T') <> '0') --Corresponsal
	AND a.fec_asiento >= TO_DATE('01012021','DDMMYYYY')
	AND a.fecha_pago >= TO_DATE('01012021','DDMMYYYY')
	AND NOT EXISTS (SELECT NULL 
					FROM EXCLUSION_OFICINAS_REACT_AUTO o 
					WHERE o.cod_agen_pago = a.cod_agen_pago)
	AND NOT EXISTS (SELECT NULL
					FROM a5031104
					WHERE a.cod_cia = a5031104.cod_cia
					AND a.num_ord_pago = a5031104.num_ord_pago)
	AND NOT EXISTS (SELECT NULL
					FROM a5021104
					WHERE a.cod_cia = a5021104.cod_cia
					AND a.num_ord_pago = a5021104.num_ord_pago)
	AND NOT EXISTS (SELECT NULL
					FROM a5031107
					WHERE a.cod_cia = a5031107.cod_cia
					AND a.num_ord_pago = a5031107.num_ord_pago)
	AND NOT EXISTS (SELECT NULL
					FROM a502_pago_bancos
					WHERE a.cod_cia = a502_pago_bancos.cod_cia
					AND a.num_ord_pago = a502_pago_bancos.num_ord_pago)
	AND NOT EXISTS (SELECT NULL
					FROM a502_pago_bancos_t
					WHERE a.cod_cia = a502_pago_bancos_t.cod_cia
					AND a.num_ord_pago = a502_pago_bancos_t.num_ord_pago)
	AND NOT EXISTS (SELECT NULL 
					FROM cuenta_destino_espec_orden c 
					WHERE c.cod_cia = a.cod_cia 
					AND c.num_ord_pago = a.num_ord_pago 
					AND c.marca_estado = 'A')
	;

	
  END IF;
END;
/