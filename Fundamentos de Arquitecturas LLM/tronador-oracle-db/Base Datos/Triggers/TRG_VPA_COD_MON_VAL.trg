CREATE OR REPLACE TRIGGER trg_vpa_cod_mon_val
BEFORE INSERT ON sb_recaudo
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
  --
  ----------------------------------------------------------------------------------------
  /******************************************
  -- TRG_VPA_COD_MON_VAL: Trigger encargado validar que se llene el campo codigo moneda ya que en algunos proceso de VPA no se le tiene en cuenta,
  --                      se realiza de esta manera para no impactar distintos procesos de la aplicacion directamente ya que la falta de este valor
 --                       solo molesta en el proceso PROGRAMA CB230836 - JOB AJDCOVPA
  --
  Referencia:
  --
  -- Procedimientos y Funciones llamadas durante la ejecucion.
  --   * :
  ----------------------------------------------------------------------------------------
  --
  -- {  COD_CAMBIO || USUARIO                   || FECHA_CAMBIO || DESCRIPCION
  -- {  V1.0       || Winer Lopez - Samtel      || 04/02/2025   || Creacion Inicial
  --
  ******************************************/
  ----------------------------------------------------------------------------------------
  --
DECLARE
  --Variables de proceso

  --Parametros de salida en procesos externos
  vo_msj_insert VARCHAR2(1000) := NULL;
  --v_cod_mon     sb_recaudo.codigo_moneda%TYPE;

  --Excepciones controladas
  ex_ctrl       EXCEPTION;

BEGIN

  --se valida el codigo de moneda
  IF :new.codigo_moneda IS NULL THEN
    --solo se busca cuando sea null
    BEGIN
      SELECT a3.cod_mon
        INTO :new.codigo_moneda
        FROM a2000030 a3
       WHERE a3.num_pol1 = :new.numero_poliza
         AND a3.cod_secc = :new.seccion
         AND a3.cod_cia  = :new.compania
         AND a3.num_end  = (SELECT MAX(x.num_end)
                              FROM a2000030 x
                             WHERE x.num_secu_pol = a3.num_secu_pol);
    EXCEPTION
      WHEN OTHERS THEN
        :new.codigo_moneda := 1;--Igualmente se le deja el valor por defecto 1 para que no vuelva a saltar error
        vo_msj_insert := 'Error buscando a30 cod_mon: ' || SUBSTR(SQLERRM,1,100);
        pr_log_trx('TRG_VPA_COD_MON_VAL','SB_RECAUDO',:new.numero_poliza,:new.seccion,NULL,vo_msj_insert);
    END;
    --
  END IF;
  --Espacio para log finaliza correctamente
  --Solo se genera log para errores
  --
EXCEPTION
  WHEN OTHERS THEN
    :new.codigo_moneda := 1;--Igualmente se le deja el valor por defecto 1 para que no vuelva a saltar error
    vo_msj_insert := 'Error general: ' || SUBSTR(SQLERRM,1,100);
    pr_log_trx('TRG_VPA_COD_MON_VAL','SB_RECAUDO',:new.numero_poliza,:new.seccion,NULL,vo_msj_insert);
END trg_vpa_cod_mon_val;
/
