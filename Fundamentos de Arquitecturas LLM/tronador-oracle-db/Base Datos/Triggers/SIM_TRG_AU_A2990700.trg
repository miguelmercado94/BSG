CREATE OR REPLACE TRIGGER SIM_TRG_AU_A2990700
  AFTER  UPDATE OF COD_SITUACION ON A2990700
  FOR EACH ROW
DECLARE

    V_Coderr                  C1991300.Cod_Error%type;
    V_MsgErr                  C1991300.MSG_ERROR%type;
    w_raise_error             exception ;

    g_producto_pers           CONSTANT NUMBER        :=  922;
    g_producto_comer          CONSTANT NUMBER        :=  923;

    w_num_pol_agrupada        NUMBER(13) ;
    w_nro_fac_agrup           NUMBER(15) ;

    w_estado_factura_agrup    VARCHAR2(2) ;

    w_encontro_datos          VARCHAR2(1) ;

BEGIN


    IF (  :new.cod_secc in ( g_producto_pers, g_producto_comer  ) ) THEN

          w_num_pol_agrupada   :=  NULL ;
          w_nro_fac_agrup      :=  NULL ;

          w_encontro_datos     := 'N' ;

          BEGIN
              select   num_pol_agrupada
                      ,sec_fac_agrup
                into   w_num_pol_agrupada
                      ,w_nro_fac_agrup
                from simapi_det_fac_agrupada e
               where e.num_secu_pol = :NEW.num_secu_pol
                 and e.num_factura  = :NEW.num_factura ;

                 w_encontro_datos     := 'S' ;

            EXCEPTION
                WHEN    NO_DATA_FOUND   THEN
                        w_encontro_datos     := 'N' ;
          END ;



          IF ( w_encontro_datos  = 'S'  ) THEN

              update simapi_det_fac_agrupada e
                   set estado_fac = :new.cod_situacion
                 Where e.num_secu_pol = :NEW.num_secu_pol
                   and e.num_factura  = :NEW.num_factura ;


              BEGIN
                      w_estado_factura_agrup := SIMAPI_PCK_AGRUPADA.fnc_estado_FacAgrup ( w_num_pol_agrupada, w_nro_fac_agrup);
              EXCEPTION
                WHEN OTHERS THEN
                   v_msgerr := ' Error llamando SIMAPI_PCK_AGRUPADA.fnc_estado_FacAgrup   sqlcode --> ' || sqlcode ||'   sqlerrm --> ' || sqlerrm  ;
                   RAISE_APPLICATION_ERROR (-20530,v_msgerr);
             END ;



              update simapi_fac_poliza_agrupada
                    set estado_fac_agrup =  w_estado_factura_agrup
                  where NRO_FAC_AGRUP    =  w_nro_fac_agrup
                    and num_pol_agrupada =  w_num_pol_agrupada ;

          END IF ;

    END IF ;

EXCEPTION
 WHEN OTHERS THEN NULL;

end SIM_TRG_AU_A2990700;
/
