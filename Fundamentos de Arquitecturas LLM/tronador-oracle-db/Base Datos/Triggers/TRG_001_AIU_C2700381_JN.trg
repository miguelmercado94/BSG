CREATE OR REPLACE TRIGGER Trg_001_Aiu_C2700381_Jn
  AFTER INSERT OR UPDATE ON C2700381 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  Tmpvar NUMBER;

  v_Operacion   CHAR(3);
  Vjn_Secuencia C2700381.Afl_Secuencia%TYPE;

BEGIN
  BEGIN
    SELECT /*+ ALL_ROWS */
     Nvl(MAX(a.Jn_Secuencia) + 1, 1)
      INTO Vjn_Secuencia
      FROM C2700381_Jn a;
  END;

  IF Updating
  THEN
    v_Operacion := 'UPD';

  ELSIF Inserting
  THEN
    v_Operacion := 'INS';

  END IF;

  BEGIN
    INSERT INTO C2700381_Jn A
      (a.Jn_Secuencia, a.Jn_Operation, a.Jn_Oracle_User, a.Jn_Datetime, a.Afl_Secuencia, a.Afl_Tipo_Identificacion, a.Afl_Numero_Identificacion, a.Afl_Digito_Verificacion, a.Afl_Tipo_Afiliado,
       a.Afl_Numero_Referencia_En_Arl, a.Afl_Numero_Formulario, a.Afl_Fecha_Afiliacion, a.Afl_Fecha_Inicio_Cobertura, a.Afl_Fecha_Fin_Cobertura, a.Afl_Fecha_Notif_Traslado, a.Afl_Tipo_Afiliacion,
       a.Afl_Estado_Afiliacion, a.Afl_Motivo_Cancelacion, a.Afl_Motivo_Cancelacion_Desc, a.Afl_Fecha_Cancelacion, a.Afl_Motivo_Anulacion, a.Afl_Motivo_Anulacion_Desc, a.Afl_Fecha_Anulacion,
       a.Afl_Fecha_Retractacion, a.Afl_Estado_Afiliado, a.Afl_Fecha_Estado_Afiliado, a.Afl_Causal_Estado_Afiliado, a.Afl_Sustento_Juridico, a.Afl_Estado_Pago, a.Aud_Creacion, a.Aud_Actualizacion,
       a.Aud_Eliminacion, a.Aud_Version, a.Aud_Usuario, a.Aud_Operacion, a.Afl_Tbl_Num_Pol_Cli, a.Afl_Tipo_Identificacion_Old, a.Afl_Numero_Identificacion_Old, a.Afl_Digito_Verificacion_Old,
       a.Afl_Reg_Mca_Envio, a.Afl_Reg_Fecha_Envio, a.Afl_Reg_Mca_Error, a.Tra_Obs_Sustento_Juridico, a.Afl_Respuesta_Proceso, a.Afl_Ult_Fecha_Actualizacion, a.Afl_Mca_Emp_Indp, a.Afl_Radicado_Respuesta,
       a.Afl_Xml_Respuesta, a.Afl_Mca_Conciliacion_Mora, a.Afl_Ult_Fech_Conciliacion_Mora)

    VALUES
      (Vjn_Secuencia, v_Operacion, USER, SYSDATE, :New.Afl_Secuencia, :New.Afl_Tipo_Identificacion, :New.Afl_Numero_Identificacion, :New.Afl_Digito_Verificacion, :New.Afl_Tipo_Afiliado,
       :New.Afl_Numero_Referencia_En_Arl, :New.Afl_Numero_Formulario, :New.Afl_Fecha_Afiliacion, :New.Afl_Fecha_Inicio_Cobertura, :New.Afl_Fecha_Fin_Cobertura, :New.Afl_Fecha_Notif_Traslado,
       :New.Afl_Tipo_Afiliacion, :New.Afl_Estado_Afiliacion, :New.Afl_Motivo_Cancelacion, :New.Afl_Motivo_Cancelacion_Desc, :New.Afl_Fecha_Cancelacion, :New.Afl_Motivo_Anulacion,
       :New.Afl_Motivo_Anulacion_Desc, :New.Afl_Fecha_Anulacion, :New.Afl_Fecha_Retractacion, :New.Afl_Estado_Afiliado, :New.Afl_Fecha_Estado_Afiliado, :New.Afl_Causal_Estado_Afiliado,
       :New.Afl_Sustento_Juridico, :New.Afl_Estado_Pago, :New.Aud_Creacion, :New.Aud_Actualizacion, :New.Aud_Eliminacion, :New.Aud_Version, :New.Aud_Usuario, :New.Aud_Operacion, :New.Afl_Tbl_Num_Pol_Cli,
       :New.Afl_Tipo_Identificacion_Old, :New.Afl_Numero_Identificacion_Old, :New.Afl_Digito_Verificacion_Old, :New.Afl_Reg_Mca_Envio, :New.Afl_Reg_Fecha_Envio, :New.Afl_Reg_Mca_Error,
       :New.Tra_Obs_Sustento_Juridico, :New.Afl_Respuesta_Proceso, :New.Afl_Ult_Fecha_Actualizacion, :New.Afl_Mca_Emp_Indp, :New.Afl_Radicado_Respuesta, :New.Afl_Xml_Respuesta,
       :New.Afl_Mca_Conciliacion_Mora, :New.Afl_Ult_Fech_Conciliacion_Mora);
  END;
END Trg_001_Aiu_C2700381_Jn;
/
