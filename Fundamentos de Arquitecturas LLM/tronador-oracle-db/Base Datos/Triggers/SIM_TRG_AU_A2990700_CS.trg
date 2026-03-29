CREATE OR REPLACE TRIGGER SIM_TRG_AU_A2990700_CS

    AFTER UPDATE OF COD_SITUACION ON A2990700
    FOR EACH ROW
DECLARE
	
	IP_POLIZA       SIM_TYP_POLIZAGEN;
    IP_NUMSECUPOL   NUMBER;
    IP_NUMEND       NUMBER;
	
	V_VALIDA		NUMBER;
	
    V_Coderr        C1991300.Cod_Error%type;
    V_MsgErr        C1991300.MSG_ERROR%type;
    w_raise_error   exception;
    
BEGIN

    IP_POLIZA       := NEW SIM_TYP_POLIZAGEN();
	IP_NUMSECUPOL   := :OLD.NUM_SECU_POL;
    IP_NUMEND       := :OLD.NUM_END;
	
	SELECT COUNT(1) 
	INTO V_VALIDA
    FROM A2000030 A, A2000020 B, A2000060 C, SIMAPI_PARAMETROS_ESTRATEGIA T
    WHERE A.NUM_SECU_POL          = IP_NUMSECUPOL
        AND A.NUM_SECU_POL          = B.NUM_SECU_POL
        AND A.NUM_SECU_POL          = C.NUM_SECU_POL
        AND SUBSTR(A.NUM_POL1,12,2) = '01'
        AND B.COD_CAMPO             = 'MCA_FCOBRO_ALT'
        AND B.VALOR_CAMPO           = 'CC'
        AND A.FOR_COBRO             = B.VALOR_CAMPO 
        AND A.NUM_END               = 0
		AND T.COD_TAB 				= 'ACTUALIZA_CC_DB'
		AND T.COD_OFERTA 			= A.SIM_ESTRATEGIAS
        AND T.COD_RAMO 				= A.COD_RAMO
        AND A.NUM_POL_ANT IS NULL;
		
	IF V_VALIDA > 0 AND :NEW.COD_SITUACION = 'CT' THEN
		
		BEGIN
		
			PROC_ACTUALIZA_FC_OFERTAS(IP_POLIZA , IP_NUMSECUPOL, IP_NUMEND);
				
		EXCEPTION
		
          WHEN OTHERS THEN
			v_msgerr := ' Error llamando PROC_ACTUALIZA_FC_OFERTAS de Celulares - sqlcode --> ' || sqlcode ||'   sqlerrm --> ' || sqlerrm ;
            RAISE_APPLICATION_ERROR (-20530,v_msgerr);
        
        END;
        
	END IF;

EXCEPTION

	WHEN NO_DATA_FOUND THEN
		NULL;

	WHEN OTHERS THEN
		v_Coderr  := sqlcode;
		v_msgerr := substr ( 'Error en el trigger SIM_TRG_AU_A2990700_CS'
							||' num_secu_pol : ' ||  to_char ( :NEW.num_secu_pol )
							|| v_msgerr
							|| sqlerrm
							, 1 , 2000 ) ;
    RAISE_APPLICATION_ERROR (-20530,v_msgerr);
  
END SIM_TRG_AU_A2990700_CS;
/
