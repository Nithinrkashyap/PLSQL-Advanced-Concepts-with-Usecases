CREATE OR REPLACE TRIGGER trg_emp_salary_validate
BEFORE UPDATE OF salary ON employee
FOR EACH ROW
BEGIN
  IF :NEW.salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative.');
  END IF;

  IF :NEW.salary < NVL(:OLD.salary, 0) * 0.5 THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'Salary cannot decrease by more than 50%.'
    );
  END IF;
END;
/