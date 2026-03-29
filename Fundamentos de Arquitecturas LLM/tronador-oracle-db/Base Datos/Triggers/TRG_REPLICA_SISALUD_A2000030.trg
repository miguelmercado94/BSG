CREATE OR REPLACE TRIGGER TRG_REPLICA_SISALUD_A2000030
	AFTER DELETE OR INSERT OR UPDATE of COD_CIA, COD_SECC, COD_RAMO, NUM_POL1, NRO_DOCUMTO, FECHA_VIG_POL, FECHA_VENC_POL, FEC_ANU_POL, MCA_ANU_POL, NUM_END, COD_END, SUB_COD_END ON A2000030 FOR EACH ROW
DECLARE
FUNCTION trfun_inserta_campo(var_campo_lo IN VARCHAR2, num_llave_lo IN NUMBER, var_oldval_lo IN VARCHAR2, var_newval_lo IN VARCHAR2) RETURN BOOLEAN;
FUNCTION trfun_inserta_llave RETURN BOOLEAN;
/***************************************************************
	Descripcisn:
    		TRIGGERS DE REPLICACION A SISALUD
    Autor:		Otello					Fecha: 20/02/2003
    Modifica:	Otello					Fecha: 20/02/2003
***************************************************************/
	--CONSTANTES
	kvar_tabla_gl CONSTANT VARCHAR2(30) := 'A2000030';
    --Variable
    var_dml_gl SISALUD_ARP_OPERACIONES.SIAO_DML%TYPE;
  	num_SecOpera_gl NUMBER;
    num_SecCampo_gl NUMBER;
    boo_llaveinsertada_gl BOOLEAN;
    boo_obligalog_gl BOOLEAN;
    var_error_gl VARCHAR2(2000);
FUNCTION trfun_inserta_campo(var_campo_lo IN VARCHAR2, num_llave_lo IN NUMBER, var_oldval_lo IN VARCHAR2, var_newval_lo IN VARCHAR2) RETURN BOOLEAN IS
BEGIN
	IF NOT boo_llaveinsertada_gl THEN
    	IF NOT trfun_inserta_llave THEN
        	RETURN FALSE;
        END IF;
    END IF;
    -- INSERTA CAMPO
   	num_SecCampo_gl := num_SecCampo_gl +1;
   	INSERT INTO SISALUD_ARP_OPER_CAMPOS(
		SAOC_SIAO_SECUENCIA, SAOC_ORDEN, SAOC_LLAVE, SAOC_CAMPO,
        SIAO_VALANTERIOR, SIAO_VALNUEVO)
	VALUES(
    	num_SecOpera_gl, num_SecCampo_gl, num_llave_lo, var_campo_lo,
        var_oldval_lo, var_newval_lo);
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
    RETURN FALSE;
END trfun_inserta_campo;
FUNCTION trfun_inserta_llave RETURN BOOLEAN IS
BEGIN
	IF boo_llaveinsertada_gl THEN
    	RETURN TRUE;
    END IF;
	/*******************************************************
       			ENCABEZADO
    ********************************************************/
    num_SecCampo_gl := 0;
    boo_llaveinsertada_gl := TRUE;
    INSERT INTO SISALUD_ARP_OPERACIONES (
    	SIAO_SECUENCIA, SIAO_DML, SIAO_TABLA,
        SIAO_FECHA_CREACION, SIAO_FECHA_REPLICA)
    VALUES (
    	num_SecOpera_gl, var_dml_gl, kvar_tabla_gl,
        SYSDATE, NULL);
	/**********************************************************
    			CAMPOS LLAVE
     **********************************************************/
    IF NOT trfun_inserta_campo('NUM_SECU_POL', 1, TO_CHAR(:OLD.NUM_SECU_POL), TO_CHAR(:NEW.NUM_SECU_POL)) THEN
    	RETURN FALSE;
    END IF;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
    RETURN FALSE;
