CREATE OR REPLACE TRIGGER TRG_AUDIT_A5021604
BEFORE UPDATE OR INSERT ON A5021604
FOR EACH ROW
DECLARE

v_Tabla AUDIT_TESO.Tabla%TYPE := 'A5021604';

v_Vlr_Anterior AUDIT_TESO.Vlr_Anterior%TYPE;
v_Vlr_Nuevo AUDIT_TESO.Vlr_Nuevo%TYPE;

v_campo AUDIT_TESO.Campo%TYPE;


BEGIN

 IF INSERTING THEN

       v_campo := 'MCA_EST_PAGO';

	   INSERT INTO AUDIT_TESO(
	    Num_Ord_Pago,	    Cod_Cia,	    Tabla,	    Campo,
	    Evento,	    Vlr_Anterior,	    Vlr_Nuevo,	    Usuario,
	    Fecha)
	    VALUES(
	      :new.Num_Ord_Pago,  	      :new.Cod_Cia,          v_Tabla,	      v_campo,
   	      'Crear',          NULL,	      :new.Mca_Est_Pago,	      USER,	      SYSDATE
        );
		
		v_campo := 'FECHA_PAGO';

	   INSERT INTO AUDIT_TESO(
	    Num_Ord_Pago,	    Cod_Cia,	    Tabla,	    Campo,
	    Evento,	    Vlr_Anterior,	    Vlr_Nuevo,	    Usuario,
	    Fecha)
	    VALUES(
	      :new.Num_Ord_Pago,  	      :new.Cod_Cia,          v_Tabla,	      v_campo,
   	      'Crear',          NULL,	      TO_CHAR(:new.fecha_pago,'DD/MM/YYYY HH24:MI:SS'),	      USER,	      SYSDATE
        );

 ELSE

 	-- Si cambio de Mca_Est_Pago buscar todas las ordenes de pago
    IF NVL(:new.Mca_Est_Pago,'-1') <> NVL(:old.Mca_Est_Pago,'-1') THEN

	   v_campo := 'MCA_EST_PAGO';
       v_Vlr_Anterior := :old.Mca_Est_Pago;
       v_Vlr_Nuevo := :new.Mca_Est_Pago;

	   INSERT INTO AUDIT_TESO(
          Num_Ord_Pago,	    Cod_Cia, 	   Vlr_Anterior,        Vlr_Nuevo,
          Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	   VALUES(
	      :new.num_ord_pago, :new.cod_cia,   v_Vlr_Anterior,      v_Vlr_Nuevo,
          v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

	   IF NVL(:old.Mca_Est_Pago,'-1') = 'T' THEN
		   INSERT INTO CEPAG_COMPARACION_ESTADOS(
				ID_SOL_COMPARACION, 
				COD_CIA,
				NUM_ORD_PAGO, 
				ESTADO_COMPARACION,
				ORIGEN_SOLICITUD,
				FECHA_CREACION)
		   VALUES (
				SEQ_CEPAG_COMPARACION_ESTADOS.NEXTVAL,
				:new.cod_cia,
				:new.num_ord_pago,    
				null,
				'TRGTRON',
				SYSDATE);
	   END IF;
    END IF;

	IF NVL(:new.fecha_pago,TO_DATE('01/01/1900','DD/MM/YYYY')) <> NVL(:old.fecha_pago,TO_DATE('01/01/1900','DD/MM/YYYY')) THEN

	   v_campo := 'FECHA_PAGO';
       v_Vlr_Anterior := TO_CHAR(:old.fecha_pago,'DD/MM/YYYY HH24:MI:SS');
       v_Vlr_Nuevo := TO_CHAR(:new.fecha_pago,'DD/MM/YYYY HH24:MI:SS');

	   INSERT INTO AUDIT_TESO(
          Num_Ord_Pago,	    Cod_Cia, 	   Vlr_Anterior,        Vlr_Nuevo,
          Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	   VALUES(
	      :new.num_ord_pago, :new.cod_cia,   v_Vlr_Anterior,      v_Vlr_Nuevo,
          v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

    END IF;
	
    IF NVL(:new.cod_benef,'-1') <> NVL(:old.cod_benef,'-1') THEN

	   v_campo := 'COD_BENEF';
       v_Vlr_Anterior := :old.cod_benef;
       v_Vlr_Nuevo := :new.cod_benef;

	   INSERT INTO AUDIT_TESO(
          Num_Ord_Pago,	    Cod_Cia, 	   Vlr_Anterior,        Vlr_Nuevo,
          Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	   VALUES(
	      :new.num_ord_pago, :new.cod_cia,   v_Vlr_Anterior,      v_Vlr_Nuevo,
          v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

    END IF;

 END IF;

END;
/