CREATE OR REPLACE TRIGGER TRG_BIU_A502FACTURAE_AUDITORIA 
BEFORE INSERT OR UPDATE  ON A502_FACTURA_E
FOR EACH ROW
WHEN (NEW.tipo_factura = 'FF')
DECLARE

	CURSOR cur_generar_id IS
		SELECT TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISSFF3') || DBMS_RANDOM.STRING('U',3)
		FROM DUAL;

	vca_comando      VARCHAR2(20);
	vca_valor_old    VARCHAR2(100);
	vca_valor_new    VARCHAR2(100);
	vca_sql          VARCHAR2(32767);
	vnu_id_factura   NUMBER;
	vca_id_auditoria VARCHAR2(20);
	vda_fecha        DATE;

BEGIN

	vda_fecha := SYSDATE;

	IF ( INSERTING ) THEN

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;

		vca_comando      := 'INSERT';
		vnu_id_factura   := :NEW.SECUENCIA;

		vca_sql          := ' VLR_TOT_FACTURA = ' || :NEW.VLR_TOT_FACTURA || ', FEC_EMISION = ' || :NEW.FEC_EMISION || ', NRO_FACTURA = ' || :NEW.NRO_FACTURA ||
							', VLR_IVA = ' || :NEW.VLR_IVA || ', VLR_IMP_CONSUMO = ' || :NEW.VLR_IMP_CONSUMO || ', COD_MON = ' || :NEW.COD_MON || 
							', COD_BENEF = '|| :NEW.COD_BENEF || ', TDOC_TERCERO = ' || :NEW.TDOC_TERCERO || ', NOMBENEF = ' || :NEW.NOMBENEF || 
							', NIT = ' || :NEW.NIT || ', TIPO_DOC = ' || :NEW.TIPO_DOC;

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, NULL, vnu_id_factura, :NEW.USUARIO, vda_fecha, 'SECUENCIA', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING )  THEN
		vca_comando    := 'UPDATE';
		vnu_id_factura := :OLD.SECUENCIA;
		vca_sql 	   := 'UPDATE A502_FACTURA_E SET ';
	END IF;

	IF ( UPDATING('VLR_TOT_FACTURA') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;

		vca_valor_old := :OLD.VLR_TOT_FACTURA;
		vca_valor_new := :NEW.VLR_TOT_FACTURA;
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET  VLR_TOT_FACTURA = ' || vca_valor_new;

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'VLR_TOT_FACTURA', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('FEC_EMISION') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.FEC_EMISION;
		vca_valor_new := :NEW.FEC_EMISION;
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET FEC_EMISION = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'FEC_EMISION', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('NRO_FACTURA') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.NRO_FACTURA;
		vca_valor_new := :NEW.NRO_FACTURA;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET NRO_FACTURA = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'NRO_FACTURA', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('VLR_IVA') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.VLR_IVA;
		vca_valor_new := :NEW.VLR_IVA;		
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET VLR_IVA = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'VLR_IVA', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('VLR_IMP_CONSUMO') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.VLR_IMP_CONSUMO;
		vca_valor_new := :NEW.VLR_IMP_CONSUMO;		
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET VLR_IMP_CONSUMO = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'VLR_IMP_CONSUMO', vnu_id_factura, vca_sql );


	END IF;

	IF ( UPDATING('COD_MON') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.COD_MON;
		vca_valor_new := :NEW.COD_MON;		
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET COD_MON = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'COD_MON', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('COD_BENEF') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;		

		vca_valor_old := :OLD.COD_BENEF;
		vca_valor_new := :NEW.COD_BENEF;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET COD_BENEF = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'COD_BENEF', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('TDOC_TERCERO') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;		

		vca_valor_old := :OLD.TDOC_TERCERO;
		vca_valor_new := :NEW.TDOC_TERCERO;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET TDOC_TERCERO = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'TDOC_TERCERO', vnu_id_factura, vca_sql );

	END IF;	

	IF ( UPDATING('NOMBENEF') ) THEN

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.NOMBENEF;
		vca_valor_new := :NEW.NOMBENEF;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET NOMBENEF = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;	

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'NOMBENEF', vnu_id_factura, vca_sql );

	END IF;	

	IF ( UPDATING('NIT') ) THEN	

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;		

		vca_valor_old := :OLD.NIT;
		vca_valor_new := :NEW.NIT;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET NIT = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'NIT', vnu_id_factura, vca_sql );

	END IF;	

	IF ( UPDATING('TIPO_DOC') ) THEN

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.TIPO_DOC;
		vca_valor_new := :NEW.TIPO_DOC;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET TIPO_DOC = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;		

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'TIPO_DOC', vnu_id_factura, vca_sql );

	END IF;

	IF ( UPDATING('ESTADO') ) THEN

		OPEN  cur_generar_id ;
		FETCH cur_generar_id INTO vca_id_auditoria ;
		CLOSE cur_generar_id;	

		vca_valor_old := :OLD.ESTADO;
		vca_valor_new := :NEW.ESTADO;	
		vca_sql 	  := 'UPDATE A502_FACTURA_E SET ESTADO = ' || vca_valor_new || ' WHERE SECUENCIA = ' || vnu_id_factura;		

		INSERT INTO A502_AUDITORIA_FACTURA_F ( ID_AUDITORIA, COMANDO, VALOR_OLD, VALOR_NEW, USUARIO, FECHA, COLUMNA, ID_FACTURA, SQL  ) 
			VALUES ( vca_id_auditoria,  vca_comando, vca_valor_old, vca_valor_new, :NEW.USUARIO, vda_fecha, 'ESTADO', vnu_id_factura, vca_sql );

	END IF;	

END;
/
