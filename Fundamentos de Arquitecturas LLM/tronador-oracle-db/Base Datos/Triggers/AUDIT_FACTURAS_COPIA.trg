CREATE OR REPLACE TRIGGER "AUDIT_FACTURAS_COPIA" BEFORE
DELETE ON A2000163 FOR EACH ROW
BEGIN
DECLARE
    codprod  number(5);
    agencia  number(5);
    poliza   number(13);
    forcobro varchar2(2);
BEGIN
    select cod_prod, num_pol1, cod_cobro
    into codprod, poliza, forcobro
    from a2990700
    where num_secu_pol = :old.num_secu_pol and
         num_factura   = :old.num_factura
    group by cod_prod, num_pol1, cod_cobro;
    select cod_agencia into agencia from a1001301
    where cod_prod = codprod and
          fecha_equipo = (select max(fecha_equipo) from a1001301
                          where cod_prod = codprod);
    insert into audit_facturas
    values (agencia, codprod,:old.num_Secu_pol,poliza,
            :old.num_factura, :old.num_end_ref, :old.cod_agrup_cont,
            :old.imp_prima,user, sysdate,:old.fecha_equipo,
            :old.fecha_emi, forcobro, :old.cod_ciacoa, :old.tipo_reg);
  exception when no_data_found then
      null;
end;
END;
/