END trfun_inserta_llave;
BEGIN
	--valida la cia secc y prod
	IF :NEW.cod_cia <> 2 OR :NEW.cod_secc <> 70  OR :NEW.cod_ramo <> 722 THEN
    	RETURN;
    END IF;
    -- Inicializa variables
    boo_llaveinsertada_gl := FALSE;
    SELECT SEQ_SIAO.NEXTVAL INTO num_SecOpera_gl FROM dual ;
	IF INSERTING THEN
    	var_dml_gl := 'INSERT';
        boo_obligalog_gl := TRUE;
	ELSIF UPDATING THEN
    IF :OLD.cod_ramo = 782 THEN
      var_dml_gl := 'INSERT';
    ELSE
      var_dml_gl := 'UPDATE';  
    END IF;
    boo_obligalog_gl := TRUE;
	ELSIF DELETING THEN
		var_dml_gl := 'DELETE';
        INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR) VALUES (num_SecOpera_gl, SYSDATE, 'Borrados de A2000030 no soportados por la interfaz: secupol '||TO_CHAR(:OLD.NUM_SECU_POL));
        RETURN;
    END IF;
	/**********************************************************
    			CAMPOS VARIABLES
     **********************************************************/
	IF (:OLD.COD_CIA <> :NEW.COD_CIA) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_CIA', 0, TO_CHAR(:OLD.COD_CIA), TO_CHAR(:NEW.COD_CIA)) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.COD_SECC <> :NEW.COD_SECC) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_SECC', 0, TO_CHAR(:OLD.COD_SECC), TO_CHAR(:NEW.COD_SECC)) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.COD_RAMO <> :NEW.COD_RAMO) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_RAMO', 0, TO_CHAR(:OLD.COD_RAMO), TO_CHAR(:NEW.COD_RAMO)) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.NUM_POL1 <> :NEW.NUM_POL1) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('NUM_POL1', 1, TO_CHAR(:OLD.NUM_POL1), TO_CHAR(:NEW.NUM_POL1)) THEN
	    	RETURN;
	    END IF;
	END IF;
    IF (:OLD.NRO_DOCUMTO <> :NEW.NRO_DOCUMTO) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('NRO_DOCUMTO', 0, TO_CHAR(:OLD.NRO_DOCUMTO), TO_CHAR(:NEW.NRO_DOCUMTO)) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.FECHA_VIG_POL <> :NEW.FECHA_VIG_POL) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('FECHA_VIG_POL', 0, TO_CHAR(:OLD.FECHA_VIG_POL, 'dd/mm/yyyy'), TO_CHAR(:NEW.FECHA_VIG_POL, 'dd/mm/yyyy')) THEN
    		RETURN;
	    END IF;
    END IF;
    IF (:OLD.FECHA_VENC_POL <> :NEW.FECHA_VENC_POL) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('FECHA_VENC_POL', 0, TO_CHAR(:OLD.FECHA_VENC_POL, 'dd/mm/yyyy'), TO_CHAR(:NEW.FECHA_VENC_POL, 'dd/mm/yyyy')) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.FEC_ANU_POL <> :NEW.FEC_ANU_POL) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('FEC_ANU_POL', 0, TO_CHAR(:OLD.FEC_ANU_POL, 'dd/mm/yyyy'), TO_CHAR(:NEW.FEC_ANU_POL, 'dd/mm/yyyy')) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.MCA_ANU_POL <> :NEW.MCA_ANU_POL) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('MCA_ANU_POL', 0, :OLD.MCA_ANU_POL, :NEW.MCA_ANU_POL) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.NUM_END <> :NEW.NUM_END OR :OLD.COD_END <> :NEW.COD_END OR :OLD.SUB_COD_END <> :NEW.SUB_COD_END)  OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('NUM_END', 0, TO_CHAR(:OLD.NUM_END), TO_CHAR(:NEW.NUM_END)) THEN
	    	RETURN;
	    END IF;
	    IF NOT trfun_inserta_campo('COD_END', 0, TO_CHAR(:OLD.COD_END), TO_CHAR(:NEW.COD_END)) THEN
	    	RETURN;
	    END IF;
	    IF NOT trfun_inserta_campo('SUB_COD_END', 0, TO_CHAR(:OLD.SUB_COD_END), TO_CHAR(:NEW.SUB_COD_END)) THEN
	    	RETURN;
	    END IF;
    END IF;
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
END;
/
