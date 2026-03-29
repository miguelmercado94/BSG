CREATE OR REPLACE TRIGGER audit_recaudos
BEFORE INSERT ON ops$puma.a5020301 FOR EACH ROW
DECLARE
    numpol1    number(13);
    anualidad  number(2);
BEGIN
   anualidad := to_number(substr(lpad(to_char(:new.num_pol1),13,'0'),12,2));
   if anualidad > 1 and :new.num_factura = 1 then
      numpol1 := :new.num_pol1 - 1;
      update c2990008
      set recaudada = 'S'
      where cod_secc = :new.cod_secc and
            num_pol1 = numpol1 ;
      if sql%notfound then
         update c2990008
         set recaudada = 'S'
         where cod_secc_renov = :new.cod_secc and
               renovada_por = :new.num_pol1 ;
      end if;
   end if;
exception when others then null;
END;
/
