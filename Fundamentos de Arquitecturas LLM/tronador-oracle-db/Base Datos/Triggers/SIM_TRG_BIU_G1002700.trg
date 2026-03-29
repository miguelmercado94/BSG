CREATE OR REPLACE TRIGGER SIM_TRG_BIU_G1002700
-- WESV: Trigger creado para sincronizar tabla de usuarios de tronador
--       con tabla de usuarios SIMON
AFTER INSERT
OR UPDATE  OR DELETE
 ON G1002700 FOR EACH ROW
DECLARE
l_identifica NUMBER(15);
l_nombre     VARCHAR2(200);
BEGIN
  BEGIN
   -- dbms_output.put_line(TRIM(SUBSTR(:new.nom_user,1,INSTR(:new.nom_user,' ') -1)));
    l_identifica := to_number(TRIM(SUBSTR(:new.nom_user,1,INSTR(:new.nom_user,' ') -1)));
    l_nombre     := SUBSTR(:new.nom_user,INSTR(:new.nom_user,' ') +1);
    EXCEPTION WHEN OTHERS THEN l_identifica:= 0;
  END;
  IF l_identifica > 0 THEN
    BEGIN
      insert INTO usuario (codigo_usuario,
                      codigo_perfil,
                      clave_usuario,
                      codigo_localidad,
                      contador_accesos,
                      fecha_activacion,
                      indicador_nivel_supervision,
                      fecha_vencimiento,
                      estado_usuario,
                      cedula_empleado,
                      codigo_empleado,
                      nombre_empleado,
                      telefono_empleado,
                      fecha_creacion,
                      fecha_transaccion,
                      usuario_transaccion,
                      cod_cia,
                      usuario_corporativo,
                      puede_delegar,
                      entidad_colocadora,
                      usuario_tronador,
                      nivel_aut,
                      num_autorizaciones)
              VALUES (l_identifica, 'DEFAULT','XX',:NEW.COD_AGENCIA,0,SYSDATE,:NEW.NIVEL_AUT
                     ,SYSDATE+5000,'A', l_identifica, NULL, l_nombre, NULL,SYSDATE,SYSDATE,USER
                     ,:NEW.cod_cia, 'N','N',NULL,:new.cod_user_cia, :NEW.NIVEL_AUT,0);
      EXCEPTION WHEN OTHERS THEN
        UPDATE usuario
          SET usuario_tronador = :new.cod_user_cia
        WHERE codigo_usuario = l_identifica;
    END;
  END IF;
  EXCEPTION WHEN OTHERS THEN NULL;
END SIM_TRG_BIU_G1002700 ;
/
