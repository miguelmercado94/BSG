CREATE OR REPLACE TRIGGER CONTROL_CIA
AFTER INSERT OR DELETE OR UPDATE ON A1000900 
FOR EACH ROW
BEGIN
 IF  DELETING THEN
	if :old.cod_cia is not null then
    BEGIN
              update emp_empresa
			  set empc_estado = 'I'
				 WHERE
				 empn_codigo = :old.cod_cia
				 ;
    exception
	  when others then
		null;
    END;
	end if;
	/*  que pasa con el nivel o falta un estado y las ciudades*/
 ELSIF UPDATING THEN
        BEGIN
              UPDATE emp_empresa
				 SET
					 empc_nombre = :new.nom_cia,
					 empc_razon_social = :new.RAZSOC_CIA,
					 empn_nit  = substr(:new.nit,1,13),
                     empc_direccion = :new.direccion
					 --empc_llave_datasource = 'ARES_ACCESO'
               WHERE empn_codigo = :old.COD_CIA;
	    exception
			   when others then
				null;
        END;
  ELSIF INSERTING THEN
	   begin
		 declare v_emp varchar2(1) := null;
		 v_nit number(13) := null;
       begin
		 begin
		  select 1 into v_emp
		  from emp_empresa
		  where empn_codigo = :new.cod_cia;
	     exception
		   when no_data_found then
			  v_emp := null;
			  when too_many_rows then
				v_emp := 1;
			  when others then
				v_emp := 1;
		 end;
		 if v_emp is null then
			   v_nit := substr(:new.nit,1,13);
			   begin
                 INSERT INTO emp_empresa
				 (
                 empn_codigo
                 ,empc_nombre
                 ,empc_razon_social
                 ,empn_nit
				 --,empc_llave_datasource
				 ,empc_estado
				 ,empc_direccion
				 )
                  VALUES
				  (:NEW.COD_CIA
                  ,:NEW.nom_cia
                  ,:NEW.RAZSOC_CIA
				  ,v_nit
				  --,'ARES_ACCESO'
				  ,'A'
				  ,:NEW.direccion
				 );
                exception
				when others then
		   dbms_output.put_line('*error insert tabla emp_empresa-neon*'
		   || 'mensaje'  || sqlerrm);
				end;
          end if;
       end;
      end;
 END IF;
END;
/
