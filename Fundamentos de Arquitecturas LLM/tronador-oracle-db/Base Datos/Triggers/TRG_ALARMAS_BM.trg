CREATE OR REPLACE TRIGGER trg_alarmas_bm
AFTER INSERT OR UPDATE OF INDICE_MASA_CORPORAL,HIPERTENSION_ARTERIAL,ESTA_EMBARAZADA,
                          CIRUGIA_PROGRAMADA, CAMBIO_MOTIVO_SALUD,COLESTEROL_TRIGLICERIDOS,
                          OBESIDAD
  ON EMI_BLOQUE_MEDICO FOR EACH ROW
DECLARE
  v_edad           number(3);
  v_suma_asegurada number(17);

BEGIN
  IF (NVL(:NEW.INDICE_MASA_CORPORAL, 0) <>
     NVL(:OLD.INDICE_MASA_CORPORAL, 0) AND
     NVL(:NEW.INDICE_MASA_CORPORAL, 0) >= 30) THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: IMC MAYOR O IGUAL A 30 - ALARMA: OBESIDAD'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.HIPERTENSION_ARTERIAL,'-') <> NVL(:OLD.HIPERTENSION_ARTERIAL,'-') AND
     NVL(:NEW.HIPERTENSION_ARTERIAL,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: HIPERTENSION ARTERIAL'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.ESTA_EMBARAZADA,'-') <> NVL(:OLD.ESTA_EMBARAZADA,'-') AND
     NVL(:NEW.ESTA_EMBARAZADA,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: ESTA EMBARAZADA'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.CIRUGIA_PROGRAMADA,'-') <> NVL(:OLD.CIRUGIA_PROGRAMADA,'-') AND
     NVL(:NEW.CIRUGIA_PROGRAMADA,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: CIRUGIA PROGRAMADA'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.CAMBIO_MOTIVO_SALUD,'-') <> NVL(:OLD.CAMBIO_MOTIVO_SALUD,'-') AND
     NVL(:NEW.CAMBIO_MOTIVO_SALUD,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: OCUPACION O RESIDENCIA SALUD'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.COLESTEROL_TRIGLICERIDOS,'-') <> NVL(:OLD.COLESTEROL_TRIGLICERIDOS,'-') AND
     NVL(:NEW.COLESTEROL_TRIGLICERIDOS,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' ||
                                 ' ALARMA: COLESTEROL Y TRIGLICERIDOS'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  IF (NVL(:NEW.OBESIDAD,'-') <> NVL(:OLD.OBESIDAD,'-') AND NVL(:NEW.OBESIDAD,'-') = 'S') THEN
    UPDATE EMI_SOLICITUD_POLIZA
       SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                 :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                 sysdate || ' ' || ' ALARMA: OBESIDAD'
     WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
  END IF;

  v_edad := Pkg_Emision_Polizas.sf_edad_asegurado(:NEW.NUMERO_SOLICITUD,
                                                  :NEW.CODIGO_RIESGO);

  select suma_asegurada
    into v_suma_asegurada
    from emi_solicitud_poliza ep
   where ep.numero_solicitud = :NEW.numero_solicitud;

  --Man 15406 Se ajusta para generar alarma de exámenes médicos por edad y suma asegurada, sólo con ciertas condiciones
  if v_edad < 46 then
    if v_suma_asegurada >= 251000000 then
      UPDATE EMI_SOLICITUD_POLIZA
         SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                   :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                   sysdate || ' ' ||
                                   ' ALARMA: REQUIERE EXAMENES MEDICOS'
       WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
    end if;
  end if;

  if v_edad >= 46 then
    if v_suma_asegurada >= 151000000 then
      UPDATE EMI_SOLICITUD_POLIZA
         SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                   :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                   sysdate || ' ' ||
                                   ' ALARMA: REQUIERE EXAMENES MEDICOS'
       WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
    end if;
  end if;

  if v_edad > 56 then
    if v_suma_asegurada >= 76000000 then
      UPDATE EMI_SOLICITUD_POLIZA
         SET OBSERVACION_USUARIO = OBSERVACION_USUARIO || ' -> ' ||
                                   :NEW.USUARIO_TRANSACCION || ' Fecha: ' ||
                                   sysdate || ' ' ||
                                   ' ALARMA: REQUIERE EXAMENES MEDICOS'
       WHERE NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD;
    end if;
  end if;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20005,
                            'Error actualizando Alarmas BM ' || SQLERRM);
END;
/
