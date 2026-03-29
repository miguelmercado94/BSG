CREATE OR REPLACE TRIGGER insercion_a2000030
after insert or
      delete or
      update of fecha_vig_pol
               ,fecha_venc_pol
               ,num_pol1
               ,mca_provisorio
               ,fecha_vig_end
               ,fecha_venc_end
               ,tipo_end
               ,cod_end
               ,sub_cod_end
               ,nro_documto
               ,cod_usr
   on a2000030
for each row
WHEN ((new.cod_cia   =  2  and
                   (new.cod_secc  =  34 or
                    new.cod_secc  = 26) and
                   new.cod_ramo not in (80,739)) or
                   (old.cod_cia   =  2  and
                   (old.cod_secc  =  34 or
                    old.cod_secc  = 26) and
                   old.cod_ramo not in (80,739)))
declare
  mensaje   varchar2(60);
Begin
   if deleting then
    begin
     insert into borrado_sisalud(num_pol1
                                ,num_secu_pol
                                ,num_end
                                ,cod_end
                                ,sub_cod_end
                                ,tipo_end
                                ,cod_cia
                                ,cod_ramo
                                ,cod_secc
                                ,cod_usr
                                ,fecha_equipo
                                ,operacion)
                           values(:old.num_pol1
                                 ,:old.num_secu_pol
                                 ,:old.num_end
                                 ,:old.cod_end
                                 ,:old.sub_cod_end
                                 ,:old.tipo_end
                                 ,:old.cod_cia
                                 ,:old.cod_ramo
                                 ,:old.cod_secc
                                 ,:old.cod_usr
                                 ,sysdate
                                 ,'delete'
                                );
     delete cambios_tronador
     where num_secu_pol = :old.num_secu_pol
       and num_end      = :old.num_end;
    end;
   else
     begin
      insert into cambios_tronador(num_pol1
                                  ,num_secu_pol
                                  ,num_end
                                  ,cod_end
                                  ,sub_cod_end
                                  ,tipo_end
                                  ,num_pol_flot
                                  ,nro_documto
                                  ,cod_cia
                                  ,cod_ramo
                                  ,cod_secc
                                  ,fec_vig_pol
                                  ,fec_vec_pol
                                  ,fec_vig_end
                                  ,mca_provisorio
                                  ,fecha_equipo
                                  ,fecha_venc_end
                                  ,cod_usr
                                  ,operacion
                                  )
                            values(:new.num_pol1
                                  ,:new.num_secu_pol
                                  ,:new.num_end
                                  ,:new.cod_end
                                  ,:new.sub_cod_end
                                  ,:new.tipo_end
                                  ,:new.num_pol_flot
                                  ,:new.nro_documto
                                  ,:new.cod_cia
                                  ,:new.cod_ramo
                                  ,:new.cod_secc
                                  ,:new.fecha_vig_pol
                                  ,:new.fecha_venc_pol
                                  ,decode(:new.tipo_end,'AT',:new.fecha_vig_end
                                  ,'AP',:new.fecha_vig_end
                                  ,'AD',:new.fecha_vig_end,null)
                                  ,:new.mca_provisorio
                                  ,sysdate
                                  ,:new.fecha_venc_end
                                  ,:new.cod_usr
                                  ,'insert'
                                  );
      exception when others then
         mensaje := substr(sqlerrm,1,60);
           begin
               insert into inconsistencias_sisalud(num_pol1
                                                  ,num_secu_pol
                                                  ,num_end
                                                  ,cod_end
                                                  ,sub_cod_end
                                                  ,tipo_end
                                                  ,num_pol_flot
                                                  ,nro_documto
                                                  ,cod_cia
                                                  ,cod_ramo
                                                  ,cod_secc
                                                  ,fec_vig_pol
                                                  ,fec_vec_pol
                                                  ,fec_vig_end
                                                  ,fecha_venc_end
                                                  ,error
                                                  ,tabla
                                                  )
                                            values(:new.num_pol1
                                                  ,:new.num_secu_pol
                                                  ,:new.num_end
                                                  ,:new.cod_end
                                                  ,:new.sub_cod_end
                                                  ,:new.tipo_end
                                                  ,:new.num_pol_flot
                                                  ,:new.nro_documto
                                                  ,:new.cod_cia
                                                  ,:new.cod_ramo
                                                  ,:new.cod_secc
                                                  ,:new.fecha_vig_pol
                                                  ,:new.fecha_venc_pol
                                                  ,decode(:new.tipo_end,'AT',
                                                  :new.fecha_vig_end,'AP',
                                                  :new.fecha_vig_end,
                                                  'AD',:new.fecha_vig_end,null)
                                                  ,:new.fecha_venc_end
                                                  ,mensaje
                                                  ,'A2000030'
                                                  );
              exception when others then null;
            end;
          /* aqui acaba el primer exception */
     end;
   end if;
--end if;
End insercion_a2000030;
/
