# Partition and Group

`GROUP BY` and `PARTITION BY` both split rows by a shared value, such as department. They answer different questions.

`GROUP BY` answers “what is true of the department as a whole?” The people disappear. One row comes back for each department, with a total such as average salary or headcount.

`PARTITION BY` answers “what is true of this person, given the other people in the same department?” Every employee stays on the result. Oracle calculates inside each department and writes that number back onto each person.

The sample below is the HR and IT slice of the employee data in [Problems/med_1.sql](Problems/med_1.sql).

## The starting table

| emp_name | department | salary |
|----------|------------|--------|
| Alice    | HR         | 60000  |
| Bob      | HR         | 60000  |
| Carol    | HR         | 55000  |
| Dan      | HR         | 40000  |
| Eve      | IT         | 90000  |
| Frank    | IT         | 90000  |
| Grace    | IT         | 50000  |

Seven rows. Two departments. HR has four people. IT has three.

## What GROUP BY does

`GROUP BY department` folds every row that shares a department into one result row. Columns that are not in the `GROUP BY` list must be wrapped in an aggregate: `AVG`, `COUNT`, `SUM`, `MAX`, `MIN`.

```sql
SELECT department,
       AVG(salary) AS avg_salary,
       COUNT(*)    AS emp_count
FROM   employee
GROUP BY department;
```

Oracle walks the table and builds two buckets.

**HR bucket**

| emp_name | salary |
|----------|--------|
| Alice    | 60000  |
| Bob      | 60000  |
| Carol    | 55000  |
| Dan      | 40000  |

Sum of salaries: 60000 + 60000 + 55000 + 40000 = 215000.
Average: 215000 / 4 = 53750.
Count: 4.

Alice, Bob, Carol, and Dan are used for the math and then dropped. The bucket becomes one row: HR, 53750, 4.

**IT bucket**

| emp_name | salary |
|----------|--------|
| Eve      | 90000  |
| Frank    | 90000  |
| Grace    | 50000  |

Sum of salaries: 90000 + 90000 + 50000 = 230000.
Average: 230000 / 3 = 76666.67 (Oracle keeps the repeating fraction; shown here to two decimals).
Count: 3.

The bucket becomes one row: IT, 76666.67, 3.

**Result of GROUP BY**

| department | avg_salary | emp_count |
|------------|------------|-----------|
| HR         | 53750      | 4         |
| IT         | 76666.67   | 3         |

Two rows. Names and individual salaries are gone. You can read “HR averages 53750 across 4 people.” You cannot read “Carol earns 55000.”

## What PARTITION BY does

`PARTITION BY` lives inside a window function, after `OVER`. It splits the same rows into windows, computes a value inside each window, and attaches that value to every original row.

Two window functions on this table:

```sql
SELECT emp_name,
       department,
       salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg,
       DENSE_RANK() OVER (
           PARTITION BY department
           ORDER BY salary DESC
       ) AS sal_rank
FROM   employee;
```

`AVG(...) OVER (PARTITION BY department)` uses the same buckets as `GROUP BY`, then copies the average onto each person in that department.

`DENSE_RANK() ... ORDER BY salary DESC` sorts inside the department and numbers the distinct salaries. Tied salaries share a rank. The next distinct salary takes the next number, so a tie does not skip a rank. That is the same ranking style as the top-3 query in [Problems/med_1.sql](Problems/med_1.sql).

**HR window**

Sorted by salary descending:

| emp_name | salary | why this rank                         | dept_avg |
|----------|--------|---------------------------------------|----------|
| Alice    | 60000  | highest salary in HR, tied with Bob   | 53750    |
| Bob      | 60000  | same salary as Alice, same rank       | 53750    |
| Carol    | 55000  | next distinct salary                  | 53750    |
| Dan      | 40000  | next distinct salary                  | 53750    |

Ranks: Alice 1, Bob 1, Carol 2, Dan 3. The department average 53750 is repeated on all four rows.

**IT window**

