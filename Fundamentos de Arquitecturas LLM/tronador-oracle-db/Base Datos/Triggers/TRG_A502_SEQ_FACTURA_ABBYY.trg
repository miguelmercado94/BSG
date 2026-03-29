CREATE OR REPLACE TRIGGER TRG_A502_SEQ_FACTURA_ABBYY

    before insert on "ABBYY"."A502_FACTURA_ABBYY" for each row
begin

    if :new.secuencia is null then

select SEQ_A502_FACTURA_ABBYY.NextVal

        into   :new.secuencia

        from   Dual;

    end if;

end TRG_A502_SEQ_FACTURA_ABBYY;
/
