CREATE OR REPLACE TRIGGER TRG_ACT_SOLIC_POC
AFTER INSERT
OR UPDATE OF ESTADOSOLICITUD ON 	ops$sisolus.LOGINES
FOR EACH ROW
DECLARE
  W_CEDULA                VARCHAR2(12) ;
  EDOCIVIL                VARCHAR2(10);
  W_NOMBRE                VARCHAR2(30) ;
  W_APELLIDO              VARCHAR2(200);
  W_TELEFONO              VARCHAR2(50) ;
  W_NOMBRE_SISOLUS        OPS$SISOLUS.USUARIOS.NOMBRE%TYPE ;
  W_NUMIDE                OPS$SISOLUS.USUARIOS.NUMIDE%TYPE ;
  W_CONCODIGO             OPS$SISOLUS.USUARIOS.CONCODIGO%TYPE ;
  CONSECUTIVO             LOGINES.CONSECUTIVO%TYPE ;
  NOMBREEMPLEADO          USUARIOS.NOMBRE%TYPE ;
  W_LOCALIDAD             USUSXCARXLOC.CODIGOLOCALIDAD%TYPE ;
  W_CARGO                 USUSXCARXLOC.CARGO_CODIGO%TYPE ;
  W_TIPSOL                LOGINES.TIPSOL_CODIGO%TYPE ;
  W_MANEJACOMPANIA        SISINF.MANEJACOMPANIA%TYPE ;
  W_ID_USUARIO            USUARIOS.ID_USUA_UNIQUE@psisolus_pnovell_novell.world%TYPE;
  TRAZA                   VARCHAR2(2000);
  W_NIT                   VARCHAR2(15);
  W_RAZSOC                VARCHAR2(50);
  w_seqsol                NUMBER(10);
  w_nomage                VARCHAR2(100);
  W_TIPIDE                VARCHAR2(2);
  w_codactbenef           NUMBER(2);
  w_fuente                VARCHAR2(10);
  w_estado_solicitud      VARCHAR2(1);
  W_TIPTRA                VARCHAR2(2);
  W_JEFARE                VARCHAR2(2);
  perfil_nue              VARCHAR2(100);
  perfil_ant              VARCHAR2(100);
  sw_no                   VARCHAR2(1):= 'S';
  w_rowid                 VARCHAR2(100);
  w_entro                 VARCHAR2(1) := 'N';
  -- NUevas variables del api terceros
  P_NumDoc        Naturales.Numero_Documento%type ;
  P_TipDoc        Naturales.TipDoc_Codigo%type:= '';
  P_Secuencia     Naturales.Secuencia%type := null;
  P_SUCURSAL      Sucursales.Numero%type;
  P_PrimerA       varchar2(20);
  P_SegundoA      varchar2(20);
  P_PrimerN       varchar2(20);
  P_SegundoN      varchar2(20);
  P_Razon_Social  Juridicos.razon_social%type;
  P_tipo          Varchar2(2);
  P_desctipo      direcciones.descripcion%type;
  P_Tipodir       direcciones.tipdir_codigo%type := 03;
  P_SecDir        Direcciones.Secuencia%type;
  P_Direccion     Direcciones.Descripcion%type;
  P_Localidad     Division_Politicas.Codigo_Tronador%type;
  P_LocCodazzi    Division_Politicas.Codigo_Codazzi%type;
  P_NomLoca       Division_Politicas.Nombre%type;
  P_Telefono      Medios_Comunicacion.Descripcion%type;
PROCEDURE P_CALCULAR_ID (W_NUMERO   NUMBER,w_tipo   VARCHAR2) IS
w_valor    NUMBER(2);
BEGIN
   w_id_usuario:= w_numero;
