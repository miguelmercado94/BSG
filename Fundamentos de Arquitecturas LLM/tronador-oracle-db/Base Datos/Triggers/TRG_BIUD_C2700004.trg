CREATE OR REPLACE TRIGGER TRG_BIUD_C2700004
BEFORE DELETE OR INSERT OR UPDATE
ON C2700004 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    -- Variables
    VObservaciones       c2700004.dlg_observaciones%TYPE;
    VObservacionesValida c2700004.dlg_observaciones%TYPE;
    VOperacion           VARCHAR2(1);
    VMarcaError          VARCHAR2(1);
    VMarcaErrorValida    VARCHAR2(1) := 'N';
    VUserGenerico        VARCHAR2(5) := 'PARP';
    NATURAL              pkg_creamod_tercero_adapt.st_adapt_natural;
    Res                  pkg_creamod_tercero_adapt.st_adapt_resultado;
 
    -- Constantes
    CCreacion      CONSTANT VARCHAR2(1) := 'C';
    CActualizacion CONSTANT VARCHAR2(1) := 'A';
    CBorrado       CONSTANT VARCHAR2(1) := 'B';
 
    -- Métodos própios del Trigger
    -- La siguiente sección de métodos resume las funcionalidades a validar
 
    -- 1. Función que determina si un tercero ya existe o no
    --     p_dcmnto_numero    IN  NUMBER
    --     p_dcmnto_tipo      IN  VARCHAR2
    FUNCTION func_existetercero(p_dcmnto_numero IN NUMBER
                               ,p_dcmnto_tipo   IN VARCHAR2) RETURN BOOLEAN IS
        l_secuencia  NUMBER(13) := NULL;
        l_sqlerr     NUMBER(6) := NULL;
        l_sqlerrm    VARCHAR2(200) := NULL;
        l_existeterc BOOLEAN := FALSE;
    BEGIN
        pkg_api1.prc_buscar_cliente(p_dcmnto_numero--
                                   ,p_dcmnto_tipo
                                   ,l_secuencia
                                   ,l_sqlerr
                                   ,l_sqlerrm);
        IF l_sqlerr = 0 THEN
            l_existeterc := TRUE;
        END IF;
        RETURN l_existeterc;
    END func_existetercero;
 
    -- 2. Validación de teléfono fijo
    FUNCTION func_estelefonovalido(p_num_telefono IN VARCHAR2) RETURN BOOLEAN IS
        l_estelefonovalido BOOLEAN := TRUE;
        l_numtelefonoproc  VARCHAR2(60);
    BEGIN
        -- Invocación a método de limpieza de caracteres especiales
        l_numtelefonoproc := to_char(arl_pck_utils.fun_retrna_crctres_numeros(p_num_telefono));
        --
        l_estelefonovalido := length(l_numtelefonoproc) between  7 and 10;
        
        RETURN l_estelefonovalido;
    END func_estelefonovalido;
 
    -- 3. Validación de teléfono celular
    FUNCTION func_escelularvalido(p_celular IN VARCHAR2) RETURN BOOLEAN IS
        l_escelularvalido BOOLEAN := TRUE;
        l_numcelularproc  VARCHAR2(60);
    BEGIN
        -- Invocación a método de limpieza de caracteres especiales
        l_numcelularproc := to_char(arl_pck_utils.fun_retrna_crctres_numeros(p_celular));
        --
        l_escelularvalido := length(l_numcelularproc) = 10;
        RETURN l_escelularvalido;
    END func_escelularvalido;
 
    -- 4. Validación de correo electrónico
    FUNCTION func_escorreovalido(p_email IN VARCHAR2) RETURN BOOLEAN IS
        l_escorreovalido BOOLEAN := TRUE;
        l_cuenta         PLS_INTEGER := 0;
    BEGIN
        BEGIN
            SELECT 1 INTO l_cuenta FROM dual WHERE regexp_like(upper(p_email), '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$');
        EXCEPTION
            WHEN OTHERS THEN
                l_escorreovalido := FALSE;
        END;
        RETURN l_escorreovalido;
    END func_escorreovalido;
 
    /*********************************************************************************************************************************
     NAME:       TRG_BIUD
     PURPOSE:
     REVISIONS:
     VER        DATE        AUTHOR           DESCRIPTION
     ---------  ----------  ---------------  ------------------------------------
     1.0        08/01/2014      79704401       1. CREATED THIS TRIGGER. 
    
     NOTES:
    
     AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
        OBJECT NAME:     TRG_BIUD
        SYSDATE:         08/01/2014
        DATE AND TIME:   08/01/2014, 02:10:13 P.M., AND 08/01/2014 02:10:13 P.M.
        USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
        TABLE NAME:      C2700004 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
        TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
    
     VER        DATE        AUTHOR           DESCRIPTION
     ---------  ----------  ---------------  ------------------------------------
     1.0.1      06/06/2014  INTASI32         1. SE AJUSTA UPDATING PARA LA CERACION DEL TERCERO
     1.0.2      29/09/2014  INTASI32         1. SE AJUSTA PARA QUE EL USUARIO QUE CREE EL TERCERO SEA PARP
     1.1.0      21/12/2015  B8092771         1. Se ajusta el código por bloques para facilitar mantenibilidad
                                                y garantizando reducción de código repetido.
     1.1.1      22/12/2015  B8092771         1. Se ajustan los métodos propios del trigger para las validaciones
                                                y se realizan los ajustes necesarios para garantizar el envío del
                                                correo electrónico, en caso que suceda algún error.
     1.1.3      27/01/2017 WILSON F LOPEZ    1. SE ADICIONA EN LA ACTUALIZACION TELEFONOS FIJO O MOVIL Y CORREO ELECTRONICO DEL DELEGADOR                                            
    *********************************************************************************************************************************/
