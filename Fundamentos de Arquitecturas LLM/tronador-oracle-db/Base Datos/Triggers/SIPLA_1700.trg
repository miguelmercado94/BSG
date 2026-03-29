CREATE OR REPLACE TRIGGER SIPLA_1700
AFTER INSERT ON A2990700
FOR EACH ROW
DECLARE
	W_TOPE   A1001376.TOPE%TYPE;
        W_ANO    VARCHAR2(4) := null;
        W_FECHA  DATE        := null;
        w_valor  A5020301.IMP_MONEDA_LOCAL%TYPE;
BEGIN
   BEGIN
        select to_char(sysdate,'YYYY') into w_ano
        from dual;
        w_fecha := to_date ( ltrim (w_ano) || '0101', 'YYYYMMDD' );
	SELECT  NVL(TOPE,0) INTO W_TOPE FROM A1001376
         WHERE  COD_PRODUCTO = 2
           AND  COD_EVENTO   = 22;
	EXCEPTION
        	WHEN NO_DATA_FOUND THEN  W_TOPE := 0;
		WHEN OTHERS THEN W_TOPE := 0;
   END;
   BEGIN
---Si es una devolucion entonces: busco el recaudo total inicial y lo comparo.
      IF  (:NEW.IMP_MONEDA_LOCAL + (NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0)) < 0) THEN
          BEGIN
      	     select /*+ index(b i1_a5020301) */
              sum(b.IMP_MONEDA_LOCAL+nvl(b.IMP_IMPTOS_MON_LOCAL,0))
   	       into w_valor
	       from a5020301 b
	      where b.cod_cia     = :new.cod_cia
  	        and b.cod_secc    = :new.cod_secc
  		and b.NUM_POL1    = :new.NUM_POL1
  		and b.num_factura = 1
  		and b.cod_ramo    = :new.COD_RAMO
	        and (tipo_actu ='CT' or tipo_actu='CP')
              group by
                    b.COD_CIA
        	   ,b.COD_SECC
        	   ,b.num_pol1
        	   ,b.cod_ramo
       	       	   ,b.num_factura;
	     EXCEPTION
		     WHEN NO_DATA_FOUND   THEN  w_valor:=0;
                     WHEN OTHERS          THEN  w_valor:=0;
          END;
          IF  (:new.IMP_MONEDA_LOCAL+nvl(:new.IMP_IMPTOS_MON_LOCAL,0))* -1
                  > w_valor * -1 * (w_tope/100) THEN
              BEGIN
	     	INSERT INTO A1001380
    	      	VALUES(
	            SECUENCIA_SEG.NEXTVAL
		   ,nvl(:NEW.NRO_DOCUMTO,0)
		   ,w_fecha
		   ,2
		   ,1
		   ,1
		   ,1
		   ,22
	       	   ,nvl(:NEW.NUM_POL1,0)
		   ,nvl(:NEW.NUM_END,0)
		   ,:NEW.COD_CIA
    		   ,:NEW.COD_SECC
		   ,null
		   ,:NEW.COD_RAMO
		   ,'Devolucion por valor de : ' ||
                    (:NEW.IMP_MONEDA_LOCAL + (NVL(:NEW.IMP_IMPTOS_MON_LOCAL,0)))
                    ||' supera el ' ||w_tope ||'% del valor inicial $ '||w_valor
		   ,user
		   ,trunc(sysdate)
                    );
		EXCEPTION
		     WHEN OTHERS          THEN  NULL;
	      END;
--DBMS_OUTPUT.PUT_LINE ('ojo pase por aqui');
          END IF;
      END IF;
   END;
END;
/
