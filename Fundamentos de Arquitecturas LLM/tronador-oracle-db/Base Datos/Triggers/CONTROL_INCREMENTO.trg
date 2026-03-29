CREATE OR REPLACE TRIGGER CONTROL_INCREMENTO
AFTER INSERT OR DELETE OR UPDATE ON a1000501
FOR EACH ROW
BEGIN
  IF  DELETING THEN
    BEGIN
	   delete ita_incremento_tasa
	   where itaf_fecha	= :old.fecha_tipo_cambio
	   and itac_codigo = 'IPC'
	   ;
    END;
  ELSIF UPDATING THEN
  begin
	declare x varchar2(1):= null;
	begin
	  select 1 into x
	  from ita_incremento_tasa
	  where
		   itac_codigo = 'IPC'
		   and itaf_fecha = :old.fecha_tipo_cambio;
        BEGIN
		   update ita_incremento_tasa
		   set itan_tasa = :new.tc1
		   where itac_codigo = 'IPC'
		   and itaf_fecha = :old.fecha_tipo_cambio
		   ;
        END;
    exception
	   when no_data_found then
		begin
	      insert into ita_incremento_tasa
	      (
	      itac_codigo
	      ,itaf_fecha
	      ,itan_tasa
	      ,itav_valor_min
          )
	      values
	      (
	      'IPC'
	      ,:new.fecha_tipo_cambio
	      ,:new.tc1
	      ,null
	      );
	   exception
			   when others then
		   dbms_output.put_line('*error insert tabla ita_incremento_tasa*'
		   || 'mensaje'  || sqlerrm);
		end;
     when others then
		 null;
    end;
  end;
  ELSIF INSERTING THEN
	   begin
	     insert into ita_incremento_tasa
	     (
	     itac_codigo
	     ,itaf_fecha
	     ,itan_tasa
	     ,itav_valor_min
         )
	     values
	     (
	     'IPC'
	     ,:new.fecha_tipo_cambio
	     ,:new.tc1
	     ,null
	     );
	   exception
	   when others then
	   dbms_output.put_line('*error insert tabla ita_incremento_tasa*'
	   || 'mensaje'  || sqlerrm);
        end;
   END IF;
END;
/
