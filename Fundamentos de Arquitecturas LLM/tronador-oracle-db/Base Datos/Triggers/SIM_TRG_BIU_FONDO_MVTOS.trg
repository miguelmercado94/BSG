CREATE OR REPLACE TRIGGER sim_trg_biu_fondo_mvtos
  before insert OR UPDATE ON SIM_FONDO_MVTOS 
  for each row
declare
  -- local variables here
begin
  IF INSERTING THEN
   :new.id_tabla := SEQ_FONDO_MVTOS.nextval;
   IF :NEW.USUARIO_CREACION IS NULL THEN
     :NEW.USUARIO_CREACION:= SUBSTR(USER,5,10);
   END IF;
   :NEW.FECHA_CREACION := SYSDATE;
    begin
      insert into sim_fondo_mvtos_hist(secuencia, 
                                      id_tabla, 
                                      id_tabla_fondo_cuenta, 
                                      nro_beneficiario, 
                                      tdoc_beneficiario, 
                                      cod_entidad, 
                                      tipo_cuenta, 
                                      numero_cuenta, 
                                      numero_recibo, 
                                      num_ord_pago, 
                                      num_factura, 
                                      fecha_transaccion, 
                                      valor_transaccion, 
                                      tipo_transaccion, 
                                      estado_transaccion, 
                                      usuario_aprob, 
                                      fecha_aprob, 
                                      usuario_envio, 
                                      fecha_envio, 
                                      usuario_creacion, 
                                      fecha_creacion, 
                                      usuario_modif, 
                                      fecha_modif, 
                                      fecha_cambio, 
                                      cod_user,
                                      TIPO_MOV,
                                      OBSERVACIONES)
     values(seq_fondo_mvtos_hist.nextval,
            :new.id_tabla, 
            :new.id_tabla_fondo_cuenta, 
            :new.nro_beneficiario, 
            :new.tdoc_beneficiario, 
            :new.cod_entidad, 
            :new.tipo_cuenta, 
            :new.numero_cuenta, 
            :new.numero_recibo, 
            :new.num_ord_pago, 
            :new.num_factura, 
            :new.fecha_transaccion, 
            :new.valor_transaccion, 
            :new.tipo_transaccion, 
            :new.estado_transaccion, 
            :new.usuario_aprob, 
            :new.fecha_aprob, 
            :new.usuario_envio, 
            :new.fecha_envio, 
            :new.usuario_creacion, 
            :new.fecha_creacion, 
            :new.usuario_modificacion, 
            :new.fecha_modificacion,
            sysdate,
            user,
            'I',
            :NEW.OBSERVACIONES);
    end;    
  ELSIF UPDATING THEN
    if nvl(:new.estado_transaccion,'XXX') <> 
       nvl(:old.estado_transaccion,'XXX') then
      if nvl(:old.estado_transaccion,'XXX') = 'REH' and
         nvl(:new.estado_transaccion,'XXX') <> 'REH' then
         NULL;
     --   raise_application_error ('-20501','No puede modificar solicitudes previamente rechazadas'); 
      end if;         
      if nvl(:old.estado_transaccion,'XXX') in('APR','REH') and
         nvl(:new.estado_transaccion,'XXX') not in ('APR','REH') then
         NULL;
      --  raise_application_error ('-20501','No puede modificar solicitudes previamente autorizadas o rechazadas'); 
      end if;         
    end if;
    IF :NEW.USUARIO_MODIFICACION IS NULL THEN
     :NEW.USUARIO_MODIFICACION := SUBSTR(USER,5,10);
   END IF;
   :NEW.FECHA_MODIFICACION := SYSDATE;
    begin
      insert into sim_fondo_mvtos_hist(secuencia, 
                                      id_tabla, 
                                      id_tabla_fondo_cuenta, 
                                      nro_beneficiario, 
                                      tdoc_beneficiario, 
                                      cod_entidad, 
                                      tipo_cuenta, 
                                      numero_cuenta, 
                                      numero_recibo, 
                                      num_ord_pago, 
                                      num_factura, 
                                      fecha_transaccion, 
                                      valor_transaccion, 
                                      tipo_transaccion, 
                                      estado_transaccion, 
                                      usuario_aprob, 
                                      fecha_aprob, 
                                      usuario_envio, 
                                      fecha_envio, 
                                      usuario_creacion, 
                                      fecha_creacion, 
                                      usuario_modif, 
                                      fecha_modif, 
                                      fecha_cambio, 
                                      cod_user,
                                      TIPO_MOV,
                                      OBSERVACIONES
                                      )
     values(seq_fondo_mvtos_hist.nextval,
            :OLD.id_tabla, 
            :OLD.id_tabla_fondo_cuenta, 
            :OLD.nro_beneficiario, 
            :OLD.tdoc_beneficiario, 
            :OLD.cod_entidad, 
            :OLD.tipo_cuenta, 
            :OLD.numero_cuenta, 
            :OLD.numero_recibo, 
            :OLD.num_ord_pago, 
            :OLD.num_factura, 
            :OLD.fecha_transaccion, 
            :OLD.valor_transaccion, 
            :OLD.tipo_transaccion, 
            :OLD.estado_transaccion, 
            :OLD.usuario_aprob, 
            :OLD.fecha_aprob, 
            :OLD.usuario_envio, 
            :OLD.fecha_envio, 
            :OLD.usuario_creacion, 
            :OLD.fecha_creacion, 
            :OLD.usuario_modificacion, 
            :OLD.fecha_modificacion,
            sysdate,
            user,
            'U'
            ,:OLD.OBSERVACIONES);
    END;                
  END IF;  

end sim_trg_biu_fondo_mvtos;
/
