CREATE OR REPLACE TRIGGER SIM_TRG_SIM_NOV_AGENTES
  before insert OR DELETE on Sim_Novedades_Agentes
  for each row
declare
  l_NumPol1     NUMBER;
  l_CodSecc     NUMBER;
  l_CodRamo     NUMBER;
  l_fechaVigpol DATE;
  l_CodUsr      VARCHAR2(20);
  l_Porcentaje  NUMBER;
  l_Codagencia  NUMBER;

BEGIN

  IF inserting  THEN
     SELECT usuario, porc_pactado
      INTO l_CodUsr, l_Porcentaje
     FROM sim_novedades_modificaciones f
     WHERE num_secu_pol = :new.num_secu_pol;
     l_CodUsr := sim_pck_seguridad.usuarioTronador(l_CodUsr);

     SELECT cod_secc, cod_ramo, num_pol1, fecha_vig_pol, substr(num_pol1,1,4)
      INTO l_CodSecc, l_CodRamo, l_Numpol1, l_fechaVigpol,l_codAgencia
     FROM a2000030 a
     WHERE num_Secu_pol = :new.Num_Secu_Pol
     AND num_end = (SELECT MAX(num_end) FROM a2000030
                     WHERE num_secu_pol = a.num_secu_pol);

/*    UPDATE a2000254
    SET fecha_baja = trunc(SYSDATE)
   WHERE num_secu_pol = :new.num_secu_pol
     AND fecha_baja IS NULL;*/

/*     SELECT a1702_cod_agencia
      into l_codAgencia
      FROM intermediarios
     WHERE clave = :new.cod_prod;*/
     INSERT INTO a2000254
     (COD_SECC,COD_RAMO, NUM_POL1, COD_PROD, COD_AGENCIA, FECHA_VIG_POL,
      FECHA_VIG, FECHA_BAJA, COD_USR, PORC_PART, LIDER, NUM_SECU_POL,PORC_COMI)
      VALUES (l_CodSecc, l_codramo, l_NumPol1, :new.cod_prod, l_CodAgencia,
              l_FechaVigpol, trunc(SYSDATE),NULL, l_codUsr, :new.Porc_Part,
              :new.Lider, :new.Num_Secu_Pol, l_Porcentaje);
/* ELSE
   UPDATE a2000254
    SET fecha_baja = trunc(SYSDATE)
   WHERE num_secu_pol = :new.num_secu_pol
     AND fecha_baja IS NULL
     AND cod_prod = :new.Cod_Prod;
*/END IF;

EXCEPTION WHEN OTHERS THEN NULL;
   sim_proc_log('Error CC ',substr(SQLERRM,1,400));
END;
/
