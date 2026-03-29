CREATE OR REPLACE TRIGGER trg_ai_c5080015_RM
before insert on c5080015_RM
for each row
declare
w_coord   number:= 0;
begin
  begin
    select conv_ent_coord
      into w_coord

      from c1001400
     where conv_cod_entidad = :new.clave_gestor
       and conv_cod_canal   = :new.cod_canal
       and fecha_baja       is null;
    exception when others then null;
  end;
  if :new.compania = 1 then
    if w_coord = 61 then
      :new.negocio_inscrito := 'TI'||:new.nro_titulo;
    else
      :new.negocio_inscrito := to_char(:new.cod_ramo)||:new.nro_titulo;
    end if;
  end if;
end;
/
