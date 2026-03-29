CREATE OR REPLACE TRIGGER TRG_BU_EMI_CAMBIA_PRODUCTO
  before update of tipo_negocio on emi_solicitud_poliza
  for each row
declare
  -- local variables here
  mensaje        VARCHAR2(255);
  var_cod_riesgo number;
BEGIN
  BEGIN
    if :old.tipo_negocio <> :new.tipo_negocio and :new.tipo_negocio = 'I' then
      --1. Cambiar a Rechazada la solicitud actual
      :new.codigo_ramo         := :old.codigo_ramo;
      :new.codigo_producto     := :old.codigo_producto;
      :new.tipo_negocio        := :old.tipo_negocio;
      :new.estado_solicitud    := 'REC';
      :new.observacion_usuario := 'SE CAMBIA A RECHAZADA POR CAMBIO DE PRODUCTO'||:new.observacion_usuario;

      if :old.tomador_es_asegurado = 'S' then
        var_cod_riesgo := 3;
      elsif :old.tomador_es_asegurado = 'N' then
        var_cod_riesgo := 1;
      end if;

      DELETE FROM EMI_MUTATING WHERE TABLE_NAME = 'EMI_SOLICITUD';

      INSERT INTO EMI_MUTATING
        (num_rowid, table_name, mensaje, numero_solicitud, codigo_riesgo)
      VALUES
        (:NEW.ROWID, 'EMI_SOLICITUD', mensaje, :NEW.numero_solicitud, var_cod_riesgo);

    elsif :old.tipo_negocio <> :new.tipo_negocio and
          :new.tipo_negocio = 'C' then
      --Se actualizan los campos normalmente cuando pasa de individual a conjunta
      :new.observacion_usuario := 'SE CAMBIA EL TIPO DE NEGOCIO A CONJUNTA '||:new.observacion_usuario;
    end if;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR EN TRG_BU_EMI_CAMBIA_PRODUCTO=>' ||
                           SQLCODE);
      DBMS_OUTPUT.PUT_LINE('MENSAJE=>' || SQLERRM);
      RAISE_APPLICATION_ERROR(-20524,
                              'TRG_BU_EMI_CAMBIA_PRODUCTO ' || SQLCODE ||
                              ' Fallo' || SQLERRM);
  END;
END TRG_BU_EMI_CAMBIA_PRODUCTO;
/
