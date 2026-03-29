CREATE OR REPLACE TRIGGER act_hist_delegacion_transp
AFTER
	INSERT OR
	UPDATE OR
	DELETE
	ON C1150753
FOR EACH ROW
DECLARE
	mi_contador		NUMBER;
BEGIN		--cod_cob, txt_cob, basica, cod_cob_inf
	IF INSERTING THEN

		--Llamado Insercion de Control de Delegaciones Utilizando Secuencia
		PCK215_CONTROL_DELEG.PRC_INSERT_CONTROL_DELEG
		(
			P_CLAVE =>
				:NEW.CLAVE,
			P_COD_AGENCIA =>
				:NEW.COD_AGENCIA,
			P_ABREV_AGENCIA =>
				:NEW.ABREV_AGENCIA,
			P_FECHA_VIG =>
				:NEW.FECHA_VIG,
			P_FECHA_BAJA =>
				:NEW.FECHA_BAJA
		);

	ELSIF UPDATING THEN

		--Llamado a la Insercion del Historico de la Delegacion
		PCK115_DELEGACION_HIS.PRC_CARG_DELEGACION_HIS
		(
			P_CLAVE =>
				:OLD.CLAVE,
			P_TIPO_DOCUMENTO =>
				:OLD.TIPO_DOCUMENTO,
			P_NUMERO_DOCUMENTO =>
				:OLD.NUMERO_DOCUMENTO,
			P_COD_AGENCIA =>
				:OLD.COD_AGENCIA,
			P_ABREV_AGENCIA =>
				:OLD.ABREV_AGENCIA,
			P_FECHA_VIG =>
				:OLD.FECHA_VIG,
			P_FECHA_BAJA =>
				:OLD.FECHA_BAJA,
			P_TIPO_OPERACION =>
				PCK115_CONSTANTES_TRANSPORTES.ACTUALIZACION
		);

		--Evaluacion de si cambio la Sucursal a la que esta Vinculado el Tercero
		IF :OLD.COD_AGENCIA != :NEW.COD_AGENCIA THEN

			--Llamado a Borrado Total de la Informacion de Control de Delegaciones por Tercero
			PCK215_CONTROL_DELEG.PRC_DELETE_TOT_CONTROL_DELEG
			(
				P_CLAVE =>
					:OLD.CLAVE
			);

			--Llamado Insercion de Control de Delegaciones con la Nueva Agencia
			PCK215_CONTROL_DELEG.PRC_INSERT_CONTROL_DELEG
			(
				P_CLAVE =>
					:NEW.CLAVE,
				P_COD_AGENCIA =>
					:NEW.COD_AGENCIA,
				P_ABREV_AGENCIA =>
					:NEW.ABREV_AGENCIA,
				P_FECHA_VIG =>
					:NEW.FECHA_VIG,
				P_FECHA_BAJA =>
					:NEW.FECHA_BAJA
			);

		END IF;

	ELSIF DELETING THEN

		--Llamado a la Insercion del Historico de la Delegacion
		PCK115_DELEGACION_HIS.PRC_CARG_DELEGACION_HIS
		(
			P_CLAVE =>
				:OLD.CLAVE,
			P_TIPO_DOCUMENTO =>
				:OLD.TIPO_DOCUMENTO,
			P_NUMERO_DOCUMENTO =>
				:OLD.NUMERO_DOCUMENTO,
			P_COD_AGENCIA =>
				:OLD.COD_AGENCIA,
			P_ABREV_AGENCIA =>
				:OLD.ABREV_AGENCIA,
			P_FECHA_VIG =>
				:OLD.FECHA_VIG,
			P_FECHA_BAJA =>
				:OLD.FECHA_BAJA,
			P_TIPO_OPERACION =>
				PCK115_CONSTANTES_TRANSPORTES.ELIMINACION
		);

		--Llamado a Borrado Total de la Informacion de Control de Delegaciones por Tercero
		PCK215_CONTROL_DELEG.PRC_DELETE_TOT_CONTROL_DELEG
		(
			P_CLAVE =>
				:OLD.CLAVE
		);

		--Llamado a Borrado Total de Informacion de Delegaciones por Clase de Poliza del Tercero
		PCK215_DELEG_CLAPOL.PRC_DELETE_TOT_DELEG_CLAPOL
		(
			P_CLAVE =>
				:OLD.CLAVE
		);

	END IF;
END act_hist_delegacion_transp;
/
