CREATE OR REPLACE TRIGGER TRG_VPA_RECAUDO_FACT_E
AFTER INSERT OR UPDATE OF ESTADO_REGISTRO, ESTADO_CTB ON SB_RECAUDO
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
WHEN ((new.estado_registro = 'CTB' OR new.estado_ctb = 'CTB') AND NEW.VALOR_FPU != 0)
  --
  ----------------------------------------------------------------------------------------
  /******************************************
  -- TRG_VPA_RECAUDO_FACT_E: Trigger encargado de registrar una factura electronica cada vez
                             que se contabiliza una factura de pago en SB_RECAUDO con valor de ahorro(FPU)
  --
  Referencia: El proceso se basa en una funcionalidad similar en SIMON del paquete
              SIM_PKG_FACTURA_ELECTRONICA.
  --
  -- Procedimientos y Funciones llamadas durante la ejecucion.
  --   * VPA_PKG_FACTURA_ELECTRONICA.PRC_INSERT_FACTE: Creacion del registro de la factura electronica
  --   * VPA_PKG_FACTURA_ELECTRONICA.PRC_LOG_FACTE   : Log del movimiento realizado
  ----------------------------------------------------------------------------------------
  --
  -- {  COD_CAMBIO || USUARIO                   || FECHA_CAMBIO || DESCRIPCION
  -- {  V1.0       || Christian Pimiento - ASW  || 14/08/2020   || Creacion Inicial
  --
  -- {  V2.0       || Christian Pimiento - ASW  || 09/09/2020   || Se modifica el ciclo iniciandolo a cero
  --
  ******************************************/
  ----------------------------------------------------------------------------------------
  --
DECLARE

  --Variables de proceso
  Vg_Reg           VPA_FACTURA_ELECTRONICA%ROWTYPE := NULL;
  Vl_Satelite      CONSTANT VARCHAR2(5) := 'VPA';
  --
  Vl_Org           CONSTANT VARCHAR2(50) := 'TRG_VPA_RECAUDO_FACT_E';
  Vl_Msj           VARCHAR2(1000);
  Vl_Tip           VARCHAR2(100);
  Vl_Sec           SB_RECAUDO.CONSECUTIVO%TYPE := :new.consecutivo;
  Vl_Pol           SB_RECAUDO.NUMERO_POLIZA%TYPE := :new.numero_poliza;

  --Parametros de salida en procesos externos
  Vo_Msj_Insert    VARCHAR2(1000) := NULL;
  
  --Excepciones Controladas
  Ex_Ctrl          EXCEPTION;

BEGIN
 
  --Se guardan los datos principales del recaudo contabilizado
  BEGIN
    Vg_Reg.Id_Factura       := Sq_FactEVpa.nextval;
    Vg_Reg.Id_Int_Fac       := :new.consecutivo;
    Vg_Reg.Cod_Cia          := :new.compania;
    Vg_Reg.Cod_Secc         := :new.seccion;
    Vg_Reg.Cod_Ramo         := :new.producto;
    Vg_Reg.Num_Pol1         := :new.numero_poliza;
    Vg_Reg.Ciclo            := 0;
    Vg_Reg.Cod_Mon          := NVL(:new.codigo_moneda, 1);
    Vg_Reg.Fecha_Factura    := SYSTIMESTAMP;
    Vg_Reg.Fec_Vcto         := COALESCE(:new.fecha_ctb,
                                        :new.fecha_recaudo,
                                        TRUNC(SYSDATE))+30; --Este parametro no esta guardado en VPA
    Vg_Reg.Imp_Prima        := ABS(:new.valor_fpu);
    Vg_Reg.Total_a_Pagar    := ABS(:new.valor_fpu);
    Vg_Reg.Prima_Prov       := 0;
    Vg_Reg.Satelite         := Vl_Satelite;
    --Aplica para Notas Credito
    IF :new.valor_fpu < 0 THEN
      BEGIN
        Vg_Reg.Consec_Nota := TO_NUMBER(SUBSTR(:new.descripcion,
                                               INSTR(:new.descripcion,':',1,1)+1));
        Vg_Reg.Descripcion_Nota := :new.descripcion;
      EXCEPTION
        WHEN OTHERS THEN
          Vg_Reg.Consec_Nota      := NULL;
          Vg_Reg.Descripcion_Nota := NULL;
      END;
    END IF;
    Vg_Reg.Estado           := 'PD';
    Vg_Reg.Usuario_Creacion := USER;
    Vg_Reg.Fecha_Creacion   := SYSDATE;
  EXCEPTION
    WHEN OTHERS THEN
      Vl_Tip := 'ASIGNACION';      
      Vl_Msj := 'Error asignando las variables del trigger: '||
                SUBSTR(dbms_utility.format_error_backtrace, 1, 1000);
      RAISE Ex_Ctrl;
  END;

  --Llamada al proceso de insercion de la factura electronica
  VPA_PKG_FACTURA_ELECTRONICA.PRC_INSERT_FACTE(Vg_Reg, Vo_Msj_Insert);
  IF Vo_Msj_Insert IS NOT NULL THEN
    Vl_Tip := 'CREACION';
    Vl_Msj := 'Error creando el registro de la factura: '||Vo_Msj_Insert;
    RAISE Ex_Ctrl;
  END IF;

  --Se registra en el Log la transaccion
  Vl_Msj := 'FACTURA REGISTRADA';
  Vl_Tip := 'EXITO';
  VPA_PKG_FACTURA_ELECTRONICA.PRC_LOG_FACTE(Vl_Org, Vl_Tip, Vl_Msj, NULL, NULL, Vg_Reg);

  --
EXCEPTION
  WHEN Ex_Ctrl THEN
    Vg_Reg.Id_Int_Fac := Vl_Sec;
    Vg_Reg.Num_Pol1   := Vl_Pol;
    Vl_Tip            := 'ERROR';
    VPA_PKG_FACTURA_ELECTRONICA.PRC_LOG_FACTE(Vl_Org, Vl_Tip, Vl_Msj, NULL, NULL, Vg_Reg);
  WHEN OTHERS THEN
    Vg_Reg.Id_Int_Fac := :new.consecutivo;
    Vg_Reg.Num_Pol1   := :new.numero_poliza;
    Vl_Tip            := 'ERROR';
    VPA_PKG_FACTURA_ELECTRONICA.PRC_LOG_FACTE(Vl_Org, Vl_Tip, SUBSTR(SQLERRM,1,1000), NULL, NULL, Vg_Reg);
END TRG_VPA_RECAUDO_FACT_E;
/
