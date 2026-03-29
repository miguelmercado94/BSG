CREATE OR REPLACE TRIGGER a5021104_a5021103
BEFORE INSERT ON A5021104 FOR EACH ROW
DECLARE

cantidad number :=0;

BEGIN

   IF :new.tdoc_tercero IS NULL THEN

         if :new.tipo_documento = '01' then
		    :new.tdoc_tercero := 'NT';
		 elsif :new.tipo_documento = '02' then
		    :new.tdoc_tercero := 'CC';
		 elsif :new.tdoc_tercero = 'TI' then
		    :new.tipo_documento := '03';
		 elsif :new.tipo_documento = '04' then
		    :new.tdoc_tercero := 'CE';
		 elsif :new.tipo_documento = '05' then
		    :new.tdoc_tercero := 'PP';
		 elsif :new.tipo_documento = '07' then
		    :new.tdoc_tercero := 'NM';
		 end if;

   END IF;

   IF :new.estado_transferencia IS NULL THEN
      :new.estado_transferencia := 0;  -- Optimizacion para usar indice I2_A5021104
   END IF;

END;
/
