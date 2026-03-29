CREATE OR REPLACE TRIGGER actualiza_poliza_madre
before insert
   on a2010030
for each row
WHEN (new.cod_cia  = 2 and
                   new.cod_secc = 34
                   and new.cod_ramo != 80)
declare
  existe varchar2(1):= 'N';
  nombre varchar2(30);
  v_secuencia number(15);
Begin
  if INSERTING then
   dbms_output.put_line('A');

  /* Goter  RPR Noviembre 9/2006
    begin
    select a.ape_benef ape
     into nombre
    from (a1001300) a
    where a.cod_benef     = :new.nro_documto
    and a.cod_act_benef = 1
    and a.fecha_equipo  = (select max(d.fecha_equipo)
                           from (a1001300) d
                           where a.cod_docum = d.cod_docum
                           and a.cod_benef = d.cod_benef
                           and d.cod_act_benef = 1
                          );
    exception when no_data_found then
     nombre:= 'PERSONA NO DEFINIDA';
    end;
    */
    Begin
    nombre := substr(pck999_terceros.fun_retorna_nombresd(:new.nro_documto,
                                                  :new.tdoc_tercero,
                                                   v_secuencia),1,30);
    Exception when others then null;
    end;
    begin
      select 'S'
        into existe
      from polmadre
      where pmd_numpol   = :new.num_pol1
      ;
      exception when no_data_found then
        begin
   dbms_output.put_line('B');
          insert into polmadre(pmd_cod_cia
                              ,pmd_cod_texto
                              ,pmd_cod_secc
                              ,pmd_numpol
                              ,pmd_nombre
                              ,pmd_num_secupol
                              )
                        values(:new.cod_cia
                              ,:new.cod_ramo
                              ,:new.cod_secc
                              ,:new.num_pol1
                              ,nombre

                              ,:new.num_secu_pol
                              );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  end if;
End actualiza_poliza_madre;
/
