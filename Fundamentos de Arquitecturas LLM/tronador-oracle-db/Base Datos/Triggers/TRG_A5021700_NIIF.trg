CREATE OR REPLACE TRIGGER TRG_A5021700_NIIF
before UPDATE  ON A5021700
FOR EACH ROW
DECLARE

BEGIN
if     :OLD.cod_cia in  (1,2,3,7) then
    IF ( nvl(:old.MCA_ESTADO,'Y') <> nvl(:new.MCA_ESTADO,'M')   or
       nvl(:old.MCA_BATCH,'Y')  <> nvl(:new.MCA_BATCH,'M')   or
       nvl(:old.MCA_cierre,'Y') <> nvl(:new.MCA_cierre,'M' ))  and
       :old.cod_cia    = :new.cod_cia     and
       :new.MCA_ESTADO = 'C'              and
       :new.MCA_BATCH  = 'S'              and
       :new.MCA_CIERRE = 'S'              then
         if     :OLD.cod_cia = 7  then
             update iasfic
               set ias220_cempres = 69
              where  ias220_cempres =  :new.cod_cia
              and    ias220_cclaasi = 'TES';
            else
             update iasfic
             set ias220_cempres = ias220_cempres + 80
             where  ias220_cempres =  :new.cod_cia
             and    ias220_cclaasi = 'TES';
         end if;
    END IF;
END IF;

END;
/
