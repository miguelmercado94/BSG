CREATE OR REPLACE TRIGGER fecha_no_habil
AFTER INSERT OR DELETE OR UPDATE ON calendario
FOR EACH ROW
BEGIN
 IF  DELETING THEN
	if :old.tipo_dia = 'F' then
    BEGIN
              delete fnh_fecha_no_habil
               WHERE fnhn_empresa = :old.cod_cia
			   and fnhf_fecha = :old.fecha;
    exception
	when others then
		null;
    END;
	end if;
 ELSIF UPDATING THEN
		if :old.tipo_dia = 'F' then
        BEGIN
              update fnh_fecha_no_habil
				 SET fnhf_fecha = :new.fecha
               WHERE fnhn_empresa = :old.cod_cia
			   and fnhf_fecha = :old.fecha;
	    exception
			   when others then
				null;
        END;
		end if;
  ELSIF INSERTING THEN
	if :old.tipo_dia = 'F' then
       begin
		 insert into fnh_fecha_no_habil
		 (
		 fnhn_empresa
		 ,fnhf_fecha
		 )
		 values
		 (
		 :new.cod_cia
		 ,:new.fecha
		 );
       exception
		  when others then
		   dbms_output.put_line('*error insert tabla fnh_fecha_no_habil-neon*'
		   || 'mensaje'  || sqlerrm);
       end;
    end if;
 END IF;
END;
/
