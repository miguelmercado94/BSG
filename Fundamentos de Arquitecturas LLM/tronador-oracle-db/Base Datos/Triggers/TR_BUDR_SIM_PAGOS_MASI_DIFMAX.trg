CREATE OR REPLACE TRIGGER TR_BUDR_SIM_PAGOS_MASI_DIFMAX
/*
    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Agosto 13 de 2018 - Mantis 55555
    Desc : Creación del trigger. Auditar tabla SIM_PAGOS_MASIVOS_DIFMAX,
           cuando se actualice o elimine un registro.
*/
  BEFORE UPDATE OR DELETE ON SIM_PAGOS_MASIVOS_DIFMAX FOR EACH ROW
Declare
  vl_Tipo_Operacion  SIM_HIST_PAGOS_MASIVOS_DIF_MAX.Tipo_Operacion%type;
  vl_ip_equipo_maquina  SIM_HIST_PAGOS_MASIVOS_DIF_MAX.IP_EQUIPO_MAQUINA%TYPE;
  vl_fecha_hoy DATE := TRUNC(SYSDATE);
Begin
  vl_ip_equipo_maquina := 'IP: '||sys_context('USERENV','ip_address')||', Host: '||sys_context('USERENV','host');
  If Updating AND
    ((NVL(:OLD.SECU_PAG_DIFMAX,-1) != NVL(:NEW.SECU_PAG_DIFMAX,-1)) OR
     (NVL(:OLD.COD_CIA,-1) != NVL(:NEW.COD_CIA,-1)) OR
     (NVL(:OLD.COD_SECC,-1) != NVL(:NEW.COD_SECC,-1)) OR
     (NVL(:OLD.COD_RAMO,-1) != NVL(:NEW.COD_RAMO,-1)) OR
     (NVL(:OLD.VALOR_MAX_DIF,0) != NVL(:NEW.VALOR_MAX_DIF,0)) OR 
     (NVL(:OLD.FECHA_ALTA,vl_fecha_hoy) != NVL(:NEW.FECHA_ALTA,vl_fecha_hoy)) OR
     (NVL(:OLD.FECHA_BAJA,vl_fecha_hoy) != NVL(:NEW.FECHA_BAJA,vl_fecha_hoy)) OR
     (NVL(:OLD.FECHA_CREACION,vl_fecha_hoy) != NVL(:NEW.FECHA_CREACION,vl_fecha_hoy)) OR
     (NVL(:OLD.USUARIO_CREACION,vl_fecha_hoy) != NVL(:NEW.USUARIO_CREACION,vl_fecha_hoy))
    ) Then
    vl_Tipo_Operacion := 'A'; -- Actualización
    INSERT INTO SIM_HIST_PAGOS_MASIVOS_DIF_MAX (SECU_HISTORIAL_PAG, TIPO_OPERACION, FECHA_OPERACION,
    USUARIO_OPERACION, IP_EQUIPO_MAQUINA, SECU_PAG_DIFMAX, COD_CIA, COD_SECC, COD_RAMO,
    VALOR_MAX_DIF, FECHA_ALTA, FECHA_BAJA, FECHA_CREACION, USUARIO_CREACION)
    VALUES (SEQ_HIST_CONFIG_VAL_DIFMAX.NEXTVAL, vl_Tipo_Operacion, SYSDATE,
    :NEW.USUARIO_CREACION, vl_ip_equipo_maquina, :OLD.SECU_PAG_DIFMAX, :OLD.COD_CIA, :OLD.COD_SECC, :OLD.COD_RAMO,
    :OLD.VALOR_MAX_DIF, :OLD.FECHA_ALTA, :OLD.FECHA_BAJA, :OLD.FECHA_CREACION, :OLD.USUARIO_CREACION);
    -- Valida solapes fechas
    SIM_PCK_CONFIG_VAL_DIF_MAX.Prc_Cargar(p_secu_pag_dif_max => :NEW.SECU_PAG_DIFMAX,
    p_cod_cia => :NEW.COD_CIA, p_cod_secc => :NEW.COD_SECC,
    p_cod_ramo => :NEW.COD_RAMO, p_valor_max_dif => :NEW.VALOR_MAX_DIF,
    p_fecha_alta => :NEW.FECHA_ALTA, p_fecha_baja => :NEW.FECHA_BAJA);
  Elsif Deleting Then
    vl_Tipo_Operacion := 'B'; -- Borrado
    INSERT INTO SIM_HIST_PAGOS_MASIVOS_DIF_MAX (SECU_HISTORIAL_PAG, TIPO_OPERACION, FECHA_OPERACION,
    USUARIO_OPERACION, IP_EQUIPO_MAQUINA, SECU_PAG_DIFMAX, COD_CIA, COD_SECC, COD_RAMO,
    VALOR_MAX_DIF, FECHA_ALTA, FECHA_BAJA, FECHA_CREACION, USUARIO_CREACION)
    VALUES (SEQ_HIST_CONFIG_VAL_DIFMAX.NEXTVAL, vl_Tipo_Operacion, SYSDATE,
    :OLD.USUARIO_CREACION, vl_ip_equipo_maquina, :OLD.SECU_PAG_DIFMAX, :OLD.COD_CIA, :OLD.COD_SECC, :OLD.COD_RAMO,
    :OLD.VALOR_MAX_DIF, :OLD.FECHA_ALTA, :OLD.FECHA_BAJA, :OLD.FECHA_CREACION, :OLD.USUARIO_CREACION);
  End If;
End TR_BUDR_SIM_PAGOS_MASI_DIFMAX;
/
