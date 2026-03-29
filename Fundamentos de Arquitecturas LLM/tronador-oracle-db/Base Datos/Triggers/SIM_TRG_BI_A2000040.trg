CREATE OR REPLACE TRIGGER SIM_TRG_BI_A2000040
BEFORE INSERT  ON A2000040 
for each ROW
DECLARE
  l_TipoEmp_Aseg     VARCHAR2(3);
  l_CodAgrupCont     VARCHAR2(9);
  l_codSecc          a2000030.cod_secc%type;
  l_codramo          a2000030.cod_ramo%type;
  
  CURSOR tipo_envio IS
   SELECT sim_tipo_envio FROM a2000030
    WHERE num_secu_pol = :new.num_secu_pol
      AND sim_tipo_envio IS NOT NULL
      AND num_end < :new.num_end
      AND EXISTS (SELECT '' FROM a2000030
                  WHERE num_secu_pol = :new.Num_Secu_Pol
                    AND num_End = :new.Num_End
                    AND sim_tipo_envio IS NULL)
    ORDER BY num_end DESC;
  
  CURSOR sistema_origen_ant is
    select b.sim_sistema_origen, b.sistema_origen
    from a2000030 b
    where num_pol1 = (select a.Num_Pol_Ant
                          from a2000030 a
                          where num_secu_pol = :new.num_secu_pol
                          and   num_end = 0
                          and   cod_secc = 1)
    and   num_end = 0
    and   cod_secc = 1;
        
BEGIN

  FOR i IN tipo_envio LOOP
      UPDATE a2000030
       SET  sim_tipo_envio = i.sim_tipo_envio,
            sim_modo_impresion = decode(i.sim_tipo_envio, 'PE','P','PA','O','O')--mantis 53004
      WHERE num_secu_pol = :new.num_secu_pol
        AND num_end = :new.num_end;
      EXIT;
  END LOOP;
  
  IF (nvl(:new.cod_agrup_cont,'0') = '001001250') THEN
      Proc_Act_Agrup_Subproducto(:new.num_secu_pol, :new.num_end, :new.cod_cob, l_CodAgrupCont);
      IF l_CodAgrupCont IS NOT NULL THEN
         :new.Cod_agrup_cont := l_CodAgrupCont;
      END IF;
  END IF;
------------------------------------------------------------------  
--  Mcga 2021/11/10
-- implementación para proyecto de circular 037 tipo de asegurado  
------------------------------------------------------------------  
  begin
      select cod_secc, cod_ramo
        into l_codSecc, l_codramo
        from A2000030
       where num_secu_pol=:new.num_secu_pol
         and num_end=0; 
      exception when others then l_codSecc:=null;
  End;    

IF l_codSecc= 4 THEN
  begin
      select valor_campo
        into l_TipoEmp_Aseg
        from A2000020
       where num_secu_pol=:new.num_secu_pol
         and cod_campo   ='TIPO_EMP_ASEG'
         and mca_vigente ='S';
      exception when others then 
              begin
                  select valor_campo_en
                    into l_TipoEmp_Aseg
                    from x2000020
                   where num_secu_pol=:new.num_secu_pol
                     and cod_campo   ='TIPO_EMP_ASEG';
                  exception when others then 
                        l_TipoEmp_Aseg:=null;
              End;    

  End;    
--  :new.cod_agrup_cont:='004477450';
  sim_proc_log('TRIGGER-CU037',:new.num_secu_pol||l_TipoEmp_Aseg||l_codramo);
  IF l_TipoEmp_Aseg is not null THEN
     IF l_TipoEmp_Aseg='EIC' and l_codramo=450 THEN
        :new.cod_agrup_cont:='004477450';
     ELSIF l_TipoEmp_Aseg='EIC' and l_codramo=440 THEN        
        :new.cod_agrup_cont:='004477440';
     ELSIF l_TipoEmp_Aseg='EIC' and l_codramo=455 THEN                
        :new.cod_agrup_cont:='004477455';
     END IF;

     IF l_TipoEmp_Aseg='SSP' and l_codramo=450 THEN 
        :new.cod_agrup_cont:='004476450';
     ELSIF l_TipoEmp_Aseg='SSP' and l_codramo=440 THEN        
        :new.cod_agrup_cont:='004476440';
     ELSIF l_TipoEmp_Aseg='SSP' and l_codramo=455 THEN                
        :new.cod_agrup_cont:='004476455';
     END IF;

  END IF;
END IF;
    
  if :new.num_end = 0 then 
    for k in sistema_origen_ant loop
      if k.sim_sistema_origen = 101 then 
        UPDATE a2000030
         SET  sim_sistema_origen = k.sim_sistema_origen
        WHERE num_secu_pol = :new.num_secu_pol
          AND num_end = 0;
   
      elsif k.sistema_origen = 101 THEN 
        UPDATE a2000030
         SET  sistema_origen = k.sistema_origen
        WHERE num_secu_pol = :new.num_secu_pol
          AND num_end = 0;        
      end if;     
    end loop;
  end if;
  
END SIM_TRG_AU_A2000040;
/
