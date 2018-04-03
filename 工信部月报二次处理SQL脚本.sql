SELECT '201603',
       '089',
       P.PROV_DESC,
       T.KPI_CODE,
       T.KPI_NAME,
       T.ID,
       SUM(CASE
             WHEN T.KPI_CODE IN ('AA1011_AS', 'AC5500_AS', 'AC5600_AS') AND
                  T.PROV_ID = '091' THEN --辽宁
              T3.KPI_VALUE
             WHEN T.KPI_CODE = 'AA1000_AS' AND T.PROV_ID = '091' THEN --辽宁
              TT.KPI_VALUE
             WHEN T.KPI_CODE = 'AC6177' THEN
              NVL(T.KPI_VALUE, 0) - NVL(T2.TOTAL_NUM, 0)
             WHEN T.PROV_ID = '999' AND T.ID <= 8 THEN --总部及其他处理为0
              0
             ELSE
              T.KPI_VALUE
           END) KPI_VALUE
  FROM (SELECT '201603' MONTH_ID,
               '089' PROV_ID,
               A.KPI_CODE,
               A.KPI_NAME,
               A.UNIT,
               A.ID,
               T.KPI_VALUE
          FROM (SELECT *
                  FROM DM_RPT_M_TELECOM_TOTAL
                 WHERE RPT_CODE = '02'
                   AND MONTH_NO = '201603'
                   AND PROV_ID = '089'
                   AND CITY_NO = '-1'
                   AND KPI_VALUE IS NOT NULL) T,
               DECODE_CW_GXBM_2013 A
         WHERE A.KPI_CODE = T.KPI_CODE(+)) T,
       (SELECT PROV_ID, KPI_CODE, SUM(KPI_VALUE) KPI_VALUE
          FROM (SELECT PROV_ID,
                       'AA1000_AS' KPI_CODE,
                       SUM(KPI_VALUE) KPI_VALUE
                  FROM DM_RPT_M_TELECOM_TOTAL
                 WHERE RPT_CODE = '02'
                   AND MONTH_NO = '201603'
                   AND CITY_NO = '-1'
                   AND KPI_CODE IN
                       ('AA1012_AS', 'AA1013', 'AA1021', 'AA1022', 'AA1023')
                   AND KPI_VALUE IS NOT NULL
                 GROUP BY PROV_ID
                UNION ALL
                SELECT PROV_ID, 'AA1000_AS' KPI_CODE, KPI_VALUE
                  FROM TEMP_GXB_LN_IMP_NEW
                 WHERE MONTH_ID = '201603'
                   AND KPI_CODE = 'AA1011')
         GROUP BY PROV_ID, KPI_CODE) TT, --辽宁AA1000_AS合计手工处理
       (SELECT * FROM GXB_1454_1457_IMP WHERE MONTH_ID = '201603') T2, --1454/1457提取数据
       (SELECT PROV_ID, KPI_CODE || '_AS' KPI_CODE, KPI_NAME, KPI_VALUE
          FROM TEMP_GXB_LN_IMP_NEW
         WHERE MONTH_ID = '201603'
           AND KPI_CODE IN ('AA1011', 'AC5500', 'AC5600')) T3, --辽宁手工填报数据
       (SELECT KPI_ORD,
               CASE
                 WHEN KPI_NAME = '销项税总额' THEN
                  'CR0000'
                 WHEN KPI_NAME = '进项税总额' THEN
                  'CS0000'
                 ELSE
                  KPI_CODE
               END KPI_CODE_NEW,
               KPI_NAME,
               KPI_VALUE
          FROM TEMP_GXB_STATD_IMP_NEW
         WHERE MONTH_ID = '201603'
           AND PROV_ID = '089') T4, --本年实际
       (SELECT CASE
                 WHEN KPI_NAME = '销项税总额' THEN
                  'CR9000'
                 WHEN KPI_NAME = '进项税总额' THEN
                  'CS9000'
                 WHEN KPI_CODE IS NOT NULL THEN
                  SUBSTR(KPI_CODE, 1, 2) || '9' || SUBSTR(KPI_CODE, 4)
               END KPI_CODE_NEW,
               KPI_VALUE
          FROM TEMP_GXB_STATD_IMP_NEW
         WHERE MONTH_ID =
               TO_CHAR(ADD_MONTHS(TO_DATE('201603', 'YYYYMM'), -12),
                       'YYYYMM')
           AND PROV_ID = '089') T5, --上年实际
       DIM_PROV P
 WHERE T.PROV_ID = P.PROV_ID(+)
   AND P.PROV_DESC = T2.PROV_DESC(+)
   AND T.PROV_ID = T3.PROV_ID(+)
   AND T.KPI_CODE = T3.KPI_CODE(+)
   AND T.KPI_CODE = T4.KPI_CODE_NEW(+)
   AND T.KPI_CODE = T5.KPI_CODE_NEW(+)
   AND T.KPI_CODE = TT.KPI_CODE(+)
   AND T.PROV_ID = TT.PROV_ID(+)
 GROUP BY T.MONTH_ID, T.PROV_ID, P.PROV_DESC, T.ID, T.KPI_CODE, T.KPI_NAME
 ORDER BY T.ID
