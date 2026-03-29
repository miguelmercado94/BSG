CREATE OR REPLACE TRIGGER TRG_REPLICA_SISALUD_A2000020
AFTER DELETE OR INSERT OR UPDATE ON A2000020 FOR EACH ROW
DECLARE
/***************************************************************
	Descripcisn:
    		TRIGGERS DE REPLICACION A SISALUD
    Autor:		Otello					Fecha: 20/02/2003
    Modifica:	Otello					Fecha: 20/02/2003
***************************************************************/
FUNCTION trfun_inserta_campo(var_campo_lo IN VARCHAR2, num_llave_lo IN NUMBER, var_oldval_lo IN VARCHAR2, var_newval_lo IN VARCHAR2) RETURN BOOLEAN;
FUNCTION trfun_inserta_llave RETURN BOOLEAN;
	--CONSTANTES
	kvar_tabla_gl CONSTANT VARCHAR2(30) := 'A2000020';
    --Variable
    var_dml_gl SISALUD_ARP_OPERACIONES.SIAO_DML%TYPE;
  	num_SecOpera_gl NUMBER;
    num_SecCampo_gl NUMBER;
    boo_llaveinsertada_gl BOOLEAN;
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
    IF NOT trfun_inserta_campo('NUM_SECU_POL', 1, TO_CHAR(:OLD.NUM_SECU_POL), TO_CHAR(:NEW.NUM_SECU_POL)) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('COD_RIES', 1, TO_CHAR(:OLD.COD_RIES), TO_CHAR(:NEW.COD_RIES)) THEN
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
    -- valida campos dinamico
    IF :NEW.cod_campo IN ('ACTIVIDADPP', 'ENCARGO_SALUD', 'CARGO_SALUD', 'CARGO_REPRES', 'TOTAL_TRABAJA') --empresa
    	OR
        :NEW.cod_campo IN ('CPOS_RIES', 'COD_PROV', 'CLASE_RIESGO', 'DESC_RIES', 'DIRECC_RIES', 'TELEFONO_SALUD', 'ACTIVIDAD', 'SUM_TRANS') -- centro costo
        OR
        :NEW.cod_campo IN ('CENTRAL_DESCEN') -- poliza
        OR
        NVL(:OLD.mca_baja_ries, 'xxx') <> NVL(:NEW.mca_baja_ries, 'xxx')
        THEN
        -- continuar
        NULL;
    ELSE
    	-- salir
    	RETURN;
    END IF;
	--valida la cia secc y prod
    DECLARE
    	num_cod_cia_blo NUMBER;
        num_cod_secc_blo NUMBER;
        num_cod_ramo_blo NUMBER;
    BEGIN
    	SELECT cod_cia, cod_secc, cod_ramo
        INTO num_cod_cia_blo, num_cod_secc_blo, num_cod_ramo_blo
        FROM A2000030
        WHERE num_secu_pol = :NEW.NUM_SECU_POL
            AND ROWNUM = 1;
		IF num_cod_cia_blo <> 2 OR num_cod_secc_blo <> 70  OR num_cod_ramo_blo  <> 722 THEN
	    	RETURN;
	    END IF;
    EXCEPTION
    	WHEN OTHERS THEN -- no pertenece al grupo ramo de ARP
        	RETURN;
    END;
    -- Inicializa variables
    boo_llaveinsertada_gl := FALSE;
    SELECT SEQ_SIAO.NEXTVAL INTO num_SecOpera_gl FROM dual ;
	IF INSERTING THEN
    	var_dml_gl := 'INSERT';
	ELSIF UPDATING THEN
		var_dml_gl := 'UPDATE';
	ELSIF DELETING THEN
		var_dml_gl := 'DELETE';
        INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR) VALUES (num_SecOpera_gl, SYSDATE, 'Borrados de A2000030 no soportados por la interfaz: secupol '||TO_CHAR(:OLD.NUM_SECU_POL) || ' campo ' || :OLD.cod_campo || ' valor' || :OLD.VALOR_CAMPO);
        RETURN;
    END IF;
      DBMS_OUTPUT.PUT_LINE ( 'cod_campo= ' || :NEW.cod_campo );
      DBMS_OUTPUT.PUT_LINE ('old ' ||:OLD.mca_baja_ries || ' new ' ||:NEW.mca_baja_ries );
	/**********************************************************
    			CAMPOS VARIABLES
     **********************************************************/
     IF :NEW.cod_campo IN ('ACTIVIDADPP', 'ENCARGO_SALUD', 'CARGO_SALUD', 'CARGO_REPRES', 'TOTAL_TRABAJA') --empresa
    	OR
        :NEW.cod_campo IN ('CPOS_RIES', 'COD_PROV', 'CLASE_RIESGO', 'DESC_RIES', 'DIRECC_RIES', 'TELEFONO_SALUD', 'ACTIVIDAD', 'SUM_TRANS') -- centro costo
        OR
        :NEW.cod_campo IN ('CENTRAL_DESCEN') -- poliza
        THEN
    	IF NOT trfun_inserta_campo(:NEW.cod_campo, 0, :OLD.VALOR_CAMPO, :NEW.VALOR_CAMPO) THEN
    		RETURN;
    	END IF;
    END IF;
    IF NVL(:OLD.mca_baja_ries, 'xxx') <> NVL(:NEW.mca_baja_ries, 'xxx') THEN
    	IF NOT trfun_inserta_campo('MCA_BAJA_RIES', 0, :OLD.mca_baja_ries, :NEW.mca_baja_ries) THEN
    		RETURN;
    	END IF;
    END IF;
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
END;
/
