CREATE OR REPLACE TRIGGER audit_emision
BEFORE DELETE ON A2990700 
FOR EACH ROW
BEGIN
 declare
 estado varchar2(1);
 begin
  begin
  select mca_Estado into estado from a2000163
  where  num_secu_pol = :old.num_Secu_pol and
         num_factura = :old.num_factura
  group by mca_estado;
 exception when no_data_found then estado := 'X';
 end;
 if ((to_char(:old.fecha_equipo ,'yyyymm') < to_char(sysdate ,'yyyymm') and
      estado != 'P')
    or  :old.cod_situacion != 'EP') then
    RAISE_APPLICATION_ERROR (-20501,'FACTURA RECAUDADA O MESES ANTERIORES');
 else
    declare
        factura number;
    begin
        select num_factura into factura from a5020301
        where cod_secc = :old.cod_secc and
              num_pol1 = :old.num_pol1 and
              num_factura = :old.num_factura and num_cuota = :old.num_cuota;
         exception when no_data_found then goto fin;
                   when too_many_rows then null;
    end;
    RAISE_APPLICATION_ERROR (-20501,'FACTURA EN A5020301');
    <<fin>>
    declare
        factura number;
    begin
        select num_factura into factura from a5021600
        where cod_secc = :old.cod_secc and
              num_pol1 = :old.num_pol1 and
              num_factura = :old.num_factura;
         exception when no_data_found then goto fin1;
                   when too_many_rows then null;
    end;
    RAISE_APPLICATION_ERROR (-20501,'FACTURA EN A5021600');
    <<fin1>>
     insert into audit_emision
     values (:old.num_pol1,:old.cod_situacion,:old.num_secu_pol,
             :old.num_end,:old.num_factura,user,sysdate,:old.fecha_equipo);
 END IF;
 end;
END;
/
