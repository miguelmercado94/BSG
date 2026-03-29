CREATE OR REPLACE TRIGGER audit_anulacion
AFTER INSERT OR DELETE OR UPDATE OF MCA_ANU_POL
     ON A2000030 FOR EACH ROW
DECLARE
    numpol1       number(13);
    codsecc       number(3);
    VNTAnulada    char(1);
    V_Multicia    varchar2(1);
    V_Lider       varchar2(1);
    V_numsecupol  number;
    V_numend      number;
    V_borrada     char(1);
    V_anulada     char(1);
    patveh        VARCHAR(20);
BEGIN

     if  DELETING then
         v_multicia := pkg299_multicompania.negocio_multicompania(:old.num_secu_pol);
         if v_multicia = 'S' then
            pkg299_multicompania.verifica_borre_anexa (:old.num_secu_pol,

                                                       :old.num_end,
                                                       v_borrada);
            if v_borrada = 'N' then
               raise_application_error (-20000, 'No puede borrar poliza lider si existe endoso anexo asociado');
            end if;
         end if;
         codsecc := :old.cod_Secc;
         numpol1 := nvl(:old.num_pol1,0);
         if nvl(:old.tipo_end,'XX') = 'RE' then
            VNTAnulada := 'S';
         Else
           VNTAnulada := 'N';
         end if;
     else
         codsecc := :new.cod_Secc;
         numpol1 := nvl(:new.num_pol1,0);
         VNTAnulada := nvl(:new.mca_anu_pol,'N');
         IF codsecc = 310   THEN  --hlc actualiza informacion runt
           BEGIN
             SELECT pat_veh
             INTO patveh
             FROM sim_X_datossoat
             WHERE num_secu_pol = :new.num_secu_pol
             AND   num_end      = :new.num_end;
           END;
           IF NVL(:NEW.TIPO_END,'X') = 'AT' THEN
             UPDATE sim_informacion_runt SET soat_fecha_vencimiento =  Add_months(soat_fecha_vencimiento,-12),
                                           soat_numero_poliza = :new.num_pol1||LPad(:new.num_end, 2, '0'),
                                           fecha_modificacion = SYSDATE
             WHERE ig_pat_veh = patveh;
           END IF;
          /* IF :NEW.NUM_END = 0 THEN
             UPDATE sim_informacion_runt SET soat_fecha_vencimiento =  :NEW.FECHA_VENC_POL,
                                           soat_numero_poliza = :new.num_pol1||LPad(:new.num_end, 2, '0'),
                                           fecha_modificacion = SYSDATE,
                                           soat_entidad_expide = 'SEGUROS COMERCIALES BOLIVAR',
                                           soat_fecha_expedicion = SYSDATE
             WHERE ig_pat_veh = patveh;
           END IF; */
         END IF;
         if updating and :old.num_end > 0 and nvl(:new.mca_anu_pol,'N') = 'S'
         then
            v_multicia := pkg299_multicompania.negocio_multicompania(:old.num_secu_pol);
            if v_multicia = 'S' then
               V_lider  := pkg299_multicompania.verifica_poliza_lider(:old.num_secu_pol);
               if V_lider = 'S' then
                  V_numsecupol := pkg299_multicompania.retorna_num_secu_pol_anexo(:old.num_secu_pol);
                  pkg299_datos_gen_mc.verifica_anulacion(p_numsecupol => v_numsecupol,
                                                         p_numend     => v_numend,
                                                         p_anulada    => v_anulada);
                  if v_anulada = 'N' then
                      raise_application_error (-20000, 'No puede anular poliza lider si esta el anexo vigente');
                  end if;
               end if;
            end if;
         end if;
     end if;
     if numpol1 > 0 then
        update c2990008
        set mca_anu_renov = VNTAnulada
          , estado_renov = decode(:new.tipo_end, 'AT',3,'RE',2,
            decode(num_pol1 + 1, renovada_por , 1,4))
        where renovada_por = numpol1  and
              cod_secc_renov = codsecc;
        update c2990008
        set anulada = VNTAnulada,
            estado = decode(VNTAnulada, 'S',3,decode(num_pol1 + 1, renovada_por , 2,1))
        where cod_secc = codsecc and
             num_pol1 = numpol1  ;
    end if;
exception
  when others then null;
end AUDIT_ANULACION;
/
