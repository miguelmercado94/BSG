CREATE OR REPLACE TRIGGER SIM_TRG_BIU_A2040100
  BEFORE INSERT OR UPDATE ON A2040100
  FOR EACH ROW
  /* Autor: Wilson Enrique Sacristan Vaca
     Fecha: Febrero 25 de 2015
     Objetivo: Sincronizar la maestra de autos con la información de expedición de Vehiculos
     */
DECLARE
l_datosAuto   sim_typ_datosAuto;
 -- rc 
 es_codigo_rc number;
BEGIN
  l_datosAuto := NEW sim_typ_datosAuto(:new.num_secu_pol
                                      ,:new.Pat_Veh
                                      ,:new.motor_veh
                                      ,:new.Chasis_Veh
                                      ,:NEW.COD_MOD
                                      ,NULL  --Vin
                                      ,:new.Cilindrada
                                      ,:new.Color
                                      ,:new.Peso
                                      ,NULL -- capacidad
                                      ,NULL -- pasajeros
                                      ,NULL  --PAIS
                                      ,:new.cod_ramo_veh
                                      ,:new.cod_marca
                                      ,:new.cod_tipo
                                      ,:new.cod_uso
                                      ,:new.cod_clase
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL);

  SELECT COUNT(1)
  INTO  es_codigo_rc
  FROM  SIM_AUTOS_TARIFACION_CLASE_VEH
  WHERE COD_FASECOLDA = :new.cod_marca ;  
     
  IF es_codigo_rc = 0 THEN
     SIM_PCK_PROCESO_DML_EMISION2.proc_actualizaMaestraAutos(l_datosAuto,'A');
  END IF;    

END SIM_TRG_BIU_A2040100;
/
