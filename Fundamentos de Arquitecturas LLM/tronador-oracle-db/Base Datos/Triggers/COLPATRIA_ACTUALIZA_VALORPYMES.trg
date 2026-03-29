CREATE OR REPLACE TRIGGER colpatria_actualiza_valorpymes
after insert or
      update of valor_asegurado
   on polizas_colpatria_mov
for each row
declare
  mensaje   varchar2(60);
  v_valor_apagar_bol       POLIZAS_COLPATRIA.VALOR_APAGAR_BOL%TYPE;
  v_valor_prima_coniva_bol POLIZAS_COLPATRIA.VALOR_PRIMA_CONIVA_BOL%TYPE;
  v_valor_prima_siniva_bol POLIZAS_COLPATRIA.VALOR_PRIMA_SINIVA_BOL%TYPE;
  v_valor_iva              POLIZAS_COLPATRIA.VALOR_IVA%TYPE;
  l_tasa_licitacion_coniva VARCHAR2(60); --Tasa licitación con Iva.
  l_tasa_licitacion_siniva VARCHAR2(60);
Begin

    BEGIN
          SELECT DAT_CAR2,DAT_CAR3
           INTO l_tasa_licitacion_coniva,l_tasa_licitacion_siniva
           FROM C9999909
           WHERE  COD_TAB  = 'TASA_GENERAL' -- FOR UPDATE
           AND  COD_CIA  = :new.cod_cia
           AND  COD_SECC = :new.cod_secc
           AND  COD_RAMO = :new.cod_producto;
       EXCEPTION
              WHEN OTHERS THEN
                PCK_COLPATRIA_VALIDACIONES.prc_Inserta_errores(:new.cod_cia,:new.cod_secc,:new.cod_producto,:new.tipo_identificacion,:new.numero_identificacion,
                :new.numero_producto,:new.tipo_poliza,:new.matricula_inmob_fact,:new.fecha_desembolso,
                :new.fecha_archivo,'F',14,'Error en Tasa de Licitación por Trigger:. ' || to_char(sqlcode,'999999')|| ' --->' || SUBSTR(SQLERRM,1,100));

                RAISE_APPLICATION_ERROR(14,'Error en Tasa de Licitación');

   END;

    ---SE REDONDEA A 2 POR SOLICITUD DE COLPATRIA
          v_valor_prima_coniva_bol := round((:new.valor_asegurado * to_number(l_tasa_licitacion_coniva))/1000,2);
          v_valor_prima_siniva_bol := round((:new.valor_asegurado * to_number(l_tasa_licitacion_siniva))/1000,2);
          v_valor_iva              := v_valor_prima_coniva_bol - v_valor_prima_siniva_bol;
          v_valor_apagar_bol       := v_valor_prima_siniva_bol + v_valor_iva;

    update polizas_colpatria p
       set p.valor_asegurado_pymes  = :new.valor_asegurado,
           p.valor_prima_coniva_bol = v_valor_prima_coniva_bol,
           p.valor_prima_siniva_bol = v_valor_prima_siniva_bol,
           p.valor_iva              = v_valor_iva,
           p.valor_apagar_bol       = v_valor_apagar_bol,
           p.imprime_doc1_estado    = 'S',
           p.fecha_modificacion     = SYSDATE
	 where p.cod_cia           = :new.cod_cia      and
          p.cod_secc          = :new.cod_secc     and
          p.cod_producto      = :new.cod_producto and
          p.numero_identificacion = :new.numero_identificacion and
          p.numero_producto       = :new.numero_producto       and
          p.matricula_inmobi      = :new.matricula_inmob_fact  and
          p.imprime_doc1_estado   = 'N' and
          valor_asegurado_pymes   = 0   and
          p.tipo_poliza  <> 'I&T';

/*dbms_output.put_line(:new.cod_cia || ',' || :new.cod_secc);
dbms_output.put_line(:new.cod_producto || ',' || :new.numero_identificacion);
dbms_output.put_line(:new.numero_producto || ',' || :new.matricula_inmobi);
dbms_output.put_line(:new.valor_asegurado);
dbms_output.put_line(sql%rowcount);  */

exception when others then
 mensaje := substr(sqlerrm,1,60);

 begin

        PCK_COLPATRIA_VALIDACIONES.prc_Inserta_errores(:new.cod_cia,:new.cod_secc,:new.cod_producto,:new.tipo_identificacion,:new.numero_identificacion,
        :new.numero_producto,:new.tipo_poliza,:new.matricula_inmob_fact,:new.fecha_desembolso,
        :new.fecha_archivo,'F',50,'Error Actualizacion Valor Pymes B6 para certificado:. ' || to_char(sqlcode,'999999')|| ' --->' || SUBSTR(SQLERRM,1,100));

		 insert into polizas_colpatria_auditoria
                  (COD_CIA,
                  COD_SECC              ,
                  COD_PRODUCTO          ,
                  TIPO_IDENTIFICACION   ,
                  NUMERO_IDENTIFICACION ,
                  NUMERO_PRODUCTO       ,
                  MATRICULA_INMOBI      ,
                  FECHA_DESEMBOLSO      ,
                  USUARIO               ,
                  TIPO_POLIZA           ,
                  TIPO_CARGUE           ,
                  FECHA_DIA             ,
                  DESCRIPCION_ERROR)
              values(
                  :new.cod_cia,
                  :new.cod_secc,
                  :new.cod_producto,
                  :new.tipo_identificacion,
                  :new.numero_identificacion,
                  :new.numero_producto,
                  :new.matricula_inmobi,
                  :new.fecha_desembolso,
                  user,
                  :new.tipo_poliza,
                  'Facturación',
                  sysdate,
                  mensaje

              );
 exception when others then null;
 end;
End colpatria_actualiza_valorpymes;
/
