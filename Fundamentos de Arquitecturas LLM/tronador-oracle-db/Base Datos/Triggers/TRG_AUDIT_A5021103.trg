CREATE OR REPLACE TRIGGER TRG_AUDIT_A5021103
BEFORE UPDATE ON A5021103
FOR EACH ROW
DECLARE

CURSOR c_Ordenes IS
SELECT cod_cia,num_ord_pago
FROM A5021604
WHERE cod_benef = :new.numero_documento
AND mca_est_pago NOT IN ('T','C','E','A');

v_Tabla AUDIT_TESO.Tabla%TYPE := 'A5021103';

v_Vlr_Anterior AUDIT_TESO.Vlr_Anterior%TYPE;
v_Vlr_Nuevo AUDIT_TESO.Vlr_Nuevo%TYPE;
v_campo AUDIT_TESO.Campo%TYPE;


BEGIN

	-- Si cambio de estado buscar todas las ordenes de pago
    IF NVL(:new.Estado,'-1') <> NVL(:old.Estado,'-1') THEN

	   v_campo := 'ESTADO';
       v_Vlr_Anterior := :old.estado;
       v_Vlr_Nuevo := :new.estado;

       FOR i IN c_ordenes LOOP

		   INSERT INTO AUDIT_TESO(
		      Num_Ord_Pago,	    Cod_Cia, 	Vlr_Anterior,	    Vlr_Nuevo,
              Tabla,	 Campo,	    Evento,		   Usuario,    Fecha)
	       VALUES(
	   	      i.num_ord_pago,   i.cod_cia,	v_Vlr_Anterior,		v_Vlr_Nuevo,
              v_Tabla,   v_campo,   'Actualizar',  USER,	   SYSDATE);

       END LOOP;

    END IF;

END;
/
