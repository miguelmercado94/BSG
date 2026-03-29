CREATE OR REPLACE TRIGGER actualiza_ramos
before insert or
      update of txt_red
   on a1001800
for each row
WHEN (new.cod_cia    = 2 and
                   new.cod_secc   in (34,26) and
                   new.cod_texto not in (80,739))
declare
  existe varchar2(1):= 'N';
Begin
  if INSERTING and :new.sub_cod_texto is null then
    begin
      select 'S'
        into existe
      from ramprod
      where cod_cia   = :new.cod_cia
        and cod_secc  = :new.cod_secc
        and cod_texto = :new.cod_texto
      ;
      exception when no_data_found then
        begin
          insert into ramprod(cod_cia
                             ,cod_secc
                             ,cod_texto
                             ,sub_cod_texto
                             ,txt_red
                              )
                       values(:new.cod_cia
                             ,:new.cod_secc
                             ,:new.cod_texto
                             ,null
                             ,:new.txt_red
                             );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING and :new.sub_cod_texto is null then
    if :new.txt_red != :old.txt_red then
      update ramprod set txt_red = :new.txt_red
      where cod_cia   = :old.cod_cia
        and cod_secc  = :old.cod_secc
        and cod_texto = :old.cod_texto;
    end if;
  end if;
End actualiza_ramos;
/
