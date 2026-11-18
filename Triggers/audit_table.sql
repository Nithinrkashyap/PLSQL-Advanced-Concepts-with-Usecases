CREATE TABLE employee_salary_audit (
    audit_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empid        NUMBER        NOT NULL,
    old_salary   NUMBER(10, 2),
    new_salary   NUMBER(10, 2),
    changed_by   VARCHAR2(128) DEFAULT USER,
    changed_at   DATE          DEFAULT SYSDATE
);