-- Отримати назви міст та їх регіони, відсортовані за назвою міста.
SELECT
	c.name as city_name
	, c.region as city_region
FROM city c
ORDER BY c.name;

-- Знайти всі міста, де регіон не вказано (NULL).
SELECT 
	c.name as city_name 
FROM city c 
WHERE c.region IS NOT NULL;

-- Додати місто "Ужгород" ("Закарпатська").
INSERT INTO city (name, region, country)
VALUES ('Ужгород', 'Закарпатська область', 'Україна');

SELECT 
	c.* 
FROM city c
WHERE c.name = 'Ужгород';

-- Змінити назву міста з "Одеса" на "Чорноморськ".
UPDATE city 
SET name = 'Чорноморськ'
WHERE c.name = 'Одеса';

SELECT 
	c.*
FROM city c
WHERE c.name = 'Чорноморськ';

-- Видалити місто "Ужгород".
DELETE FROM city 
WHERE c.city_id = 9;

SELECT * FROM city;

----------------------------------------------------------------------------------------

-- Отримати всі унікальні категорії предметів.
SELECT DISTINCT
	s.category 
FROM subject s;

-- Знайти предмети, опис яких містить "підготовка до олімпіади".
SELECT 
	s.name as subject_name
	, s.description 
FROM subject s
WHERE s.description LIKE '%підготовка до олімпіади%';

-- Додати предмет "Інформатика", категорія "Точні науки".
INSERT INTO subject (name, category)
VALUES ('Інформатика', 'Точні науки');

SELECT 
	s.*
FROM subject s
WHERE s.name = 'Інформатика';

-- Додати опис до "Інформатики".
UPDATE subject 
SET description = 'Шкільна програма, програмування, розвиваючі курси'
WHERE subject_id = 10;

SELECT 
	s.* 
FROM subject s
WHERE s.subject_id = 10;

-- Видалити предмет "Інформатика"
DELETE FROM subject 
WHERE s.subject_id = 10;

SELECT 
	s.* 
FROM subject s
WHERE s.name = 'Інформатика';

----------------------------------------------------------------------------------------

-- Порахувати кількість рівнів викладання.
SELECT COUNT(name) 
FROM teaching_level;

-- Знайти рівні, у назві яких присутнє "Класи".
SELECT 
	tl.name as teaching_level_name 
FROM teaching_level tl
WHERE tl.name LIKE '%класи%';

-- Додати рівень "Підготовка до школи".
INSERT INTO teaching_level (name, position)
VALUES ('Підготовка до школи', 8);

SELECT 
	tl.* 
FROM teaching_level tl
WHERE tl.name = 'Підготовка до школи';

-- Додати опис для "Підготовки до школи"
UPDATE teaching_level 
SET description = 'Підготовчі курси до школи'
WHERE level_id = 10;

SELECT 
	tl.* 
FROM teaching_level tl
WHERE tl.level_id = 10;

-- Видалити рівень підготовки "Підготовка до школи"
DELETE FROM teaching_level 
WHERE name = 'Підготовчі курси до школи';

SELECT 
	tl.* 
FROM teaching_level tl
WHERE tl.name = 'Підготовчі курси до школи';

----------------------------------------------------------------------------------------

-- Отримати всіх користувачів, відсортованих за датою реєстрації.
SELECT 
	CONCAT_WS(' ', u.first_name, u.last_name) as user_full_name
	, u.email
	, u.registration_date
FROM "user" u 
ORDER BY u.registration_date;

-- Знайти всіх користувачів з типом 'tutor'.
SELECT 
	CONCAT_WS(' ', u.first_name, u.last_name) as user_full_name
FROM "user" u
WHERE u.user_type = 'tutor';

-- Зареєструвати репетитора 'tutor.only@email.com', 'hash_xyz', 'Анна', 'Мельник'.
INSERT INTO "user" (email, password_hash, first_name, last_name, phone, user_type)
VALUES ('anna_melnyk@email.com', 'anna_passwd', 'Анна', 'Мельник', '+380995335467', 'tutor');

SELECT 
	u.* 
FROM "user" u
WHERE u.first_name = 'Анна' AND u.last_name = 'Мельник';

-- Оновити номер телефону для користувача з ID = 5 на '0671112233'.
UPDATE "user"
SET phone = '+380630898845'
WHERE user_id = 13;

SELECT 
	u.*
FROM "user" u
WHERE u.user_id = 13;

-- Видалити користувача Анна Мельник.
SELECT 
	u.user_id 
	, u.first_name
	, u.last_name
FROM "user" u 
WHERE u.first_name = 'Анна' AND u.last_name = 'Мельник';

DELETE FROM "user"
WHERE user_id = 13;

SELECT 
	u.* 
FROM "user" u 
WHERE u.user_id = 13;

----------------------------------------------------------------------------------------

-- Отримати 3 найстарших учня, відсортованих за віком (спадання).
SELECT 
	st.* 
FROM student st
ORDER BY st.age DESC
LIMIT 3;

-- Отримати учнів, молодших за 18 років. 
SELECT 
	st.* 
