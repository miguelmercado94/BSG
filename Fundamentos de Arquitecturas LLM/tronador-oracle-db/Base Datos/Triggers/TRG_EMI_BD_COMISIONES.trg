CREATE OR REPLACE TRIGGER TRG_EMI_BD_COMISIONES
  before delete on EMI_COMISIONES
  for each row
declare
  var_mutating NUMBER;
begin

     SELECT COUNT(*)
       INTO var_mutating
       FROM EMI_MUTATING eg
      WHERE EG.NUMERO_SOLICITUD =  :old.numero_solicitud
        AND EG.MENSAJE = :old.clave_intermediario;

     --Si no se cambió la clave desde la pantalla de intermediario
     IF var_mutating = 0 THEN

     update emi_solicitud_poliza ep
        set ep.clave_intermediario = null,
            ep.porc_participacion = 0,
            ep.mca_lider = 'N',
            ep.localidad_radicacion = null,
            ep.tiene_segunda_clave = 'N'
      where ep.numero_solicitud = :old.numero_solicitud
        and ep.clave_intermediario = :old.clave_intermediario;

      update emi_solicitud_poliza es
         set es.clave_intermediario_2 = null,
             es.porc_participacion_2 = 0,
             es.mca_lider_2 = 'N',
             es.localidad_radicacion_2 = null,
             es.tiene_segunda_clave = 'N'
       where es.numero_solicitud = :old.numero_solicitud
         and es.clave_intermediario_2 = :old.clave_intermediario;
      ELSE
          DELETE FROM EMI_MUTATING WHERE TABLE_NAME = 'EMI_SOLICITUD_CLAVE';
      END IF;

end TRG_EMI_BD_COMISIONES;
/
