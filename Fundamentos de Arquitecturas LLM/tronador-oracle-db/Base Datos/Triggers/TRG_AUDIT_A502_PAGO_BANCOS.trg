CREATE OR REPLACE TRIGGER TRG_AUDIT_A502_PAGO_BANCOS
BEFORE UPDATE OR INSERT OR DELETE ON A502_PAGO_BANCOS
FOR EACH ROW
DECLARE

v_Tabla AUDIT_TESO.Tabla%TYPE := 'A502_PAGO_BANCOS';

v_Vlr_Anterior AUDIT_TESO.Vlr_Anterior%TYPE;
v_Vlr_Nuevo AUDIT_TESO.Vlr_Nuevo%TYPE;

v_campo AUDIT_TESO.Campo%TYPE;


BEGIN   
 IF INSERTING THEN

       v_campo := 'MCA_ENVIADO';

	   INSERT INTO AUDIT_TESO(
		      Num_Ord_Pago,	    Cod_Cia, 	Vlr_Anterior,	    Vlr_Nuevo,
              Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
       VALUES(
	      	:new.Num_Ord_Pago, :new.Cod_Cia,  NULL, 	:new.MCA_ENVIADO,
              v_Tabla,   v_campo,   'Crear',       USER,	   SYSDATE);

 ELSIF DELETING THEN

       v_campo := 'MCA_ENVIADO';

	   INSERT INTO AUDIT_TESO(
		      Num_Ord_Pago,	    Cod_Cia, 	Vlr_Anterior,	    Vlr_Nuevo,
              Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
       VALUES(
	      	:old.Num_Ord_Pago, :old.Cod_Cia, :old.MCA_ENVIADO, NULL,
              v_Tabla,   v_campo,   'Borrar',       USER,	   SYSDATE);

ELSE
    IF (NVL(:new.Numero_agrupa,'-1') <> NVL(:old.Numero_agrupa,'-1'))
		OR (NVL(:new.MCA_ENVIADO,'-1') <> NVL(:old.MCA_ENVIADO,'-1'))
		OR (NVL(:new.MCA_EXITOSO,'-1') <> NVL(:old.MCA_EXITOSO,'-1'))
	THEN
		IF NVL(:new.Numero_agrupa,'-1') <> NVL(:old.Numero_agrupa,'-1') THEN
			v_campo := 'NUMERO_AGRUPA';
			v_Vlr_Anterior := :old.Numero_agrupa;
			v_Vlr_Nuevo := :new.Numero_agrupa;
		ELSIF NVL(:new.MCA_ENVIADO,'-1') <> NVL(:old.MCA_ENVIADO,'-1') THEN
			v_campo := 'MCA_ENVIADO';
			v_Vlr_Anterior := :old.MCA_ENVIADO;
			v_Vlr_Nuevo := :new.MCA_ENVIADO;
		ELSIF NVL(:new.MCA_EXITOSO,'-1') <> NVL(:old.MCA_EXITOSO,'-1') THEN
			v_campo := 'MCA_EXITOSO';
			v_Vlr_Anterior := :old.MCA_EXITOSO;
			v_Vlr_Nuevo := :new.MCA_EXITOSO;			
		END IF;
        
        INSERT INTO AUDIT_TESO(
          Num_Ord_Pago,	    Cod_Cia, 	   Vlr_Anterior,        Vlr_Nuevo,
          Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	   VALUES(
	      :new.num_ord_pago, :new.cod_cia,   v_Vlr_Anterior,     v_Vlr_Nuevo,
          v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

    END IF;
  END IF;
END;
/
