CREATE OR REPLACE TRIGGER TRG_BI_EMI_ESTRUCT_ANEXO_HOGAR
BEFORE INSERT
ON EMI_ESTRUCT_ANEXO_HOGAR REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
  IF NVL(:NEW.VLR_CONTENIDOS,0) + NVL(:NEW.VLR_EDIF,0) > 600000000 THEN
      RAISE_APPLICATION_ERROR(-20600,'Los valores asegurados suman mas de 600 millones');
  END IF;

  IF NVL(:NEW.VLR_EDIF,0) > 0 AND NVL(:NEW.VLR_CONTENIDOS,0) * 0.3 > NVL(:NEW.VLR_EDIF,0) THEN
      RAISE_APPLICATION_ERROR(-20601,'El valor de contenidos supera el 30% del valor asegurado');
  END IF;

  IF NVL(:NEW.VLR_CONTENIDOS,0) + NVL(:NEW.VLR_EDIF,0)  = 0 THEN
      RAISE_APPLICATION_ERROR(-20602,'Es obligatorio ingresar uno de los valores del inmueble o contenidos');
  END IF;

  IF  NVL(:NEW.VLR_CONTENIDOS,0) > 70000000 AND NVL(:NEW.VLR_EDIF,0)  = 0 THEN
      RAISE_APPLICATION_ERROR(-20604,'El valor de contenidos no puede superar los 70 millones si no hay valor asegurado');
  END IF;

END;
/
