# LAG — Window Function Guide

`LAG` is an **analytic (window) function** in SQL (Oracle, PostgreSQL, SQL Server, etc.). It lets each row “see” a value from an **earlier** row in a defined sort order—without a self-join.

---

## What it does

```sql
LAG(column, offset [, default]) OVER (
    [PARTITION BY ...]
    ORDER BY ...
)
```

| Argument | Meaning |
|----------|---------|
| `column` | Value to copy from a prior row (e.g. `reading_value`) |
| `offset` | How many rows **back** (1 = immediately previous row) |
| `default` (optional) | Used when there is no prior row (often omitted → `NULL`) |
| `OVER (...)` | Defines **groups** (`PARTITION BY`) and **order** (`ORDER BY`) |

**One row back:** `LAG(reading_value, 1)` → previous row’s `reading_value`.  
**Two rows back:** `LAG(reading_value, 2)` → value from two rows earlier.

Opposite function: **`LEAD(column, n)`** looks **forward** *n* rows.

---

## Why LAG is used

1. **Compare row to its predecessor** — deltas, “changed since last reading,” day-over-day growth.
2. **Detect patterns on ordered data** — consecutive equal values, streaks, runs (see `med_2.sql`).
3. **Avoid messy self-joins** — one ordered pass instead of `JOIN t ON t2.id = t.id - 1`.
4. **Per-group history** — with `PARTITION BY`, “previous” resets inside each group (per user, per device, etc.).

LAG answers: **“What was this column on the row before me (in this order)?”**

---

## Use cases (typical)

| Domain | Example |
|--------|---------|
| Sensors / logs | Current reading minus `LAG(reading_value, 1)` → spike detection |
| Finance | Today’s price vs `LAG(price, 1)` → daily return |
| Sessions / events | Time since last event: `logged_at - LAG(logged_at, 1)` |
| Quality / monitoring | Flag when `status <> LAG(status, 1)` → state change |
| Practice (`med_2`) | `LAG(..., 1)` + `LAG(..., 2)` → “same value 3 times in a row” |

---

## Dry run: sample table `app_log`

Same shape as in `med_2.sql`:

```sql
CREATE TABLE app_log (
    id            NUMBER PRIMARY KEY,
    reading_value NUMBER NOT NULL,
    logged_at     DATE DEFAULT SYSDATE NOT NULL
);
```

### Input data (12 rows)

| id | reading_value |
|----|---------------|
| 1  | 5             |
| 2  | 5             |
| 3  | 5             |
| 4  | 3             |
| 5  | 3             |
| 6  | 5             |
| 7  | 5             |
| 8  | 5             |
| 9  | 5             |
| 10 | 7             |
| 11 | 7             |
| 12 | 8             |

### Step 1 — Run the window expressions

```sql
SELECT
    id,
    reading_value,
    LAG(reading_value, 1) OVER (ORDER BY id) AS prev_1,
    LAG(reading_value, 2) OVER (ORDER BY id) AS prev_2
FROM app_log
ORDER BY id;
```

Oracle evaluates **one ordered window** (`ORDER BY id`). For each row, `prev_1` = row *id−1*’s value; `prev_2` = two rows back.

### Step 2 — Dry-run result (row by row)

| id | reading_value | prev_1 | prev_2 | Notes |
|----|---------------|--------|--------|-------|
| 1  | 5             | NULL   | NULL   | No prior rows |
| 2  | 5             | 5      | NULL   | Matches previous once |
| 3  | 5             | 5      | 5      | **Triple 5** (current = prev_1 = prev_2) |
| 4  | 3             | 5      | 5      | Value changed |
| 5  | 3             | 3      | 5      | Only two 3s in a row (id 4–5), not three |
| 6  | 5             | 3      | 3      | New run starts |
| 7  | 5             | 5      | 3      | |
| 8  | 5             | 5      | 5      | **Triple 5** |
| 9  | 5             | 5      | 5      | **Triple 5** (same run: ids 7–9) |
| 10 | 7             | 5      | 5      | |
| 11 | 7             | 7      | 5      | Two 7s only |
| 12 | 8             | 7      | 7      | Single 8 |

**How to read id = 8 manually**

- Sort order: … row id 6 (5), 7 (5), **8 (5)** …
- `LAG(..., 1)` at id 8 → id 7 → `5` → **prev_1 = 5**
- `LAG(..., 2)` at id 8 → id 6 → `5` → **prev_2 = 5**
- Current `reading_value` is also `5` → three consecutive 5s ending at id 8.

**How to read id = 2 manually**

- Only one row exists before id 2.
- `LAG(..., 1)` → id 1 → `5` → **prev_1 = 5**
- `LAG(..., 2)` needs two rows back → none → **prev_2 = NULL**

### Step 3 — Using LAG for “3 consecutive same values” (`med_2`)

At any row where **current = prev_1 = prev_2**, that row is the **third** (or later) step in a run of the same `reading_value`:

```sql
WHERE reading_value = prev_1
  AND reading_value = prev_2
```

From the dry run, qualifying rows:

| id | reading_value | Why |
|----|---------------|-----|
| 3  | 5             | 5, 5, 5 (ids 1–3) |
| 8  | 5             | …, 5, 5, 5 (ids 6–8) |
| 9  | 5             | …, 5, 5, 5 (ids 7–9) |

Final answer (distinct values that appear in at least one triple):

```text
reading_value
-------------
            5
```

(`3` has only two in a row; `7` has only two; `8` has no triple.)

---

## LAG vs self-join (mental model)

**Self-join idea:** “Give me `t_prev.reading_value` where `t_prev.id = t.id - 1`.”

**LAG idea:** “In sorted order, give me the value *offset* rows above.”

Same result for simple `ORDER BY id`, but LAG stays readable when you need `LAG(..., 2)`, `PARTITION BY`, or multiple prior columns.

---

## Quick reference

```sql
-- Previous value
LAG(amount, 1) OVER (ORDER BY txn_date)

-- Per account, previous balance
LAG(balance, 1) OVER (PARTITION BY account_id ORDER BY txn_date)

-- Change from previous row
reading_value - LAG(reading_value, 1) OVER (ORDER BY id) AS delta

-- Third column in a run (med_2 pattern)
LAG(reading_value, 1) OVER (ORDER BY id),
LAG(reading_value, 2) OVER (ORDER BY id)
```

---

## Related file

- [`med_2.sql`](./med_2.sql) — `app_log` setup and query using `LAG(reading_value, 1)` and `LAG(reading_value, 2)`.