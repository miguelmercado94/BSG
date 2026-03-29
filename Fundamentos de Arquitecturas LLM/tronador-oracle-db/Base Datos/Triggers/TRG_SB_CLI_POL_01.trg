CREATE OR REPLACE TRIGGER TRG_SB_CLI_POL_01
AFTER INSERT ON SB_CLIENTE_POLIZA FOR EACH ROW
DECLARE

   Ent_Mensaje       VARCHAR2(500) := NULL;
   Ent_Sw_Proceso    VARCHAR2(1)   := NULL;
   Ent_Sw_Commit     VARCHAR2(1)   := 'N';
   Ent_Sw_Pos        NUMBER(7)     := NULL;
   Ent_NmReg         NUMBER(7)     := 0;

   v_pk VARCHAR2(500);
   v_log VARCHAR2(100);
   v_procesar VARCHAR2(10);

BEGIN

   v_procesar := 'N';
   -- Ini Implementar Control para Desactivar TRIGGER si el JOB esta activo.
   SELECT VALOR INTO v_procesar FROM PARAMTRON WHERE Tipo_Parametro = 'TipoCliente';

   IF v_procesar <> 'TRG' THEN

       RETURN; -- SALIR.  No procesar

   END IF;

   -- Fin Implementar Control

   v_pk := 'ConSec='||:NEW.CONSECUTIVO||' NumPol='||:NEW.NUMERO_POLIZA||' TipoReg='||:NEW.Tipo_Registro||' ClaseReg='||:NEW.Clase_Registro||' EstadoReg='||:NEW.ESTADO_REGISTRO;

   IF INSERTING THEN

       v_log := 'After Inserting ...';

   ELSIF UPDATING THEN

       v_log := 'After Updating!!!  ERROR!!! Revisar !!!';

   ELSE

       v_log := 'After Deleted!!! ERROR!!  Revisar!!!';
       v_pk  := 'ConSec='||:OLD.CONSECUTIVO||' NumPol='||:OLD.NUMERO_POLIZA;

   END IF;

   PR_LOG_TESO('TRG_SB_CLI_POL_01',v_log||' '||v_pk);

   PR_LOG_TESO('TRG_SB_CLI_POL_01','Antes FON_FACT_CUENTA '||v_pk);
		   FON_FACT_CUENTA(:NEW.Consecutivo,
						   :NEW.Numero_Poliza,
						   :NEW.Producto,
						   :NEW.Seccion,
						   :NEW.Poliza_Anualidad,
						   :NEW.Numero_Identificacion,
						   :NEW.Tipo_Registro,
						   :NEW.Fecha_Inicio_Poliza,
						   Ent_Mensaje,
						   Ent_Sw_Proceso,
						   Ent_Sw_Commit,
						   Ent_Sw_Pos,
						   Ent_Nmreg,
						   :NEW.Usuario);

     IF Ent_Sw_Proceso = 'N' THEN

	     PR_LOG_TESO('TRG_SB_CLI_POL_01','Fallo FON_FACT_CUENTA: ConSec='||:NEW.Consecutivo||' NumPol='||:NEW.NUMERO_POLIZA||' Mje->'||ent_Mensaje);

--   Al activar el UPDATE se genera el error: ORA-04091: table OPS$PUMA.SB_CLIENTE_POLIZA is mutating
--	 UPDATE SB_CLIENTE_POLIZA
--	 SET motivo = SUBSTR(Ent_Mensaje,LENGTH(Ent_Mensaje)-100),
--	     estado_registro = 'PEN'
--	 WHERE rowid = :NEW.rowid;

--   SE DEBE INHABILITAR EL RAISE PARA PERMITIR QUE EL REGISTRO SE INSERTE Y LUEGO SE PUEDA PROCESAR
--	 RAISE_APPLICATION_ERROR(-20000,Ent_Mensaje);
     ELSE

	     PR_LOG_TESO('TRG_SB_CLI_POL_01','Paso Ok FON_FACT_CUENTA: ConSec='||:NEW.Consecutivo||' NumPol='||:NEW.NUMERO_POLIZA||' Mje->'||ent_Mensaje);

-- Al activar el UPDATE se genera el error: ORA-04091: ta¦le OPS$PUMA.SB_CLIENTE_POLIZA is mutating
-- 	     UPDATE SB_CLIENTE_POLIZA
--		 SET motivo = 'Registro Procesado.'
--		 WHERE rowid = :NEW.rowid;

     END IF;

END;
/
