CREATE OR REPLACE TRIGGER a5021103_a1001300
BEFORE INSERT OR UPDATE ON a5021103 FOR EACH ROW
DISABLE
DECLARE

  reg_Tercero   pkg_api.t_generico_terceros;

BEGIN

		IF :new.tdoc_tercero IS NOT NULL THEN

			reg_Tercero.p_numero_documento := :new.numero_documento;
			reg_Tercero.p_tipo_documento := :new.tdoc_tercero;
			pkg_api.prc_generico_terceros(reg_Tercero);

		ELSE

			reg_Tercero :=  NULL;
			reg_Tercero.p_secuencia_tercero	:=pkg_api1.fun_traer_datos_sin_tip_doc(:new.numero_documento,reg_Tercero.p_tipo_documento);
            pkg_api.prc_generico_terceros(reg_Tercero);
            :new.tdoc_tercero :=reg_Tercero.p_tipo_documento;

		END IF;

		IF reg_Tercero.p_sqlerr <> 0 THEN
            raise_application_error(-20500,'No existe tercero con este documento. Por favor verifique.');
		END IF;

END;
/
