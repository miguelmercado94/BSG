CREATE OR REPLACE TRIGGER SIM_TRG_BIU_CREGLAS
before INSERT OR UPDATE
OF dssel1,dssel2,dssel3,dssel4,dssel5,dssel6,dssel7,dssel8,dssel9,
dssel10,dssel11,dssel12,dssel13,dssel14,dssel15,dssel16,dssel17,
dssel18,dssel19,dssel20,dssel21,dssel22,dssel23,dssel24,dssel25,
dssel26,dssel27,dssel28,dssel29,dssel30,dssel31,dssel32,dssel33,
dssel34,dssel35,dssel36
ON CREGLAS 
FOR EACH ROW
DECLARE
  l_selectCompleto     SIM_PCK_TIPOS_GENERALES.t_clob;
BEGIN
  SELECT
   replace(TRIM(rpad(:new.dssel1 , 80, ' ')|| rpad(:new.dssel2 , 80, ' ') ||
             rpad(:new.dssel3 , 80, ' ')|| rpad(:new.dssel4 , 80, ' ') ||
             rpad(:new.dssel5 , 80, ' ')|| rpad(:new.dssel6 , 80, ' ') ||
             rpad(:new.dssel7 , 80, ' ')|| rpad(:new.dssel8 , 80, ' ') ||
             rpad(:new.dssel9 , 80, ' ')|| rpad(:new.dssel10, 80, ' ') ||
             rpad(:new.dssel11, 80, ' ')|| rpad(:new.dssel12, 80, ' ') ||
             rpad(:new.dssel13, 80, ' ')|| rpad(:new.dssel14, 80, ' ') ||
             rpad(:new.dssel15, 80, ' ')|| rpad(:new.dssel16, 80, ' ')  ||
             rpad(:new.dssel17, 80, ' ') || rpad(:new.dssel18, 80, ' ') ||
             rpad(:new.dssel19, 80, ' ') || rpad(:new.dssel20, 80, ' ') ||
             rpad(:new.dssel21, 80, ' ') || rpad(:new.dssel22, 80, ' ') ||
             rpad(:new.dssel23, 80, ' ') || rpad(:new.dssel24, 80, ' ') ||
             rpad(:new.dssel25, 80, ' ') || rpad(:new.dssel26, 80, ' ') ||
             rpad(:new.dssel27, 80, ' ') || rpad(:new.dssel28, 80, ' ') ||
             rpad(:new.dssel29, 80, ' ') || rpad(:new.dssel30, 80, ' ') ||
             rpad(:new.dssel31, 80, ' ') || rpad(:new.dssel32, 80, ' ') ||
             rpad(:new.dssel33, 80, ' ') || rpad(:new.dssel34, 80, ' ') ||
             rpad(:new.dssel35, 80, ' ') || rpad(:new.dssel36, 80, ' ')),chr(13),chr(10))
         INTO l_selectCompleto
         FROM dual;
    DELETE FROM sim_reglas_variable 
     WHERE cod_regla = :new.cdreg;         
    sim_pck_reglas.convertirReglaProc (:new.cdreg, l_selectCompleto,
                                       'N',:new.procedimiento_generado
                                      ,:new.regla_Completa
                                      ,:new.tipo_regla,:new.error_compilacion);
  BEGIN
    IF :new.procedimiento_generado IS NOT NULL THEN
      sim_pcK_reglas.compilarPrograma(:new.cdreg,:new.procedimiento_generado,:new.error_compilacion);
    END IF;
  END;
END SIM_TRG_BIU_CREGLAS;
/
