CREATE OR REPLACE TRIGGER CONTROL_TASAS
AFTER INSERT OR DELETE OR UPDATE ON a1000500
FOR EACH ROW
BEGIN
  IF  DELETING THEN
    BEGIN
	   delete tas_tasa_cambio
	   where tasf_fecha	= :old.fecha_tipo_cambio
	   and tasn_moneda = :old.cod_mon
	   ;
    END;
  ELSIF UPDATING THEN
  begin
	declare x varchar2(1):= null;
	begin
	  select 1 into x
	  from tas_tasa_cambio
	  where
		   tasn_moneda = :old.cod_mon
		   and tasf_fecha = :old.fecha_tipo_cambio;
        BEGIN
		   update tas_tasa_cambio
		   set tasv_valor = :new.tc1
		   where tasn_moneda = :old.cod_mon
		   and tasf_fecha = :old.fecha_tipo_cambio
		   ;
        END;
    exception
	   when no_data_found then
		begin
			 insert into tas_tasa_cambio
	          (
			   tasn_moneda
			   ,tasf_fecha
			   ,tasv_valor
              )
	          values
	          (
               :new.cod_mon
			   ,:new.fecha_tipo_cambio
			   ,:new.tc1
			   );
			   exception
			   when others then
		   dbms_output.put_line('*error insert tabla tas_tasa_cambio-neon-b*'
		   || 'mensaje'  || sqlerrm);
		end;
       when others then
		 null;
    end;
  end;
  ELSIF INSERTING THEN
	   begin
			 insert into tas_tasa_cambio
	          (
			   tasn_moneda
			   ,tasf_fecha
			   ,tasv_valor
              )
	          values
	          (
               :new.cod_mon
			   ,:new.fecha_tipo_cambio
			   ,:new.tc1
			   );
			   exception
			   when others then
		   dbms_output.put_line('*error insert tabla tas_tasa_cambio-neon*'
		   || 'mensaje'  || sqlerrm);
        end;
   END IF;
END;
/
