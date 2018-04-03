SELECT B.PROV_DESC,
       B.INCLUDE_CBSS,
       B.CITY_DESC,
       B.KPI_NAME,
       B.UNIT,
       B.CITY_ORD,
       B.ID,
       B.KPI_CODE,
       A.KPI_VALUE, --页面添加四舍五入
       A.KPI_VALUE_LM,
       CASE
         WHEN A.KPI_VALUE IS NULL AND A.KPI_VALUE_LM IS NULL THEN
          NULL
         ELSE
          NVL(A.KPI_VALUE, 0) - NVL(A.KPI_VALUE_LM, 0)
       END KPI_VALUE_JZ,
       ROUND(DECODE(A.KPI_VALUE_LM,
                    0,
                    NULL,
                    A.KPI_VALUE / A.KPI_VALUE_LM - 1),
             4) KPI_VALUE_HB
  FROM (SELECT T.KPI_CODE,
               DECODE(PROV_ID, '111', '-1', PROV_ID) PROV_ID,
               CITY_NO,
               SUM(DECODE(MONTH_NO, MONTH_C, KPI_VALUE, 0)) KPI_VALUE,
               SUM(DECODE(MONTH_NO, MONTH_LM, KPI_VALUE, 0)) KPI_VALUE_LM
          FROM DM.DM_RPT_M_TELECOM_TOT_AFTER T,
               (SELECT MONTH_C,
                       TO_CHAR(ADD_MONTHS(TO_DATE(MONTH_C, 'yyyymm'), -1),
                               'yyyymm') MONTH_LM
                  FROM (SELECT '201603' MONTH_C FROM DUAL)),
               ZB_DM.DECODE_CW_GXBM_2013 D
         WHERE T.KPI_CODE = D.KPI_CODE
           AND T.KPI_CODE <> 'AC8210'
           AND RPT_CODE = '02'
           AND MONTH_NO IN
               ('201603',
                TO_CHAR(ADD_MONTHS(TO_DATE('201603', 'yyyymm'), -1), 'yyyymm'))
         GROUP BY PROV_ID, CITY_NO, T.KPI_CODE) A,
       (SELECT *
          FROM (SELECT B.PROV_ID,
                       PROV_DESC,
                       ORD,
                       CITY_DESC,
                       CITY_ID,
                       CITY_ORD
                  FROM DM_DIM.DIM_PROVINCE B, ZB_DM.V_DIM_AREA C
                 WHERE B.PROV_ID = C.PROV_ID
                UNION ALL
                SELECT PROV_ID, PROV_DESC, ORD, PROV_DESC, '-1', '-1'
                  FROM DM_DIM.DIM_PROVINCE
                UNION ALL
                SELECT '-1' PROV_ID,
                       '全国' PROV_DESC,
                       0 ORD,
                       '全国',
                       '-1',
                       '-1'
                  FROM DUAL
                UNION ALL
                SELECT '999' PROV_ID,
                       '总部及其他' PROV_DESC,
                       41 ORD,
                       '总部及其他',
                       '-1',
                       '-1'
                  FROM DUAL
                UNION ALL
                SELECT '222' PROV_ID,
                       '国际业务部' PROV_DESC,
                       42 ORD,
                       '国际业务部',
                       '-1',
                       '-1'
                  FROM DUAL
                UNION ALL
                SELECT '333' PROV_ID,
                       '运维部' PROV_DESC,
                       43 ORD,
                       '运维部',
                       '-1',
                       '-1'
                  FROM DUAL),
               ZB_DM.DECODE_CW_GXBM_2013) B
 WHERE B.PROV_ID = A.PROV_ID(+)
   AND B.CITY_ID = A.CITY_NO(+)
   AND B.KPI_CODE = A.KPI_CODE(+)
   AND (B.PROV_ID = '-1' AND B.PROV_DESC = '全国')
   
 ----DM表来源：
 ZBA_DMA.DM_RPT_M_TELECOM_TOT_AFTER
 --DMA 来源表

 INSERT /*+APPEND*/
      INTO ZBA_DMA.DM_RPT_M_TELECOM_TOT_AFTER NOLOGGING
        SELECT /*+PARALLEL(T,4)*/
         V_ACCT_MONTH MONTH_ID,
         DEPT_CODE AS PROV_ID,
         '-1' CITY_NO,
         T.KPI_CODE,
         B.KPI_ORDER,
         '02',
         T.KPI_VALUE
          FROM ZBA_DMA.DM_RPT_M_DATA_INTE_MANUAL T, DMCODE_STAT_KPI_LIB B
         WHERE T.KPI_CODE = B.KPI_CODE(+)
           AND B.KPI_ORDER IS NOT NULL
           AND T.RECORD_TYPE = '1'
           AND T.FILE_CODE = 'GXBTJYB'
           AND T.KPI_CODE <> 'AC8210'
           AND T.MONTH_ID = V_ACCT_MONTH
           AND T.DEPT_CODE = V_PROVID.PROV_ID;
      COMMIT;
      INSERT /*+APPEND*/
      INTO ZBA_DMA.DM_RPT_M_TELECOM_TOT_AFTER NOLOGGING
        SELECT /*+PARALLEL(T,4)*/
         V_ACCT_MONTH MONTH_ID,
         T.PROV_ID,
         T.CITY_NO,
         T.KPI_CODE,
         B.KPI_ORDER  AS KPI_ORD,
         T.RPT_CODE,
         T.KPI_VALUE
          FROM ZBA_DMA.DM_RPT_M_TELECOM_TOTAL T, DMCODE_STAT_KPI_LIB B
         WHERE T.KPI_CODE = B.KPI_CODE(+)
           AND T.MONTH_ID = V_ACCT_MONTH
           AND T.RPT_CODE = '02' ---工信部
           AND B.KPI_ORDER IS NOT NULL
           AND T.KPI_CODE <> 'AC8210'
           AND T.PROV_ID = V_PROVID.PROV_ID
           AND T.CITY_NO <> '-1';
      COMMIT;
      --单独处理AC8210
      INSERT /*+APPEND*/
      INTO ZBA_DMA.DM_RPT_M_TELECOM_TOT_AFTER NOLOGGING
        SELECT /*+PARALLEL(T,4)*/
         V_ACCT_MONTH MONTH_ID,
         T.PROV_ID,
         T.CITY_NO,
         T.KPI_CODE,
         B.KPI_ORDER  AS KPI_ORD,
         T.RPT_CODE,
         T.KPI_VALUE
          FROM ZBA_DMA.DM_RPT_M_TELECOM_TOTAL T, DMCODE_STAT_KPI_LIB B
         WHERE T.KPI_CODE = B.KPI_CODE(+)
           AND T.MONTH_ID = V_ACCT_MONTH
           AND T.RPT_CODE = '02' ---工信部
           AND B.KPI_ORDER IS NOT NULL
           AND T.KPI_CODE = 'AC8210'
           AND T.PROV_ID = V_PROVID.PROV_ID
           AND T.CITY_NO = '-1';
      COMMIT;
