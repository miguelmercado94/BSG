CREATE OR REPLACE TRIGGER TRG_ACTU_ESTADO
  after insert OR UPDATE on sim_log_reenvio_soat  
  for each row
declare
begin
  IF :NEW.ESTADO IN ('E','R','0') THEN
   begin
    UPDATE SIM_DATOSSOAT SET ESTADO_IMPRESION = 'ENV'
    where num_secu_pol = :new.num_secu_pol
    and   num_end      = :new.num_end;
   end;
   Begin
     update sim_log_cotizacion_soat set envio_pdf = 'S',
                                       fecha_envio_pdf = sysdate
     where num_secu_pol = :new.num_secu_pol
     and   num_end      = :new.num_end;
   End;  
  END IF;  
end TRG_ACTU_ESTADO;
/
