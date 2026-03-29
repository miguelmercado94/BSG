CREATE OR REPLACE TRIGGER TRG_REPLICA_SISALUD_C2700003
AFTER DELETE OR INSERT OR UPDATE OF COD_CIA, COD_SECC, COD_RAMO, NUM_POL1, CENTRO_TRAB, NIT, IDE_NIT, SEXO, COD_CARGO, COD_EPS, COD_AFP, FEC_NACE, FEC_INGRESO, FEC_BAJA, COD_MOVIMI, FECHA_NOV ON C2700003 FOR EACH ROW
DECLARE
FUNCTION trfun_inserta_campo(var_campo_lo IN VARCHAR2, num_llave_lo IN NUMBER, var_oldval_lo IN VARCHAR2, var_newval_lo IN VARCHAR2) RETURN BOOLEAN;
FUNCTION trfun_inserta_llave RETURN BOOLEAN;
/***************************************************************
	Descripci"n:
    		TRIGGERS DE REPLICACION A SISALUD
    Autor:		Otello					 Fecha: 20/02/2003
    Modifica:	Otello					 Fecha: 20/02/2003
    Modifica   Jairo Fracica DS          Fecha: 01/05/2008
               Se Crea Nuevo Trigger para que se Inserten las novedades a Sisalud ARP de acuerdo a
               la nueva tabla de Novedades  C2700003 teniendo en cuenta el Estado de la novedad
***************************************************************/
	--CONSTANTES
	kvar_tabla_gl CONSTANT VARCHAR2(30) := 'C2700003';
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
    IF NOT trfun_inserta_campo('IDE_NIT', 1, :OLD.IDE_NIT, :NEW.IDE_NIT) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('NIT', 1, TO_CHAR(:OLD.NIT), TO_CHAR(:NEW.NIT)) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('CENTRO_TRAB', 1, TO_CHAR(:OLD.CENTRO_TRAB), TO_CHAR(:NEW.CENTRO_TRAB)) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('ESTADO', 1, :OLD.COD_MOVIMI, :NEW.COD_MOVIMI) THEN
    	RETURN FALSE;
    END IF;
    IF NOT trfun_inserta_campo('FEC_INGRESO', 1, TO_CHAR(:OLD.FEC_INGRESO, 'dd/mm/yyyy'), TO_CHAR(:NEW.FEC_INGRESO, 'dd/mm/yyyy')) THEN
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
    IF :NEW.COD_MOVIMI IS NULL OR :NEW.COD_MOVIMI NOT IN ('ING', 'RET', 'VCT', 'VSP') THEN
    	RETURN;
    END IF;

-- JF 22-05-2008 SE INCLUYE EL ESTADO DE LA NOVEDAD PARA VERIFICAR QUE SE EFECTUE ISC-Ingreso si cargado,RSC, Retiro Si Cargado,NSC,  Novedad si Cargada.
    IF :NEW.ESTADO_NOVEDAD IS NULL OR :NEW.ESTADO_NOVEDAD NOT IN ('ISC', 'RSC', 'NSC') THEN
    	RETURN;
    END IF;


    -- Inicializa variables
    boo_llaveinsertada_gl := FALSE;
    SELECT SEQ_SIAO.NEXTVAL INTO num_SecOpera_gl FROM dual ;
	IF INSERTING THEN
    	var_dml_gl := 'INSERT';
        boo_obligalog_gl := TRUE;
        IF NOT trfun_inserta_llave THEN
        	RETURN;
        END IF;
	ELSIF UPDATING THEN
    IF :OLD.Cod_Ramo = 782 THEN
        var_dml_gl := 'INSERT';
      ELSE
        var_dml_gl := 'UPDATE';
    END IF;    
        --boo_obligalog_gl := FALSE;
        boo_obligalog_gl := TRUE;
        IF NOT trfun_inserta_llave THEN
        	RETURN;
        END IF;
	ELSIF DELETING THEN
		var_dml_gl := 'DELETE';
        INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR) VALUES (num_SecOpera_gl, SYSDATE, 'Borrados de C2700003 no soportados por la interfaz: pol '||TO_CHAR(:OLD.NUM_POL1)|| ' nit ' ||:OLD.NIT);
        RETURN;
    END IF;
    /**********************************************************
    			CAMPOS VARIABLES
    **********************************************************/
    --Empleado
	IF (:OLD.SEXO <> :NEW.SEXO) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('SEXO', 0, :OLD.SEXO, :NEW.SEXO) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.FEC_NACE <> :NEW.FEC_NACE) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('FEC_NACE', 0, TO_CHAR(:OLD.FEC_NACE, 'dd/mm/yyyy'), TO_CHAR(:NEW.FEC_NACE, 'dd/mm/yyyy')) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.COD_EPS <> :NEW.COD_EPS) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_EPS', 0, TO_CHAR(:OLD.COD_EPS), TO_CHAR(:NEW.COD_EPS)) THEN
	    	RETURN;
	    END IF;
    END IF;
    IF (:OLD.COD_AFP <> :NEW.COD_AFP) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_AFP', 0, TO_CHAR(:OLD.COD_AFP), TO_CHAR(:NEW.COD_AFP)) THEN
	    	RETURN;
	    END IF;
    END IF;
    --Relacion Laboral
    IF (:OLD.COD_CARGO <> :NEW.COD_CARGO) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('COD_CARGO', 0, TO_CHAR(:OLD.COD_CARGO), TO_CHAR(:NEW.COD_CARGO)) THEN
	    	RETURN;
	    END IF;
    END IF;
	IF (:OLD.FEC_BAJA <> :NEW.FEC_BAJA) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('FEC_BAJA', 0, TO_CHAR(:OLD.FEC_BAJA, 'dd/mm/yyyy'), TO_CHAR(:NEW.FEC_BAJA, 'dd/mm/yyyy')) THEN
	    	RETURN;
	    END IF;
    END IF;
/*    IF (:OLD.SAL_LIQUI <> :NEW.SAL_LIQUI) OR boo_obligalog_gl THEN
	    IF NOT trfun_inserta_campo('SAL_LIQUI', 0, TO_CHAR(:OLD.SAL_LIQUI), TO_CHAR(:NEW.SAL_LIQUI)) THEN
	    	RETURN;
	    END IF;
    END IF;*/
EXCEPTION WHEN OTHERS THEN
	var_error_gl := SQLERRM;
    INSERT INTO  SISALUD_ARP_ERRORES (SAER_SIAO_SECUENCIA, SAER_FECHA, SAER_ERROR)
    VALUES (num_SecOpera_gl, SYSDATE, var_error_gl);
END;
/
