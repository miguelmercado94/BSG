CREATE OR REPLACE TRIGGER SIM_TRG_AI_SEGCTRTEC
  AFTER INSERT OR UPDATE ON SIM_SEG_CTROLES_TECNICOS
  FOR EACH ROW
DECLARE
l_numPol1 NUMBER(15):= 0;
l_codCia  NUMBER(2):= 0;
l_codRamo  NUMBER(3):= 0;
l_codSecc  NUMBER(3):= 0;
l_simUsuario VARCHAR2(50);
l_simCanal NUMBER(5):= 0;
l_mail VARCHAR2(100):= 'wilson.sacristan@segurosbolivar.com';
l_secuencia NUMBER(15):= 0;
TYPE t_listaMails  IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
l_listaMails t_listaMails;
BEGIN
  l_listaMails(1):= 'nn@seg.com';
--  l_listaMails(1):= 'wilson.sacristan@segurosbolivar.com';
--  l_listaMails(3):= 'andres.villada@segurosbolivar.com';
--  l_listaMails(4):= 'wilson.ricardo.lopez@segurosbolivar.com';
  BEGIN
    SELECT num_pol1, cod_cia, cod_secc, cod_ramo, nvl(sim_usuario_creacion,:new.usuario_destino), sim_canal
      INTO l_numpol1, l_codcia, l_codsecc, l_codramo,l_simUsuario, l_simCanal
      FROM a2000030
     WHERE num_secu_pol = :new.num_secu_pol
       AND num_end = 0;
    EXCEPTION WHEN OTHERS THEN NULL;
  END;
  
  sim_proc_log('SIM_TRG_AI_SEGCTRTEC',:NEW.USUARIO_DESTINO ||' - '||     l_simUsuario||' - '||:new.usuario_creacion);
  IF :NEW.USUARIO_DESTINO = l_simUsuario
      AND :new.Usuario_Destino <> :new.usuario_creacion THEN
--    FOR i IN 1..l_listaMails.count LOOP
/*     BEGIN
    sim_pck_generales.proc_enviarEmail
    ('Simon@segurosbolivar.com'
    ,l_listaMails(i)
    ,9996
   ,'(Mail de Prueba) Se ha actualizado el control técnico en la poliza ' ||l_numPol1
              ||', por favor consulte el estado en la aplicacion Simon Ventas '||chr(14)
                                     ,'N'
                                     ,NULL);
       EXCEPTION WHEN OTHERS THEN NULL;
     END;*/
   BEGIN
     BEGIN
       SELECT sim_seq_bitacoras_seg_reg.nextval
         INTO l_secuencia
         FROM dual;
     END;
     INSERT INTO sim_bitacora_seg_ct (id_bit_seg_ctr
                                 ,id_seg_ctr_tec
                                 ,usuario_destino
                                 ,leido)
                         VALUES  (l_secuencia
                                 ,:NEW.ID_SEGCONTEC
                                 ,l_simUsuario
                                 ,'N'
                                 );
         EXCEPTION WHEN OTHERS THEN NULL;
     END;
--  END LOOP;
  END IF;
END SIM_TRG_AI_SEGCTRTEC;
/