END;
PROCEDURE P_INSERTAR_TRAZA IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('INSERTANDO EN TRAZA');
  INSERT INTO TRAZA@psisolus_pnovell_novell.world(PROGRAMA
                 ,PARAMETROS
                  ,TRAZA
                 ,FECHA_REGISTRO
                 )
           VALUES('TRG_ACT_SOLIC_POC'
                 ,''
                 ,TRAZA
                 ,SYSDATE
                 );
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR INSERTANDO EN LA TRAZA '||SQLERRM);
END;
-- Empieza procedimiento principal del Trigger
BEGIN
  w_rowid := :NEW.ROWID;
  IF UPPER(USER) NOT IN ('NOVELL','DIRXML','OPS$NOVELL','OPS$DIRXML',
                 'NOVELL2','OPS$NOVELL2','NOVELL3')
     AND :NEW.ESTADOSOLICITUD <> 'E' AND
      :NEW.codigocategoria NOT IN ('IADCAR04','IADVEN04','IATELV07','IEALIA04'
     ) THEN
    TRAZA := ' ';
    --BUSCO LOS DATOS DE NOMINA
    TRAZA := TRAZA || ' BUSC NOMINA: '|| :NEW.USUXCARXLO_USUARIO_CODIGOINTER
          ||', '||:NEW.LOGIN||', '||:NEW.ESTADOSOLICITUD;
    W_TIPSOL := :NEW.TIPSOL_CODIGO;
    IF ((:NEW.TIPSOL_CODIGO != '2021') OR
        (:NEW.ESTADOSOLICITUD = 'A' AND :NEW.TIPSOL_CODIGO = '2021'))THEN
      -- CEDULA DEL EMPLEADO
      TRAZA := ' BORRANDO INFORMACION DE ANTERIOR ROWID '|| :NEW.ROWID;
      IF :NEW.tipsol_codigo != '2021' THEN
        BEGIN
	  DELETE dirxml.SOLICITUDES@psisolus_pnovell_novell.world
	   WHERE ROW_ID_ORIG = w_rowid;
	  EXCEPTION WHEN OTHERS THEN NULL;
	END;
      END IF;
      DBMS_OUTPUT.PUT_LINE('ENTRANDO A BUSQUEDA:');
      TRAZA := 'ENTRANDO A BUSQUEDA: '
               || :NEW.USUXCARXLO_USUARIO_CODIGOINTER||', '||:NEW.LOGIN;
      BEGIN
        SELECT HVCINTRA_CEDULA
              ,HVPINTRA.HVCINTRA_NOMTRA
              ,RTRIM(LTRIM(HVPINTRA.HVCINTRA_PRIAPE||' '
               ||HVPINTRA.HVCINTRA_SEGAPE))
  	      ,HVCINTRA_TELRES
  	      ,A.NOMBRE
  	      ,A.CONCODIGO
  	      ,HVCINTRA_TIPIDE
  	      ,48
  	      ,'SARH'
  	      ,HVPINTRA.HVCINTRA_CODTRA
  	      ,HVCINTRA_TIPTRA
      	      ,AOCCARES_JEFARE
              ,'S'
          INTO W_CEDULA
    	      ,W_NOMBRE
    	      ,W_APELLIDO
  	      ,W_TELEFONO
  	      ,W_NOMBRE_SISOLUS
  	      ,W_CONCODIGO
  	      ,W_TIPIDE
  	      ,w_codactbenef
  	      ,w_fuente
  	      ,w_numide
  	      ,W_TIPTRA
  	      ,W_JEFARE
              ,sw_no
          FROM HVPINTRA@sisolus_pnomi_nomi.world
  	      ,OPS$SISOLUS.USUARIOS A
  	      ,AOPCARES@sisolus_pnomi_nomi.world
         WHERE (A.NUMIDE = HVPINTRA.HVCINTRA_CODTRA
  	        OR hvpintra.hvcintra_cedula = a.numide)
           AND (   HVCINTRA_retira = DECODE(:NEW.tipsol_codigo,'2041','S','N')
                OR HVCINTRA_retira = DECODE(:NEW.tipsol_codigo,'2041','N','N')
               )
           AND A.CODIGOINTERNO = :NEW.USUXCARXLO_USUARIO_CODIGOINTER
  	   AND HVCINTRA_CARTRA = AOCCARES_CARESP
  	;
        EXCEPTION WHEN NO_DATA_FOUND THEN
  	    -- EMPIEZA LA BUSQUEDA EN SIFVE
        BEGIN
          SELECT HVCINFHV_CEDULA
  	        ,HVCINFHV_PRIAPE||' '||HVCINFHV_SEGAPE
  	        ,NVL(HVCINFHV_NOMTRA,
                     SUBSTR(HVCINFHV_PRIAPE||' '||HVCINFHV_SEGAPE,1,60))
  	        ,HVCINTRA_TELRES
                ,HVCINFHV_NUMIDE
                ,SUBSTR(DECODE(A.HVNINTRA_TIPCON,1
                   ,SUBSTR(A.HVCINTRA_NOMTRA,1,20)
                          ||' '||A.HVCINTRA_PRIAPE,A.HVCINTRA_RAZSOC),1,30)
   	           ,DECODE(A.HVNINTRA_TIPCON,1,'CC','NT')
                   ,2
  	           ,'SIFVE'
  	           ,HVNINTRA_NUMCLA
  	           ,HVNINFHV_TIPCON
  	           ,'G'
                   ,'S'
              INTO W_cedula
  		  ,W_APELLIDO
  		  ,W_NOMBRE
  		  ,W_TELEFONO
  		  ,W_NIT
  		  ,W_RAZSOC
  		  ,W_TIPIDE
  		  ,w_codactbenef
  		  ,w_fuente
  		  ,w_numide
  		  ,W_TIPTRA
  		  ,W_JEFARE
                  ,sw_no
             FROM HVPINFHV@sisolus_psifve_sifv.world
  	         ,HVPINTRA@sisolus_psifve_sifv.world A
  		 ,OPS$SISOLUS.USUARIOS B
            WHERE (HVCINFHV_NUMIDE = B.NUMIDE
  	       OR HVCINFHV_CEDULA =  B.NUMIDE)
           AND (hvcinfhv_estcon = DECODE(:NEW.tipsol_codigo,'2041','AC','AC')
              OR hvcinfhv_estcon = DECODE(:NEW.tipsol_codigo,'2041','RT','AC'))
              AND A.HVCINTRA_CODTRA = HVCINFHV_CODTRA
  	      AND B.CODIGOINTERNO = :NEW.USUXCARXLO_USUARIO_CODIGOINTER;
           EXCEPTION WHEN NO_DATA_FOUND THEN
           BEGIN
             w_entro := 'N';
