CREATE TABLE employee (
    empid  NUMBER        NOT NULL,
    name   VARCHAR2(100),
    salary NUMBER(10, 2),
    CONSTRAINT employee_pk PRIMARY KEY (empid)
);

INSERT INTO employee (empid, name, salary)
SELECT LEVEL,
       'Employee ' || TO_CHAR(LEVEL),
       ROUND(40000 + (LEVEL * 250.75), 2)
FROM   dual
CONNECT BY LEVEL <= 100;

COMMIT;

