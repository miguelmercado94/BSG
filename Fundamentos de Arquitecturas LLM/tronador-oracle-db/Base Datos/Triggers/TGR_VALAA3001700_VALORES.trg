CREATE OR REPLACE TRIGGER tgr_valaa3001700_valores
  FOR INSERT OR UPDATE ON a3001700
COMPOUND TRIGGER
/* Objetivo: Validar que no exista mas de una liquidacion con la misma orden de pago
  Solucion mantis 84809*/
  v_cuenta    NUMBER;
  v_numordern NUMBER;
  v_cod_cia   NUMBER;
  v_valida    NUMBER(2);
  AFTER EACH ROW IS
  BEGIN
    v_numordern := :new.num_ord_pago;
    v_cod_cia   := :new.cod_cia;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    BEGIN
    
      BEGIN
        SELECT c.codigo
          INTO v_valida
          FROM c9999909 c
         WHERE c.cod_tab = 'VALIDA_DUP_A3001700';
      EXCEPTION
        WHEN no_data_found THEN
          v_valida := 1;
      END;
    
      IF v_valida = 1 AND v_numordern IS NOT NULL AND v_cod_cia IS NOT NULL AND
         v_numordern > 0 THEN
        SELECT COUNT(*)
          INTO v_cuenta
          FROM a3001700 a
         WHERE a.num_ord_pago = v_numordern AND
               a.cod_cia = v_cod_cia
         GROUP BY a.num_ord_pago;
      
        IF v_cuenta > 1 THEN
          raise_application_error(-20000,
                                  'La orden de pago ya existe ' || v_numordern || ' - ' ||
                                  v_cuenta);
        END IF;
      
        SELECT COUNT(*)
          INTO v_cuenta
          FROM a5021604 a
         WHERE a.cod_cia = v_cod_cia AND
               a.num_ord_pago = v_numordern;
      
        IF v_cuenta > 1 THEN
          raise_application_error(-20000, 'Esta liquidacion ya fue pagada');
        END IF;
      END IF;
    END;
  
  END AFTER STATEMENT;

END tgr_valaa3001700_valores;
/