| emp_name | salary | why this rank                         | dept_avg |
|----------|--------|---------------------------------------|----------|
| Eve      | 90000  | highest salary in IT, tied with Frank | 76666.67 |
| Frank    | 90000  | same salary as Eve, same rank         | 76666.67 |
| Grace    | 50000  | next distinct salary                  | 76666.67 |

Ranks: Eve 1, Frank 1, Grace 2. Grace is rank 2, because the tie at 90000 used rank 1 once and `DENSE_RANK` does not leave a gap.

**Result of PARTITION BY**

| emp_name | department | salary | dept_avg | sal_rank |
|----------|------------|--------|----------|----------|
| Alice    | HR         | 60000  | 53750    | 1        |
| Bob      | HR         | 60000  | 53750    | 1        |
| Carol    | HR         | 55000  | 53750    | 2        |
| Dan      | HR         | 40000  | 53750    | 3        |
| Eve      | IT         | 90000  | 76666.67 | 1        |
| Frank    | IT         | 90000  | 76666.67 | 1        |
| Grace    | IT         | 50000  | 76666.67 | 2        |

Seven rows in, seven rows out. Each person still has a name and a salary. Beside those, each row now carries the department average and that person’s rank inside the department.

A filter can sit on top of this, the way `med_1.sql` keeps `sal_rank <= 3`. The window is calculated first. The filter then drops rows. It does not change how the rank was numbered.

## Dry run, side by side

Start with the seven employees. Both statements see the same rows.

```
Alice  HR  60000
Bob    HR  60000
Carol  HR  55000
Dan    HR  40000
Eve    IT  90000
Frank  IT  90000
Grace  IT  50000
```

**Step 1. Split by department.** Both statements make the same two piles.

```
HR:  Alice 60000, Bob 60000, Carol 55000, Dan 40000
IT:  Eve 90000, Frank 90000, Grace 50000
```

**Step 2. Compute inside each pile.**

| pile | salaries                         | sum    | count | average  | dense rank by salary desc      |
|------|----------------------------------|--------|-------|----------|--------------------------------|
| HR   | 60000, 60000, 55000, 40000       | 215000 | 4     | 53750    | 60000 → 1, 55000 → 2, 40000 → 3 |
| IT   | 90000, 90000, 50000              | 230000 | 3     | 76666.67 | 90000 → 1, 50000 → 2           |

**Step 3. The statements leave the piles differently.**

`GROUP BY` emits the pile itself:

```
HR  53750     4
IT  76666.67  3
```

`PARTITION BY` writes the pile’s numbers back onto each member and emits the members:

```
Alice  HR  60000  dept_avg 53750     rank 1
Bob    HR  60000  dept_avg 53750     rank 1
Carol  HR  55000  dept_avg 53750     rank 2
Dan    HR  40000  dept_avg 53750     rank 3
Eve    IT  90000  dept_avg 76666.67  rank 1
Frank  IT  90000  dept_avg 76666.67  rank 1
Grace  IT  50000  dept_avg 76666.67  rank 2
```

Same split. Same averages. `GROUP BY` returns 2 rows. `PARTITION BY` returns 7 rows.

## Difference

| | GROUP BY | PARTITION BY |
|--|----------|----------------|
| Where it is written | `GROUP BY department` after `FROM` | inside `OVER (PARTITION BY department)` |
| Rows returned | one row per department (2 here) | one row per employee (7 here) |
| Employee name and salary | dropped, unless they are grouped too | kept on every row |
| The number you get | a property of the department | the same department property, repeated on each person in it |
| Extra argument | the grouped columns | an optional `ORDER BY` inside the window, required by `DENSE_RANK` |
| Use it when | you want department totals, counts, or averages alone | you want each person listed with their department average or rank |

`GROUP BY department` with `AVG(salary)` and `PARTITION BY department` around `AVG(salary)` use the same buckets and the same arithmetic. The average for HR is 53750 either way. The difference is the shape of the result: a summary row per department, or every employee still present with that summary attached.
