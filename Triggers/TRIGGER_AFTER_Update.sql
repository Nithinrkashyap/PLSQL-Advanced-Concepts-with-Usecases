CREATE OR REPLACE TRIGGER trg_emp_salary_audit
AFTER UPDATE OF salary ON employee
FOR EACH ROW
WHEN (NVL(OLD.salary, -1) <> NVL(NEW.salary, -1))
BEGIN
  INSERT INTO employee_salary_audit (
      empid,
      old_salary,
      new_salary
  )
  VALUES (
      :OLD.empid,
      :OLD.salary,
      :NEW.salary
  );
  -- changed_by, changed_at use table defaults (USER, SYSDATE)
END;
/