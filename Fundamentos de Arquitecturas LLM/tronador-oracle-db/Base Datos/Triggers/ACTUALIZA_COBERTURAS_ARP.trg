CREATE OR REPLACE TRIGGER actualiza_coberturas_arp
before insert or
      update of txt_cob
   on a1002100
for each row
WHEN (new.cod_cia    = 2)
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
    and cod_secc  = 70;
      exception when others then
        seccion := 0;
  end;
   if INSERTING then
    begin
      select 'S'
        into existe
      from arp_ccobprod
      where ccp_cod_cia      = :new.cod_cia
        and ccp_cod_secc     = 70
        and ccp_cod_texto    = :new.cod_ramo
        and ccp_cdgo_cobrtra = :new.cod_cob
      ;
      exception when no_data_found then
        begin
          insert into arp_ccobprod(ccp_cod_cia
                                  ,ccp_cod_texto
                                  ,ccp_cod_secc
                                  ,ccp_cdgo_cobrtra
                                  ,ccp_descrip
                                  )
                            values(:new.cod_cia
                                  ,:new.cod_ramo
                                  ,70
                                  ,:new.cod_cob
                                  ,:new.txt_cob
                                  );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    end;
  elsif UPDATING then
    if  :new.txt_cob  != :old.txt_cob then
      update arp_ccobprod
        set ccp_descrip      = :new.txt_cob
      where ccp_cod_cia      = :old.cod_cia
        and ccp_cod_texto    = :old.cod_ramo
        and ccp_cod_secc     = 70
        and ccp_cdgo_cobrtra = :old.cod_cob;
    end if;
  end if;
End actualiza_coberturas_arp;
/
