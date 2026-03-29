CREATE OR REPLACE TRIGGER TRG_IVA_COM_SOAT
  AFTER INSERT OR DELETE OR UPDATE  ON A2000252 
  FOR EACH ROW
DECLARE
  L_SOAT    VARCHAR2(1) := 'N';
  L_RES_IVA NUMBER(5);
  L_PORC_IVA NUMBER(5,2);
BEGIN
  BEGIN
    SELECT 'S'
      INTO L_SOAT
      FROM SIM_DATOSSOAT D
     WHERE D.NUM_SECU_POL IN ( :NEW.NUM_SECU_POL, :OLD.NUM_SECU_POL)
       AND D.NUM_END = 0;
  EXCEPTION
    WHEN OTHERS THEN
      L_SOAT := 'N';
  END;

  --sim_proc_log('hlc 14062022 l_soat new ' || l_soat ||' --- '|| :new.num_secu_pol ||' --- '||:new.num_end ,'');    
  --sim_proc_log('hlc 14062022 l_soat old ' || l_soat ||' --- '|| :old.num_secu_pol ||' --- '||:old.num_end ,'');    
  IF L_SOAT = 'S' THEN
    BEGIN
      SELECT SAGHI.RESPONSABLE_IVA REG_IVA, SAGHI.VALOR_IVA PORCENTAJE
        INTO L_RES_IVA, L_PORC_IVA
        FROM S0H_V_INFO_TRIBIVA SAGHI
       WHERE SAGHI.CLAVE = :NEW.COD_AGENTE;
    EXCEPTION
      WHEN OTHERS THEN
        L_RES_IVA  := 2;
        L_PORC_IVA := 0;
    END;
    IF INSERTING AND :NEW.COD_AGRUP_CONT = '310310315' THEN
      INSERT INTO SIM_COMISIONES_IVA_SOAT
        (NUM_SECU_POL,
         NUM_END,
         TIPO_REG,
         NUM_FACTURA,
         COD_CIACOA,
         COD_AGENTE,
         COM_NORMAL,
         PRI_COM,
         FOR_ACTUACION,
         PORC_COMI,
         COD_BENEF,
         COD_AGRUP_CONT,
         FECHA_EMI_END,
         VLR_IVA_COMISION,
         PORC_IVA_COMISION)
      VALUES
        (:NEW.NUM_SECU_POL,
         :NEW.NUM_END,
         :NEW.TIPO_REG,
         :NEW.NUM_FACTURA,
         :NEW.COD_CIACOA,
         :NEW.COD_AGENTE,
         :NEW.COM_NORMAL,
         :NEW.PRI_COM,
         :NEW.FOR_ACTUACION,
         :NEW.PORC_COMI,
         :NEW.COD_BENEF,
         :NEW.COD_AGRUP_CONT,
         :NEW.FECHA_EMI_END,
         DECODE(L_RES_IVA,1,ROUND((:NEW.COM_NORMAL*19)/100,0),0), 
         DECODE(L_RES_IVA,1,L_PORC_IVA,0));
    END IF;
    IF DELETING THEN
  --    sim_proc_log('hlc 14062022 delete  ' || l_soat,'');    
      DELETE SIM_COMISIONES_IVA_SOAT
       WHERE NUM_SECU_POL = :OLD.NUM_SECU_POL
         AND NUM_END = :OLD.NUM_END;
    END IF;
    IF UPDATING AND :NEW.COD_AGRUP_CONT = '310310315' THEN
      UPDATE SIM_COMISIONES_IVA_SOAT
         SET NUM_SECU_POL      = :NEW.NUM_SECU_POL,
             NUM_END           = :NEW.NUM_END,
             TIPO_REG          = :NEW.TIPO_REG,
             NUM_FACTURA       = :NEW.NUM_FACTURA,
             COD_CIACOA        = :NEW.COD_CIACOA,
             COD_AGENTE        = :NEW.COD_AGENTE,
             COM_NORMAL        = :NEW.COM_NORMAL,
             PRI_COM           = :NEW.PRI_COM,
             FOR_ACTUACION     = :NEW.FOR_ACTUACION,
             PORC_COMI         = :NEW.PORC_COMI,
             COD_BENEF         = :NEW.COD_BENEF,
             COD_AGRUP_CONT    = :NEW.COD_AGRUP_CONT,
             FECHA_EMI_END     = :NEW.FECHA_EMI_END,
             VLR_IVA_COMISION  = DECODE(L_RES_IVA,1,ROUND((:NEW.COM_NORMAL*19)/100,0),0),
             PORC_IVA_COMISION = DECODE(L_RES_IVA,1,L_PORC_IVA,0)
       WHERE NUM_SECU_POL = :NEW.NUM_SECU_POL
         AND NUM_END = :NEW.NUM_END;
    END IF;
  END IF;
END TRG_IVA_COM_SOAT;
/
