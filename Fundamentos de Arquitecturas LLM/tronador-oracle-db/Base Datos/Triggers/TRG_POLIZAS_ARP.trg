CREATE OR REPLACE TRIGGER Trg_Polizas_Arp
    AFTER DELETE OR
          INSERT OR
          UPDATE OF Num_Pol1, Mca_Provisorio, Fecha_Vig_Pol, Fecha_Vig_End, Fecha_Venc_Pol,
                    Fecha_Venc_End, Num_Pol_Ant, Num_Secu_Pol, Nro_Documto, Renovada_Por,
                    Num_End, Cod_End, Sub_Cod_End, Tipo_End, Tdoc_Tercero
    ON A2000030 
    REFERENCING NEW AS New OLD AS Old
    FOR EACH ROW
WHEN (
(New.Cod_Cia = 2
       AND New.Cod_Secc = 70)
       OR (Old.Cod_Cia = 2
       AND Old.Cod_Secc = 70)
      )
DECLARE

      v_procesar_act  VARCHAR2(20) := NULL;

BEGIN
    IF INSERTING
    THEN
        BEGIN
            /********************************************************************************************************************************************************/
            /* ENGINEER : WILSON FERNANDO LOPEZ COLMENARES                               DATE CREATED: 07/02/2014  MNTS:000000  SEQUENCE REQUIREMENT :SRS00952      */
            /* DESCRIPTION :1.CREA TERCERO DELEGADO                                      DATE MODIFIC: 14/05/2014  MNTS:260004  SEQUENCE REQUIREMENT :SRTO0021      */
            /*              1.SE DESHABILITA PROCEDIMIENTO HASTA EFECTUAR AJUSTES TRNDOR DATE MODIFIC: 27/05/2014  MNTS:000000  SEQUENCE REQUIREMENT :SRTO0000      */
            /*              1.SE ADICIONA LA TABLA C2700007                              DATE MODIFIC: 14/07/2014  MNTS:000000  SEQUENCE REQUIREMENT :SRTO0144      */
            /*              1.SE ADICIONA EN LA TABLA C2700007 COD_END Y SUB_COD_END     DATE MODIFIC: 27/07/2014  MNTS:027252  SEQUENCE REQUIREMENT :Srto[154-2014]*/
            /********************************************************************************************************************************************************/

            INSERT INTO C2700007 (Dlgt_Tipo_Doc_Empresa, Dlgt_Numero_Doc_Empresa, Dlgt_Num_Secu_Pol, Dlgt_Cod_End, Dlgt_Sub_Cod_End,
                                  Aud_Fecha_Creacion, Aud_Usuario_Creacion, Aud_Operacion, Dlgt_Num_Pol_Cli)
                 VALUES (:new.Tdoc_Tercero, :new.Nro_Documto, :new.Num_Secu_Pol, :new.Cod_End, :new.Sub_Cod_End, SYSDATE, USER, 'PENDIENTE', :new.num_pol_cli);
        END;

        BEGIN
            BEGIN
                /********************************************************************************************************************************************************/
                /* ENGINEER : WILSON FERNANDO LOPEZ COLMENARES                               DATE CREATED: 03/08/2020  IOPM[001-2020-584][ARL][SAT]MntsNo[82764]        */
                /* DESCRIPTION :1.CREA EL REGISTRO PARA PROCESAR LA EMPRESA Y ENVIARLA POSTERIOR A MINSALUD                                                             */
                /********************************************************************************************************************************************************/
                
                IF (:new.Cod_End = 2 AND :new.Sub_Cod_End = 0) THEN
                   
                   v_procesar_act := Arl_Sat_Online_Pck_Utility.Diferencia_Act_Econo(:new.Num_Secu_Pol);
                               
                END IF;
                
                IF (NVL(:new.Mca_Provisorio, 'N') = 'N') THEN
                
                INSERT INTO Sim_Arl_Sat_Empresas A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Num_Secu_Pol,
                                                    A.Tdoc_Tercero, A.Nro_Documto, A.Num_End, A.Cod_End, A.Sub_Cod_End,
                                                    A.Tipo_End, A.Fecha_Emi_End, A.Fecha_Vig_Pol, A.Fecha_Vig_End, A.Fecha_Venc_Pol,
                                                    A.Fecha_Venc_End, A.Num_Pol_Ant, A.Renovada_Por, A.Fecha_Creacion, A.Estado, A.Tipo_Movimiento)
                         VALUES (:new.Cod_Cia, :new.Cod_Secc, :new.Cod_Ramo, :new.Num_Pol1, :new.Num_Secu_Pol, :new.Tdoc_Tercero, :new.Nro_Documto, :new.Num_End, :new.Cod_End, :new.Sub_Cod_End, :new.Tipo_End,
                             :new.Fecha_Emi_End, :new.Fecha_Vig_Pol, :new.Fecha_Vig_End, :new.Fecha_Venc_Pol, :new.Fecha_Venc_End, :new.Num_Pol_Ant, :new.Renovada_Por, :new.Fecha_Creacion,
                             'PENDIENTE', v_procesar_act);
                             
                END IF;
            END;
        END;
    END IF;
    
    -- Se inserta la novedad solo cuando el control técnico ha sido aprobado.
    IF UPDATING ('Mca_Provisorio') THEN
      
      IF (NVL(:new.Mca_Provisorio, 'N') = 'N' AND NVL(:old.Mca_Provisorio, 'N') = 'S') THEN
                    
          INSERT INTO Sim_Arl_Sat_Empresas A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Num_Secu_Pol,
                                              A.Tdoc_Tercero, A.Nro_Documto, A.Num_End, A.Cod_End, A.Sub_Cod_End,
                                              A.Tipo_End, A.Fecha_Emi_End, A.Fecha_Vig_Pol, A.Fecha_Vig_End, A.Fecha_Venc_Pol,
                                              A.Fecha_Venc_End, A.Num_Pol_Ant, A.Renovada_Por, A.Fecha_Creacion, A.Estado, A.Tipo_Movimiento)
          VALUES (:new.Cod_Cia, :new.Cod_Secc, :new.Cod_Ramo, :new.Num_Pol1, :new.Num_Secu_Pol, :new.Tdoc_Tercero, :new.Nro_Documto, :new.Num_End, :new.Cod_End, :new.Sub_Cod_End, :new.Tipo_End,
                   :new.Fecha_Emi_End, :new.Fecha_Vig_Pol, :new.Fecha_Vig_End, :new.Fecha_Venc_Pol, :new.Fecha_Venc_End, :new.Num_Pol_Ant, :new.Renovada_Por, :new.Fecha_Creacion,
                   'PENDIENTE', v_procesar_act);
               
      END IF;
        
    END IF;
    
    -- Se captura el dato de Fecha_Vig_Pol y Fecha_Emi_End en novedades de cancelación.  
    IF UPDATING ('Fecha_Vig_End')
    THEN
      
      BEGIN
      
        IF (:old.Fecha_Vig_End IS NULL) THEN
          
          UPDATE Sim_Arl_Sat_Empresas A
          SET A.Fecha_Vig_End = :new.Fecha_Vig_End, A.Fecha_Emi_End = :new.Fecha_Emi_End 
          WHERE A.Num_Pol1 = :old.Num_Pol1
          AND A.Fecha_Creacion = :old.Fecha_Creacion
          AND A.Num_End = :old.Num_End;
          
        END IF;
        
      END;
      
    END IF;
    
END Trg_Polizas_Arp;
/
