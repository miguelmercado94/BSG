CREATE OR REPLACE TRIGGER insercion_a2000040
before insert or
       delete or
       update of suma_aseg
                ,cod_ries
                ,num_end
                ,cod_cob
                ,mca_tipo_cob
   on a2000040
for each row
WHEN (new.cod_cob > 600 or
                   new.cod_cob = 259 or
                   new.cod_cob = 588)
declare
  existe varchar2(1):= 'N';
  mensaje   varchar2(60);
  vcodsecc  number;
  vcodcia  number;
  vcodramo  number;
  Vmcatipocob varchar2(1);
Begin

  if deleting then
    delete cambios_tronador
     where  num_secu_pol = :old.num_secu_pol
       and  num_end      = :old.num_end
       and  cod_ries     = :old.cod_ries
       and  cod_cob      = :old.cod_cob;
  else

    begin

      select cod_cia, 'S', cod_secc, cod_ramo
        into vcodcia, existe , vcodsecc, vcodramo
      from a2000030
      where num_secu_pol   = :new.num_secu_pol
        and rownum <= 1;
      exception when no_data_found then
        existe := 'N';
                when others then existe := 'S';
    end;
   /* begin
    select mca_tipo_cob into Vmcatipocob
      from a1002000
     where cod_cob = :new.cod_cob and rownum <= 1;
     if :new.mca_tipo_cob != vmcatipocob then
          insert into audit_exclu
          values (:new.num_secu_pol, :new.cod_cob, vcodcia, sysdate,
          'TRG_COB', 'Cambio', substr(user,5,8));
      --raise_application_error(-20000, 'No puede cambiar tipo de Cobertura');
     end if;
     exception when others then
        insert into audit_exclu
         values (:new.num_secu_pol, :new.cod_cob, vcodcia, sysdate,
         'TRG_COB', 'NoExis', substr(user,5,8));
    end;*/
    if existe = 'S' and vcodsecc in (34,26) and vcodramo not in (80,739)
    then
      begin
        insert into cambios_tronador(num_secu_pol
                                    ,num_end
                                    ,cod_ries
                                    ,cod_cob
                                    ,mca_vigente_cob
                                    ,suma_aseg
                                    )
                              values(:new.num_secu_pol
                                    ,:new.num_end
                                    ,:new.cod_ries
                                    ,:new.cod_cob
                                    ,:new.mca_vigente
                                    ,:new.suma_aseg
                                    );
        exception when others then
          mensaje := substr(sqlerrm,1,60);
          begin
            insert into inconsistencias_sisalud(num_secu_pol
                                               ,num_end
                                               ,cod_ries
                                               ,mca_vigente_cob
                                               ,suma_aseg
                                               ,error
                                               ,tabla
                                               )
                                         values(:new.num_secu_pol
                                               ,:new.num_end
                                               ,:new.cod_ries
                                               ,:new.mca_vigente
                                               ,:new.suma_aseg
                                               ,mensaje
                                               ,'A2000040'
                                               );
            exception when others then null;
          end;
        /* aqui acaba el primer exception */
      end;
    end if;

  end if;
End insercion_a2000040;
/
