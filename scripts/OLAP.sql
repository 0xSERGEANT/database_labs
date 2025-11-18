-- Загальна кількість репетиторів у системі
SELECT
	COUNT(t.*) AS total_tutors
FROM tutor t;

-- Знайти id репетитора з найвищою ціною за урок 
SELECT 
	MAX(ts.hourly_rate) AS max_rate
FROM tutor_subject ts;

-- Кількість унікальних предметів, які викладають репетитори
SELECT
	COUNT(DISTINCT ts.subject_id) as unique_subject_taught
FROM tutor_subject ts;

-- Порахувати загальну кількість підтверджених бронювань
SELECT 
	COUNT(b.*) AS booking_completed
FROM booking b
WHERE b.status = 'completed';

-- Знайти середню вартість заняття у кожного репетитора
SELECT 
	ts.tutor_id 
	, AVG(hourly_rate) AS average_rate
FROM tutor_subject ts 
GROUP BY ts.tutor_id;

-- Знайти кількість завершених бронювать для кожного репетитора 
SELECT 
	COUNT(b.*) AS nunber_of_cmpl_bk
	, tutor_id
FROM booking b
WHERE b.status = 'completed'
GROUP BY b.tutor_id;

-- Розрахувати мінімальну, максимальну та середню погодинну ставку для кожного репетитора
SELECT
	ts.tutor_id
	, MIN(ts.hourly_rate) AS minimal_hourly_rate
	, MAX (ts.hourly_rate) AS maximal_hourly_rate
	, ROUND(AVG(ts.hourly_rate), 2) AS average_hourly_rate
FROM tutor_subject ts
GROUP BY ts.tutor_id
ORDER BY ts.tutor_id;

-- Знайти всіх репетиторів, які викладають більше ніж 3 різні комбінації "предмет/рівень"
SELECT
    ts.tutor_id
    , COUNT(ts.*) as number_of_offers
FROM tutor_subject ts
GROUP BY ts.tutor_id
HAVING COUNT(ts.*) > 3
ORDER BY ts.tutor_id DESC;

------------------------------------------------------------------------------------------------------------------------

-- Знайти всіх репетиторів, які не мають жодного відгуку 
SELECT 
	t.tutor_id
	, r.review_id
FROM tutor t 
LEFT JOIN review r USING(tutor_id) 
WHERE r.review_id IS NULL;

-- Вивести усі бронювання і відгуки до них (якщо відгуку немає показати "відсутній")
SELECT 
	b.booking_id 
	, b.status
	, r.rating
	, COALESCE(r.comment, 'відсутній') AS comment
FROM booking b
LEFT JOIN review r USING(booking_id);

-- Вивести імена усіх репетиторів, назви предметів, які вони викладають та їх ціну за занятті відповідно до предметів
SELECT 
	CONCAT_WS(' ', u.first_name, u.last_name) AS full_name
	, s.name AS subject_name
	, tl.name AS level_name
	, ts.hourly_rate
FROM "user" u
INNER JOIN tutor t ON u.user_id = t.tutor_id
INNER JOIN tutor_subject ts USING(tutor_id)
INNER JOIN subject s USING(subject_id)
INNER JOIN teaching_level tl USING(level_id)
ORDER BY full_name;

-- Отримати список репетиторів разом із їхніми рейтингами на основі відгуків студентів
SELECT
	CONCAT_WS(' ', u.first_name, u.last_name) AS tutor_full_name
	, rev.rating
FROM "user" u
INNER JOIN review rev ON u.user_id = rev.tutor_id;

-- Отримати список усіх студентів разом із їхніми бронюваннями та статусами бронювань
SELECT
	CONCAT_WS(' ', u.first_name, u.last_name) AS student_full_name
    , b.booking_id
    , b.status
FROM "user" AS u
LEFT JOIN booking AS b ON u.user_id = b.student_id
WHERE u.user_type = 'student';

-- Вивести топ-5 репетиторів, відсортованих за їхнім середнім рейтингом, 
-- показати для кожного з них кількість завершених уроків та середню вартість одного уроку
SELECT 
    CONCAT_WS(' ', u.first_name, u.last_name) AS tutor_name
    , ROUND(AVG(rev.rating), 2) AS average_rating
    , COUNT(DISTINCT b.booking_id) AS completed_lessons
    , ROUND(AVG(ts.hourly_rate), 2) AS avg_lesson_cost
FROM tutor t
INNER JOIN "user" u ON t.tutor_id = u.user_id
LEFT JOIN review rev ON t.tutor_id = rev.tutor_id
LEFT JOIN booking b ON t.tutor_id = b.tutor_id AND b.status = 'completed'
LEFT JOIN tutor_subject ts ON t.tutor_id = ts.tutor_id
GROUP BY t.tutor_id, u.first_name, u.last_name
ORDER BY average_rating DESC;

------------------------------------------------------------------------------------------------------------------------

-- Знайти назви всіх предметів, які наразі не викладає жоден репетитор
SELECT
	s.name as subject_name
	, s.category as subject_category
FROM subject s
WHERE s.subject_id NOT IN (
	SELECT ts.subject_id
	FROM tutor_subject ts
);

-- Знайти всіх учнів, що ніколи не мали жодних бронювань
SELECT
	CONCAT_WS(' ', u.first_name, u.last_name) AS student_full_name
	, u.email as student_email
FROM "user" u
WHERE u.user_type = 'student'
AND u.user_id NOT IN (
	SELECT b.student_id
	FROM booking b
);

-- Показати ID усіх завершених бронювань, на які студенти залишили відгук
SELECT
	b.booking_id
	, b.student_id
	, b.tutor_id
	, b.created_at
FROM booking b
WHERE b.status = 'completed'
AND b.booking_id IN (
	SELECT rev.booking_id
	FROM review rev
);

-- Знайти всі відгуки з мінімальною оцінкою 
SELECT
	r.rating 
	, r.comment 
FROM review r 
WHERE r.rating = (
	SELECT 
		MIN(rating)
	FROM review 
);

-- Знайти студента з ім'ям 'Анна Сідоренко' та отримати всі його дані зі студентської таблиці
SELECT 
	s.* 
FROM student s
WHERE student_id = (
	SELECT user_id 
	FROM "user" 
	WHERE first_name = 'Анна' AND last_name = 'Сідоренко'
);

-- Знайти всіх користувачів, які є студентами старших класів (школа 10-11 класи)
SELECT 
	u.* 
FROM "user" u
WHERE user_id IN (
	SELECT student_id 
	FROM student 
	WHERE school_grade > 9
);

-- АБО:
WITH high_school_grade AS (
	SELECT student_id 
	FROM student 
	WHERE school_grade > 9
)
SELECT 
	u.* 
FROM "user" u
INNER JOIN high_school_grade ON high_school_grade.student_id = u.user_id;

-- Знайти назви всіх предметів, які належать до категорії 'Точні науки'
SELECT sub.name
FROM (
    SELECT name, category 
    FROM "subject" 
    WHERE category = 'Точні науки'
) AS sub;

-- Знайти рівні викладання, де середня вартість заняття вище за середню вартість заняття по всій системі
SELECT 
	ts.level_id, 
	ROUND(AVG(ts.hourly_rate), 2) as average_hourly_rate
FROM tutor_subject ts
GROUP BY ts.level_id
HAVING AVG(ts.hourly_rate) > (
	SELECT ROUND(AVG(ts.hourly_rate), 2) 
	FROM tutor_subject ts
);