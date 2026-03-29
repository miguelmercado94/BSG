CREATE OR REPLACE TRIGGER SIM_TRG_AU_SIMDETMAEAUT
  AFTER UPDATE ON SIM_DETALLE_MAESTRA_AUTOS
  FOR EACH ROW
  /* Autor: Wilson Enrique Sacristan Vaca
     Fecha: Marzo 09 de 2015
     Objetivo: Llevar log de cambios hechos en la tabla SIM_DETALLE_MAESTRA_AUTOS
     */
DECLARE
  l_def_cadena       VARCHAR2(20):= 'XXXXXXXXXXXXXXX';
--  l_def_valor        NUMBER:= 9999;
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
  IF NVL(:NEW.cod_marca,l_def_cadena) <>  NVL(:old.cod_marca,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'MARCA_AUTOS',:OLD.cod_marca,:new.cod_marca,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.cod_tipo,l_def_cadena) <>  NVL(:old.cod_tipo,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'TIPO_AUTOS',:OLD.cod_tipo,:new.cod_tipo,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.cod_uso,l_def_cadena) <>  NVL(:old.cod_uso,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'USO_AUTOS',:OLD.cod_uso,:new.cod_uso,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
  IF NVL(:NEW.cod_clase,l_def_cadena) <>  NVL(:old.cod_clase,l_def_cadena) THEN
    insertaInconsistencia(:OLD.PLACA,'CLASE_AUTOS',:OLD.cod_clase,:new.cod_clase,:NEW.FUENTE_ULTIMA_MODIFICACION);
  END IF;
END;
/
