CREATE OR REPLACE TRIGGER TRG_AIUD_R_C9999909
  after insert or update or delete on C9999909
  for each row
declare
v_ope varchar2(3) := null;
begin
 IF     DELETING  THEN v_ope := 'DEL';
  ELSIF UPDATING  THEN v_ope := 'UPD';
  ELSIF INSERTING THEN v_ope := 'INS';
  ELSE  V_OPE :='ERR';
 END IF;

  IF UPDATING OR INSERTING THEN
   insert into C9999909_jn (
  JN_OPERATION     ,JN_ORACLE_USER      ,JN_DATETIME         ,JN_NOTES
  ,JN_APPLN        ,JN_SESSION          ,COD_TAB             ,COD_RAMO
  ,COD_SECC        ,COD_CIA             ,FECHA_ACT           ,CODIGO
  ,CODIGO1         ,CODIGO2             ,DAT_OBS             ,DAT_CAR
  ,DAT_NUM         ,COD_CAMPO           ,RANGO1              ,RANGO2
  ,RANGO3          ,USUARIO             ,FECHA_BAJA          ,FECHA_ALTA
  ,DAT_OBS2        ,RANGO4              ,COD_AGENCIA         ,DAT_CAR2
  ,DAT_CAR3        ,DAT_CAR4            )
  values      (
  v_ope            , user               , sysdate           ,NULL
  ,NULL            ,NULL                ,:new.COD_TAB       ,:new.COD_RAMO
  ,:new.COD_SECC   ,:new.COD_CIA        ,:new.FECHA_ACT     ,:new.CODIGO
  ,:new.CODIGO1    ,:new.CODIGO2        ,:new.DAT_OBS       ,:new.DAT_CAR
  ,:new.DAT_NUM    ,:new.COD_CAMPO      ,:new.RANGO1        ,:new.RANGO2
  ,:new.RANGO3     ,:new.USUARIO        ,:new.FECHA_BAJA    ,:new.FECHA_ALTA
  ,:new.DAT_OBS2   ,:new.RANGO4         ,:new.COD_AGENCIA   ,:new.DAT_CAR2
  ,:new.DAT_CAR3   ,:new.DAT_CAR4            )        ;

  ELSIF DELETING THEN
  insert into C9999909_jn (
  JN_OPERATION     ,JN_ORACLE_USER      ,JN_DATETIME         ,JN_NOTES
  ,JN_APPLN        ,JN_SESSION          ,COD_TAB             ,COD_RAMO
  ,COD_SECC        ,COD_CIA             ,FECHA_ACT           ,CODIGO
  ,CODIGO1         ,CODIGO2             ,DAT_OBS             ,DAT_CAR
  ,DAT_NUM         ,COD_CAMPO           ,RANGO1              ,RANGO2
  ,RANGO3          ,USUARIO             ,FECHA_BAJA          ,FECHA_ALTA
  ,DAT_OBS2        ,RANGO4              ,COD_AGENCIA         ,DAT_CAR2
  ,DAT_CAR3        ,DAT_CAR4            )
  values      (
  v_ope            , user               , sysdate           ,NULL
  ,NULL            ,NULL                ,:OLD.COD_TAB       ,:OLD.COD_RAMO
  ,:OLD.COD_SECC   ,:OLD.COD_CIA        ,:OLD.FECHA_ACT     ,:OLD.CODIGO
  ,:OLD.CODIGO1    ,:OLD.CODIGO2        ,:OLD.DAT_OBS       ,:OLD.DAT_CAR
  ,:OLD.DAT_NUM    ,:OLD.COD_CAMPO      ,:OLD.RANGO1        ,:OLD.RANGO2
  ,:OLD.RANGO3     ,:OLD.USUARIO        ,:OLD.FECHA_BAJA    ,:OLD.FECHA_ALTA
  ,:OLD.DAT_OBS2   ,:OLD.RANGO4         ,:OLD.COD_AGENCIA   ,:OLD.DAT_CAR2
  ,:OLD.DAT_CAR3   ,:OLD.DAT_CAR4            )        ;     END IF;
end;
/
