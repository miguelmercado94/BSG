CREATE OR REPLACE TRIGGER actualiza_coberturas_transp
BEFORE
	INSERT OR
	UPDATE OR
	DELETE
  OF cod_cob, txt_cob, basica, cod_cob_inf
	ON A1002100
FOR EACH ROW
WHEN (
		NEW.cod_cia = 3
AND
		(
				NEW.cod_ramo  = 55
		OR	NEW.cod_ramo  = 60
		)
)
DECLARE
	existe	VARCHAR2(1):= PCK115_CONSTANTES_TRANSPORTES.NO;
	seccion	NUMBER(3);
BEGIN		--cod_cob, txt_cob, basica, cod_cob_inf
	IF INSERTING THEN
		IF :NEW.cod_cob_inf IS NULL THEN
			--Inserta Informacion Del Trayecto
			PCK115_TRAYECTO_TRANSPORTES.PRC_INSERT_TRAYECTO
			(
				P_TRAYECTO =>
					:NEW.cod_cob,
				P_DESC_TRAYECTO =>
					:NEW.txt_cob
			);
		ELSE
			--Inserta Informacion De la Cobertura
			PCK115_COBERTURA_TRANSPORTES.PRC_INSERT_COBERTURA
			(
				P_COBERTURA =>
					:NEW.cod_cob,
				P_DESC_COBERTURA =>
					:NEW.txt_cob,
				P_BASICA =>
					:NEW.basica,
				P_DEPENDIENTE =>
					:NEW.MCA_EXCLU_XL,
				P_TRAYECTO =>
					:NEW.cod_cob_inf,
				P_PORC_DIST =>
					NULL,
				P_PORC_PARTIC_SUM =>
					NULL,
				P_FECHA_VIG =>
					SYSDATE,
				P_FECHA_BAJA =>
					NULL
			);
		END IF;
	ELSIF UPDATING THEN
		IF :NEW.cod_cob_inf IS NULL THEN
			--Modifica la Informacion Del Trayecto
			PCK115_TRAYECTO_TRANSPORTES.PRC_UPDATE_TRAYECTO
			(
				P_TRAYECTO =>
					:NEW.cod_cob,
				P_DESC_TRAYECTO =>
					:NEW.txt_cob
			);
		ELSE
			--Modifica la Informacion De la Cobertura
			PCK115_COBERTURA_TRANSPORTES.PRC_UPDATE_COBERTURA
			(
				P_COBERTURA =>
					:NEW.cod_cob,
				P_DESC_COBERTURA =>
					:NEW.txt_cob,
				P_BASICA =>
					:NEW.basica,
				P_DEPENDIENTE =>
					:NEW.MCA_EXCLU_XL,
				P_TRAYECTO =>
					:NEW.cod_cob_inf,
				P_PORC_DIST =>
					NULL,
				P_PORC_PARTIC_SUM =>
					NULL,
				P_FECHA_VIG =>
					SYSDATE,
				P_FECHA_BAJA =>
					NULL
			);
		END IF;
	ELSIF DELETING THEN
		IF :NEW.cod_cob_inf IS NULL THEN
			--Elimina la Informacion Del Trayecto
			PCK115_TRAYECTO_TRANSPORTES.PRC_DELETE_TRAYECTO
			(
				P_TRAYECTO =>
					:NEW.cod_cob
			);
		ELSE
			--Elimina la Informacion De la Cobertura
			PCK115_COBERTURA_TRANSPORTES.PRC_DELETE_COBERTURA
			(
				P_COBERTURA =>
					:NEW.cod_cob
			);
		END IF;
	END IF;
END actualiza_coberturas_transp;
/
