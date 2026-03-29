CREATE OR REPLACE TRIGGER TRG_AI_EMI_CLIENTE
AFTER INSERT
ON EMI_CLIENTE
DECLARE

  t_sol           Pkg_Emi_Cliente.t_solicitud  ;
  t_newcli        Pkg_Emi_Cliente.t_cliente     ;

  var_row         ROWID;
  var_mensaje     VARCHAR2(255);
  var_numero_solicitud  EMI_CLIENTE.NUMERO_SOLICITUD%TYPE  := NULL ;
  var_codigo_riesgo     EMI_CLIENTE.codigo_riesgo%TYPE     := NULL ;


  W_NUMERO_DOCUMENTO                 EMI_CLIENTE.NUMERO_DOCUMENTO%TYPE      := NULL;
  W_TIPDOC_CODIGO                    EMI_CLIENTE.TIPDOC_CODIGO%TYPE         := NULL;
  W_FECHA_DILIGENCIAMIENTO           EMI_CLIENTE.FECHA_DILIGENCIAMIENTO%TYPE:= NULL;
  W_USUARIO_TRANSACCION           EMI_CLIENTE.USUARIO_TRANSACCION%TYPE:= NULL;

BEGIN

          SELECT num_rowid
               , mensaje
               , numero_solicitud
               , codigo_riesgo
            INTO var_row
               , var_mensaje
               , var_numero_solicitud
               , var_codigo_riesgo
            FROM EMI_MUTATING
           WHERE table_name = 'EMI_CLIENTE_INSERT';

          DELETE FROM EMI_MUTATING WHERE table_name = 'EMI_CLIENTE_INSERT';
          -- select * from EMI_mutating

          SELECT
                  NUMERO_DOCUMENTO
                 ,TIPDOC_CODIGO
                 ,FECHA_DILIGENCIAMIENTO
				 ,USUARIO_TRANSACCION
            INTO
                  W_NUMERO_DOCUMENTO
                 ,W_TIPDOC_CODIGO
                 ,W_FECHA_DILIGENCIAMIENTO
				 ,W_USUARIO_TRANSACCION
            FROM EMI_CLIENTE
           WHERE  NUMERO_SOLICITUD = VAR_NUMERO_SOLICITUD
             AND  CODIGO_RIESGO    = VAR_CODIGO_RIESGO ;

        -- Datos de La solicitud
        t_sol                                             :=   NULL ;
        t_sol.p_NUMERO_SOLICITUD                          :=  VAR_NUMERO_SOLICITUD;
        t_sol.p_codigo_riesgo                             :=  VAR_CODIGO_RIESGO;
        t_sol.p_NUMERO_DOCUMENTO                          :=  W_NUMERO_DOCUMENTO;
        t_sol.p_TIPO_documento                            :=  W_TIPDOC_CODIGO;
        t_sol.p_fecha_solicitud                           :=  W_FECHA_DILIGENCIAMIENTO;
        t_sol.p_usuario_transaccion                          :=  W_USUARIO_TRANSACCION ;

        DBMS_OUTPUT.PUT_LINE('TRG_AI_EMI_CLIENTE : Antes de llamar =>pkg_emi_cliente.emi_actualizar_cliente ');
        Pkg_Emi_Cliente.emi_actualizar_cliente(t_sol);
        DBMS_OUTPUT.PUT_LINE('TRG_AI_EMI_CLIENTE : Despues de llamar =>pkg_emi_cliente.emi_actualizar_cliente ');
        IF t_sol.P_SQLERR <> 0 THEN
           RAISE_APPLICATION_ERROR (-20522,'Error Solicitud  '||t_sol.p_sqlerr ||' Fallo'||t_sol.p_sqlerrm);
        END IF;

EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR EN TRG_AI_EMI_CLIENTE =>'||SQLCODE);
        DBMS_OUTPUT.PUT_LINE('MENSAJE=>'||SQLERRM);
        RAISE_APPLICATION_ERROR (-20523,'TRG_AI_EMI_CLIENTE  '||SQLCODE ||' Fallo'||SQLERRM);
END;
/
