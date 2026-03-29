CREATE OR REPLACE TRIGGER "SIM_TRG_BIU_G2000020"
BEFORE
  INSERT OR
  UPDATE OF COD_NIVEL, NUM_SECU,MCA_BAJA OR
  DELETE
  ON G2000020
FOR EACH ROW
DECLARE
  l_titulo       sim_pck_tipos_generales.t_var_corto;
  c_tipoCompDef  sim_pck_tipos_generales.t_var_corto:= 'TX';
  c_categoriaDef sim_pck_tipos_generales.t_var_corto:= '99';
  c_estadoDef    sim_pck_tipos_generales.t_caracter:= 'A';
  l_secc         sim_pck_tipos_generales.t_num_secuencia;
  l_descripcion  sim_pck_tipos_generales.t_var_largo;
  l_existe       sim_pck_tipos_generales.t_caracter:= 'N';
  -- Ajuste TuSeguro Luisa Leguizamón 03/04/2020
  c_CodLista     sim_g2000020.cod_lista%TYPE;
  
BEGIN
  IF INSERTING OR UPDATING THEN
    BEGIN
      SELECT SP.COD_SECC
        INTO l_secc
        FROM SIM_PRODUCTOS SP
       WHERE SP.COD_CIA = :NEW.COD_CIA
         AND SP.COD_PRODUCTO = :NEW.COD_RAMO;
    EXCEPTION WHEN no_data_found THEN
        sim_pck_errores.grabarLog('SIM_TRG_BIU_G2000020','Error al extraer seccion',NULL);
    END;
    BEGIN
      --Wesv 20130607 : Inclusion en sim_categorias_dv_producto
      SELECT 's'
        INTO l_existe
        FROM sim_categorias_dv_producto scdp
       WHERE scdp.cod_cia = :new.cod_cia
         AND scdp.cod_prod = :new.Cod_Ramo
         AND scdp.id_categoria = decode(:new.cod_nivel,1,98,2,99,5,15,c_categoriaDef)
         AND scdp.nivel = :new.cod_nivel;
       EXCEPTION WHEN OTHERS THEN
        BEGIN
          BEGIN
            SELECT SC.DESCRIPCION
              INTO l_descripcion
              FROM SIM_CATEGORIAS_DV SC
             WHERE SC.ID_CATEGORIA = decode(:new.cod_nivel,1,98,2,99,5,15,c_categoriaDef);
          END;
          BEGIN
            insert INTO sim_categorias_dv_producto (id_categoria_prod,
                                                    cod_cia,
                                                    cod_prod,
                                                    orden,
                                                    nivel,
                                                    nombre_categoria,
                                                    id_categoria,
                                                    cod_secc,
                                                    obligatorio,
                                                    usuario_creacion,
                                                    fecha_creacion)
                                             VALUES (sim_seq_cat_dv_prod.nextval
                                             ,:new.cod_cia
                                             ,:new.cod_ramo
                                             ,:new.cod_nivel
                                             ,:new.cod_nivel
                                             ,l_descripcion
                                             ,decode(:new.cod_nivel,1,98,2,99,5,15,c_categoriaDef)
                                             ,l_secc
                                             ,'S'
                                             ,USER
                                             ,SYSDATE
                                             );
          EXCEPTION WHEN no_data_found THEN
            sim_pck_errores.grabarLog('SIM_TRG_BIU_G2000020','Error al grabar sim_categorias_dv_producto:'||SQLERRM||' - '||SQLCODE,NULL);
        END;
      END;
    END;
  END IF;
  IF inserting THEN
    BEGIN
      SELECT G.TXT_TITULO
        INTO l_titulo
        FROM G2000010 G
       WHERE g.cod_cia = :NEW.COD_CIA
         AND g.cod_campo = :new.Cod_Campo;
     EXCEPTION WHEN OTHERS THEN
       l_titulo := 'TITULO NO ENCONTRADO';
    END;
    BEGIN
    
    -- Ajuste TuSeguro Luisa Leguizamón 03/04/2020
    IF :new.Cod_Ramo IN (922,923) AND SUBSTR(:new.cod_campo,1,8) = 'API_DEDU' THEN
        c_tipoCompDef := 'CO';
        c_CodLista := 'TS_DEDU_BIEN_EST_ENT';
    END IF;  
    
    INSERT INTO sim_g2000020 (cod_cia,
                              cod_ramo,
                              cod_campo,
                              categoria,
                              orden_categoria,
                              nivel,
                              tupla,
                              componente,
                              titulo,
                              URL,
                              cod_lista,
                              label1,
                              valor1,
                              label2,
                              valor2,
                              label3,
                              valor3,
                              fecha_creacion,
                              fecha_alta,
                              usuario_creacion,
                              fecha_modifica,
                              usuario_modifica,
                              estado,
                              num_secu)
                      VALUES (:new.cod_cia,
                              :new.cod_ramo,
                              :new.cod_campo,
--                              c_categoriaDef,
                               -- Se asigna categoria default dependiendo del nivel
                              decode(:new.cod_nivel,1,98,2,99,5,15,c_categoriaDef),
                              NULL,
                              :new.cod_nivel,
                              NULL,
                              c_tipoCompDef,
                              l_titulo,
                              NULL,
                              -- Ajuste TuSeguro Luisa Leguizamón 02/04/2020
                              c_CodLista,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              SYSDATE,
                              SYSDATE,
                              :new.COD_USR,
                              NULL,
                              NULL,
                              c_estadoDef,
                              :new.num_secu);
      EXCEPTION WHEN dup_val_on_index THEN
        -- No hace nada ya que los registros no se borran cuando se hace paso
        -- de productos - Wesv 20121002
       sim_pck_errores.grabarLog('SIM_TRG_BIU_G2000020','Inconsistencia en insert sim_g2000020:'||
       :new.cod_cia||' - '||:new.cod_ramo||' - '||:new.cod_campo||' :' ||SQLERRM||' - '||SQLCODE,NULL);
    END;
  ELSIF updating  THEN
    IF (nvl(:NEW.COD_NIVEL,0) <> nvl(:old.cod_nivel,0) OR
        nvl(:NEW.num_secu,0) <> nvl(:old.num_secu,0) OR
        nvl(:NEW.mca_baja,'N') <> nvl(:old.mca_baja,'N')) THEN
      UPDATE sim_g2000020 t
         SET t.nivel = :NEW.COD_NIVEL
            ,t.estado = decode (nvl(:new.mca_baja,'N'),'S','I','A')
            ,t.num_secu = :NEW.num_secu
            ,t.usuario_modifica = :new.cod_usr
            ,t.fecha_modifica = SYSDATE
       WHERE t.cod_cia = :old.Cod_Cia
         AND t.cod_campo = :old.Cod_Campo
         AND t.cod_ramo = :OLD.COD_RAMO;
   END IF;
  ELSIF deleting THEN
    UPDATE sim_g2000020  t
       SET t.estado = 'I'
          ,t.fecha_modifica = SYSDATE
          ,t.usuario_modifica = :old.cod_usr
     WHERE t.cod_cia = :old.Cod_Cia
       AND t.cod_campo = :old.Cod_Campo
       AND t.cod_ramo = :OLD.COD_RAMO;
  END IF;
END SIM_TRG_BIU_G2000020;
/
