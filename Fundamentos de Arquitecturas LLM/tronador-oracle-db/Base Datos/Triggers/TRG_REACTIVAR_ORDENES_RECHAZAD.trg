CREATE OR REPLACE TRIGGER TRG_REACTIVAR_ORDENES_RECHAZAD
AFTER INSERT OR UPDATE OF COD_ENTIDAD_DESTINO, NUMERO_CTA_DESTINO, TIPO_CTA, ESTADO 
ON A5021103 
FOR EACH ROW
DISABLE
DECLARE
  
    V_DESCR_ERROR VARCHAR2(400);
    v_ubicacion_error VARCHAR2(200);
BEGIN
  --actualizacion de cuenta o de estado
  IF UPDATING THEN
    --Si solo se cambio datos de la cuenta de un producto financiero ya activo
    IF :NEW.ESTADO = 1 AND :OLD.ESTADO = 1 THEN
      --actualizar las ordenes de pago rechazadas y disponibles (para enviar al centralizador) que eran y siguen siendo del proceso de Davivienda:
      v_ubicacion_error := 'PRC_ACTUALIZA_CTA_OP_DAVIVIEND';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_DAVIVIEND(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );
      
      IF :NEW.COD_ENTIDAD_DESTINO IN(7,1507) THEN
        
        --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_BANCOLOMB;

        --Si antes la cuenta no era de Bancolombia y ahora si 
        IF :NEW.COD_ENTIDAD_DESTINO <> :OLD.COD_ENTIDAD_DESTINO THEN
          --moviendo las ordenes del proceso de Davivienda al proceso transferencia Bancolombia
          v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIVI_A_BCOL';
          PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIVI_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                    :NEW.TDOC_TERCERO,
                                                                    :NEW.TIPO_CTA,
                                                                    :NEW.NUMERO_CTA_DESTINO,
                                                                    :NEW.COD_ENTIDAD_DESTINO
                                                                    );  
                                                                    
          --mover ordenes de pago de proceso ventanilla a proceso transferencia bancolombia las op q son de cia = 1,2 o 3
          --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
          /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_VENTAN_A_BCOL';
          PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_VENTAN_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                    :NEW.TDOC_TERCERO,
                                                                    :NEW.TIPO_CTA,
                                                                    :NEW.NUMERO_CTA_DESTINO,
                                                                    :NEW.COD_ENTIDAD_DESTINO
                                                                    );*/

          --mover de daviplata a proceso transferencia bancolombia las op q son de cia = 1,2 o 3
          v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIPL_A_BCOL';
          PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIPL_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                    :NEW.TDOC_TERCERO,
                                                                    :NEW.TIPO_CTA,
                                                                    :NEW.NUMERO_CTA_DESTINO,
                                                                    :NEW.COD_ENTIDAD_DESTINO
                                                                    );

        
        END IF;
                                                                  
      END IF;   

      --Si antes tenia cuenta Bancolombia y ahora no
      IF :NEW.COD_ENTIDAD_DESTINO NOT IN(7,1507) AND :OLD.COD_ENTIDAD_DESTINO IN(1507,7) THEN
        --moviendo las ordenes del proceso de transferencia Bancolombia al proceso Davivienda 
        --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
        /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_BCOL_A_DAVIVI';
        PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_BCOL_A_DAVIVI(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );*/
                                                                  
        --mover ordenes de pago de proceso ventanilla a davivienda bco dest 7 o <> 7
        --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
        /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_VENTA_A_DAVIV';
        PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_VENTA_A_DAVIV(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );*/
     
        --mover ordenes de pago del proceso daviplata al proceso davivenda (con bco dest 7 o <> 7)
        v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIP_A_DAVIV';
        PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIP_A_DAVIV(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );

      END IF;

    ELSIF :NEW.ESTADO IN (2,3) AND :OLD.ESTADO = 1 THEN --esta inactivando la cuenta que tiene la persona
      --moviendo las ordenes del proceso de Davivienda al proceso ventanilla Bancolombia
      v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIV_A_VENTA';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIV_A_VENTA(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );        
      --moviendo las ordenes del proceso de Davivienda al proceso Daviplata
      v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIV_A_DAVIP';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIV_A_DAVIP(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );
    
      --si la cuenta q estan inactivando es de bancolombia
      --IF :OLD.COD_ENTIDAD_DESTINO = 7 THEN 
        --moviendo las ordenes del proceso de transferencia Bancolombia al proceso ventanilla Bancolombia
        --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
        /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_BCOL_A_VENTAN';
        PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_BCOL_A_VENTAN(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );*/
         
        --moviendo las ordenes del proceso de transferencia Bancolombia al proceso Daviplata
        --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
        /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_BCOL_A_DAVIPL';
        PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_BCOL_A_DAVIPL(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );*/
      --END IF;
    
    
      --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_VENTA_A_DAVIP
    
      --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIP_A_VENTA
      
      --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_DAVIPLATA;
      
      --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_VENTANILL;
      
    
    END IF;	
	
  END IF;

  --Estan creando o activando una cuenta	
  IF :NEW.ESTADO = 1 AND (INSERTING OR (UPDATING AND :OLD.ESTADO IN (2,3))) THEN
  
    --mover ordenes de pago del proceso daviplata al proceso davivenda (con bco dest 7 o <> 7)
    v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIP_A_DAVIV';
    PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIP_A_DAVIV(:new.NUMERO_DOCUMENTO,
                                                              :NEW.TDOC_TERCERO,
                                                              :NEW.TIPO_CTA,
                                                              :NEW.NUMERO_CTA_DESTINO,
                                                              :NEW.COD_ENTIDAD_DESTINO
                                                              );
  
    --mover ordenes de pago de proceso ventanilla a davivienda bco dest 7 o <> 7
    --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
    /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_VENTA_A_DAVIV';
    PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_VENTA_A_DAVIV(:new.NUMERO_DOCUMENTO,
                                                              :NEW.TDOC_TERCERO,
                                                              :NEW.TIPO_CTA,
                                                              :NEW.NUMERO_CTA_DESTINO,
                                                              :NEW.COD_ENTIDAD_DESTINO
                                                              );*/
  
    IF :NEW.COD_ENTIDAD_DESTINO IN (1507, 7) THEN
      --mover de daviplata a proceso transferencia bancolombia las op q son de cia = 1,2 o 3
      v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIPL_A_BCOL';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIPL_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );
  
      --mover ordenes de pago de proceso ventanilla a proceso transferencia bancolombia las op q son de cia = 1,2 o 3
      --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
      /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_VENTAN_A_BCOL';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_VENTAN_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );*/
  
      --mover ordenes de pago de proceso Davivienda a proceso transferencia bancolombia las op q son de cia = 1,2 o 3
      v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_DAVIVI_A_BCOL';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_DAVIVI_A_BCOL(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );
                                                                
      --PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_BANCOLOMB;
    ELSE
      --moviendo las ordenes del proceso de transferencia Bancolombia al proceso Davivienda 
      --09-12-2021 se deshabilita a solicitud de Marco Aponte (no tocar las O.P. disponibles)
      /*v_ubicacion_error := 'PRC_ACT_Y_MOV_OP_BCOL_A_DAVIVI';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACT_Y_MOV_OP_BCOL_A_DAVIVI(:new.NUMERO_DOCUMENTO,
                                                                :NEW.TDOC_TERCERO,
                                                                :NEW.TIPO_CTA,
                                                                :NEW.NUMERO_CTA_DESTINO,
                                                                :NEW.COD_ENTIDAD_DESTINO
                                                                );*/

      --actualizar las ordenes de pago rechazadas y disponibles (para enviar al centralizador) que eran y siguen siendo del proceso de Davivienda:
      v_ubicacion_error := 'PRC_ACTUALIZA_CTA_OP_DAVIVIEND';
      PCK_MOVIMIENTO_ORDENES_PAGO.PRC_ACTUALIZA_CTA_OP_DAVIVIEND(:new.NUMERO_DOCUMENTO,
                                                                  :NEW.TDOC_TERCERO,
                                                                  :NEW.TIPO_CTA,
                                                                  :NEW.NUMERO_CTA_DESTINO,
                                                                  :NEW.COD_ENTIDAD_DESTINO
                                                                  );

    END IF;

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    V_DESCR_ERROR := SUBSTR('EXCEPCION EN '||v_ubicacion_error||': '||SQLERRM,1,400);      
    BEGIN
      DBMS_OUTPUT.PUT_LINE('EXCEPCION TRG PPAL: '||V_DESCR_ERROR);
      INSERT INTO CEPAG_ERRORES (ID_ERROR, DESCRIPCION, FECHA_CREACION, TIPO_ERROR) 
      VALUES (SEQ_CEPAG_ERRORES.NEXTVAL, V_DESCR_ERROR, SYSDATE, 'ERRL');
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
END;
/