--              FOR cp IN (SELECT b.cod_benef            codben
--                    ,LTRIM(RTRIM(b.ape_benef,' '),' ') apeben
-- 	           ,LTRIM(RTRIM(b.nom_benef,' '),' ') nomben
-- 	           ,b.tel_benef                       telben
--                    ,a.numide   numide
-- 	           ,LTRIM(RTRIM(b.ape_benef,' '),' ')
--                     ||','||LTRIM(RTRIM(b.nom_benef,' '),' ') nomcom
-- 	           ,b.cod_docum                              coddoc
--   		       ,b.cod_act_benef                          codact
--               FROM OPS$SISOLUS.USUARIOS A
--                   ,a1001300 b
--              WHERE A.codigointerno = :NEW.USUXCARXLO_USUARIO_CODIGOINTER
--                AND a.numide = b.cod_benef
--                AND b.fecha_equipo = (SELECT MAX(c.fecha_equipo)
--                                        FROM a1001300 c
--  	                              WHERE c.cod_benef = b.cod_benef))LOOP
-- 	        W_cedula      := cp.codben;
-- 	        W_APELLIDO    := cp.apeben;
--          W_NOMBRE      := cp.nomben;
-- 	        W_TELEFONO    := cp.telben;
-- 	        W_NIT         := cp.codben;
-- 	        W_RAZSOC      := cp.nomcom;
-- 	        W_TIPIDE      := cp.coddoc;
-- 	        w_codactbenef := cp.codact;
-- 	        w_fuente      := 'TRONADOR';
-- 	        w_numide      := cp.numide;
-- 	        W_TIPTRA      := 'G';
-- 	        W_JEFARE      := 'G';
--                 sw_no         := 'S';
--                 w_entro := 'S';
--               END LOOP;

		begin
		  select a.numide
		    into w_numide
			from OPS$SISOLUS.USUARIOS A
		   where a.CODIGOINTERNO = :NEW.USUXCARXLO_USUARIO_CODIGOINTER;
        		   -----------------
		   P_NumDoc     := w_numide;
                 pck999_terceros.PRC_DATOSD_TERCERO(P_NumDoc  ,
                              P_TipDoc      ,
                              P_Secuencia   ,
                              P_SUCURSAL    ,
                              P_PrimerA     ,
                              P_SegundoA    ,
                              P_PrimerN     ,
                              P_SegundoN    ,
                              P_Razon_Social,
                              P_tipo        ,
                              P_desctipo    ,
                              P_Tipodir     ,
                              P_SecDir      ,
                              P_Direccion   ,
                              P_Localidad   ,
                              P_LocCodazzi  ,
                              P_NomLoca     ,
                              P_Telefono     );
 	        W_cedula      := p_numdoc;
 	        W_APELLIDO    := substr(trim(P_PrimerA ||' ' || P_SegundoA ),1,200);
            W_NOMBRE      := substr(trim(P_PrimerN ||' ' || P_SegundoN ),1,30);
 	        W_TELEFONO    := p_telefono;
 	        W_NIT         := p_numdoc;
 	        W_RAZSOC      := substr(p_razon_social,1,50);
 	        W_TIPIDE      := p_tipdoc;
 	        w_codactbenef := 1;
 	        w_fuente      := 'TRONADOR';
