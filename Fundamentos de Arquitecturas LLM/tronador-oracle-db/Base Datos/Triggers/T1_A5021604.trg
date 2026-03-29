CREATE OR REPLACE TRIGGER t1_a5021604
before insert  on a5021604 for each row
DECLARE

  reg_Tercero   pkg_api.t_generico_terceros;
  v_Tdoc_Tercero VARCHAR2(3);

BEGIN

		IF :new.tdoc_tercero IS NOT NULL THEN

			reg_Tercero.p_numero_documento := :new.cod_benef;
			reg_Tercero.p_tipo_documento := :new.tdoc_tercero;
			pkg_api.prc_generico_terceros(reg_Tercero);

		ELSE

			reg_Tercero :=  null;
			reg_Tercero.p_secuencia_tercero	:=pkg_api1.fun_traer_datos_sin_tip_doc(:new.cod_benef,v_Tdoc_Tercero);
            pkg_api.prc_generico_terceros(reg_Tercero);
            :new.tdoc_tercero :=v_Tdoc_Tercero;

		END IF;

		IF reg_Tercero.p_sqlerr <> 0 THEN
            raise_application_error(-20500,'No existe tercero con este documento. Por favor verifique.');
		END IF;

END;
/
