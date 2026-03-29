CREATE OR REPLACE TRIGGER SIPLA_1600
AFTER INSERT ON A5021600
FOR EACH ROW
DECLARE
	W_TOPE   A1001376.TOPE%TYPE;
	W_TOPE1  A1001376.TOPE%TYPE;
        W_ANO    VARCHAR2(4) := null;
        W_FECHA  DATE        := null;
BEGIN
   BEGIN
        select to_char(sysdate,'YYYY') into w_ano
        from dual;
        w_fecha := to_date ( ltrim (w_ano) || '0101', 'YYYYMMDD' );
	SELECT  NVL(TOPE,0) INTO W_TOPE FROM A1001376
         WHERE  COD_PRODUCTO = 2
           AND  COD_EVENTO   = 13;
	EXCEPTION
        	WHEN NO_DATA_FOUND THEN  W_TOPE := 0;
		WHEN OTHERS THEN W_TOPE := 0;
   END;
   Begin
	SELECT  NVL(TOPE,0) INTO W_TOPE1 FROM A1001376
	 WHERE  COD_PRODUCTO = 2
      	   AND  COD_EVENTO   = 9;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN  W_TOPE1 := 0;
		WHEN OTHERS 	   THEN  W_TOPE1 := 0;
   end;
   BEGIN
	IF    :NEW.COD_PAGO      =  2  AND :NEW.MCA_CAJA_BCO  = 'C'
          AND :NEW.RECIBO       !=  0  AND :NEW.RECIBO   IS NOT  NULL
	  AND (:NEW.IMP_MON_PAIS + (NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0)) >= W_TOPE)
          AND :NEW.TIPO_ACTU     = 'CB'  THEN
           BEGIN
	     INSERT INTO A1001380
    	      VALUES(
	            SECUENCIA_SEG.NEXTVAL
		   ,nvl(:NEW.COD_BENEF,0)
		   ,w_fecha
		   ,2
		   ,1
		   ,1
		   ,1
		   ,13
	       	   ,nvl(:NEW.NUM_POL1,0)
		   ,nvl(:NEW.NUM_END,0)
		   ,null
    		   ,:NEW.RECIBO
		   ,null
		   ,null
		   ,'RECAUDO DE TRANSACCION EN EFECTIVO POR VALOR DE : ' ||
                     (:NEW.IMP_MON_PAIS + (NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0))) ||
                       ' SUPERA EL TOPE = ' || w_tope
		   ,user
		   ,trunc(sysdate)
                    );
		EXCEPTION
		     WHEN OTHERS          THEN  NULL;
	   END;
	   DBMS_OUTPUT.PUT_LINE ('Debe exigir formato. Transaccion en efectivo supera el tope : ' || w_tope)
;
	ELSIF  :NEW.COD_PAGO      =  2  AND :NEW.MCA_CAJA_BCO  = 'C'
           AND :NEW.RECIBO       !=  0  AND :NEW.RECIBO   IS NOT  NULL
           AND (:NEW.IMP_MON_PAIS + NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0) >= W_TOPE1)
           AND :NEW.CONCEPTO IN('030','290','292','294','297')  THEN
           BEGIN
             INSERT INTO A1001380
              VALUES(
                    SECUENCIA_SEG.NEXTVAL
                   ,nvl(:NEW.COD_BENEF,0)
                   ,w_fecha
                   ,2
                   ,1
                   ,1
                   ,1
                   ,9
                   ,nvl(:NEW.NUM_POL1,0)
                   ,nvl(:NEW.NUM_END,0)
		   ,null
                   ,:NEW.RECIBO
                   ,null
                   ,null
                   ,'RECAUDO DE SALVAMENTOS EN EFECTIVO POR VALOR DE : ' ||(:NEW.IMP_MON_PAIS + (NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0))) ||' SUPERA EL TOPE = ' || w_tope
		   ,user
                   ,trunc(sysdate)
                    );
                EXCEPTION
                     WHEN OTHERS          THEN  NULL;
           END;
	END IF;
   END;
END;
/
