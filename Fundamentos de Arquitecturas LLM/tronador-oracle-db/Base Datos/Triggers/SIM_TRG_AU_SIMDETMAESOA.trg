CREATE OR REPLACE TRIGGER SIM_TRG_AU_SIMDETMAESOA
  AFTER UPDATE ON SIM_DETALLE_MAESTRA_SOAT
  FOR EACH ROW
  /* Autor: Wilson Enrique Sacristan Vaca
     Fecha: Marzo 09 de 2015
     Objetivo: Llevar log de cambios hechos en la tabla SIM_DETALLE_MAESTRA_SOAT
     */
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
    EXCEPTION WHEN OTHERS THEN NULL;
  END insertaInconsistencia;
BEGIN

  IF NVL(:NEW.linea,l_def_valor) <>  NVL(:old.linea,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'LINEA_SOAT',:OLD.linea,:new.linea,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.servicio,l_def_valor) <>  NVL(:old.servicio,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'SERVICIO_SOAT',:OLD.servicio,:new.servicio,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.uso,l_def_valor) <>  NVL(:old.uso,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'USO_SOAT',:OLD.uso,:new.uso,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.marca_runt,l_def_valor) <>  NVL(:old.marca_runt,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'MARCA_SOAT',:OLD.marca_runt,:new.marca_runt,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.clase_runt,l_def_valor) <>  NVL(:old.clase_runt,l_def_valor) THEN
    insertaInconsistencia(:OLD.PLACA,'CLASE_SOAT',:OLD.clase_runt,:new.clase_runt,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;

END;
/