FROM student st 
WHERE st.age < 18;

-- Додати нового учня з Києва, віком 14 років
INSERT INTO "user" (email, password_hash, first_name, last_name, phone, user_type)
VALUES ('coshovyi_maksik@email.com', 'maksik_parol', 'Максим', 'Кошовий', '+380998708907', 'student');

SELECT 
	u.* 
FROM "user" u
WHERE u.user_type = 'student' AND u.first_name = 'Максим' AND u.last_name = 'Кошовий';

SELECT 
	c.name
	, city_id
FROM city c
WHERE c.name = 'Київ';

SELECT 
	st.*
FROM student st; 

INSERT INTO student (student_id, city_id, age, school_grade)
VALUES (14, 1, 14, 8);

SELECT 
	st.* 
FROM student st
WHERE st.student_id = 15;

-- Оновити місто для студента Максима Кошового на Харків
SELECT 
	c.city_id
	, name
FROM city c
WHERE c.name = 'Харків';

SELECT 
	u.user_id 
FROM "user" u
WHERE u.first_name = 'Максим' AND u.last_name = 'Кошовий';

UPDATE student 
SET city_id = 2
WHERE student_id = 14;

SELECT 
	st.*
FROM student st
WHERE ststudent_id = 14;

-- Видалити профіль студента Максима Кошового.
SELECT 
	u.user_id 
FROM "user" u
WHERE u.first_name = 'Максим' AND u.last_name = 'Кошовий';

DELETE FROM "user" 
WHERE user_id = 14;

SELECT 
	u.* 
FROM "user" u 
WHERE u.user_id = 14; 

SELECT 
	st.* 
FROM student st 
WHERE st.student_id = 14; 

----------------------------------------------------------------------------------------

-- Отримати ID, досвід, та рейтинг репетиторів.
SELECT 
	t.tutor_id
	, t.years_experience
	, t.average_rating
FROM tutor t;

-- Знайти репетиторів з міста Київ, які працюють офлайн.
SELECT 
	c.* 
FROM city c 
WHERE c.name = 'Київ';

SELECT 
	t.*
FROM tutor t 
WHERE t.city_id = 1 AND t.offline_available = TRUE; 

-- Додати профіль репетитора: вік 42, досвід 15, освіта "ХПІ".
SELECT 
	u.* 
FROM "user" u;

INSERT INTO "user" (email, password_hash, first_name, last_name, phone, user_type)
VALUES ('svitlana_2001@gmail.com', 'svitlanana', 'Світлана', 'Квітка', '+380995434156', 'tutor');

SELECT 
	u.user_id 
	, u.first_name
	, u.last_name
FROM "user" u
WHERE u.first_name ='Світлана' AND u.last_name = 'Квітка';

SELECT 
	t.*
FROM tutor t;

INSERT INTO tutor (tutor_id, city_id, age, years_experience, education, online_available, offline_available)
VALUES (17, null, 42, 15, 'ХНУ ім. Каразіна', TRUE, false);

SELECT 
	t.* 
FROM tutor t 
WHERE t.tutor_id = 17;

-- Позначити проведеня оффлайн занять та заповнити поле "адресса" (для цього також додати місто).
SELECT 
	c.* 
FROM city c; 

SELECT 
	t.* 
FROM tutor t 
WHERE t.tutor_id = 17;

UPDATE tutor 
SET city_id = 6, address = 'вул Шовковична 10', offline_available = TRUE 
WHERE tutor_id = 17;

SELECT 
	t.* 
FROM tutor t 
WHERE t.tutor_id = 17;

-- Видалити профіль репетитора з ID = 17.
SELECT 
	u.* 
FROM "user" u 
WHERE u.user_id = 17;

DELETE FROM "user" 
WHERE user_id = 17; 

SELECT 
	u.* 
FROM "user" u 
WHERE u.user_id = 17;

SELECT 
	t.* 
FROM tutor t 
WHERE t.tutor_id = 17;

----------------------------------------------------------------------------------------

-- Отримати всі зв'язки, відсортовані за hourly_rate (від найдорожчих).
SELECT 
	ts.* 
FROM tutor_subject ts 
ORDER BY ts.hourly_rate DESC;

-- Знайти пропозиції з ціною в діапазоні 400-600 грн.
SELECT 
	ts.* 
FROM tutor_subject ts
WHERE ts.hourly_rate BETWEEN 400 AND 600
ORDER BY ts.hourly_rate DESC;

-- Додати: репетитору Івану Петренко, предмет "Фізика", "Університетський рівень", ціна 500.00.
SELECT 
	u.user_id
FROM "user" u
WHERE u.first_name = 'Іван' AND u.last_name = 'Петренко';

SELECT 
	s.subject_id
	, s.name
FROM subject s 
WHERE s.name = 'Фізика'; 

SELECT
	tl.level_id
	, tl. name
FROM teaching_level tl
WHERE tl.name = 'Університетський рівень';

INSERT INTO tutor_subject (tutor_id, subject_id, level_id, hourly_rate)
VALUES (1, 2, 6, 500.00);

SELECT 
	ts.* 
