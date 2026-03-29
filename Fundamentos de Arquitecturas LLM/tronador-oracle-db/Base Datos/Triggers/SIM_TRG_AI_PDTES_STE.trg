CREATE OR REPLACE TRIGGER SIM_TRG_AI_PDTES_STE
  AFTER INSERT ON SIM_PDTES_STELLENT
  FOR EACH ROW
  /* Autor:MAOR /WESV
     Fecha: Agosto 31 - 2017
     Objetivo: Incluir en la tabla c9999040 la info para aquellas declaraciones que no pudieron indexarse
     */
DECLARE
  ip_proceso sim_typ_proceso;
  op_arrerrores sim_typ_array_error;
  op_resultado NUMBER:= 0;
  IP_CODRIES NUMBER;
  op_arrdecaseprd sim_typ_array_decasegprd;
  
  
BEGIN
  ip_proceso :=NEW sim_typ_proceso();
  op_arrerrores :=NEW sim_typ_array_error();
  op_arrdecaseprd           := New sim_typ_array_decasegprd();

  BEGIN
      Delete C9999040 Where USUARIO = 'DEC_ASEG_VIDA'
       AND num_secu_pol = :NEW.NUM_SECU_POL;
  END;
  IF :NEW.NOMBREAPLICACION = 'INFOVIDA' THEN
   BEGIN
     SELECT cod_cia
           ,cod_secc
           ,cod_ramo
       INTO ip_proceso.p_cod_cia
           ,ip_proceso.p_cod_secc
           ,ip_proceso.p_cod_producto
       FROM a2000030 h
      WHERE h.num_secu_pol = :new.num_secu_pol
        AND h.num_end = 0;
   END;
  For reg_c1 In (Select Distinct b.cod_ries
                   From   sim_decl_aseg_pol b
                   Where  b.num_secu_pol = :NEW.NUM_SECU_POL)  Loop
      ip_codries                := reg_c1.cod_ries;
      sim_pck_cotizadores_web.leedeclasegpol(:NEW.NUM_SECU_POL,
                                             ip_codries,
                                             op_arrdecaseprd,
                                             'S',
                                             ip_proceso,
                                             op_resultado,
                                             op_arrerrores);

       If op_resultado = 0 Then
         For  i  IN  1.. op_arrdecaseprd.count  LOOP
              Insert Into C9999040(USUARIO,
                                   NUM_SECU_POL,
                                   ORDEN,
                                   COLNUM01,
                                   COLCAR15,
                                   COLCAR16)
              Values  ('DEC_ASEG_VIDA',
                       :NEW.NUM_SECU_POL,
                       i,
                       ip_codries,
                       substr(op_arrdecaseprd(i).PREGUNTA,1,200),
                       op_arrdecaseprd(i).VLR_DEFAULT
                       );
         End LOOP;
       End If;
  End Loop;
  END IF;  
  EXCEPTION WHEN OTHERS THEN NULL;                                  
END SIM_TRG_AI_PDTES_STE;
/
