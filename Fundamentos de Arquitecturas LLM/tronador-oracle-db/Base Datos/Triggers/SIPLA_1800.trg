CREATE OR REPLACE TRIGGER SIPLA_1800
AFTER INSERT ON A2000040
FOR EACH ROW
WHEN ( NEW.NUM_END > 0        AND  NEW.TIPO_REG = 'T' AND       (NEW.END_SUMA_ASEG <> 0 OR   NEW.END_PRIMA_COB <> 0) )
DECLARE
	W_EVENTO        A1001380.COD_EVENTO%TYPE;
	W_MENSAJE       A1001380.OBSERVACIONES%TYPE;
        W_ANO    	VARCHAR2(4) := null;
        W_FECHA  	DATE        := null;
	w_cod_cia	A2000030.cod_cia%TYPE;
	w_cod_secc	A2000030.cod_secc%TYPE;
	w_num_end	A2000030.num_end%TYPE;
	w_nro_documto	A2000030.nro_documto%TYPE;
	dummy		integer;
  vtipoend varchar2(2);
BEGIN
   select tipo_end into vtipoend from a2000030
   where num_Secu_pol = :new.num_secu_pol and
         num_end = :new.num_end;
   if vtipoend != 'AT' and vtipoend != 'RE' then
   select to_char(sysdate,'YYYY') into w_ano
   from dual;
   w_fecha := to_date ( ltrim (w_ano) || '0101', 'YYYYMMDD' );
   BEGIN
	IF :NEW.NUM_END   > 0 and :NEW.TIPO_REG = 'T' AND
	  (:NEW.END_SUMA_ASEG <> 0 OR :NEW.END_PRIMA_COB <> 0) THEN
	   Begin
	     If  :NEW.END_SUMA_ASEG <> 0 then
		  w_evento  := 3;
  		  w_mensaje := 'Cambio del valor asegurado';
	     Else
    		  If  :NEW.END_PRIMA_COB <> 0 then
        	       w_evento  := 4;
            	       w_mensaje := 'Cambio de cobertura';
    		  End if;
	     End if;
	     select  count(*) into dummy
	       from  A1001380
     	      where  fecha_vigencia 	 = w_fecha
     	        and  cod_producto   	 = 2
     	        and  cod_clase_pr   	 = 1
     	        and  tipo_benef      	 = 1
     	        and  por            	 = 1
     	        and  cod_evento     	 = w_evento
     	        and  nvl(num_secu_pol,0) = :new.num_secu_pol
     	        and  nvl(num_end,0) 	 = :new.num_end;
             If dummy = 0 then
	        Begin
	   	  select  /*+ index(I1_A2000030) */
          nro_documto
	       into w_nro_documto
	    	 from   A2000030
	     	 where num_secu_pol = :new.num_secu_pol
         	   and  (cod_cia 		    = 3 or
		   	          (cod_cia = 2 and cod_secc = 40)) -- vida
   	       	 and   num_end > 0
 	     	 group   by
 	 	 	     cod_cia
 		   	  ,cod_secc
 		   	  ,num_secu_pol
		   	  ,nro_documto;
        	  exception
                	   when no_data_found then  null;
       			   when others        then
           		   begin
  DBMS_OUTPUT.PUT_LINE ('Debe actualizar informacion complementaria');
           		      INSERT INTO A1001380
              			VALUES (
                    			SECUENCIA_SEG.NEXTVAL
                   			,nvl(w_nro_documto,0)
                   			,w_fecha
                   			,2
                   			,1
                   			,1
                   			,1
                   			,w_evento
                   			,:NEW.NUM_SECU_POL
                   			,:NEW.NUM_END
		   			,null
                   			,null
                   			,:new.tipo_reg
                   			,null
			                ,w_mensaje
		   			,user
                   			,trunc(sysdate)
                 		       );
                	      EXCEPTION
                     		  WHEN OTHERS   THEN  NULL;
			   End;
                End;
	     End if;
	   End;
        End if;
   End;
 end if;
 exception when others then null;
End;
/
