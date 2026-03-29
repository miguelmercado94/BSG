CREATE OR REPLACE TRIGGER coberturas_c1340290
before insert
   on c1340290
for each row
WHEN (new.cod_secc   = 34  and
                   new.cod_cob    < 100 and
                   new.cod_ramo  != 80  or
                   new.cod_ramo  != 750)
declare
  existe varchar2(1):= 'N';
  desc_cobertura varchar2(30);
Begin
   if INSERTING then
    begin
     select desc_concep
     into desc_cobertura
     from a7000300
     where cod_cia        = 2
       and cod_concep_rva = :new.cod_cob;
     exception when no_data_found then
       desc_cobertura := 'COBERTURA NO DEFINIDA';
    end;
    begin
      select 'S'
        into existe
      from ccobprod
      where ccp_cod_cia      = 2
        and ccp_cod_secc     = :new.cod_secc
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
                              ,2
                              ,:new.cod_ramo
                              ,:new.cod_secc
                              ,:new.cod_cob
                              ,desc_cobertura
                              );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
   end if;
End coberturas_c1340290;
/
