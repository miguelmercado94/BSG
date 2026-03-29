CREATE OR REPLACE TRIGGER TRG_REPLICA_SISALUD_C2700100
AFTER DELETE OR INSERT OR UPDATE ON C2700100 FOR EACH ROW
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
	kvar_tabla_gl CONSTANT VARCHAR2(30) := 'C2700100';
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
    IF (var_campo_lo = 'CENTRO_TRAB' OR var_campo_lo = 'COD_RIES') AND LENGTH(var_newval_lo)>5 THEN   --yeison Orozco
      RETURN FALSE;
      ELSE
   	INSERT INTO SISALUD_ARP_OPER_CAMPOS(
		SAOC_SIAO_SECUENCIA, SAOC_ORDEN, SAOC_LLAVE, SAOC_CAMPO,
        SIAO_VALANTERIOR, SIAO_VALNUEVO)
	VALUES(
    	num_SecOpera_gl, num_SecCampo_gl, num_llave_lo, var_campo_lo,
        var_oldval_lo, var_newval_lo);
    RETURN TRUE;
    END IF;
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
    IF NOT trfun_inserta_campo('NUM_POL1', 1, TO_CHAR(:OLD.NUM_POL1), TO_CHAR(:NEW.NUM_POL1)) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('COD_BENEF', 1, TO_CHAR(:OLD.COD_BENEF), TO_CHAR(:NEW.COD_BENEF)) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('PERIODO_PAGO', 1, TO_CHAR(:OLD.PERIODO_PAGO), TO_CHAR(:NEW.PERIODO_PAGO)) THEN
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
		IF :OLD.Cod_Ramo = 782 THEN
        var_dml_gl := 'INSERT';
      ELSE
        var_dml_gl := 'UPDATE';
    END IF;    
        boo_obligalog_gl := FALSE;
	ELSIF DELETING THEN
		var_dml_gl := 'DELETE';
        INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR) VALUES (num_SecOpera_gl, SYSDATE, 'Borrados de C2700100 no soportados por la interfaz: pol '||TO_CHAR(:OLD.NUM_POL1)|| ' cod_benef ' ||:OLD.COD_BENEF || ' periodo ' ||:OLD.PERIODO_PAGO);
        RETURN;
    END IF;
    IF trfun_inserta_llave THEN
    	RETURN;
    END IF;
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
END;
/
