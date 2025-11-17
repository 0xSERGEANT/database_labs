-- Загальна кількість репетиторів у системі
SELECT
	COUNT(t.*) AS total_tutors
FROM tutor t;

-- Кількість унікальних предметів, які викладають репетитори
SELECT
	COUNT(DISTINCT ts.subject_id) as unique_subject_taught
FROM tutor_subject ts;

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

-- Отримати список репетиторів разом із їхніми рейтингами на основі відгуків студентів
SELECT
	u.first_name || ' ' || u.last_name AS tutor_full_name
	, rev.rating
FROM "user" u
INNER JOIN review rev ON u.user_id = rev.tutor_id;

-- Отримати список усіх студентів разом із їхніми бронюваннями та статусами бронювань
SELECT
	u.first_name || ' ' || u.last_name AS tutor_full_name
    , b.booking_id
    , b.status
FROM "user" AS u
LEFT JOIN booking AS b ON u.user_id = b.student_id
WHERE u.user_type = 'student';

-- Вивести топ-5 репетиторів, відсортованих за їхнім середнім рейтингом, 
-- показати для кожного з них кількість завершених уроків та середню вартість одного уроку
SELECT 
    u.first_name || ' ' || u.last_name AS tutor_name
    , ROUND(AVG(rev.rating), 2) AS average_rating
    , COUNT(DISTINCT b.booking_id) AS completed_lessons
    , ROUND(AVG(ts.hourly_rate), 2) AS avg_lesson_cost
FROM tutor t
INNER JOIN "user" u ON t.tutor_id = u.user_id
LEFT JOIN review rev ON t.tutor_id = rev.tutor_id
LEFT JOIN booking b ON t.tutor_id = b.tutor_id AND b.status = 'completed'
LEFT JOIN tutor_subject ts ON t.tutor_id = ts.tutor_id
GROUP BY t.tutor_id, u.first_name, u.last_name
ORDER BY t.average_rating DESC;

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
	u.first_name || ' ' || u.last_name AS student_full_name
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
	, student_id
	, tutor_id
	, created_at
FROM booking b
WHERE b.status = 'completed'
AND b.booking_id IN (
	SELECT rev.booking_id
	FROM review rev
);
