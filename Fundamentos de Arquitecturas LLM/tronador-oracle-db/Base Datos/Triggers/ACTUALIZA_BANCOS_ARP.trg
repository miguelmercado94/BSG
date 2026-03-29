CREATE OR REPLACE TRIGGER ACTUALIZA_BANCOS_ARP
before insert or
      update of nom_entidad
   on A5020900
for each row
-----------------------------------------------------------------------------
-- Objetivo : insertar o actualizar las entidades bancarias en el sistema de
--            informacion de SISALUD ARP
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : marzo 08 de 2003
-------------------------------------------------------------------------------

declare
  existe varchar2(1):= 'N';
Begin
  if INSERTING then
    begin
      select 'S'
        into existe
      from arp_entbanc
      where etb_num_entidad = :new.num_entidad;
      exception when no_data_found then
        begin
          insert into arp_entbanc(etb_num_entidad
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
      update arp_entbanc set etb_nom_entidad = :new.nom_entidad
      where etb_num_entidad  = :old.num_entidad;
    end if;
  end if;
End actualiza_bancos_arp;
/
