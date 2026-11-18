DECLARE
    CURSOR c_emp IS
        SELECT empid, name, salary
        FROM   employee
        WHERE  salary IS NULL OR salary < 30000;

    v_old_salary employee.salary%TYPE;
    v_new_salary employee.salary%TYPE;
    v_count      NUMBER := 0;
BEGIN
  FOR rec IN c_emp LOOP
        v_old_salary := rec.salary;
        v_new_salary := 30000;

        UPDATE employee
        SET    salary = v_new_salary
        WHERE  empid = rec.empid;

        IF SQL%ROWCOUNT = 1 THEN
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE(
                'Employee ' || rec.empid || ' - ' || rec.name ||
                ': ' || NVL(TO_CHAR(v_old_salary), 'NULL') ||
                ' -> ' || TO_CHAR(v_new_salary)
            );
        END IF;
    END LOOP;

    FOR rec IN (SELECT empid, name, salary FROM employee WHERE salary >= 50000) LOOP
        v_old_salary := rec.salary;
        v_new_salary := ROUND(rec.salary * 1.10, 2);

        UPDATE employee
        SET    salary = v_new_salary
        WHERE  empid = rec.empid;

        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(
            'Employee ' || rec.empid || ' - ' || rec.name ||
            ': ' || TO_CHAR(v_old_salary) || ' -> ' || TO_CHAR(v_new_salary)
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total employees updated: ' || v_count);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/