-- 	        w_numide      := p_numdoc;
 	        W_TIPTRA      := 'G';
 	        W_JEFARE      := 'G';
            sw_no         := 'S';
            w_entro := 'S';
          exception when others then
		     sw_no := 'N';
			 w_entro := 'N';
		end;
          IF w_entro = 'N' AND :NEW.sisinf_codigo
                              NOT IN ('TR','PR','CA','SH','SF') THEN
 	        TRAZA := TRAZA ||' NO DATOS EN NOM-TER.';
	    RAISE_APPLICATION_ERROR (-20501,'Error en act. Tabla '||
                  ' Interm.Usuarios, por ' ||traza);
              ELSE
                sw_no:= 'N';
              END IF;
           END;
         END;
      END;
      TRAZA := ' DATOS:'||W_CEDULA||','||W_NOMBRE|| ','||W_APELLIDO||traza;
      TRAZA := ' BUSC.SISOLUS DATOS USUARIO: '||:NEW.CONSECUTIVO||','
               ||:OLD.TIPSOL_CODIGO || ','||:OLD.USUXCARXLO_USUARIO_CODIGOINTER
               ||','||:OLD.USUXCARXLO_CODIGOLOCALIDAD||','
               ||:OLD.USUXCARXLO_CARGO_CODIGO||','||:OLD.SISINF_CODIGO
               || ','|| :OLD.CODIGOCATEGORIA|| ',' ||:OLD.LOGIN ||traza;
      -- INSERTO EL USUARIO
      TRAZA := ' INSERTANDO EN USUARIOS:'||W_NOMBRE||'-'||W_APELLIDO||'-'
               ||W_TELEFONO||'-'||W_NOMBRE_SISOLUS||'-'
               ||W_LOCALIDAD||' - '||W_CARGO||traza;
	  DBMS_OUTPUT.PUT_LINE('adsfasdfasdfasdfasd');
      IF sw_no = 'S' THEN
      BEGIN
        -- VERIFICA SI USR EXISTE CON
        SELECT TO_NUMBER(ID_USUA_UNIQUE)
          INTO W_ID_USUARIO
          FROM USUARIOS@psisolus_pnovell_novell.world
         WHERE CEDULA = NVL(W_NIT,W_CEDULA) ;
   	EXCEPTION WHEN TOO_MANY_ROWS THEN
  	  RAISE_APPLICATION_ERROR (-20503,'Muchas tuplas para: '||w_cedula);
	  WHEN NO_DATA_FOUND THEN
   	  BEGIN
            P_CALCULAR_ID (NVL(W_NIT,W_CEDULA),w_tipide);
   	    TRAZA := ' INSERTA EL REGISTRO :' || W_ID_USUARIO;
            INSERT INTO USUARIOS@psisolus_pnovell_novell.world
                                (ID_USUA_UNIQUE
                                ,FNAME
               		        ,LNAME
               			,DISABLED
               			,PHONENO
               			,NUMIDE
               			,NOMBREEMPLEADO
               			,CODIGOLOCALIDAD
               			,CARGO_CODIGO
   				,LOGIN
   				,FUENTEUSUARIO
   				,tipo_identificacion
   				,cod_act_benef
   				,cedula
                		)
       		         VALUES (W_ID_USUARIO
                   		,SUBSTR(NVL(w_razsoc,W_NOMBRE),1,64)
       				,SUBSTR(W_APELLIDO,1,64)
       				,0
       				,W_TELEFONO
                                ,DECODE(w_numide,w_cedula,NULL,w_numide)
       				,SUBSTR(W_NOMBRE||' '||w_apellido,1,60)
       				,:NEW.USUXCARXLO_CODIGOLOCALIDAD
       				,:NEW.USUXCARXLO_CARGO_CODIGO
   				,:NEW.LOGIN
   				,w_fuente
   				,w_TIPIDE
   				,w_codactbenef
   				,NVL(w_nit,w_cedula)
   				);
       	  END;
      END;
    -- AHORA INSERTA LA SOLICITUD CON EL NUMERO DE W_ID_USUARIO
