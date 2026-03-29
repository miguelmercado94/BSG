CREATE OR REPLACE TRIGGER SIM_TRG_BIU_DATOSSOAT
  BEFORE insert OR UPDATE ON SIM_DATOSSOAT
  FOR EACH ROW
  /* Autor: Wilson Enrique Sacristan Vaca
     Fecha: Febrero 25 de 2015
     Objetivo: Sincronizar la maestra de autos con la informacion de expedicion del Soat
     */
DECLARE
l_datosAuto   sim_typ_datosAuto;
l_numpol1     sim_pck_tipos_generales.t_num_valor;
BEGIN
  BEGIN
    SELECT NUM_POL1
      INTO l_numpol1
      FROM a2000030 a
     WHERE a.num_secu_pol = :new.num_secu_pol
       AND nvl(a.num_end,0)      = 0;
    EXCEPTION WHEN OTHERS THEN
      l_numpol1 := 0;
  END;
  sim_proc_log('SIM_TRG_BIU_DATOSSOAT.inicio','0: '||:new.vin);

  l_datosAuto := NEW sim_typ_datosAuto(l_numpol1
                                      ,:new.Pat_Veh
                                      ,:new.motor_veh
                                      ,:new.Chasis_Veh
                                      ,:new.Vin
                                      ,:new.Modelo
                                      ,:new.Cilindraje
                                      ,NULL  -- color
                                      ,NULL  -- peso
                                      ,:new.Capacidad
                                      ,:new.Nro_Pasajeros
                                      ,:new.COD_PAIS
                                      ,NULL  --aut_cod_ramo_veh,
                                      ,NULL  -- aut_cod_marca
                                      ,NULL  -- aut_cod_tipo
                                      ,NULL  -- aut_cod_uso
                                      ,NULL  -- aut_cod_clase
                                      ,NULL-- :new.Cod_Ramo_Veh
                                      ,:new.Marca_Runt
                                      ,:new.uso
                                      ,:new.Clase_Runt
                                      ,:new.Linea
                                      ,:new.Servicio);
--  sim_proc_log('SIM_TRG_BIU_DATOSSOAT.inicio','1');
  SIM_PCK_PROCESO_DML_EMISION2.proc_actualizaMaestraAutos(l_datosAuto,'S');
--    sim_proc_log('SIM_TRG_BIU_DATOSSOAT.inicio','2. '||SQLERRM);
-- EXCEPTION WHEN OTHERS THEN
  --     sim_proc_log('SIM_TRG_BIU_DATOSSOAT.inicio','3. '||SQLERRM);
END SIM_TRG_BIU_DATOSSOAT;
/