BEGIN
    IF NOT (instr(nvl(:new.dlg_mca_para_envio, 'P'), 'S') > 0) THEN
        <<valida_operacion>>
        BEGIN
            -- Inserción (Creación)
            IF inserting THEN
                VOperacion := CCreacion;
            END IF;
            -- Actualización
            IF UPDATING THEN
                IF (:New.Dlg_Numero_Documento <> :Old.Dlg_Numero_Documento OR :New.Dlg_Tipo_Documento <> :Old.Dlg_Tipo_Documento
                  OR :New.Dlg_Telefono_Residencia <> :Old.Dlg_Telefono_Residencia  OR :New.Dlg_Telefono_Movil <> :Old.Dlg_Telefono_Movil 
                  OR :New.Dlg_Correo_Electronico <>  :Old.Dlg_Correo_Electronico) THEN
                  
                    Voperacion := Cactualizacion;
                END IF;
            END IF;
            -- Borrado
            IF deleting THEN
                VOperacion := CBorrado;
            END IF;
        END valida_operacion;
    
        -- Bloque de operación
        -- Si se realiza una inserción o una actualización de un tercero, entonces, se procede a realizar
        -- el flujo de inserción de datos.
        IF VOperacion IN (CCreacion, CActualizacion) THEN
            dbms_output.put_line('TDOC TERCERO ' || :new.dlg_numero_documento || ', NUM_DOC ' || :new.dlg_tipo_documento);
            IF NOT (func_existetercero(:new.dlg_numero_documento, :new.dlg_tipo_documento)) THEN
                BEGIN
                    VObservacionesValida := ('Respuesta validaciones. * ');
                    -- Inicio de sección de validación (pendiente escalar)
                    -- 1. Validación de teléfono
                    IF NOT (func_estelefonovalido(:new.dlg_telefono_residencia)) THEN
                        VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de número de teléfono.');
                        VMarcaErrorValida    := 'S';
                    END IF;
                
                    -- 2. Validación de número de celular.
                    IF NOT (func_escelularvalido(:new.dlg_telefono_movil)) THEN
                        VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de número de celular.');
                        VMarcaErrorValida    := 'S';
                    END IF;
                
                    -- 3. Validación de Correo Electrónico
                    IF NOT (func_escorreovalido(:new.dlg_correo_electronico)) THEN
                        VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de correco electrónico.');
                        VMarcaErrorValida    := 'S';
                    END IF;
                
                    -- Si las validaciones son correctas, entonces se invoca la creación del tercero.
                    Res                        := NULL;
                    Res.p_compania             := 2;
                    Res.p_ramo_seccion         := 70;
                    Res.p_producto             := 722;
                    Res.p_usuario              := VUserGenerico;
                    Res.p_sistema              := 'SIMON_WEB';
                    natural.p_dcmnto_numero    := :new.dlg_numero_documento;
                    natural.p_dcmnto_tipo      := :new.dlg_tipo_documento;
                    natural.p_ncmnto_fecha     := :new.dlg_fecha_nacimiento;
                    natural.p_ncmnto_ciudad    := :new.dlg_ciudad_nacimiento;
                    natural.primer_nombre      := :new.dlg_primero_nombre;
                    natural.segundo_nombre     := :new.dlg_segundo_nombre;
                    natural.primer_apellido    := :new.dlg_primer_apellido;
                    natural.segundo_apellido   := :new.dlg_segundo_apellido;
                    natural.p_sexo             := :new.dlg_sexo;
                    natural.p_nacionalidad     := :new.dlg_nacionalidad;
                    natural.p_dir_residencial  := :new.dlg_direccion;
                    natural.p_dir_res_ciudad   := :new.dlg_ciudad_residencia;
                    natural.p_dir_res_telefono := :new.dlg_telefono_residencia;
                    natural.p_email            := :new.dlg_correo_electronico;
                    natural.p_celular          := :new.dlg_telefono_movil;
                    natural.p_banca_seguros    := 'N';
                    natural.p_usuario          := VUserGenerico;
                    pkg_creamod_tercero_adapt.prc_crea_natural(NATURAL, Res);
                
                    -- RESTRICCION
                    VObservaciones := ('Respuesta Existe Tercero.*  ' || Res.p_existe_tercero) || ' ' ||
                                      ('Respuesta Tercero Consultable.* ' || Res.p_tercero_consultable) || ' ' ||
                                      ('Respuesta Restringe Operaciones.* ' || Res.p_se_restringe_operaciones) || ' ' || VObservacionesValida;
                
                    IF Res.p_sqlerr <> 0 THEN
                        VObservaciones := VObservaciones || ' ' || ('Error ' || Res.p_sqlerr || Res.p_msj_usuario);
                    
                        -- Validación Error contiene la palabra 'FALTA'
                        BEGIN
                            SELECT 'S' --
                              INTO VMarcaError
                              FROM dual
                             WHERE upper(VObservaciones) LIKE '%FALTA%';
                        EXCEPTION
                            WHEN no_data_found THEN
                                VMarcaError := NULL;
                            WHEN OTHERS THEN
                                VMarcaError := 'S';
                        END;
                    
                        IF VMarcaError = 'S' OR VMarcaErrorValida = 'S' THEN
                            :new.aud_operacion := 'ER';
                        END IF;
                    
                        IF natural.p_secuencia > 0 THEN
                            :new.dlg_mca_tercero       := 'S';
                            :new.dlg_secuencia_tercero := natural.p_secuencia;
                        ELSE
                            :new.dlg_mca_tercero := 'R';
                            IF VOperacion = CCreacion THEN
                                :new.dlg_secuencia_tercero := natural.p_secuencia;
                            END IF;
                        END IF;
                    
                        :new.dlg_observaciones := VObservaciones;
                    ELSE
                        :new.dlg_mca_tercero       := 'S';
                        :new.dlg_secuencia_tercero := natural.p_secuencia;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        VObservaciones       := VObservaciones || ' ' || ('Error ' || SQLERRM);
                        :new.dlg_mca_tercero := 'R';
                        --   :NEW.Dlg_Observaciones   := Vobservaciones;
                END;
            ELSE
                dbms_output.put_line('El tercero ya existe');
                VObservaciones := VObservaciones || ' ' || ('El tercero ya existe.');
            
                VObservacionesValida := ('Respuesta validaciones. * ');
                -- Inicio de sección de validación (pendiente escalar)
                -- 1. Validación de teléfono
                IF NOT (func_estelefonovalido(:new.dlg_telefono_residencia)) THEN
                    VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de número de teléfono.');
                    VMarcaError          := 'S';
                END IF;
            
                -- 2. Validación de número de celular.
                IF NOT (func_escelularvalido(:new.dlg_telefono_movil)) THEN
                    VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de número de celular.');
                    VMarcaError          := 'S';
                END IF;
            
                -- 3. Validación de Correo Electrónico
                IF NOT (func_escorreovalido(:new.dlg_correo_electronico)) THEN
                    VObservacionesValida := VObservacionesValida || ' ' || ('Formato incorrecto de correco electrónico.');
                    VMarcaError          := 'S';
                END IF;
                VObservaciones := VObservaciones || VObservacionesValida;
            END IF;
        END IF;
        :new.dlg_observaciones := VObservaciones;
        IF VMarcaError = 'S' OR VMarcaErrorValida = 'S' THEN
            -- Se actualiza la marca para envío en 'EP' Error Pendiente de envío
            :new.dlg_mca_para_envio := 'EP';
        ELSE
            -- Se actualiza la marca para envío en 'OP' OK Pendiente de envío
            :new.dlg_mca_para_envio := 'OP';
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- CONSIDER LOGGING THE ERROR AND THEN RE-RAISE
        --     RAISE;
        dbms_output.put_line('Error ' || SQLERRM || 'linea ' || dbms_utility.format_error_backtrace());
        :new.dlg_mca_para_envio := 'EP';
        :new.dlg_observaciones  := ('Respuesta Existe Tercero.*  ' || SQLERRM);
END trg_BIUD_c2700004;
/
