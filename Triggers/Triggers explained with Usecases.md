# Salary triggers on Employee

One trigger stops a bad salary before it is saved. The other records a real salary change in an audit table after the save succeeds.

The live row and the history row are different jobs. Employee answers “what is this person paid now?” The audit table answers “what did it used to be, who changed it, and when?”

## The two tables

**Employee** is the current record. Each person has one row, identified by employee id, with a name and one salary. A successful update replaces that salary. The previous number does not stay on this table.

**Employee salary audit** is the history. It does not replace employee. Every time a salary actually changes, one new row is added. The same employee id can appear many times, once per change. Each history row stores:

- its own audit id, so history rows stay unique even when they belong to the same person
- the employee id, so the history can be tied back to the person
- the salary before the change
- the salary after the change
- who made the change (the database user, filled automatically)
- when the change happened (the database date and time, filled automatically)

## Why the audit table is required

An update on employee overwrites the salary column. After that statement commits, the old salary is gone from the live table. Nothing on employee can tell you the earlier amount, the size of the change, the person who issued it, or the time it happened.

That gap matters in payroll and HR:

- A dispute needs the amount before and after, not only today’s figure.
- A review needs a timeline of raises and cuts for one person.
- An investigation needs the database user and the timestamp, which the live row does not keep.
- A correction later is safer when you can see the value you are correcting from.

The audit table is append-only memory for those facts. Employee stays one row per person and always shows the current salary. The audit table grows by one row per real change and is never the place you read “current pay” from.

The history is written by a trigger, not left to each application. Any update of salary — a screen, a script, or another program — passes through the same rule. Callers do not have to remember to insert an audit row, and they cannot skip the log by updating employee alone.

Rejected updates do not belong in the audit table. If the before-update check fails, the salary is not saved and the after-update trigger does not run, so a forbidden value never becomes history.

## What a trigger is

A trigger is a block of work Oracle runs by itself when a chosen change happens on a table. You do not call it. An insert, update, or delete on that table is the event that fires it.

These examples are row-level: the trigger runs once for each row the statement touches. A statement that updates fifty salaries runs the trigger fifty times, each time with that row’s old values and new values.

Two images of the row are available inside a row-level trigger:

- the old image is the row as it was before this change
- the new image is the row as this change wants to leave it

Inside the trigger body those images are referred to with a colon (`:OLD`, `:NEW`). In the optional WHEN filter on the trigger header, the same images are referred to without a colon (`OLD`, `NEW`).

## Skeleton of a trigger

Read this as the shape of the statement, from top to bottom. Words in capitals are the fixed parts. Words in lower case are what you fill in.

1. **Create or replace trigger**, then the trigger name.
2. **Timing.** Either BEFORE or AFTER.
3. **Event.** INSERT, UPDATE, or DELETE. On an update you may limit it to one column, written as UPDATE OF that column.
4. **On**, then the table name.
5. **For each row**, when the trigger must see each changed row rather than the statement as a whole.
6. **When**, optional. A condition on the old and new images. If it is false, Oracle skips the body for that row. The original change still stands.
7. **Begin**, then the work, then **end**.

```sql
CREATE OR REPLACE TRIGGER trigger_name
BEFORE | AFTER
INSERT OR UPDATE [OF column_name] OR DELETE
ON table_name
[FOR EACH ROW]
[WHEN (condition)]          -- OLD / NEW, no colon
BEGIN
  -- body; row values are :OLD.column_name and :NEW.column_name
END;
/
```

Brackets mark optional parts. Use BEFORE or AFTER, not both. Name only the events you need. `OF column_name` applies to UPDATE only. `FOR EACH ROW` is what makes `:OLD` and `:NEW` available. `WHEN` uses `OLD` and `NEW` without a colon, and only to decide whether the body runs.

A validation trigger uses steps 1 through 5 and 7. The condition lives inside the body, because a failed check must stop the update.

An audit trigger uses all seven steps. The WHEN step keeps the body from running when the salary did not actually change.

Statement-level triggers omit “for each row” and cannot see old and new column values. They are the wrong shape for per-person salary checks and per-person history, which is why both triggers here are row-level.

## Before and after

**Before** means the body runs prior to the row being written. Use it to accept or reject the new values. If the body raises an application error, Oracle rolls that change back. The new salary is not stored, and any after trigger for that change does not run.

**After** means the body runs once the row has been written successfully. Use it for side effects that should exist only when the change is real: a history row, a notification, a copy elsewhere. An after trigger should not be the place that decides whether the salary was legal. By then the row is already updated, and a WHEN clause cannot raise an error.

Column-specific form (UPDATE OF salary) means other updates on employee, such as a name change, do not fire these triggers.

## Use case: stop an illegal salary

Trigger: the before-update trigger on employee, limited to the salary column, for each row.

Business rule:

- salary cannot be negative
- salary cannot fall to less than half of the previous salary

Why before: the check has to happen while the new value can still be refused. The body looks at the new salary, and at the old salary when it measures the size of a cut. Each broken rule raises its own application error so the caller sees which rule failed.

Why this is not a WHEN filter: WHEN only chooses whether the body runs. A false WHEN skips the body and still allows the update. Validation must run the body and then fail the statement. That is an IF inside the body, followed by an application error.

What the user experiences: the update of that employee does not commit the bad salary. No audit row is written for the attempt.

## Use case: keep a salary history

Trigger: the after-update trigger on employee, limited to the salary column, for each row, with a WHEN test that the salary actually changed.

Why after: history should describe a change that landed. The body inserts one row into the employee salary audit table: employee id from the old image, previous salary, and new salary. The database user and the timestamp are left to the audit table’s own defaults, so the trigger does not have to set them.

Why WHEN: an update can name the salary column and set it to the same number it already holds. That is not a pay change. WHEN compares old and new salary (treating a missing value as comparable) and skips the insert when they match. The employee update still succeeds. You simply do not add a useless history row.

Why a separate table: see the section above. The insert does not change the employee row. It only appends the facts the live row is about to forget.

## What happens on one salary update

1. Someone updates salary on one or more employee rows.
2. For each row, the before trigger runs and applies the two rules.
3. If a rule fails, that update fails. Employee is unchanged for that row. The audit table gets nothing.
4. If the rules pass, Oracle stores the new salary on employee.
5. The after trigger is considered for that row.
6. If the salary is the same as before, WHEN skips the body.
7. If the salary differs, one row is inserted into the employee salary audit table with the employee id, the old salary, the new salary, the current database user, and the current time.

## WHEN and IF, in one line each

WHEN sits on the trigger header. It asks whether the body should run. It cannot reject the update.

IF sits inside the body. It asks what to do now that the body is running, including rejecting the change.

Pattern used here: before validation uses IF. After audit uses WHEN.
