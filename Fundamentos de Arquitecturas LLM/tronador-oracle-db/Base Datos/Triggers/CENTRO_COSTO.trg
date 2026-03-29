CREATE OR REPLACE TRIGGER centro_costo
AFTER INSERT OR DELETE OR UPDATE ON a1000702
FOR EACH ROW
BEGIN
 IF  DELETING THEN
    BEGIN
      DELETE cen_centro_costo
      WHERE
      cenn_codigo = :OLD.cod_agencia
      ;
    EXCEPTION
	  WHEN OTHERS THEN
		NULL;
    END;
 ELSIF UPDATING THEN
        BEGIN
          UPDATE cen_centro_costo
          SET cenc_nombre = :NEW.nom_agencia
          WHERE
          cenn_codigo = :OLD.cod_agencia
			   ;
	    EXCEPTION
			   WHEN OTHERS THEN
				NULL;
        END;
  ELSIF INSERTING THEN
	   BEGIN
        DECLARE
        CURSOR ciudad IS
        SELECT
        cod_cia
        ,nom_cia
        ,RAZSOC_CIA
        ,SUBSTR(NIT,1,13) nit
        ,direccion
        FROM
        a1000900
        ;
        reg NUMBER(1);
        BEGIN
          FOR i IN ciudad LOOP
	  BEGIN
            INSERT INTO CEN_CENTRO_COSTO
            (
            cenn_empresa
            ,cenn_codigo
            ,cenc_nombre
            ,cenc_estado
            ,cenn_empleado_jefe
            ,cenc_ubi_geo
            ,cenc_sigla
            ,cenc_movimiento
            )
            VALUES
            (
            i.cod_cia
            ,:NEW.cod_agencia
            ,:NEW.nom_agencia
            ,'A'
            ,NULL
            ,SUBSTR(:NEW.cpos_agencia,1,6)
            ,NULL
            ,'N'
            );
           EXCEPTION
		       WHEN OTHERS THEN
		        dbms_output.put_line('*error insert tabla cen_centro_costo*'
		        || 'mensaje'  || SQLERRM);
           END;
          END LOOP;
        END;
       END;
 END IF;
END;
/
