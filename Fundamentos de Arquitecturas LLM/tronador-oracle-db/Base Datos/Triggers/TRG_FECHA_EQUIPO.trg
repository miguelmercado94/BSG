CREATE OR REPLACE TRIGGER Trg_Fecha_Equipo
  BEFORE INSERT OR UPDATE OF Fecha_Equipo,DESC_POL
  ON A2000030
  FOR EACH ROW
DECLARE
   vl_fecha_equipo_end   a2000030.fecha_equipo%TYPE; --Daniel Torres ASW
   vl_Recaudo            VARCHAR2(1);
   vl_FechaTes           DATE;
 --  l_fechabase Date := to_Date('19012018','DDMMYYYY');
BEGIN

    BEGIN
        /*Stiven Benavides Mantis-53750 17/05/2017*/
        /*GD986-916 - Se agrega CHE(13) que es otro salto de linea*/
        IF :new.desc_pol IS NOT NULL THEN
            :new.desc_pol := REPLACE(
                               REPLACE(
                                 regexp_replace(:new.desc_pol,'[[:space:]]\s',''),
                               CHR(10)),
                             CHR(13));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
    /*Rosario Puertas Se reversa manejo de emision futura */
  /* If :new.Fecha_Emi >= l_Fechabase Then
      If :new.Num_End = 0 Then
        If  substr(:new.num_pol1,12,2) > 1 And :new.Num_Pol1 Is Not Null
        And  :new.Num_Pol_Ant = :new.Num_Pol1 -1  And :NEW.Fecha_Vig_pol > trunc(Sysdate) Then
         -- Renovacion  anticipada
          :new.fecha_equipo := :new.fecha_vig_pol;
        Else    --  Endoso 0
          :new.fecha_equipo := :new.fecha_emi_end;
        End If;
      Elsif  :new.fecha_vig_pol <= trunc(sysdate) -- modificacion poliza ya inicio vigencia
       Then
        :new.fecha_equipo := :new.fecha_emi_end;
      Elsif  substr(:new.num_pol1,12,2) > 1 Then
       :new.fecha_equipo := :new.fecha_vig_pol;
      Else :new.fecha_equipo := :new.fecha_emi_end;
      End If;
   Else*/
   IF INSERTING THEN
      BEGIN
        /* vl_Recaudo := 'N';
         BEGIN
            IF :new.num_end > 0 THEN
               SELECT fecha_equipo
               INTO vl_fecha_equipo_end
               FROM a2000163
              WHERE num_secu_pol = :new.num_secu_pol
                AND fecha_equipo  = (SELECT MAX(fecha_equipo) FROM a2000163
                                      WHERE num_secu_pol = :new.num_secu_pol)
                AND rownum <= 1;
            ELSE
               BEGIN
                  SELECT 'S',  last_day(nvl( fec_valor, fec_situ))
                    INTO vl_Recaudo, vl_fecha_equipo_end
                    FROM a2990700
                   WHERE num_secu_pol = :new.num_secu_pol
                     AND num_factura = 1
                  -- AND fecha_equipo > trunc(SYSDATE)
                     AND cod_situacion in ('CT', 'PP')
                     AND ((to_char(last_day(nvl( fec_valor, fec_situ)),'YYYYMM') = to_char(SYSDATE,'YYYYMM'))
                        OR last_day(nvl( fec_valor, fec_situ)) + 2 <= trunc(SYSDATE))  ;
                  EXCEPTION WHEN OTHERS THEN NULL;
               END;
            END IF;
            EXCEPTION
               WHEN OTHERS THEN  vl_fecha_equipo_end := :NEW.fecha_vig_end;
         END;*/
         :new.fecha_equipo := :new.fecha_emi_end;
         IF ( :NEW.Fecha_Equipo < :NEW.Fecha_Vig_End ) THEN -- Expedicion adelantada
         /*   IF :new.num_end = 0 THEN
          \* :NEW.Fecha_Equipo := :NEW.Fecha_Vig_End;*\
               IF vl_Recaudo = 'N' THEN
                  :NEW.Fecha_Equipo := :NEW.Fecha_Vig_End;
               ELSE
                  :New.Fecha_Equipo := vl_fecha_equipo_end;
               END IF;
            ELSIF  vl_fecha_equipo_end > trunc(SYSDATE) THEN  -- Modif. Pol adelantad
               :new.fecha_equipo := vl_fecha_equipo_end;
            END IF;*/
            if substr(:new.num_pol1,12,2)  > 1 then -- Renovaciones
               if trunc(sysdate) < :NEW.Fecha_Vig_pol   then
                  :new.fecha_equipo := :NEW.Fecha_vig_pol;
               end if;
            end if;
         END IF;
  /*  End If;*/
         P299REA_PCU001( :NEW.Num_Secu_Pol, :NEW.Num_End, :NEW.Fecha_Equipo );
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
      END; 
--   ELSE
--      vl_FechaTes := sim_pck_updFechaEquipo.Fun_FechaTes;
       
      
   END IF;    
END;
/
