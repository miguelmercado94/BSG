CREATE OR REPLACE TRIGGER trg_au_c1001000
after update of COD_IDENTIF, TDOC_TERCERO, SEC_TERCERO
on c1001000
for each row
declare
w_coord   number:= 0;
begin
  update c5080002
     set TDOC_TERCERO_ENT = :new.tdoc_tercero
	   , SEC_TERCERO_ENT  = :new.sec_tercero
	   , DEB_NIT_ENTIDAD  = :new.cod_identif
   where deb_nit_entidad  = :old.cod_identif
     and deb_clave_gestor = :new.cod_entidad;
  update c5080004
     set DEB_NIT_ENTIDAD  = :new.cod_identif
	    ,TDOC_TERCERO     = :new.tdoc_tercero
		,SEC_TERCERO      = :new.sec_tercero
   where deb_nit_entidad  = :old.cod_identif
     and tdoc_tercero     = :old.tdoc_tercero;
end;
/