--      traza := traza ||' inserta en solicitudes '||:new.consecutivo;
      -- Establece estado solic. de acuerdo a la parametrizacion de la tabla
      --  dirxml.reglas_sisolus
      BEGIN
	SELECT dirxml.seq_solno.NEXTVAL@psisolus_pnovell_novell.world
              ,dirxml.fdir_estado_solicitud@psisolus_pnovell_novell.world
                                           (:NEW.USUXCARXLO_CARGO_CODIGO
	                                   ,:NEW.SISINF_CODIGO
                                           ,:NEW.USUXCARXLO_CODIGOLOCALIDAD
		                           ,:NEW.CODIGOCATEGORIA
				           ,w_tipsol
                                           ,W_TIPTRA
                                           ,W_JEFARE
                                           ,W_FUENTE)
          INTO w_seqsol,w_estado_solicitud
	  FROM dual;
      END;
--traza := 'Traza:  seguimiento de prueba '||w_seqsol||' - '
-- ||w_estado_solicitud||' - '||:new.rowid ;
      INSERT INTO dirxml.SOLICITUDES@psisolus_pnovell_novell.world
                                    (NUMSOLICITUD
		                    ,CODIGOCATEGORIA
  				    ,TIPSOL
				    ,EGL
				    ,SISINF_CODIG
				    ,OBSERVACIONES
				    ,FUENTESOLICITUD
				    ,ID_USUA_UNIQUE
				    ,ROW_ID_ORIG
				    ,rolorg)
		             VALUES (w_seqsol
			            ,:NEW.CODIGOCATEGORIA
				    ,W_TIPSOL
			            ,NVL(w_estado_solicitud
                                        ,:NEW.ESTADOSOLICITUD)
                                    ,DECODE(w_tipsol,'2021'
                                    ,SUBSTR(:NEW.observaciones,1,10)
                                    ,:NEW.SISINF_CODIGO)
                                    ,w_seqsol || ','||
				     W_TIPSOL || ',' ||
				     NVL(w_estado_solicitud
                                        ,:NEW.ESTADOSOLICITUD) || ',' ||
				     :NEW.sisinf_codigo || ',' ||
				     'SISOLUS'|| ',' ||
				     :NEW.CODIGOCATEGORIA || ',' ||
				     :NEW.login||'##'
				    ,'SISOLUS'
				    ,W_ID_USUARIO
				    ,w_rowid
				    ,:NEW.login
				    );
	END IF;
    END IF;
  END IF;
  EXCEPTION WHEN OTHERS THEN
    TRAZA:= TRAZA || ' ' ||SQLERRM||' '||SQLCODE;
--  P_INSERTAR_TRAZA;
    RAISE_APPLICATION_ERROR (-20503,'Error Tab.Int.Usu:'||SQLCODE||' '
                            ||tRAZA);
END;
/
