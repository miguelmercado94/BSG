CREATE OR REPLACE TRIGGER COMPANIAS_ASEG
AFTER INSERT OR DELETE OR UPDATE ON a1000600
FOR EACH ROW
BEGIN
  IF  DELETING THEN
    BEGIN
	   delete com_compania
	   where
	   comn_codigo = :old.cod_ciacoa
	   ;
	   exception
	   when others then
	   null;
    END;
  ELSIF UPDATING THEN
        BEGIN
		   update com_compania
		   set comc_nombre = substr(:new.NOM_CIACOA,1,40)
		   where comn_codigo = :old.cod_ciacoa
		   ;
		   exception
		   when others then
		   null;
         END;
  ELSIF INSERTING THEN
	   begin
			 insert into com_compania
	          (
			  comn_codigo,
			  comc_nombre
              )
	          values
	          (
	          :new.cod_ciacoa
			  ,substr(:new.NOM_CIACOA,1,40)
			   );
        exception
		when others then
		   dbms_output.put_line('*error insert tabla com_compania*'
		   || 'mensaje'  || sqlerrm);
        end;
   END IF;
END;
/
