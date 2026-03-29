CREATE OR REPLACE TRIGGER TRG_NOBORRARHI
	BEFORE DELETE ON SIM_CARGA_LIQUIDACIONES_HI
	FOR EACH ROW
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;	
	
	v_usuario VARCHAR2(4000);
	l_msg     VARCHAR2(4000) := NULL;
	l_json    VARCHAR2(4000) := NULL;
	

BEGIN
	v_usuario := SYS_CONTEXT('USERENV', 'SESSION_USER')||' - '||
	SYS_CONTEXT('USERENV', 'IP_ADDRESS')||' - Programa:  '||
	SYS_CONTEXT('USERENV', 'MODULE');
	

	IF :OLD.COD_RAMO = 445 THEN
		l_msg  :=' eliminando informacion coopropiedad: ' || :OLD.NDOC_BENEF  || ' Usuario: ' || v_usuario;
					
						 
		l_json := '{"estado": "ER","respuesta": "' || l_msg || '"}';
	
		INSERT INTO SIM_LOG_CERTIFICADOS_CUOTASALDIA
			(id_log,
			 id_certificado,
			 nro_documento,
			 fecha_registro,
			 proceso,
			 estado,
			 request,
			 response,
			 resultado,
			 observaciones)
		VALUES
			(SEQ_SIM_LOG_CERTIFICADOS_CAD.NEXTVAL,
			 :OLD.SECUENCIA,
			 :OLD.NDOC_BENEF,
			 SYSDATE,
			 'Error borrando en tabla hi liquidaciones',
			 'E',
			 NULL,
			 l_json,
			 -1,
			 null);

commit;
	
		RAISE_APPLICATION_ERROR(-20002,
														'No se pueden eliminar los registros de esta tabla para el producto 445 - Cuotas Al Dia');
	END IF;
END TRG_NOBORRARHI;
/
