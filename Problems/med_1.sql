-- Description
-- You are given an employee table. Each row is one employee.
-- Return department name, employee name, and salary for every employee whose salary is among the top 3 unique salaries in that department.

-- “Top 3” means the three largest distinct salary values in the department (not “third row only”).
-- If a department has fewer than 3 distinct salaries, include everyone in those ranks.
-- If several employees share a salary that counts in the top 3, include all of them.
-- Sort result by department name, then salary descending, then emp



CREATE TABLE department1 (
    id   NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL
);

CREATE TABLE employee1 (
    id            NUMBER PRIMARY KEY,
    name          VARCHAR2(100) NOT NULL,
    salary        NUMBER(10, 2) NOT NULL,
    department_id NUMBER NOT NULL,
    CONSTRAINT emp1_dept_fk
        FOREIGN KEY (department_id) REFERENCES department1(id)
);

-- Departments (3 rows)
INSERT INTO department1 (id, name) VALUES (1, 'HR');
INSERT INTO department1 (id, name) VALUES (2, 'IT');
INSERT INTO department1 (id, name) VALUES (3, 'Sales');

-- Employees (10 rows)
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 1, 'Alice',  60000.00, 1);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 2, 'Bob',    60000.00, 1);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 3, 'Carol',  55000.00, 1);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 4, 'Dan',    40000.00, 1);

INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 5, 'Eve',    90000.00, 2);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 6, 'Frank',  90000.00, 2);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 7, 'Grace',  50000.00, 2);

INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 8, 'Henry', 100000.00, 3);
INSERT INTO employee1 (id, name, salary, department_id) VALUES ( 9, 'Ivan',   95000.00, 3);
INSERT INTO employee1 (id, name, salary, department_id) VALUES (10, 'Jane',   80000.00, 3);

COMMIT;


--!CTE
WITH RANKED AS (

SELECT 

d.name department_name,
e.name emp_name,
e.SALARY salary,

DENSE_RANK()
 
 OVER
(PARTITION BY e.DEPARTMENT_ID
ORDER BY e.SALARY DESC
)
AS Sal_rank

FROM 
EMPLOYEE1 e

join 
DEPARTMENT1 d 

ON d.id = e.DEPARTMENT_ID





)

SELECT 

department_name,
emp_name,
salary

FROM RANKED 

where Sal_rank <=3

;