FROM tutor_subject ts
WHERE ts.tutor_id = 1 AND subject_id = 2 AND level_id = 6;

-- Збільшити ціну на 50 грн для всіх, хто викладає предмет "Математика" і коштує < 500.
SELECT 
	s.* 
FROM subject s
WHERE s.name = 'Математика';

UPDATE tutor_subject 
SET hourly_rate = hourly_rate + 50 
WHERE subject_id = 1 AND hourly_rate < 500;

SELECT 
	ts.subject_id
	, ts.hourly_rate
FROM tutor_subject ts
WHERE ts.subject_id = 1; 

-- Видалити предмет "Фізика" для "Університетського рівня" у репетитора Івана Петренко
SELECT 
	ts.* 
FROM tutor_subject ts
WHERE ts.tutor_id = 1 AND subject_id = 2 AND level_id = 6;

DELETE FROM tutor_subject 
WHERE tutor_subject_id = 20;

SELECT 
	ts.* 
FROM tutor_subject ts
WHERE ts.tutor_subject_id = 20;

----------------------------------------------------------------------------------------

-- Отримати розклад на 15-11-2025.
SELECT 
	sch.date
	, sch.is_available
	, sch.start_time
	, sch.end_time 
FROM schedule sch 
WHERE sch.date = '2025-11-15';

-- Отримати 5 найближчих вільних слотів (починаючи з сьогодні).
SELECT 
	sch.date
	, sch.start_time 
	, sch.end_time 
FROM schedule sch 
WHERE sch.is_available = TRUE AND sch.date >= CURRENT_DATE
ORDER BY sch.date
LIMIT 5;

-- Додати слот для репетитора з ID=1, дата '2025-11-05', 10:00 - 11:00.
INSERT INTO schedule (tutor_id, date, start_time, end_time, is_available)
VALUES (1, '2025-11-05', '10:00:00', '11:00:00', TRUE);

SELECT 
	sch.*
FROM schedule sch 
WHERE sch.tutor_id = 1 AND sch.date = '2025-11-05';

-- Позначити слот (ID=13) як недоступний (заброньовано).
UPDATE schedule 
SET is_available = FALSE 
WHERE schedule_id = 13; 

SELECT 
	sch.is_available
FROM schedule sch 
WHERE schedule_id = 13;

-- Видалити всі слоти репетитора ID = 1 на '2025-11-05'.
DELETE FROM schedule 
WHERE tutor_id = 1 AND date = '2025-11-05';

SELECT 
	sch.* 
FROM schedule sch 
WHERE sch.tutor_id = 1 AND sch.date = '2025-11-05'; 

----------------------------------------------------------------------------------------

-- Отримати ID студента, ID репетитора та статус для всіх бронювань.
SELECT 
	b.student_id
	, b.tutor_id
	, b.status
FROM booking b;

-- Знайти всі бронювання, які відносяться до заняття у форматі 'online'.
SELECT 
	b.* 
FROM booking b
WHERE format = 'online'

-- Додати брнювання заняття для уня з ID = 8 у репетитора з ID = 4 на заняття по Хімії (ID = 5) 2025-11-10 на 15:00 онлайн.
SELECT 
	sch.schedule_id
FROM schedule sch
WHERE sch.tutor_id = 4 AND sch.date = '2025-11-10' AND sch.start_time = '15:00:00';

INSERT INTO booking (student_id, tutor_id, subject_id, level_id, schedule_id, format)
VALUES (8, 4, 5, 3, 15, 'online');

SELECT 
	b.* 
FROM booking b
WHERE b.schedule_id = 15;

-- Додати опис до щойно створеного бронювання.
UPDATE booking
SET notes = 'Неорганічна хімія'
WHERE booking_id = 6;

SELECT 
	b.* 
FROM booking b
WHERE b.booking_id = 6;

-- Видалити бронювання з ID = 6.
DELETE FROM booking 
WHERE booking_id = 6;

SELECT 
	b.* 
FROM booking b
WHERE b.booking_id = 6;

----------------------------------------------------------------------------------------

-- Отримати оцінки (rating) та коментарі.
SELECT 
	r.rating
	, r.comment
FROM review r;

-- Знайти всі відгуки з оцінкою 5.
SELECT 
	r.rating 
	, r.comment 
FROM review r
WHERE r.rating = 5;

-- Додати анонімний відгук: booking_id = 3 (студент ID=8, репетитор ID=4), оцінка 3.
INSERT INTO review (booking_id, student_id, tutor_id, rating, is_anonymous)
VALUES (3, 8, 4, 3, TRUE);

SELECT 
	r.* 
FROM review r
WHERE booking_id = 3;

--Оновити коментар для відгуку з ID = 7 на "Відредаговано: ..."
UPDATE review
SET comment = 'Відредаговано: дуже мало практики на заняттях, суто теорія'
WHERE review_id = 7;

SELECT
	r.comment
FROM review r 
WHERE r.review_id = 7;

-- Видалити відгук з ID = 7.
DELETE FROM review 
WHERE r.review_id = 7;

SELECT
	r.*
FROM review r 
WHERE r.review_id = 7;