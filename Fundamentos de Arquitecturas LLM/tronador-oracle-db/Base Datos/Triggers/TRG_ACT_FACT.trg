CREATE OR REPLACE TRIGGER trg_act_fact
		  BEFORE UPDATE OF NUM_FACTURA ON a2990700
		  FOR EACH ROW
BEGIN
 Declare

   V_anexa         varchar2(1);
   V_multicia      varchar2(1);
   V_SECTERCERO    NUMBER(13) := NULL;
   V_TIPO          VARCHAR2(1) := NULL;
   V_DESROL        VARCHAR2(60) := NULL;
   V_CODACTBENEF   NUMBER(2) := NULL;
   V_MCAESTADO	   VARCHAR2(1) := 'V';
   V_FECHAPAGO	   DATE := NULL;
   V_FECASIENTO	   DATE := NULL;
   V_PORCCOMI	     NUMBER(5,2) := 100;
 Begin
 If user like '%INTASI14' or user like '%PUMA'  then
    v_multicia := pkg299_multicompania.negocio_multicompania(:new.num_secu_pol);
    if v_multicia = 'S' and nvl(:new.secuencia ,0) = 0 then

       pkg299_multicompania.asigna_secuencia_a2000163(p_numsecupol => :new.num_Secu_pol,
                                                      p_numfactura => :new.num_factura);

       pkg299_multicompania.asigna_secuencia_a2990700(p_numsecupol => :new.num_secu_pol,
                                                      p_numfactura => :new.num_factura,
                                                      p_secuencia => :new.secuencia,
                                                      p_lider => :new.lider);
     if   nvl(:new.secuencia ,0) = 0 then
       select cons_fac_multicia.nextval into :new.secuencia from dual;
      :new.lider := pkg299_multicompania.verifica_poliza_lider(:new.num_secu_pol);
     end if;
       declare
          id_var a2000163%rowtype;

       begin
         pkg299_datos_gen_mc.recupera_a2000163(p_numsecupol => :new.num_secu_pol,
                                               p_numfactura => :new.num_factura,
                                               id_var => id_var);
         if nvl(:new.sec_tercero,0) != 0 then
         Begin
            pck999_terceros.Prc_Roltercero(v_sectercero,v_tipo,v_codactbenef,v_desrol);
         exception when others
           then v_codactbenef := 1;
         end;
         else
            v_codactbenef := 1;
         end if;
         begin
             insert into a502_multi_cia(secuencia,lider, cod_cia, cod_secc, cod_ramo, num_pol1,
               num_end, num_factura, num_cuota, fecha_vig_fact, fecha_vto_fact, fecha_equipo,
               cod_situacion, cod_prod, cod_benef, cod_act_benef, clave_gestor, imp_prima,
               imp_mon_local, imp_imptos_local, imp_der_emi, imp_rec_adm, cod_mon, tc,
               porc_comi, fecha_pago, fec_asiento, mca_estado)
             values(:new.secuencia,:new.lider, :new.cod_cia, :new.cod_secc,
                    :new.cod_ramo, :new.num_pol1,:new.num_end, :new.num_factura,nvl(:new.num_cuota,1),
                    id_var.fecha_vig_fact,id_var.fecha_vto_fact, id_var.fecha_equipo,:new.cod_situacion,
                    nvL(:new.cod_prod,99999), nvl(:new.nro_documto,9999999999),v_codactbenef,
                    nvl(:new.clave_gestor,99999),:new.imp_prima,:new.imp_moneda_local, :new.imp_imptos_mon_local,
                   :new.imp_der_emi, :new.imp_rec_adm, id_var.cod_mon, id_var.tc,
                   v_porccomi,  v_fechapago,v_fecasiento, v_mcaestado);
        end;
     Exception when others then
        raise_application_error (-20000, sqlerrm);
     End;
  end if;
 End if;
 End;
 Exception when others then null;
END;
/
