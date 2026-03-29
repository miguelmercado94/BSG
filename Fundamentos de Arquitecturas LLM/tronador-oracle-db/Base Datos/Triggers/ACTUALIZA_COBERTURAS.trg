CREATE OR REPLACE TRIGGER actualiza_coberturas
before insert or
      update of txt_cob
   on a1002100
for each row
WHEN (new.cod_cia    = 2 and
                   new.cod_ramo  not in (80,739))
declare
  existe varchar2(1):= 'N';
  seccion number(3);
Begin
  begin
    select cod_secc
    into seccion
    from a1001800
    where cod_cia =  2
    and cod_texto = :new.cod_ramo
    and sub_cod_texto is null
    and cod_secc  in (34,26);
      exception when others then
        seccion := 0;
  end;
  if seccion = 34 then
   if INSERTING then
    begin
      select 'S'
        into existe
      from ccobprod
      where ccp_cod_cia      = :new.cod_cia
        and ccp_cod_secc     in (34,26)
        and ccp_cod_texto    = :new.cod_ramo
        and ccp_cod_conc_cob = :new.cod_cob
      ;
      exception when no_data_found then
        begin
          insert into ccobprod(ccp_indvlrag
                              ,ccp_cod_cia
                              ,ccp_cod_texto
                              ,ccp_cod_secc
                              ,ccp_cod_conc_cob
                              ,ccp_descrip
                              )
                        values(0
                              ,:new.cod_cia
                              ,:new.cod_ramo
                              ,34
                              ,:new.cod_cob
                              ,:new.txt_cob
                              );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then
    if  :new.txt_cob  != :old.txt_cob then
      update ccobprod
        set ccp_descrip      = :new.txt_cob
      where ccp_cod_cia      = :old.cod_cia
        and ccp_cod_texto    = :old.cod_ramo
        and ccp_cod_secc     = 34
        and ccp_cod_conc_cob = :old.cod_cob;
    end if;
  end if;
end if;
  if seccion = 26 then
   if INSERTING then
    begin
      select 'S'
        into existe
      from ccobprod
      where ccp_cod_cia      = :new.cod_cia
        and ccp_cod_secc     = 26
        and ccp_cod_texto    = :new.cod_ramo
        and ccp_cod_conc_cob = :new.cod_cob
      ;
      exception when no_data_found then
        begin
          insert into ccobprod(ccp_indvlrag
                              ,ccp_cod_cia
                              ,ccp_cod_texto
                              ,ccp_cod_secc
                              ,ccp_cod_conc_cob
                              ,ccp_descrip
                              )
                        values(0
                              ,:new.cod_cia
                              ,:new.cod_ramo
                              ,26
                              ,:new.cod_cob
                              ,:new.txt_cob
                              );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then
    if  :new.txt_cob  != :old.txt_cob then
      update ccobprod
        set ccp_descrip      = :new.txt_cob
      where ccp_cod_cia      = :old.cod_cia
        and ccp_cod_texto    = :old.cod_ramo
        and ccp_cod_secc     = 26
        and ccp_cod_conc_cob = :old.cod_cob;
    end if;
  end if;
end if;
End actualiza_coberturas;
/
