--REPORT 1
--Report showing details(Name,Email,Experience) of Sales Supervisors for TOP 3 and BOTTOM 3 Revenue generating Projects
--This report helps in analyzing the Employees' performance (based on revneue brought to the company)

SELECT first_name
  || ' '
  || last_name AS "EMPLOYEE NAME",
  email,
  job_id,
  TRUNC((SYSDATE-pe.HIRE_DATE)/365)|| ' years ' AS experience,
  'TOP 3'                                   AS "EMPLOYEE RANK"
FROM (SELECT SALESREP_ID,
      SUM(agreed_budget) AS "REVENUE"
    FROM project  
    WHERE status='Completed'
    GROUP BY SALESREP_ID
    ORDER BY SUM(agreed_budget) DESC
    ) p
	JOIN project_employee pe
ON p.SALESREP_ID    =pe.EMPLOYEE_ID
  WHERE rownum<=3
UNION
SELECT first_name
  || ' '
  || last_name AS "employee name",
  email,
  job_id,
  TRUNC((SYSDATE-pe.HIRE_DATE)/365)|| ' years ' AS experience ,
  'BOTTOM 3'                                AS "EMPLOYEE RANK"
FROM (SELECT SALESREP_ID,
      SUM(agreed_budget) AS "REVENUE"
    FROM project  
    WHERE status='Completed'
    GROUP BY SALESREP_ID
    ORDER BY SUM(agreed_budget) ASC
    ) p
	JOIN project_employee pe
ON p.SALESREP_ID   =pe.EMPLOYEE_ID
  WHERE rownum<=3
ORDER BY "EMPLOYEE RANK" DESC;



--REPORT 2
--Report showing Priority tasks for a factory. By prioritizing, overall delivery time is reduced considerably.
/*Tasks are ranked based on the Project deadline and priority of the products within a project. 
  Tasks with equal priority are ranked the same */
--Model specifications of Elevator/Escalator are also provided in the report.This acts as a priority list.

SELECT pd.project_id,
  p.deadline,
  RANK() OVER (Partition BY NULL order by p.deadline,pd.priority ASC) AS "FACTORY PRIORITY",
  pd.MODEL_ID,
  pd.QUANTITY,
  (
  CASE
    WHEN pd.MODEL_CATEGORY='E'
    THEN 'Elevator'
    ELSE 'Escalaltor'
  END) "MODEL CATEGORY",
  pd.CAPACITY,
  pd.STATUS,
  NVL(TO_CHAR(pde.BREADTH),'Not Applicable')  as Breadth,
  NVL(TO_CHAR(pde.HEIGHT),'Not Applicable') as Height,
  NVL(TO_CHAR(pde.LENGTH),'Not Applicable') as Length,
  NVL(TO_CHAR(pde.MAX_RISE),'Not Applicable') as Max_rise,
  NVL(TO_CHAR(pde.MAX_SPEED),'Not Applicable') as Max_speed,
  NVL(TO_CHAR(pde.DOOR_TYPE),'Not Applicable') as Door_type,
  NVL(TO_CHAR(pds.VELOCITY),'Not Applicable') as Velocity,
  NVL(TO_CHAR(pds.ANGLE),'Not Applicable') as Angle,
  NVL(TO_CHAR(pds.STEP_WIDTH),'Not Applicable') as Step_width
FROM project p
JOIN project_details pd
ON (p.project_id=pd.project_id)
FULL OUTER JOIN PROJECT_DETAILS_ELEVATOR pde
ON (pd.project_id=pde.project_id
AND pd.model_id  =pde.MODEL_ID)
FULL OUTER JOIN PROJECT_DETAILS_ESCALATOR pds
ON (pd.project_id=pds.project_id
AND pd.model_id  =pds.MODEL_ID)
WHERE p.status!  ='Completed'
ORDER BY p.deadline,
  pd.priority; 
  
 
--REPORT 3
--Report to show products ordered by Sales for each quarter of an year.
--This reports helps in identifying top selling produts and also analyze sales trends across quarters.

SELECT Year,Quarter,
  model_name,
  SUM(quantity) AS "TOTAL SALES"
FROM
  (SELECT pd.model_id,
    pc.model_name,
    pc.model_category,
    pd.quantity,
    TO_CHAR(p.start_date,'YYYY')AS Year,
    TO_CHAR(p.start_date,'Q')AS Quarter
  FROM project p
  JOIN project_details PD
  ON p.project_id=pd.project_id
  JOIN product_config PC
  ON pd.model_id=pc.model_id
  )
GROUP BY model_name,Quarter,Year
ORDER BY 1,2,4 DESC;


--REPORT 4
-- A bill contains time,cost,product details for a given Customer.
--Query to generate a Bill for a Customer after a project is completed
--Customer Id is a substitution variable and needs to be provided real time. 
--Below  are few sample Customer Ids
--Customer Ids
--1001
--1005

SELECT DECODE(MOD(a.row#,7) ,1, 'Client Name: '
  ||b.client_name ,2, 'Address: '
  ||b.street_name ,3, 'City: '
  ||b.city,4,'State: '
  ||b.state,5,'Cost :'
  ||TO_CHAR(b.actual_budget,'fm$9,999,999.00'),6,'Start Date :'
  ||b.start_Date,0,'End Date :'
  ||b.end_Date) AS "Bill"
FROM
  (SELECT client_name,
    street_name,
    city,
    state,
    actual_budget,
    start_date,
    end_Date
  FROM Project p
  JOIN client c
  ON p.CLIENT_ID    =c.CLIENT_ID
  WHERE c.CLIENT_ID =
   &&client_id
  AND status LIKE 'Completed'
  ) b,
  (SELECT rownum AS row# FROM USER_OBJECTS WHERE rownum < 8
  ) a
union all
SELECT 'PRODUCT DETAILS' FROM dual
UNION ALL
SELECT
  CASE
    WHEN pd.model_category LIKE 'E'
    THEN 'Elevator'
    ELSE 'Escalator'
  END
  || ' - Quantity:' ||COUNT(1)
  || ' ; Model Name:'
  ||LISTAGG(pc.MODEL_name,',') WITHIN GROUP (
ORDER BY pd.model_category DESC)
  || ' ; Model Number:'
  ||LISTAGG(pc.MODEL_id,',') WITHIN GROUP (
ORDER BY pd.model_category DESC)
FROM Project p
JOIN project_details pd on p.project_id=pd.project_id
JOIN PRODUCT_CONFIG pc on pd.model_id=pc.model_id
WHERE p.status LIKE 'C%'
AND p.client_id=&client_id
GROUP BY pd.model_category;

--To reset the substitution variable.Use of && stores values of the substitution variable
undefine client_id