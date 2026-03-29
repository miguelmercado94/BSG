CREATE OR REPLACE TRIGGER "TRG_NUM_POL_CLI_COT"
  BEFORE INSERT OR UPDATE OF "NUM_POL1", "MCA_PROVISORIO" ON "OPS$PUMA"."SIM_COTIZACION_ENDOSO"
  FOR EACH ROW
BEGIN
  DECLARE
    L_CONTA NUMBER;
    --l_resultado  NUMBER;
    /*
      <Comment>
       <Modifica>
       <Autor></Autor>
       <Fecha></Fecha>
       <Control>2</Control>
       <Objetivo>valida que no exist n datos en la tabla a2000163 para cambiar el numero de la poliza
       </Objetivo>
      </Modifica>
    </Comment>
      */
      -- RPR 03/08/2022  Nuevo Manejo de fecha equipo
      l_Anualidad number;
      l_FechaFact date;
  BEGIN
    :NEW.MCA_PROVISORIO := NVL(:NEW.MCA_PROVISORIO, 'N');
    IF :NEW.NUM_POL1 IS NOT NULL AND :NEW.NUM_END = 0 THEN
      :NEW.MCA_DATOS_MIN := 'N';
    END IF;
    IF INSERTING THEN
      :NEW.MCA_ADM_PROD := NULL;
      IF NVL(:NEW.MCA_PROVISORIO, 'N') = 'N' THEN
        IF :NEW.NUM_POL1 IS NOT NULL THEN
          :NEW.NUM_POL_CLI := SUBSTR(:NEW.NUM_POL1, 5, 7);
        ELSE
          :NEW.NUM_POL_CLI := SUBSTR(:NEW.NUM_POL_COTIZ, 5, 7);
        END IF;
      ELSE
        IF :NEW.NUM_END > 0 OR
           (:NEW.NUM_POL1 IS NOT NULL AND SUBSTR(:NEW.NUM_POL1, 12, 2) > 1 AND
           NVL(:NEW.NUM_POL_ANT, 0) != 0) THEN
          :NEW.NUM_POL_CLI := SUBSTR(:NEW.NUM_POL1, 5, 7);
        END IF;
      END IF;
      /* Se elimina condicion  de fecha equipo RPR 03/08/2022
        IF :NEW.COD_SECC = 310 OR :NEW.NUM_END <> 0 Then
       If trunc(Sysdate) <= :new.fecha_vig_end And :new.num_end > 0 Then
          If :new.cod_end = 900 And :new.sub_cod_end = 0 Then
             :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
          Else
            :new.fecha_equipo := :new.fecha_vig_end;
          End If;
       Else
         
        :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
        --sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 4 Queda sysdate ',:new.Fecha_Equipo);
       End If;
      --  :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
      END IF;
      --sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 2',:new.Fecha_Equipo);
     */ 
    ELSE
      IF :OLD.NUM_END = 0 THEN
        /*
          select count(*) into conta from a2000163
          where num_secu_pol= :old.num_secu_pol;
        */
        SELECT L_CONTA + COUNT(*)
          INTO L_CONTA
          FROM A2990700
         WHERE NUM_SECU_POL = :OLD.NUM_SECU_POL
           AND NUM_POL1 = :OLD.NUM_POL1
           AND :OLD.NUM_POL1 != :NEW.NUM_POL1;
        IF L_CONTA > 0 THEN
          RAISE_APPLICATION_ERROR(-20000, 'Error Numero de poliza');
        END IF;

      END IF;
      --sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 5 ',:new.Fecha_Equipo);
     
      IF :NEW.MCA_PROVISORIO = 'S' AND :NEW.NUM_END = 0 AND
         (SUBSTR(:NEW.NUM_POL1, 12, 2) = 1 OR (SUBSTR(:NEW.NUM_POL1, 12, 2) > 1 AND
         NVL(:NEW.NUM_POL_ANT, 0) = 0)) THEN

        SELECT COUNT(*)
          INTO L_CONTA
          FROM A2990601
         WHERE COD_CIA = :NEW.COD_CIA
           AND COD_SECC = :NEW.COD_SECC
           AND COD_AGENCIA = SUBSTR(:NEW.NUM_POL1, 1, 4)
           AND NUM_POL = SUBSTR(:NEW.NUM_POL1, 5, 7);
        IF L_CONTA = 0 THEN
          :NEW.NUM_POL_CLI := NULL;
        END IF;
      ELSIF :NEW.MCA_PROVISORIO = 'N' THEN
        :NEW.NUM_POL_CLI := SUBSTR(:NEW.NUM_POL1, 5, 7);
      END IF;
      --  hlc 04062014  conytabilidad soart por fecha de emision
      --  Se añade el cambio de fechas de equipos para numeros de endoso.
      --  Daniel Torres ASW 09092015
      -- sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 6 ',:new.Fecha_Equipo);
     /* Se elimina condicion de fecha equipo  RPR 03/08/2022
      IF (:NEW.COD_SECC = 310 OR :NEW.NUM_END <> 0)
      AND  (TO_CHAR(:OLD.FECHA_EQUIPO,'YYYYMM') = TO_CHAR(SYSDATE,'YYYYMM') 
      OR nvl(:OLD.MCA_PROVISORIO,'N') = 'S')THEN
      -- sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 7 ',:new.fecha_equipo);
      -- sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 7 vig y endoso  ',:new.fecha_vig_end||' '||:new.num_end);
     
       If trunc(Sysdate) <= :new.fecha_vig_end And :new.num_end > 0 Then
          :new.fecha_equipo := TRUNC(SYSDATE);--:new.fecha_vig_end;
         --  sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 8 Queda vigend ',:new.Fecha_Equipo);
       Else
         
        :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
       -- sim_proc_log('TRG_FECHA-Paso Num_pol_cli paso 9 Queda sysdate ',:new.Fecha_Equipo);
       End If;
       */
      END IF;
  -- Nuevo Manejo de fecha Equipo RPR 03/08/2022
  If :NEW.COD_SECC = 310  then  -- SOAT 
     :NEW.FECHA_EQUIPO := trunc(sysdate);
  Elsif :new.num_pol1 is not null then -- Pólizas
     l_Anualidad := nvl(substr(:new.num_pol1,12,2),1);
     prc999_autos_cltvas_grabalog('TRG_NUM_POL_CLI','Poliza: '||:new.num_pol1 || ' Anualidad: ' || l_Anualidad);
     IF l_ANUALIDAD > 1 then -- Renovacion 
        if :new.NUM_END = 0 THEN  -- Retroactiva es el sysdate si es adelantada es la vigencia poliza
           :NEW.FECHA_EQUIPO := greatest(:new.fecha_vig_end, trunc(sysdate));
        else
          Begin
           -- ESTCORE-8994: SE AGREGA INSTRUCCION NVL TRUNC(SYSDATE) PARA LOS CASOS EN QUE NO RETRONA INFORMACION
           Select max(NVL(fecha_equipo, TRUNC(SYSDATE)))
            into l_fechaFact
           from a2000163
           where num_secu_pol = :new.num_secu_pol
           and   cod_agrup_cont = 'GENERICOS'
           and tipo_reg = 'T'
           and num_end = 0;
          Exception when others then null;
            l_fechaFact  := trunc(sysdate);
          end;
          if l_FechaFact <= trunc(sysdate) then
             :NEW.FECHA_EQUIPO := trunc(sysdate);
          else
             :NEW.FECHA_EQUIPO := l_fechaFact;
          end if;
        end if;
        prc999_autos_cltvas_grabalog('TRG_NUM_POL_CLI1','Fecha equipo: ' || :NEW.FECHA_EQUIPO);
     ELSE
        -- Nuevos negocios o Modificaciones de NN
      :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
      prc999_autos_cltvas_grabalog('TRG_NUM_POL_CLI2','Fecha equipo: ' || :NEW.FECHA_EQUIPO);
     END IF; 
   else -- Cotizaciones
      :NEW.FECHA_EQUIPO := TRUNC(SYSDATE);
   end if;   
  END;
  IF :NEW.MCA_PROVISORIO != 'S' AND :NEW.NUM_END = 0 THEN
    :NEW.NUM_POL_CLI := NVL(:NEW.NUM_POL_CLI, SUBSTR(:NEW.NUM_POL1, 5, 7));
  END IF;

END;
/