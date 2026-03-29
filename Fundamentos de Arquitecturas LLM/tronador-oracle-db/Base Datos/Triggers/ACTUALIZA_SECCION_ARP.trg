CREATE OR REPLACE TRIGGER actualiza_seccion_arp
before insert or
      update of nom_secc
   on a1000200
for each row
WHEN (new.cod_cia = 2)
declare
  existe varchar2(1):= 'N';
Begin
  if INSERTING then
    begin
      select 'S'
        into existe
      from arp_seccion
      where cod_secc  = :new.cod_secc
        and cod_cia   = :new.cod_cia;
      exception when no_data_found then
        begin
          insert into arp_seccion(cod_cia
                                 ,cod_secc
                                 ,nom_secc
                                  )
                            values(:new.cod_cia
                                  ,:new.cod_secc
                                  ,:new.nom_secc
                                  );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then
    if :new.nom_secc != :old.nom_secc then
      update arp_seccion
      set nom_secc = :new.nom_secc
      where cod_cia  = :old.cod_cia
        and cod_secc = :old.cod_secc;
    end if;
  end if;
End actualiza_seccion_arp;
/
