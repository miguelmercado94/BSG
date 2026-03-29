CREATE OR REPLACE TRIGGER BORRA_MC
  before delete on a2990700
  for each row
declare
	Obj typ_multicia_c2999300 := typ_multicia_c2999300(null,null,null,null,null,null,null,
                                                     null,null,null,null,null);
  v_c2999300    c2999300%rowtype;
  V_existe      a2000030.mca_provisorio%type;
Begin

   Obj.numsecupol      := :old.num_secu_pol;
   Obj.numend          := :old.num_end;
   pkg299_multicompania.verifica_endoso_multicia(Obj, v_c2999300);
   if obj.lider = 'S' then
     begin
        select 'S' into v_existe
        from a2000163
        where num_secu_pol = v_c2999300.num_secu_pol_anexo
        and   num_end_ref  = v_c2999300.num_end_anexo;
        exception
          when no_data_found then v_existe := 'N';
          when too_many_rows then v_existe := 'S';
      end;
      if v_existe = 'S' then
        raise_application_error(-20500,'No puede Borrar Poliza Lider, Tiene polizas anexas ');
      end if;
   end if;
end BORRA_MC;
/
