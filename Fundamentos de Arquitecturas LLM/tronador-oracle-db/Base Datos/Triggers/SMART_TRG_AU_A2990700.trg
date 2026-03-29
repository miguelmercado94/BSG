CREATE OR REPLACE TRIGGER SMART_TRG_AU_A2990700

  AFTER UPDATE OF COD_SITUACION ON A2990700
  FOR EACH ROW
  WHEN (NEW.COD_SITUACION= 'CT' AND NEW.NUM_END = 0)

 -- ajuste trigger
DECLARE

  IP_NUMSECUPOL A2000030.num_secu_pol%type;
  IP_NUMEND     A2000030.num_end%type;

  V_VALIDA NUMBER;

  V_Coderr C1991300.Cod_Error%type;
  V_MsgErr C1991300.MSG_ERROR%type;
  w_raise_error exception;

BEGIN


  IP_NUMSECUPOL := :OLD.NUM_SECU_POL;
  IP_NUMEND     := :OLD.NUM_END;

  IF IP_NUMEND = 0 THEN
    SELECT COUNT(1)
      INTO V_VALIDA
      FROM A2000030 A, A2000020 B, A2000060 C
     WHERE A.NUM_SECU_POL = IP_NUMSECUPOL
       AND A.NUM_SECU_POL = B.NUM_SECU_POL
       AND A.NUM_SECU_POL = C.NUM_SECU_POL
       AND SUBSTR(A.NUM_POL1, 12, 2) = '01'
       AND B.COD_CAMPO = 'TIPOFCOBRO1FRA'
       AND B.VALOR_CAMPO = 'CO'
       AND A.FOR_COBRO   = 'CC'
       AND A.NUM_END = 0
       AND A.NUM_POL_ANT IS NULL;

    IF V_VALIDA > 0 AND :NEW.COD_SITUACION = 'CT' THEN

      BEGIN
        Begin
          Update A2000030 j
             Set j.for_cobro = 'DB'
           Where j.num_secu_pol = Ip_numsecupol
             and j.num_end = Ip_numend;
        Exception
          when others then
            null;
        End;
        Begin
          Update A2000020 k
             set k.valor_campo = 'DC'
           Where k.num_secu_pol = Ip_numsecupol
             and k.num_end = Ip_numend
             and k.cod_campo = 'TIPOFCOBRO1FRA';
        Exception
          when others then
            null;
        End;

      EXCEPTION

        WHEN OTHERS THEN
          v_msgerr := ' Error llamando Trigger Update A2000030 sqlcode --> ' ||
                      sqlcode || '   sqlerrm --> ' || sqlerrm;
          RAISE_APPLICATION_ERROR(-20530, v_msgerr);

      END;

    END IF;
  END IF;
EXCEPTION

  WHEN NO_DATA_FOUND THEN
    NULL;

  WHEN OTHERS THEN
    v_Coderr := sqlcode;
    v_msgerr := substr('Error en trigger SMART_TRG_AU_A2990700 numsecupol : ' || to_char(:NEW.num_secu_pol) ||
                       v_msgerr || sqlerrm,
                       1,
                       2000);
    RAISE_APPLICATION_ERROR(-20530, v_msgerr);

END SMART_TRG_AU_A2990700;
/