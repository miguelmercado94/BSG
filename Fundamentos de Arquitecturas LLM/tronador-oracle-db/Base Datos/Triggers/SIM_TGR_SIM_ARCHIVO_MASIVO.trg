CREATE OR REPLACE TRIGGER SIM_TGR_SIM_ARCHIVO_MASIVO
  before insert on SIM_ARCHIVO_MASIVO
  for each row
declare
  v_secuencia number(17) := 0;
begin
  select CODIGO
    INTO v_secuencia
    from c9999909
   where cod_tab = 'PAR_SOAT_ONLINE'
     and dat_car = 'NUMERO_CARGUE';

  :new.id_archivo := v_secuencia;

end SIM_TGR_SIM_ARCHIVO_MASIVO;
/
