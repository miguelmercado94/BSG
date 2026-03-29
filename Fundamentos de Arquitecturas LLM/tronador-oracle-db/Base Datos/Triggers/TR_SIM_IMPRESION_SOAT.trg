CREATE OR REPLACE TRIGGER tr_sim_impresion_soat
  after insert on sim_impresion_soat  
  for each row
declare
  -- local variables here
begin
    ag_interface_operativa.descargue_polizas (
    un_sitio_almacenamiento    => :new.agencia_expedicion,
    un_causa                   => :new.estado_impresion,   -- 'I'mpresion o 'A'nulacion
    un_poliza                  =>  :new.nro_soat ,
    un_negocio                => :new.num_pol1,
    un_poliza_original        => :new.nro_soatant,
    un_documento              => :new.usuario_impresion,
    un_causa_novedad          => :new.causal);
end tr_sim_impresion_soat;
/
