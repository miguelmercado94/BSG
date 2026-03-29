CREATE OR REPLACE TRIGGER trg_ai_c5080015
before insert on c5080015
for each row
declare
w_coord   number:= 0;
w_canal   number:= 0;
begin
  begin
    select conv_ent_coord,
           conv_cod_canal
      into w_coord,
           w_canal
      from c1001400
     where conv_cod_entidad = :new.clave_gestor
       and conv_cod_canal   = :new.cod_canal
       and fecha_baja       is null;
    exception when others then null;
  end;
  if :new.compania = 1 then
    if w_coord = 61 then
      :new.negocio_inscrito := 'TI'||:new.nro_titulo;
    elsif w_coord in (51) and w_canal in (2,3) then
      :new.negocio_inscrito := :new.nro_titulo;
    else   
      :new.negocio_inscrito := to_char(:new.cod_ramo)||:new.nro_titulo;
    end if;
  end if;
  if :new.tipdoc_ctahabiente is null then
    begin
	  :new.tipdoc_ctahabiente:=PCK_DEBITO_AUTOMATICO.FCO_RETORNA_DOCUMENTO(:new.NRO_DOCUMTO,:new.secter_ctahabiente);
	  exception when others then null;
	end;
  end if;
end;
