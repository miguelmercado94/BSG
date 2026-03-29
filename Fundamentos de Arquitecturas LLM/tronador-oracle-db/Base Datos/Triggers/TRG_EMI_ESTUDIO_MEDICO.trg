CREATE OR REPLACE TRIGGER trg_emi_estudio_medico
AFTER INSERT ON EMI_MEDICAMENTO_ASEGURADO
FOR EACH ROW
DECLARE
 var_estudio NUMBER;
BEGIN

 SELECT estudio
   INTO var_estudio
   FROM EMI_MEDICAMENTOS
  WHERE codigo_med = :NEW.cod_med;

  IF var_estudio IS NOT NULL THEN
     IF var_estudio = 1 THEN
	    UPDATE EMI_BLOQUE_MEDICO SET estudio_hta = 'S' WHERE numero_solicitud = :NEW.numero_solicitud AND codigo_riesgo = :NEW.codigo_riesgo;
     ELSIF var_estudio = 2 THEN
        UPDATE EMI_BLOQUE_MEDICO SET estudio_diabetes = 'S' WHERE numero_solicitud = :NEW.numero_solicitud AND codigo_riesgo = :NEW.codigo_riesgo;
	 ELSIF var_estudio = 3 THEN
        UPDATE EMI_BLOQUE_MEDICO SET estudio_lipidos = 'S' WHERE numero_solicitud = :NEW.numero_solicitud AND codigo_riesgo = :NEW.codigo_riesgo;
 	END IF;
  END IF;
END;
/
