CREATE OR REPLACE TRIGGER SIM_TRG_AU_SIMMAEAUT
  AFTER UPDATE ON SIM_MAESTRA_AUTOS
  FOR EACH ROW
  /* Autor: Wilson Enrique Sacristan Vaca
     Fecha: Marzo 09 de 2015
     Objetivo: Llevar log de cambios hechos en la tabla SIM_MAESTRA_AUTOS
     */
DISABLE
DECLARE
  l_def_cadena       VARCHAR2(20):= 'XXXXXXXXXXXXXXX';
  l_def_valor        NUMBER:= 9999;
  PROCEDURE insertaInconsistencia(ip_placa        VARCHAR2
                                 ,ip_campo        VARCHAR2
                                 ,ip_valorAnt     VARCHAR2
                                 ,ip_valorNue     VARCHAR2
                                 ,ip_fuenteCambio VARCHAR2) IS
  BEGIN

    INSERT INTO sim_incons_maestra_autos(placa
                                        ,campo
                                        ,valor_maestra
                                        ,valor_nuevo
                                        ,fuente
                                        ,fecha_creacion)
                                 VALUES (ip_placa
                                        ,ip_campo
                                        ,ip_valorAnt
                                        ,ip_valorNue
                                        ,ip_fuenteCambio
                                        ,SYSDATE);
--    EXCEPTION WHEN OTHERS THEN NULL;
  END insertaInconsistencia;
BEGIN
  IF NVL(:NEW.motor_veh,l_def_cadena) <>  NVL(:old.motor_veh,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'MOTOR_VEH',:OLD.MOTOR_VEH,:new.Motor_Veh,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.chasis_veh,l_def_cadena) <>  NVL(:old.chasis_veh,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'CHASIS',:OLD.chasis_veh,:new.chasis_veh,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.modelo,l_def_valor) <>  NVL(:old.modelo,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'MODELO',:OLD.modelo,:new.modelo,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.cilindraje,l_def_valor) <>  NVL(:old.cilindraje,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'CILINDRAJE',:OLD.cilindraje,:new.cilindraje,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.capacidad,l_def_cadena) <>  NVL(:old.capacidad,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'CAPACIDAD',:OLD.capacidad,:new.capacidad,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.nro_pasajeros,l_def_valor) <>  NVL(:old.nro_pasajeros,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'PASAJEROS',:OLD.nro_pasajeros,:new.nro_pasajeros,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.cod_pais,l_def_valor) <>  NVL(:old.cod_pais,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'PAIS',:OLD.cod_pais,:new.cod_pais,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.vin,l_def_valor) <>  NVL(:old.vin,l_def_valor)  THEN
    insertaInconsistencia(:OLD.PLACA,'VIN',:OLD.vin,:new.vin,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.color,l_def_valor) <>  NVL(:old.color,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'COLOR',:OLD.color,:new.color,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.peso,l_def_valor) <>  NVL(:old.peso,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'PESO',:OLD.peso,:new.peso,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
END SIM_TRG_BIU_SIMMAEAUT;
/
