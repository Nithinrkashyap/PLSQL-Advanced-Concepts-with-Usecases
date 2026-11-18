-- Requires table: employee (see Triggers/indx1.sql)

CREATE OR REPLACE VIEW v_employee_summary AS
SELECT empid,
       name,
       salary
FROM employee
WHERE salary IS NOT NULL;

-- Example: SELECT empid, name FROM v_employee_summary WHERE salary > 50000;