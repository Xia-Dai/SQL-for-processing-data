SELECT P.PROV_DESC,
       P.CITY_DESC,
       P.KPI_NAME,
       P.UNIT,
       P.ATTR,
       P.CITY_ORD,
       P.ID,
       P.KPI_CODE,
       A.KPI_VALUE KPI_M,
       CASE
         WHEN A.KPI_VALUE IS NULL AND A.KPI_VALUE_LM IS NULL THEN
          NULL
         ELSE
          NVL(A.KPI_VALUE, 0) - NVL(A.KPI_VALUE_LM, 0)
       END KPI_JZ,
       ROUND(DECODE(A.KPI_VALUE_LM,
                    NULL,
                    NULL,
                    0,
                    NULL,
                    NVL(A.KPI_VALUE, 0) / A.KPI_VALUE_LM - 1),
             6) KPI_HB,
       CASE
         WHEN A.KPI_VALUE IS NULL AND A.KPI_VALUE_LYL IS NULL THEN
          NULL
         ELSE
          NVL(A.KPI_VALUE, 0) - NVL(A.KPI_VALUE_LYL, 0)
       END KPI_LJZ,
       ROUND(DECODE(A.KPI_VALUE_LY,
                    NULL,
                    NULL,
                    0,
                    NULL,
                    NVL(A.KPI_VALUE, 0) / A.KPI_VALUE_LY - 1),
             6) KPI_TB
  FROM (SELECT T.KPI_CODE,
               DECODE(PROV_ID, '111', '-1', PROV_ID) PROV_ID,
               AREA_NO CITY_NO,
               SUM(DECODE(ACCT_DATE, MONTH_C, ROUND(TO_NUMBER(KPI_VALUE)))) KPI_VALUE,
               SUM(DECODE(ACCT_DATE, MONTH_LM, ROUND(TO_NUMBER(KPI_VALUE)))) KPI_VALUE_LM,
               SUM(DECODE(ACCT_DATE, MONTH_LYL, ROUND(TO_NUMBER(KPI_VALUE)))) KPI_VALUE_LYL,
               SUM(DECODE(ACCT_DATE, MONTH_LY, ROUND(TO_NUMBER(KPI_VALUE)))) KPI_VALUE_LY
          FROM DM.DM_RPT_M_DATA_APP_MANUAL T,
               (SELECT MONTH_C,
                       TO_CHAR(ADD_MONTHS(TO_DATE(MONTH_C, 'yyyymm'), -1),
                               'yyyymm') MONTH_LM,
                       SUBSTR(MONTH_C, 1, 4) - 1 || '12' MONTH_LYL,
                       TO_CHAR(ADD_MONTHS(TO_DATE(MONTH_C, 'yyyymm'), -12),
                               'yyyymm') MONTH_LY
                  FROM (SELECT '201603' MONTH_C FROM DUAL)) C,
               ZB_DM.DECODE_TXNLM_2013 D
         WHERE T.KPI_CODE = D.KPI_CODE
           AND T.FILE_CODE = 'TXNLYB'
           AND ACCT_DATE IN
               ('201603',
                TO_CHAR(ADD_MONTHS(TO_DATE('201603', 'yyyymm'), -1), 'yyyymm'),
                SUBSTR('201603', 1, 4) - 1 || '12',
                TO_CHAR(ADD_MONTHS(TO_DATE('201603', 'yyyymm'), -12),
                        'yyyymm'))
         GROUP BY PROV_ID, AREA_NO, T.KPI_CODE) A,
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
                  FROM DUAL) A,
               ZB_DM.DECODE_TXNLM_2013 B) P
 WHERE A.PROV_ID(+) = P.PROV_ID
   AND A.CITY_NO(+) = P.CITY_ID
   AND A.KPI_CODE(+) = P.KPI_CODE
   AND (P.PROV_ID = '-1' AND P.PROV_DESC = '全国')
 ORDER BY P.ORD, P.CITY_ORD, P.ID
