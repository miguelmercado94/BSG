CREATE OR REPLACE TRIGGER "SIM_TRG_AU_A2000030" BEFORE UPDATE OF "MCA_TERM_OK" ON "A2000030" FOR EACH ROW
WHEN (new.sim_usuario_creacion IS NULL OR new.cod_end = 900 AND new.sub_cod_end =90
     OR new.Sim_Tipo_Envio IS Null Or new.sim_estrategias Is Null
      )
DECLARE
   Op_Resultado        number;
   Op_Sim_Subproducto  number(3);
   Op_Sim_No_Stellent  number(20);
   Op_Sim_Referido     varchar2(1);
   Op_Estrategia       number(15);
   Op_Entidad          number(15);
   l_num_secu_pol      number;
   l_Num_pol1          number;
   l_num_end           number;
   l_cod_secc          number;
   l_usuarioSimon      VARCHAR2(30);
   l_Estrategia        Number;
   l_Entidad           Number;
   l_Fechavig          Date;
 CURSOR tipo_envio IS
   SELECT sim_tipo_envio, num_end FROM a2000030
    WHERE num_secu_pol = :new.num_secu_pol
      AND sim_tipo_envio IS NOT NULL
      AND num_end < :new.num_end
      AND :new.sim_tipo_envio IS NULL
    ORDER BY num_end DESC;
BEGIN
If :new.num_end > 0 Then
  Begin
  FOR i IN tipo_envio LOOP
      UPDATE a2000030
       SET  sim_tipo_envio = i.sim_tipo_envio
      WHERE num_secu_pol = :new.num_secu_pol
        AND num_end = :new.num_end;
      EXIT;
  END LOOP;
  Exception When Others Then Null;
  End;
  End If;
  IF UPDATING THEN
     -- Si hay datos para actualizar, ejecuta los procesos del paquete de sincronización
     --
        l_num_secu_pol  :=  :new.num_secu_pol;
        l_Num_pol1      :=  :new.num_pol1;
        l_num_end       :=  :new.num_end;
        l_cod_secc      :=  :new.cod_secc;

        --
        -- 'PRODUCTOS' = SIM_SUBPRODUCTO / 'NRO_OPTICA' = SIM_NUMERO_STELLENT / 'ACT_REFERIDO' = SIM_REFERIDO
        --
        SIM_PCK_SINCRONIZACION.Proc_Sincroniza_DV_Poliza( l_num_secu_pol
                                                         ,l_num_end
                                                         ,Op_Resultado
                                                         ,Op_Sim_Subproducto
                                                         ,Op_Sim_No_Stellent
                                                         ,Op_Sim_Referido
                                                         ,Op_Estrategia
                                                         ,Op_entidad
                                                         );
        IF Op_Resultado  =  0  THEN
           :new.sim_subproducto     :=  Op_Sim_Subproducto;
           :new.SIM_NUMERO_STELLENT :=  Op_Sim_No_Stellent;
           :new.SIM_REFERIDO        :=  Op_Sim_Referido;
           :new.SIM_ESTRATEGIAS         :=  Op_Estrategia;
           :new.SIM_ENTIDAD_COLOCADORA  :=  Op_entidad;
        END IF;

        --
        --  Inserta en SIM_TEXTOS_POLIZAS ORDEN / COD_TEXTO / SUB_COD_TEXTO / TEXTO
      /*  SIM_PCK_SINCRONIZACION.Proc_Sincroniza_Textos   ( l_num_secu_pol
                                                         ,l_Num_pol1
                                                         ,l_num_end
                                                         ,l_cod_secc
                                                         ,'N'
                                                         ,Op_Resultado     );*/
        --
        --  Inserta en SIM_RIESGO_POLIZA l_descripcion/l_cod_prov/l_cpos_ries/l_direccion/l_marca_baja/ l_fecha_origen / l_Imp_prima / l_Imp_prima_End
       IF nvl(:new.tipo_end,'XX') NOT IN ('AT','RE') THEN
         SIM_PCK_SINCRONIZACION.Proc_Sincroniza_DV_Riesgo
        (l_num_secu_pol ,l_num_end ,:new.cod_cia, l_cod_secc , :new.cod_ramo, :new.fecha_vig_end, :new.fecha_vig_pol,
         :new.fecha_venc_pol, :new.mca_anu_pol, :new.cod_usr, Op_resultado);
       END IF;
       IF l_cod_secc in (922,923) THEN
         SIM_PCK_SINCRONIZACION.Proc_Sincroniza_Est_Version(l_num_secu_pol, l_num_end, Op_resultado);
       END IF;
     END IF;
   --  sim_proc_log('TRIGGER A2000030 '||l_num_secu_pol,'');
    
       simapi_retorna_estrategia_pol(l_num_secu_pol, l_Estrategia, l_entidad, l_Fechavig);
       :new.sim_estrategias := l_estrategia;
       :new.sim_Entidad_colocadora := l_entidad;
       Select num_tarjeta, decode(sim_tipo_envio,'PE','P','PA','O',sim_modo_impresion)
        Into :New.num_tarjeta, :New.sim_modo_impresion
        From x2000030
       Where num_secu_pol = l_num_secu_pol;
   --  sim_proc_log('TRIGGER A2000030 '||l_num_secu_pol,l_estrategia||'-'||l_entidad||'-'||:New.num_tarjeta||'-'|| :New.sim_modo_impresion);
     
EXCEPTION WHEN OTHERS  THEN
  NULL;
END SIM_TRG_AU_A2000030;
/
