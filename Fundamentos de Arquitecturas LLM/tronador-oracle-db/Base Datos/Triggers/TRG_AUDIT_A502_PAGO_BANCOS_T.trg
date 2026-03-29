CREATE OR REPLACE TRIGGER TRG_AUDIT_A502_PAGO_BANCOS_T
BEFORE UPDATE OR INSERT OR DELETE ON A502_PAGO_BANCOS_T
FOR EACH ROW
DECLARE

v_Tabla AUDIT_TESO.Tabla%TYPE := 'A502_PAGO_BANCOS_T';

v_Vlr_Anterior AUDIT_TESO.Vlr_Anterior%TYPE;
v_Vlr_Nuevo AUDIT_TESO.Vlr_Nuevo%TYPE;

v_campo AUDIT_TESO.Campo%TYPE;


BEGIN 
 IF INSERTING THEN

       v_campo := 'ESTADO_TRANSFERENCIA';

	   INSERT INTO AUDIT_TESO(
		      Num_Ord_Pago,	    Cod_Cia, 	Vlr_Anterior,	    Vlr_Nuevo,
              Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
       VALUES(
	      	:new.Num_Ord_Pago, :new.Cod_Cia,  NULL, 	:new.ESTADO_TRANSFERENCIA,
              v_Tabla,   v_campo,   'Crear',       USER,	   SYSDATE);

 ELSIF DELETING THEN

       v_campo := 'ESTADO_TRANSFERENCIA';

	   INSERT INTO AUDIT_TESO(
		      Num_Ord_Pago,	    Cod_Cia, 	Vlr_Anterior,	    Vlr_Nuevo,
              Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
       VALUES(
	      	:old.Num_Ord_Pago, :old.Cod_Cia, :old.ESTADO_TRANSFERENCIA, NULL,
              v_Tabla,   v_campo,   'Borrar',       USER,	   SYSDATE);

ELSE
  IF NVL(:new.Estado_Transferencia,'-1') <> NVL(:old.Estado_Transferencia,'-1') THEN

	   v_campo := 'ESTADO_TRANSFERENCIA';
       v_Vlr_Anterior := :old.Estado_Transferencia;
       v_Vlr_Nuevo := :new.Estado_Transferencia;
      

	   INSERT INTO AUDIT_TESO(
          Num_Ord_Pago,	    Cod_Cia, 	   Vlr_Anterior,        Vlr_Nuevo,
          Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	   VALUES(
	      :new.num_ord_pago, :new.cod_cia,   v_Vlr_Anterior,     v_Vlr_Nuevo,
          v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

  END IF;
	
  IF NVL(:new.Numero_agrupa,'-1') <> NVL(:old.Numero_agrupa,'-1') THEN

        v_campo := 'NUMERO_AGRUPA';
        v_Vlr_Anterior := :old.Numero_agrupa;
        v_Vlr_Nuevo := :new.Numero_agrupa;

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
