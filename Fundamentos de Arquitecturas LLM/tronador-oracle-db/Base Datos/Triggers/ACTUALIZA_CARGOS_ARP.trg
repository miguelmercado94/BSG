CREATE OR REPLACE TRIGGER ACTUALIZA_CARGOS_ARP
before insert or
      update of desc_ocupacion
   on C2700016
for each row
-----------------------------------------------------------------------------
-- Objetivo : insertar o actualizar los CARGOS en sistema de informacion de
--            SISALUD ARP
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : junio 10 de 2003
-------------------------------------------------------------------------------
declare
  existe varchar2(1):= 'N';
Begin
  /* Ini Mantis 29225 omontiel 26/08/2014 -- Se elimina las operaciones sobre ARP_CARGOS desde el trigger y se migra al procedimiento ARL_PCK_JOB.Prc_Crea_Cargo_ARP
  if INSERTING then
    begin
      select 'S'
        into existe
      from arp_cargos
      where carg_codigo  = :new.cod_cargo;
      exception when no_data_found then
        begin
          insert into arp_cargos(carg_codigo
                               ,carg_descripci
                               )
                         values(:new.cod_cargo
                               ,:new.desc_ocupacion
                               );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then*/
  IF UPDATING then
    :new.mca_migra := 'A';
	/*
	if :new.desc_ocupacion != :old.desc_ocupacion then
      update arp_cargos
      set carg_descripci = :new.desc_ocupacion
      where carg_codigo =  :old.cod_cargo;
    end if;*/ -- Fin Mantis 29225
  end if;
End actualiza_cargos_arp;
/
