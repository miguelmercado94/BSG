CREATE OR REPLACE TRIGGER TRG_EMI_CAMBIA_COMISIONES
  BEFORE INSERT OR UPDATE ON EMI_COMISIONES
  FOR EACH ROW
DECLARE
  var_claves NUMBER;
BEGIN

  IF :old.clave_intermediario <> :new.clave_intermediario THEN
    --Se inserta para saber que el cambio se realizó desde la pantalla de comisiones y
    --así no eliminar el registro desde emi_solicitud_poliza
    INSERT INTO EMI_MUTATING
      (NUM_ROWID, TABLE_NAME, MENSAJE, NUMERO_SOLICITUD, CODIGO_RIESGO)
    VALUES
      (NULL,
       'EMI_ACTUALIZA_CLAVE',
       :NEW.CLAVE_INTERMEDIARIO,
       :NEW.NUMERO_SOLICITUD,
       NULL);

    SELECT COUNT(*)
      INTO var_claves
      FROM emi_solicitud_poliza es
     WHERE (es.clave_intermediario = :old.clave_intermediario OR
           es.clave_intermediario_2 = :old.clave_intermediario)
       AND es.numero_solicitud = :new.numero_solicitud;

    IF var_claves > 0 THEN
      UPDATE emi_solicitud_poliza es
         SET es.clave_intermediario  = :new.clave_intermediario,
             es.localidad_radicacion = :new.localidad_radicacion,
             es.mca_lider            = :new.mca_lider,
             es.porc_participacion   = :new.porc_participacion
       WHERE es.clave_intermediario = :old.clave_intermediario
         AND es.numero_solicitud = :new.numero_solicitud;

      UPDATE emi_solicitud_poliza es
         SET es.clave_intermediario_2  = :new.clave_intermediario,
             es.localidad_radicacion_2 = :new.localidad_radicacion,
             es.mca_lider_2            = :new.mca_lider,
             es.porc_participacion_2   = :new.porc_participacion
       WHERE es.clave_intermediario_2 = :old.clave_intermediario
         AND es.numero_solicitud = :new.numero_solicitud;
    END IF;
  ELSE
    --Si la clave no existe en la solicitud de la póliza
    IF :new.nro_secu = 1 THEN
      UPDATE emi_solicitud_poliza es
         SET es.clave_intermediario  = :new.clave_intermediario,
             es.localidad_radicacion = :new.localidad_radicacion,
             es.mca_lider            = :new.mca_lider,
             es.porc_participacion   = :new.porc_participacion,
             es.tiene_segunda_clave  = DECODE(es.clave_intermediario_2,
                                              NULL,
                                              'N',
                                              'S')
       WHERE es.numero_solicitud = :new.numero_solicitud;

    END IF;
    --Se valida porque se estaban actualizando ambas claves con el mismo intermediario
    IF :new.nro_secu = 2 THEN

      UPDATE emi_solicitud_poliza es
         SET es.clave_intermediario_2  = :new.clave_intermediario,
             es.localidad_radicacion_2 = :new.localidad_radicacion,
             es.mca_lider_2            = :new.mca_lider,
             es.porc_participacion_2   = :new.porc_participacion,
             es.tiene_segunda_clave    = 'S'
       WHERE es.numero_solicitud = :new.numero_solicitud;
    END IF;
  END IF;

  IF :old.clave_intermediario IS NULL AND
     :new.clave_intermediario IS NOT NULL THEN
    IF :new.nro_secu = 2 THEN
      UPDATE emi_solicitud_poliza es
         SET es.clave_intermediario_2  = :new.clave_intermediario,
             es.localidad_radicacion_2 = :new.localidad_radicacion,
             es.mca_lider_2            = :new.mca_lider,
             es.porc_participacion_2   = :new.porc_participacion,
             es.tiene_segunda_clave    = 'S'
       WHERE es.numero_solicitud = :new.numero_solicitud;
    END IF;
  END IF;

  IF :new.mca_lider = 'S' AND :new.nro_secu > 2 THEN
    UPDATE emi_solicitud_poliza es
       SET es.mca_lider = 'N', es.mca_lider_2 = 'N'
     WHERE es.numero_solicitud = :new.numero_solicitud;
  END IF;

END TRG_EMI_CAMBIA_COMISIONES;
/
