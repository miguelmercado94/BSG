CREATE OR REPLACE TRIGGER a5021103_CTA0
before
     insert or update  ON A5021103      for each row
begin
 if :new.estado = 1 then
      if :new.numero_cta_destino = 0   then
           raise_application_error(
          -20500, 'Cuenta Bancaria en CERO  ');
      end if;
         if :new.tdoc_tercero is null then
              raise_application_error(
          -20600, 'digite un tipo de documento  ');
      end if;
 end if;
end;
/
