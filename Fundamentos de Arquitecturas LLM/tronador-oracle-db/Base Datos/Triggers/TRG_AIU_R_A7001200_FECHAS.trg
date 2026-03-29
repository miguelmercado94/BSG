CREATE OR REPLACE TRIGGER TRG_AIU_R_A7001200_FECHAS
  AFTER INSERT OR UPDATE OF FEC_REAP_RVA, FEC_BAJA_RVA
    ON A7001200
  FOR EACH ROW
DECLARE
  v_operacion varchar2(1);
BEGIN
 IF INSERTING THEN v_operacion := 'I';
 ELSE              v_operacion := 'U';
 END IF;

 IF :NEW.FEC_REAP_RVA > SYSDATE + 1 OR
    :NEW.FEC_REAP_RVA < TO_DATE('19900101','YYYYMMDD') THEN
    BEGIN
    INSERT INTO C9990921 (TABLA       , CAMPO ,  OPERACION,
                          USUARIO_RESPONSABLE ,  FECHA_CREACION,
                          USUARIO_CREACION,      VALOR,
                          LLAVE1      ,LLAVE2 ,  LLAVE3)
                VALUES  ('A7001200','FEC_REAP_RVA',v_operacion,
                         'INTASI20', SYSDATE,
                          USER     , :NEW.FEC_REAP_RVA ,
                          :NEW.NUM_SECU_EXPED,:NEW.VALOR_MOVIM,
                          'cob:'||:NEW.COD_COB||' ord '||:NEW.NRO_ORDEN_EXP);
     EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
 END IF;
 IF (:NEW.FEC_BAJA_RVA > SYSDATE + 1 OR
    :NEW.FEC_BAJA_RVA < TO_DATE('19900101','YYYYMMDD')) THEN
    BEGIN
    INSERT INTO C9990921 (TABLA       , CAMPO ,  OPERACION,
                          USUARIO_RESPONSABLE ,  FECHA_CREACION,
                          USUARIO_CREACION,      VALOR,
                          LLAVE1      ,LLAVE2 ,  LLAVE3)
                VALUES  ('A7001200','FEC_BAJA_RVA',v_operacion,
                         'INTASI20', SYSDATE,
                          USER     , :NEW.FEC_BAJA_RVA ,
                          :NEW.NUM_SECU_EXPED,:NEW.VALOR_MOVIM,
                          'cob:'||:NEW.COD_COB||' ord '||:NEW.NRO_ORDEN_EXP);
     EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
 END IF;

END TRG_AIU_R_A7001200_FECHAS;
/
