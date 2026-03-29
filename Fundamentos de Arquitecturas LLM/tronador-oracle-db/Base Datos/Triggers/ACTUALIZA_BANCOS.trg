CREATE OR REPLACE TRIGGER ACTUALIZA_BANCOS
before insert or
      update of nom_entidad
   on A5020900
for each row
-----------------------------------------------------------------------------
-- Objetivo : insertar o actualizar las entidades bancarias en el sistema de
--            informacion de SISALUD
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : febrero 14 de 2000
-------------------------------------------------------------------------------

declare
  existe varchar2(1):= 'N';
Begin
  if INSERTING then
    begin
      select 'S'
        into existe
      from entbanc
      where etb_num_entidad = :new.num_entidad;
      exception when no_data_found then
        begin
          insert into entbanc(etb_num_entidad
                             ,etb_nom_entidad
                             )
                       values(:new.num_entidad
                             ,:new.nom_entidad
                             );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then
    if :new.nom_entidad != :old.nom_entidad then
      update entbanc set etb_nom_entidad = :new.nom_entidad
      where etb_num_entidad  = :old.num_entidad;
    end if;
  end if;
End actualiza_bancos;
/
