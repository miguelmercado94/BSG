CREATE OR REPLACE TRIGGER TRG_AU_EMI_CLIENTE_BENEF
AFTER UPDATE OF ES_BENEF_CONYUGE,ES_BENEF_H1,ES_BENEF_H2,ES_BENEF_H3,ES_BENEF_MADRE,ES_BENEF_PADRE
             ON EMI_CLIENTE FOR EACH ROW
BEGIN
  --1. Inserta como beneficiario de la solicitud al conyuge del asegurado

  IF (   ( :OLD.ES_BENEF_CONYUGE <> :NEW.ES_BENEF_CONYUGE AND :NEW.ES_BENEF_CONYUGE = 'S')
      OR ( :OLD.ES_BENEF_CONYUGE IS NULL AND :NEW.ES_BENEF_CONYUGE = 'S')
	 ) THEN
    Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_CONYUGE
								                  ,:NEW.NUMERO_DOCUMENTO_CONYUGE
								                  ,:NEW.PRIMER_NOMBRE_CONYUGE
								   				  ,:NEW.SEGUNDO_NOMBRE_CONYUGE
								   				  ,:NEW.PRIMER_APELLIDO_CONYUGE
								   				  ,:NEW.SEGUNDO_APELLIDO_CONYUGE
												  ,1 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );
  ELSIF (:OLD.ES_BENEF_CONYUGE <> :NEW.ES_BENEF_CONYUGE AND :NEW.ES_BENEF_CONYUGE = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_CONYUGE
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_CONYUGE;
  END IF;

  --2. Inserta como beneficiario de la solicitud al primer hijo

  IF(   (:OLD.ES_BENEF_H1 <> :NEW.ES_BENEF_H1 AND :NEW.ES_BENEF_H1 = 'S')
     OR (:OLD.ES_BENEF_H1 IS NULL AND :NEW.ES_BENEF_H1 = 'S')
	) THEN
    Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_H1
								                  ,:NEW.NUMERO_DOCUMENTO_H1
								                  ,:NEW.PRIMER_NOMBRE_HIJO1
								   				  ,:NEW.SEGUNDO_NOMBRE_HIJO1
								   				  ,:NEW.PRIMER_APELLIDO_HIJO1
								   				  ,:NEW.SEGUNDO_APELLIDO_HIJO1
												  ,3 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );
  ELSIF (NVL(:OLD.ES_BENEF_H1,'') <> :NEW.ES_BENEF_H1 AND :NEW.ES_BENEF_H1 = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_H1
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_H1;
  END IF;

   --3. Inserta como beneficiario de la solicitud al segundo hijo
  IF(   (:OLD.ES_BENEF_H2 <> :NEW.ES_BENEF_H2 AND :NEW.ES_BENEF_H2 = 'S')
     OR (:OLD.ES_BENEF_H2 IS NULL AND :NEW.ES_BENEF_H2 = 'S')
	) THEN

    Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_H2
								                  ,:NEW.NUMERO_DOCUMENTO_H2
								                  ,:NEW.PRIMER_NOMBRE_HIJO2
								   				  ,:NEW.SEGUNDO_NOMBRE_HIJO2
								   				  ,:NEW.PRIMER_APELLIDO_HIJO2
								   				  ,:NEW.SEGUNDO_APELLIDO_HIJO2
												  ,3 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );
  ELSIF (:OLD.ES_BENEF_H2 <> :NEW.ES_BENEF_H2 AND :NEW.ES_BENEF_H2 = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_H2
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_H2;
  END IF;



   --4. Inserta como beneficiario de la solicitud al tercer hijo
  IF(   (:OLD.ES_BENEF_H3 <> :NEW.ES_BENEF_H3 AND :NEW.ES_BENEF_H3 = 'S')
     OR (:OLD.ES_BENEF_H3 IS NULL AND :NEW.ES_BENEF_H3 = 'S')
	) THEN

    Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_H3
								                  ,:NEW.NUMERO_DOCUMENTO_H3
								                  ,:NEW.PRIMER_NOMBRE_HIJO3
								   				  ,:NEW.SEGUNDO_NOMBRE_HIJO3
								   				  ,:NEW.PRIMER_APELLIDO_HIJO3
								   				  ,:NEW.SEGUNDO_APELLIDO_HIJO3
												  ,3 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );


  ELSIF (:OLD.ES_BENEF_H3 <> :NEW.ES_BENEF_H3 AND :NEW.ES_BENEF_H3 = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_H3
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_H3;
  END IF;

   --5. Inserta como beneficiario de la solicitud al padre
  IF(    (:OLD.ES_BENEF_PADRE <> :NEW.ES_BENEF_PADRE AND :NEW.ES_BENEF_PADRE = 'S')
      OR (:OLD.ES_BENEF_PADRE IS NULL AND :NEW.ES_BENEF_PADRE = 'S')
	) THEN
    Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_PADRE
								                  ,:NEW.NUMERO_DOCUMENTO_PADRE
								                  ,:NEW.PRIMER_NOMBRE_PADRE
								   				  ,:NEW.SEGUNDO_NOMBRE_PADRE
								   				  ,:NEW.PRIMER_APELLIDO_PADRE
								   				  ,:NEW.SEGUNDO_APELLIDO_PADRE
												  ,4 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );
  ELSIF (:OLD.ES_BENEF_PADRE <> :NEW.ES_BENEF_PADRE AND :NEW.ES_BENEF_PADRE = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_PADRE
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_PADRE;
  END IF;


--6. Inserta como beneficiario de la solicitud a la madre

  IF(   (:OLD.ES_BENEF_MADRE <> :NEW.ES_BENEF_MADRE AND :NEW.ES_BENEF_MADRE = 'S')
     OR (:OLD.ES_BENEF_MADRE IS NULL AND :NEW.ES_BENEF_MADRE = 'S')
	) THEN

	Pkg_Emision_Polizas.prc_guarda_beneficiarios(  1 --woperacion
	                                              ,:NEW.NUMERO_SOLICITUD
												  ,:NEW.CODIGO_RIESGO
								   				  , NULL --consecutivo
								   				  ,:NEW.TIPO_DOCUMENTO_MADRE
								                  ,:NEW.NUMERO_DOCUMENTO_MADRE
								                  ,:NEW.PRIMER_NOMBRE_MADRE
								   				  ,:NEW.SEGUNDO_NOMBRE_MADRE
								   				  ,:NEW.PRIMER_APELLIDO_MADRE
								   				  ,:NEW.SEGUNDO_APELLIDO_MADRE
												  ,4 --parentesco
												  ,NULL --calidad
												  ,0 --porcparticipa
												  ,NULL --pagototal
												  ,NULL --rentamensual
												  ,NULL --anospago
												  ,:NEW.USUARIO_TRANSACCION -- wusuario
				                                  );
  ELSIF (:OLD.ES_BENEF_MADRE <> :NEW.ES_BENEF_MADRE AND :NEW.ES_BENEF_MADRE = 'N') THEN
       DELETE FROM EMI_BENEFICIARIOS
         WHERE NUMERO_SOLICITUD         = :NEW.NUMERO_SOLICITUD
	       AND CODIGO_RIESGO 			= :NEW.CODIGO_RIESGO
		   AND TIPDOC_CODIGO			= :NEW.TIPO_DOCUMENTO_PADRE
		   AND NUMERO_DOCUMENTO			= :NEW.NUMERO_DOCUMENTO_PADRE;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20000,'No se puede asociar beneficiario a la solicitud'||SQLERRM);
END;
/
