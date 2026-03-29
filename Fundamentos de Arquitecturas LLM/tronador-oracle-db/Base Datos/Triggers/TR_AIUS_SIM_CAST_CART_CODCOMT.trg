CREATE OR REPLACE TRIGGER TR_AIUS_SIM_CAST_CART_CODCOMT
/*
    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Septiembre 10 de 2015 - Mantis 38430 - Proyecto Castigo de Cartera
    Desc : Creación del trigger. Valida solo exista un comite activo
*/
  AFTER INSERT OR UPDATE ON SIM_CASTIGO_CARTERA_COMITE
Declare
  vl_cod_comite_activo sim_castigo_cartera_comite.cod_comite%type;
Begin
  -- Cantidad de comites activos
  If SIM_PCK_CASTIGO_CARTERA_COMITE.Fun_Cantidad_Comite_Estado('A') > 1 Then
    vl_cod_comite_activo := SIM_PCK_CASTIGO_CARTERA_COMITE.Fun_Comite_Activo;
    raise_application_error(-20001,'Solo se puede tener un comité ACTIVO y el actual es el: '||vl_cod_comite_activo);
  End If;
End TR_AIUS_SIM_CAST_CART_CODCOMT;
/
