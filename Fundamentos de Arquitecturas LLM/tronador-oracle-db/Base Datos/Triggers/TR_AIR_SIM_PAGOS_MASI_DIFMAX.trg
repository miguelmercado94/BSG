CREATE OR REPLACE TRIGGER TR_AIR_SIM_PAGOS_MASI_DIFMAX
/*
    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Agosto 13 de 2018 - Mantis 55555
    Desc : Creación del trigger. Auditar tabla SIM_PAGOS_MASIVOS_DIFMAX,
           cuando se inserte un registro.
*/
  AFTER INSERT ON SIM_PAGOS_MASIVOS_DIFMAX FOR EACH ROW
Declare
  vl_Tipo_Operacion  SIM_HISTORIAL_PAGOS_MASIVOS.Tipo_Operacion%type;
  vl_ip_equipo_maquina  SIM_HISTORIAL_PAGOS_MASIVOS.IP_EQUIPO_MAQUINA%TYPE;
Begin
  If Inserting Then
    vl_Tipo_Operacion := 'C'; -- Creación
    vl_ip_equipo_maquina := 'IP: '||sys_context('USERENV','ip_address')||', Host: '||sys_context('USERENV','host');
    INSERT INTO SIM_HIST_PAGOS_MASIVOS_DIF_MAX (SECU_HISTORIAL_PAG, TIPO_OPERACION, FECHA_OPERACION,
    USUARIO_OPERACION, IP_EQUIPO_MAQUINA, SECU_PAG_DIFMAX, COD_CIA, COD_SECC, COD_RAMO,
    VALOR_MAX_DIF, FECHA_ALTA, FECHA_BAJA, FECHA_CREACION, USUARIO_CREACION)
    VALUES (SEQ_HIST_CONFIG_VAL_DIFMAX.NEXTVAL, vl_Tipo_Operacion, SYSDATE,
    :NEW.USUARIO_CREACION, vl_ip_equipo_maquina, :NEW.SECU_PAG_DIFMAX, :NEW.COD_CIA,
    :NEW.COD_SECC, :NEW.COD_RAMO, :NEW.VALOR_MAX_DIF, :NEW.FECHA_ALTA, :NEW.FECHA_BAJA,
    :NEW.FECHA_CREACION, :NEW.USUARIO_CREACION);
    -- Valida solapes fechas
    dbms_output.put_line('Prc_Cargar insertar');
    SIM_PCK_CONFIG_VAL_DIF_MAX.Prc_Cargar(p_secu_pag_dif_max => :NEW.SECU_PAG_DIFMAX,
    p_cod_cia => :NEW.COD_CIA, p_cod_secc => :NEW.COD_SECC,
    p_cod_ramo => :NEW.COD_RAMO, p_valor_max_dif => :NEW.VALOR_MAX_DIF,
    p_fecha_alta => :NEW.FECHA_ALTA, p_fecha_baja => :NEW.FECHA_BAJA);
  End If;
End TR_AIR_SIM_PAGOS_MASI_DIFMAX;
/
