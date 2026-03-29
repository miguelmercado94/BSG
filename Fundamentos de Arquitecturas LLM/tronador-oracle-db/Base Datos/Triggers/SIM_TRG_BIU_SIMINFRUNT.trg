CREATE OR REPLACE TRIGGER SIM_TRG_BIU_SIMINFRUNT
-- WESV: Trigger creado para sincronizar tabla de información runt con la maestra autos
-- SIM_MAESTRA_AUTOS
AFTER INSERT
OR UPDATE
 ON SIM_INFORMACION_RUNT FOR EACH ROW
DECLARE
l_datosAuto   sim_typ_datosAuto;
l_numpol1     sim_pck_tipos_generales.t_num_secuencia;
BEGIN
  l_datosAuto := NEW sim_typ_datosAuto(l_numpol1
                                      ,:new.Ig_Pat_Veh
                                      ,:NEW.IGV_NUMERO_MOTOR
                                      ,:new.igv_numero_chasis
                                      ,:NEW.IGV_NUMERO_VIN
                                      ,:new.igv_modelo
                                      ,:NEW.IGV_CILINDRAJE
                                      ,:NEW.IGV_COLOR
                                      ,NULL
                                      ,nvl(:new.dt_capacidad_carga,0)
                                      ,NULL
                                      ,:new.ig_pais
                                      ,NULL  --aut_cod_ramo_veh,
                                      ,NULL  -- aut_cod_marca
                                      ,NULL  -- aut_cod_tipo
                                      ,NULL  -- aut_cod_uso
                                      ,NULL  -- aut_cod_clase
                                      ,NULL--:new.Cod_Ramo_Veh
                                      ,:new.Igv_Marca
                                      ,NULL
                                      ,:new.Ig_Clase_Vehiculo
                                      ,:new.Igv_Linea
                                      ,:new.ig_tipo_servicio);
  SIM_PCK_PROCESO_DML_EMISION2.proc_actualizaMaestraAutos(l_datosAuto,'R');
END SIM_TRG_BIU_SIMINFRUNT ;
/
