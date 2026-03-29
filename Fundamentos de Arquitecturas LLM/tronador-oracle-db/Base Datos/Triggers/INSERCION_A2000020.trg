CREATE OR REPLACE TRIGGER "INSERCION_A2000020" BEFORE UPDATE OR INSERT OR DELETE OF "COD_RIES", "VALOR_CAMPO", "MCA_BAJA_RIES", "MCA_VIGENTE" ON "A2000020" FOR EACH ROW
WHEN (
new.cod_campo = 'DESC_RIES' or
       new.cod_campo = 'COD_BENEF' or
       new.cod_campo = 'COD_BENE' or
       new.cod_campo = 'SEXO' or
       new.cod_campo = 'FECHA_NACIMIEN' or
       new.cod_campo = 'FECHA_NACIMIENTO' or
       new.cod_campo = 'ASEG_TOMADOR' or
       new.cod_campo = 'CODIGO_NUI' or
       new.cod_campo = 'FEC_INGRESO' or
       new.cod_campo = 'OPCION_POLIZA' or
       new.cod_campo = 'COD_ASEG1' or
       new.cod_campo = 'COD_ASEG' or
       new.cod_campo = 'FECHA_NCMNTO' or
       new.cod_campo = 'SEXO_BONA' or
       new.cod_campo = 'COD_DOCUM' or
       new.cod_campo = 'OPCION_ASEG' or
       new.cod_campo = 'FECHA_ORIGEN' Or
       new.cod_campo = 'NRO_OPTIKA'
      )
declare
-------------------------------------------------------------------------------
-- Objetivo : insertar en la tabla cambios_tronador de sisalud para actualizar
--            la informacion en el sistema de informacion de SISALUD
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : Febrero 22 del 2000
-- Modificado : diciembre 19 del 2000 modificado para insertar los cambios que
--            se realicen en el producto de accidentes escolares
-------------------------------------------------------------------------------
  mensaje   varchar2(60);
  pol1 number(15);
  secc number(3);
Begin
 begin
    SELECT MAX(num_pol1)
          ,cod_secc
      INTO pol1
          ,secc
      FROM a2000030
     WHERE num_secu_pol = :new.num_secu_pol
       AND cod_secc     in (34,26)
       AND cod_cia      = 2
       AND cod_ramo   not in (80,739)
     GROUP BY cod_secc;

      EXCEPTION WHEN OTHERS THEN
        pol1 := 0;
        secc := 0;
  END;
  
  IF deleting Then
   
  BEGIN
     DELETE sim_tmp_asegurados
      WHERE num_secu_pol = :old.Num_Secu_Pol
        AND num_end      = :old.num_end
        AND cod_ries     = :old.cod_ries
       AND cod_campo     = :old.cod_campo;

  END;
  
   BEGIN
    DELETE cambios_tronador
     WHERE num_secu_pol = :old.num_secu_pol
       AND num_end      = :old.num_end
       AND cod_ries     = :old.cod_ries
       AND cod_campo    = :old.cod_campo;
   END;


  ELSE
--    IF inserting AND :new.cod_campo = 'COD_ASEG1'  THEN
     IF inserting THEN
        IF  (secc = 34 AND :new.cod_campo = 'COD_BENE')
         OR (secc != 34 AND :new.cod_campo = 'COD_ASEG1')
         OR (:new.cod_campo = 'CODIGO_NUI' And secc In (34,26)) 
         Or (:new.cod_campo = 'NRO_OPTIKA' And secc In (34,26)) THEN
           BEGIN
              UPDATE sim_tmp_asegurados
                 SET mca_vigente = 'N'
               WHERE num_secu_pol = :new.Num_Secu_Pol
                 AND cod_ries   = :new.cod_ries
                 And cod_campo = :new.cod_campo;
            END;

            BEGIN
              INSERT INTO sim_tmp_asegurados(num_secu_pol,num_end,cod_ries,cod_campo,valor_campo,mca_vigente)
                   VALUES (:new.Num_Secu_Pol,:new.Num_End,:new.cod_ries,:new.Cod_Campo,:new.Valor_Campo,:new.Mca_Vigente);
            END;
        END IF;
    if nvl(pol1,0) > 0  then
      begin
        insert into cambios_tronador(num_secu_pol
                                    ,num_pol1
                                    ,num_end
                                    ,cod_ries
                                    ,cod_campo
                                    ,valor_campo
                                    ,mca_baja_ries
                                    ,mca_vigente
                                    )
                              values(:new.num_secu_pol
                                    ,pol1
                                    ,:new.num_end
                                    ,:new.cod_ries
                                    ,:new.cod_campo
                                    ,:new.valor_campo
                                    ,:new.mca_baja_ries
                                    ,:new.mca_vigente
                                    );
        exception when others then
          mensaje := substr(sqlerrm,1,60);
          begin
            insert into inconsistencias_sisalud(num_secu_pol
                                               ,num_end
                                               ,cod_ries
                                               ,cod_campo
                                               ,valor_campo
                                               ,mca_baja_ries
                                               ,mca_vigente
                                               ,error
                                               ,tabla
                                               )
                                         values(:new.num_secu_pol
                                               ,:new.num_end
                                               ,:new.cod_ries
                                               ,:new.cod_campo
                                               ,:new.valor_campo
                                               ,:new.mca_baja_ries
                                               ,:new.mca_vigente
                                               ,mensaje
                                               ,'A2000020'
                                               );
            exception when others then null;
          end;
        /* aqui acaba el primer exception */
      end;
    end if;
  ELSIF updating  AND ((secc = 34 AND :new.cod_campo = 'COD_BENE')
         OR (secc != 34 AND :new.cod_campo = 'COD_ASEG1')
         OR (:new.cod_campo = 'CODIGO_NUI' And secc In (34,26))
         Or (:new.cod_campo = 'NRO_OPTIKA' And secc In (34,26)))
         AND :new.valor_campo != :old.Valor_Campo THEN
           BEGIN
              UPDATE sim_tmp_asegurados
                 SET mca_vigente = 'N'
               WHERE num_secu_pol = :new.Num_Secu_Pol
                 AND cod_ries   = :new.cod_ries
                 And cod_campo = :new.cod_campo;
            END;

            BEGIN
              INSERT INTO sim_tmp_asegurados(num_secu_pol,num_end,cod_ries,cod_campo,valor_campo,mca_vigente/*,cod_nui*/)
                   VALUES (:new.Num_Secu_Pol,:new.Num_End,:new.cod_ries,:new.Cod_Campo,:new.Valor_Campo,:new.Mca_Vigente/*,codnui*/);
            END;
 END IF;
END IF;
End insercion_a2000020;
/
