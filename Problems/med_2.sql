-- Description
-- Table app_log: each row is one event, ordered by id.
-- Return distinct reading_value that appears in at least 3 consecutive rows (same value).

CREATE TABLE app_log (
    id             NUMBER PRIMARY KEY,
    reading_value  NUMBER NOT NULL,
    logged_at      DATE DEFAULT SYSDATE NOT NULL
);

-- Sample data (12 rows)
INSERT INTO app_log (id, reading_value) VALUES ( 1, 5);
INSERT INTO app_log (id, reading_value) VALUES ( 2, 5);
INSERT INTO app_log (id, reading_value) VALUES ( 3, 5);

INSERT INTO app_log (id, reading_value) VALUES ( 4, 3);
INSERT INTO app_log (id, reading_value) VALUES ( 5, 3);

INSERT INTO app_log (id, reading_value) VALUES ( 6, 5);
INSERT INTO app_log (id, reading_value) VALUES ( 7, 5);
INSERT INTO app_log (id, reading_value) VALUES ( 8, 5);
INSERT INTO app_log (id, reading_value) VALUES ( 9, 5);

INSERT INTO app_log (id, reading_value) VALUES (10, 7);
INSERT INTO app_log (id, reading_value) VALUES (11, 7);
INSERT INTO app_log (id, reading_value) VALUES (12, 8);

COMMIT;

-- Write your query below (no PL/SQL block required unless you want a function).


WITH CONSECUTIVE_THREE_ROWS AS (

SELECT 
ID,
reading_value,
LAG(READING_VALUE,1) over (ORDER BY ID) AS PREV_1
,
LAG(READING_VALUE,2) OVER (ORDER BY ID) AS PREV_2
from APP_LOG

)


SELECT 
DISTINCT reading_valUE
FROM 
CONSECUTIVE_THREE_ROWS 
WHERE READING_VALUE = PREV_1
AND READING_VALUE = PREV_2 
ORDER BY READING_VALUE;
