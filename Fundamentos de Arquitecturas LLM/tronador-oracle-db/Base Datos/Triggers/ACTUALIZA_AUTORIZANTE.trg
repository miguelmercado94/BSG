CREATE OR REPLACE TRIGGER actualiza_autorizante
before insert
   on a5010020
for each row
WHEN (new.cod_agencia = 8225)
declare
  existe varchar2(1):= 'N';
  nombre varchar2(20);
Begin
  if INSERTING then
   begin
     select nom_autoriza
      into nombre
     from a5010010
     where autorizante = :new.autorizante;
      exception when no_data_found then
       nombre := 'AUTORIZANTE NO DEFINIDO';
   end;
   begin
     select 'S'
       into existe
     from autorizantes
     where atz_codemp      = :new.autorizante
       and atz_cod_agencia = :new.cod_agencia;
      exception when no_data_found then
        begin
          insert into autorizantes (atz_cod_agencia
                                   ,atz_codemp
                                   ,atz_nombre)
                             values(:new.cod_agencia
                                   ,:new.autorizante
                                   ,nombre
                                   );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  end if;
End actualiza_autorizante;
/
