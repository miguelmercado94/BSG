CREATE OR REPLACE TRIGGER CONTROL_CIU
AFTER INSERT OR DELETE OR UPDATE ON a1000100
FOR EACH ROW
BEGIN
  IF  DELETING THEN
    if :old.cod_postal is not null then
        raise_application_error (-20000, 'No se pueden Borrar codigos de localidades');
    end if;
    BEGIN
	declare v_oficina number(6) := null;
	begin
	   v_oficina := to_number(substr(:old.cod_postal,1,6));
	   delete  ubi_ubicacion
	   where
			  ubic_codigo = 'G'
	          and ubin_numero = v_oficina
	   ;
	   end;
    END;

  ELSIF UPDATING THEN
        if :old.cod_postal is not null and
           :old.cod_postal != :new.cod_postal then
            raise_application_error (-20000, 'No se permite cambiar el codigo de las localidades');
        end if;

        BEGIN
		   update ubi_ubicacion
		   set ubic_nombre = :new.nomb_prov
		   where ubin_numero =  to_number(substr(:new.cod_postal,1,5))
		   ;
         END;
  ELSIF INSERTING THEN
	   begin
        declare
        cursor ciudad is
        select
        cod_cia
        ,nom_cia
        ,RAZSOC_CIA
        ,substr(NIT,1,13) nit
        ,direccion
        from
        a1000900
        ;
        reg number(1);
        begin
          for i in ciudad loop
	         begin
			 if :new.cod_postal > 0 then
			 begin
			 insert into ubi_ubicacion
	          (
              ubin_empresa
			  ,ubic_codigo
			  ,ubin_numero
			  ,ubin_nivel
			  ,ubic_historia
			  ,ubin_padre
			  ,ubic_nombre
			  ,ubic_localizacion
			  ,ubic_mvto
              )
	          values
	          (
               i.cod_cia
			   ,'G'
               ,to_number(:new.cod_postal)
               ,1
               ,'G@'  || :new.cod_postal
			   ,0
			   ,:new.nomb_prov
			   ,null
			   ,'N'
			   );
				exception
				when others then
		   dbms_output.put_line('*error insert tabla ubi_ubicacion-neon*'
		   || 'mensaje'  || sqlerrm);
			   end;
			  end if;
             end;
          end loop;
        end;
       end;
   END IF;
END;
/
