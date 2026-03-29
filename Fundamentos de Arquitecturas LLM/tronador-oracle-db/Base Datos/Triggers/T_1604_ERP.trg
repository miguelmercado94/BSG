CREATE OR REPLACE TRIGGER t_1604_ERP
before
update ON A5021604 for each row
declare
--  cantidad       number             :=0;
ESTADO           varchar(3)            := null;
tipo_doc         varchar(2)            := null;
banco_cliente    varchar (6)           := null;
cuenta_cliente   varchar(15)           := null;
numero_cheque    varchar2(8)        := null;
nuevo_cheque     varchar2(8)        := null;
mensaje          varchar2(2000)     := null;
fecha            date               := sysdate;
cheque_ant      varchar2(08)        := null;
begin
   if :old.mca_tipo_ord = 'C' and (:old.sub_tipo_ord in ('L', 'W')) then

       if nvl(:new.for_pago,9) in ( 1,6) then
          tipo_doc := 'TR';
          else
            if   :old.num_cheque is not null or  nvl(:new.for_pago,9) = 5 then
               tipo_doc := 'CH';
             else
                tipo_doc  := 'OG';
            end if;
       end if;
       begin
         if nvl(:old.mca_est_pago,'X') <> :new.mca_est_pago then
             if nvl(:new.mca_est_pago,'X') = 'A' and :old.cod_banco is null then
                estado := 'AN';
              elsif  nvl(:new.mca_est_pago,'X') = 'A' and :old.cod_banco is not null then
                  estado := 'ANS';
                  numero_cheque := :old.num_cheque;
                  nuevo_cheque :=  :new.num_cheque ;
                 elsif  :new.mca_est_pago = 'Y' then
                    estado := 'ANS';
                  numero_cheque := :old.num_cheque;
                  nuevo_cheque :=  :new.num_cheque ;

              elsif nvl(:new.mca_est_pago,'X') = 'T' then
                 if nvl(:new.for_pago,9) = 1 then
                     estado := 'TRS';
                     begin
                      select numero_cta_destino,cod_entidad_destino
                        into cuenta_cliente,banco_cliente
                       from a5021104 where cod_cia = :old.cod_cia
                             and num_ord_pago = :old.num_ord_pago;
                     exception
                          when  others then
                             escribir_log_errores(SEQ_LOGS.NextVal,
                           'TESO_ERP',
                          sysdate,
                           null,
                           'error a5021104' ||
                           ' compania: '  ||  :old.cod_cia
                           || 'orden pago' || :old.num_ord_pago
                          ||
                           'mensa' || sqlerrm );
                     end;
                       numero_cheque := :new.num_cheque;
                  elsif nvl(:new.for_pago,9) = 6 then
                   estado := 'TRS';
                   begin
                         select numero_cta_destino,cod_entidad_destino
                        into cuenta_cliente,banco_cliente
                       from a5021103 a,a5021604 b
                       where  a.numero_documento  = b.cod_benef
                           and a.tdoc_tercero = b.tdoc_tercero
                           and cod_cia = :old.cod_cia
                             and num_ord_pago = :old.num_ord_pago;
                       exception
                          when  others then
                             escribir_log_errores(SEQ_LOGS.NextVal,
                           'TESO_ERP',
                          sysdate,
                           null,
                           'error a5021104' ||
                           ' compania: '  ||  :old.cod_cia
                           || 'orden pago' || :old.num_ord_pago
                          ||
                           'mensa' || sqlerrm );
                     end;
                           numero_cheque := 1;
                  else
                    if :old.cod_banco  is not null and
                        :new.cod_banco is not null and
                        :old.mca_est_pago is null
                      -- :old.num_cheque <> :new.num_cheque
                       and :new.mca_est_pago = 'T'
                       and :new.num_cheque  is not null then
                       begin
                          select max(num_cheque)
                            into cheque_ant
                          from a5010031
                          where clave = :old.clave
                          and  num_cheque < :new.num_cheque
                          and cod_concilia = 'CA' ;
                        end;
                        if cheque_ant is not null then
                       estado := 'ANR';
                       numero_cheque :=   :new.num_cheque ;
                       nuevo_cheque  :=   cheque_ant;
                       else
                         estado := 'CHS';
                         numero_cheque := :new.num_cheque;
                     end if;
                  else
                     estado := 'CHS';
                     numero_cheque := :new.num_cheque;
                   end if;
                    end if;
               end if;
           elsif nvl(:old.causal_rechazo,0) <> nvl(:new.causal_rechazo,0)
                  and :new.causal_rechazo is not null then
                  estado := 'TRR';
         /* elsif :old.num_cheque <> :new.num_cheque
                  and :new.mca_est_pago = 'T'
                  and :new.num_cheque  is not null then
                  estado := 'ANR';
                  numero_cheque := :old.num_cheque;
                  nuevo_cheque :=  :new.num_cheque ;*/

           end if;

         begin
         pk_int_teso_people.estado_tesoreria( :old.num_ord_pago,
                                              :old.sub_tipo_ord,   /*JAPP 11/09/2014*/
                                              :old.cod_cia,
                                              tipo_doc,
                                              estado,
                                              numero_cheque,
                                              nuevo_cheque,
                                              banco_cliente,
                                              cuenta_cliente,
                                              fecha,
                                              mensaje);

            EXCEPTION WHEN OTHERS THEN
              escribir_log_errores(SEQ_LOGS.NextVal,
                           'TESO_ERP',
                          sysdate,
                           null,
                           'error llamado  pk_int_teso_people' ||
                           ' orden: '  ||  :old.num_ord_pago
                           || 'compania' || :old.cod_cia ||
                           'tipodoc' ||  tipo_doc || 'estado' || estado
                          || 'numero cheque' || numero_cheque ||
                           'chequereemp' || nuevo_cheque || 'banco' ||
                           banco_cliente || 'cuentacli' || cuenta_cliente ||
                           'mensajeerror' || sqlerrm );
            begin
          --NOTA CAMPO ESTADO_ERP TABLA tesoreria intefaz_erp  debe ser  actualizado unicamente por people
           insert into intefaz_erp values   ( :old.num_ord_pago,
                                                :old.cod_cia,
                                                tipo_doc,
                                                 estado,
                                                 numero_cheque,
                                                 nuevo_cheque,
                                                 banco_cliente,
                                                 cuenta_cliente,
                                                 fecha,
                                                 mensaje,
                                                 null);

         EXCEPTION WHEN OTHERS THEN
                     escribir_log_errores(SEQ_LOGS.NextVal,
                           'TESO_ERP',
                          sysdate,
                           null,
                           'error insertar tabla intefaz_erp' ||
                           ' orden: '  ||  :old.num_ord_pago
                           || 'compania' || :old.cod_cia ||
                           'tipodoc' ||  tipo_doc || 'estado' || estado
                          || 'numero cheque' || numero_cheque ||
                           'chequereemp' || nuevo_cheque || 'banco' ||
                           banco_cliente || 'cuentacli' || cuenta_cliente ||
                           'mensajeerror' || sqlerrm );
         end;
         end;

        end;
   end if;
  end;
/
