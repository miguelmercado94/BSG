CREATE OR REPLACE TRIGGER TRG_BU_R_x2000030
  BEFORE UPDATE OF fecha_vig_end, periodo_fact, cod_mon, fecha_vig_pol, fecha_venc_pol, nro_documto
     ON x2000030   FOR EACH ROW
DECLARE
   V_Primera        Naturales.Primer_Apellido%TYPE;
  V_Segundoa       Naturales.Segundo_Apellido%TYPE;
  V_Primern        Naturales.Primer_Nombre%TYPE;
  V_Segundon       Naturales.Segundo_Nombre%TYPE;
  V_Razon_Social   Juridicos.Razon_Social%TYPE;
  V_Tipo           VARCHAR2 (1);
  V_Desctipo       VARCHAR2 (200);
BEGIN
  IF :new.fecha_vig_end  IS NULL AND :new.fecha_vig_pol IS NOT NULL AND :new.Cod_Conv IS NULL
    AND :new.cant_sini3 IS NOT NULL
     THEN
    --  sim_proc_log('TRG x2000030 '||:new.fecha_vig_pol||' convenio '||:new.Cod_Conv,'');
      raise_application_error(-20100,'Error actualizando fecha nula x2000030');
  END IF;
  IF (nvl(:old.periodo_fact,0)<>nvl(:new.periodo_fact,0)) OR
     (nvl(:old.cod_mon,0)<>nvl(:new.cod_mon,0)) OR
     (nvl(:old.Fecha_Venc_Pol,add_months(:old.fecha_vig_pol,12)) <>
      nvl(:new.Fecha_Venc_Pol,add_months(:new.fecha_vig_pol,12))) OR
     (:old.fecha_vig_pol <> :new.fecha_vig_pol)
   THEN
     UPDATE sim_x_riesgo_poliza
        SET mca_procesado = 'N'
        WHERE num_secu_pol = :new.num_secu_pol;
  END IF;
   IF :NEW.Nro_Documto IS NOT NULL AND :NEW.Tdoc_Tercero IS NOT NULL
     AND :old.Nro_Documto != :new.Nro_Documto
    THEN
      BEGIN
        :NEW.Sec_Tercero   := NULL;
        PCK999_TERCEROS.Prc_Datosd_Tercero (:NEW.Nro_Documto, :NEW.Tdoc_Tercero, :NEW.Sec_Tercero,
                                            V_Primera, V_Segundoa, V_Primern,
                                            V_Segundon, V_Razon_Social, V_Tipo,
                                            V_Desctipo);
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
   END IF;
end TRG_BU_R_x2000030;
/
