CREATE OR REPLACE TRIGGER TRG_UA_A5021700
AFTER UPDATE OF MCA_ESTADO ON A5021700 
FOR EACH ROW
WHEN (NEW.MCA_ESTADO='C')
BEGIN
    --Elimina los datos que hay actualmente para la cia
  --  DELETE A5021600_PRESTAMOS
   -- WHERE COD_CIA=:New.COD_CIA;
  BEGIN
      --Despues de haber cerrado la tesoreria para la Cia, Copia la tabla fuente en la de prestamos
      INSERT INTO A5021600_PRESTAMOS
      SELECT * FROM A5021600 A5
      WHERE COD_CIA = :New.COD_CIA;
  EXCEPTION
   WHEN OTHERS THEN
    raise_application_error(-2000,'No se han podido pasar los datos a la tabla de recaudos prestamos!');
  END;
  
  IF :NEW.COD_CIA IN (1, 2, 3, 87) THEN
	  BEGIN	
		  --Despues de haber cerrado la tesoreria para la Cia, Copia la tabla fuente en la de auxiliares
		  INSERT INTO A5021600_AUXILIARES
		  SELECT * FROM A5021600 A5
		  WHERE COD_CIA = :New.COD_CIA;
	  EXCEPTION
	   WHEN OTHERS THEN
		raise_application_error(-2000,'No se han podido pasar los datos a la tabla de auxiliares!');
	  END;
  END IF;	  
END;
/
