CREATE OR REPLACE TRIGGER "TRG_HIST_CLASSIFICACION_2" BEFORE
  UPDATE ON IND_REGLAS_CLASIFICACION FOR EACH ROW
DECLARE v_id NUMBER := NULL;
  BEGIN
    BEGIN
      SELECT ID
      INTO v_id
      FROM SIM_CLASSIFICACION_REGLAS_JN
      WHERE ID  = :NEW.ID
      AND ROWNUM=1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT
      INTO OPS$PUMA.SIM_CLASSIFICACION_REGLAS_JN
        (
          ID,
          CONSECUENCIA,
          PRODUCTO,
          SCORE_RIESGO,
          COBERTURA ,
          CAUSA,
          MODELO_RIESGO_PRETENSION,
          RESULTADO_ENCUESTA,
          MOTOR_CLASIFICACION_CASO,
          CLASIFICACION_CASO_CODE,
          CLV,
          COMPANY,
          SECCION,
          FECHA_MODIFICACION,
          USUARIO_MODIFICACION,
          FECHA_BAJA
        )
        VALUES
        (
          :old.ID,
          :old.CONSECUENCIA,
          :old.PRODUCTO,
          :old.SCORE_RIESGO,
          :old.COBERTURA ,
          :old.CAUSA,
          :old.MODELO_RIESGO_PRETENSION,
          :old.RESULTADO_ENCUESTA,
          :old.MOTOR_CLASIFICACION_CASO,
          :old.CLASIFICACION_CASO_CODE,
          :old.CLV,
          :old.COMPANY,
          :old.SECCION,
          :old.FECHA_CREACION,
          :old.USUARIO_CREACION,
          :OLD.FECHA_BAJA
        );
    END;
	
 END TRG_HIST_CLASSIFICACION_2;
/
