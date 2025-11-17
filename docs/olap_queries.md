# OLAP Запити - Аналітична обробка даних

Даний документ містить детальний опис OLAP (Online Analytical Processing) запитів для системи пошуку репетиторів. OLAP запити використовуються для аналізу даних, генерації звітів та отримання статистичної інформації про роботу системи.

## Зміст
- [Агрегатні функції](#агрегатні-функції)
- [Групування даних (GROUP BY)](#групування-даних-group-by)
- [З'єднання таблиць (JOIN)](#зєднання-таблиць-join)
- [Підзапити](#підзапити)
- [Складні аналітичні запити](#складні-аналітичні-запити)

---

## Агрегатні функції

### 1. Загальна кількість репетиторів у системі

```sql
SELECT
    COUNT(t.*) AS total_tutors
FROM tutor t;
```

**Пояснення:**
- Використовує агрегатну функцію `COUNT()` для підрахунку всіх записів у таблиці `tutor`
- Повертає загальну кількість зареєстрованих репетиторів у системі
- Результат: одне число - кількість репетиторів

### 2. Максимальна ціна за урок серед усіх репетиторів

```sql
SELECT 
    MAX(ts.hourly_rate) AS max_rate
FROM tutor_subject ts;
```

**Пояснення:**
- `MAX()` знаходить найвищу погодинну ставку серед усіх предметів та рівнів
- Аналізує таблицю `tutor_subject`, де зберігаються ціни репетиторів за різні предмети
- Корисно для розуміння верхнього цінового діапазону на платформі

### 3. Кількість унікальних предметів

```sql
SELECT
    COUNT(DISTINCT ts.subject_id) as unique_subject_taught
FROM tutor_subject ts;
```

**Пояснення:**
- `DISTINCT` забезпечує підрахунок тільки унікальних предметів
- Показує різноманітність предметів, які викладають репетитори
- Допомагає зрозуміти покриття освітніх напрямків на платформі

### 4. Кількість завершених бронювань

```sql
SELECT 
    COUNT(b.*) AS booking_completed
FROM booking b
WHERE b.status = 'completed';
```

**Пояснення:**
- Фільтрує бронювання за статусом 'completed' за допомогою `WHERE`
- Підраховує успішно проведені уроки
- Важливий показник активності та успішності платформи

---

## Групування даних (GROUP BY)

### 5. Середня вартість заняття для кожного репетитора

```sql
SELECT 
    ts.tutor_id,
    AVG(hourly_rate) AS average_rate
FROM tutor_subject ts 
GROUP BY ts.tutor_id;
```

**Пояснення:**
- `GROUP BY` групує записи за ID репетитора
- `AVG()` обчислює середню ставку для кожного репетитора окремо
- Результат: список репетиторів з їх середніми ставками
- Допомагає порівнювати цінову політику репетиторів

### 6. Кількість завершених бронювань для кожного репетитора

```sql
SELECT 
    COUNT(b.*) AS nunber_of_cmpl_bk,
    tutor_id
FROM booking b
WHERE b.status = 'completed'
GROUP BY b.tutor_id;
```

**Пояснення:**
- Спочатку фільтрує тільки завершені бронювання
- Потім групує їх за репетиторами
- Показує продуктивність кожного репетитора
- Корисно для рейтингування та аналізу популярності

### 7. Статистика ставок для кожного репетитора

```sql
SELECT
    ts.tutor_id,
    MIN(ts.hourly_rate) AS minimal_hourly_rate,
    MAX(ts.hourly_rate) AS maximal_hourly_rate,
    ROUND(AVG(ts.hourly_rate), 2) AS average_hourly_rate
FROM tutor_subject ts
GROUP BY ts.tutor_id
ORDER BY ts.tutor_id;
```

**Пояснення:**
- Комплексний аналіз цінової політики кожного репетитора
- `MIN()`, `MAX()`, `AVG()` - повна статистика ставок
- `ROUND(..., 2)` - округлення до двох знаків після коми
- `ORDER BY` - сортування результатів за ID репетитора
- Показує цінові діапазони для різних предметів одного репетитора

### 8. Репетитори з великою кількістю пропозицій (HAVING)

```sql
SELECT
    ts.tutor_id,
    COUNT(ts.*) as number_of_offers
FROM tutor_subject ts
GROUP BY ts.tutor_id
HAVING COUNT(ts.*) > 3
ORDER BY ts.tutor_id DESC;
```

**Пояснення:**
- `HAVING` фільтрує групи після агрегації (на відміну від `WHERE`)
- Знаходить репетиторів, що викладають більше 3 комбінацій предмет/рівень
- Показує найбільш універсальних репетиторів
- `ORDER BY ... DESC` - сортування у спадному порядку

---

## З'єднання таблиць (JOIN)

### 9. Репетитори без відгуків (LEFT JOIN)

```sql
SELECT 
    t.tutor_id,
    r.review_id
FROM tutor t 
LEFT JOIN review r USING(tutor_id) 
WHERE r.review_id IS NULL;
```

**Пояснення:**
- `LEFT JOIN` зберігає всі записи з лівої таблиці (`tutor`)
- `USING(tutor_id)` - спрощений синтаксис для з'єднання за однаковою колонкою
- `WHERE ... IS NULL` - фільтрує записи без відгуків
- Допомагає ідентифікувати нових репетиторів або тих, хто потребує покращення сервісу

### 10. Бронювання з відгуками або без них

```sql
SELECT 
    b.booking_id,
    b.status,
    r.rating,
    COALESCE(r.comment, 'відсутній') AS comment
FROM booking b
LEFT JOIN review r USING(booking_id);
```

**Пояснення:**
- Показує всі бронювання разом з відгуками (якщо є)
- `COALESCE()` замінює NULL значення на 'відсутній'
- Дає повну картину зворотного зв'язку від студентів

### 11. Повна інформація про репетиторів та їх предмети (INNER JOIN)

```sql
SELECT 
    CONCAT_WS(' ', u.first_name, u.last_name) AS full_name,
    s.name AS subject_name,
    tl.name AS level_name,
    ts.hourly_rate
FROM "user" u
INNER JOIN tutor t ON u.user_id = t.tutor_id
INNER JOIN tutor_subject ts USING(tutor_id)
INNER JOIN subject s USING(subject_id)
INNER JOIN teaching_level tl USING(level_id)
ORDER BY full_name;
```

**Пояснення:**
- Множинні `INNER JOIN` об'єднують 5 таблиць
- `CONCAT_WS(' ', ...)` - з'єднує ім'я та прізвище з пробілом
- Показує детальну інформацію про всі послуги репетиторів
- Результат: повний каталог послуг з цінами

### 12. Репетитори та їх рейтинги

```sql
SELECT
    CONCAT_WS(' ', u.first_name, u.last_name) AS tutor_full_name,
    rev.rating
FROM "user" u
INNER JOIN review rev ON u.user_id = rev.tutor_id;
```

**Пояснення:**
- З'єднує користувачів з їх отриманими оцінками
- Показує всі індивідуальні оцінки для кожного репетитора
- Базовий запит для подальшого аналізу рейтингів

### 13. Студенти та їх бронювання (LEFT JOIN з фільтрацією)

```sql
SELECT
    CONCAT_WS(' ', u.first_name, u.last_name) AS student_full_name,
    b.booking_id,
    b.status
FROM "user" AS u
LEFT JOIN booking AS b ON u.user_id = b.student_id
WHERE u.user_type = 'student';
```

**Пояснення:**
- Фільтрує тільки студентів за типом користувача
- `LEFT JOIN` показує всіх студентів, навіть без бронювань
- Корисно для аналізу активності студентів

### 14. Топ-5 репетиторів за рейтингом (складний JOIN з агрегацією)

```sql
SELECT 
    CONCAT_WS(' ', u.first_name, u.last_name) AS tutor_name,
    ROUND(AVG(rev.rating), 2) AS average_rating,
    COUNT(DISTINCT b.booking_id) AS completed_lessons,
    ROUND(AVG(ts.hourly_rate), 2) AS avg_lesson_cost
FROM tutor t
INNER JOIN "user" u ON t.tutor_id = u.user_id
LEFT JOIN review rev ON t.tutor_id = rev.tutor_id
LEFT JOIN booking b ON t.tutor_id = b.tutor_id AND b.status = 'completed'
LEFT JOIN tutor_subject ts ON t.tutor_id = ts.tutor_id
GROUP BY t.tutor_id, u.first_name, u.last_name
ORDER BY average_rating DESC;
```

**Пояснення:**
- Комбінує дані з 5 таблиць для комплексного аналізу
- `COUNT(DISTINCT ...)` уникає дублювання бронювань
- Додаткова умова в `LEFT JOIN`: `AND b.status = 'completed'`
- Сортування за середнім рейтингом дає топ репетиторів
- Показує ключові метрики: рейтинг, кількість уроків, середню ціну

---

## Підзапити

### 15. Предмети, які ніхто не викладає (NOT IN)

```sql
SELECT
    s.name as subject_name,
    s.category as subject_category
FROM subject s
WHERE s.subject_id NOT IN (
    SELECT ts.subject_id
    FROM tutor_subject ts
);
```

**Пояснення:**
- Підзапит повертає всі ID предметів, які викладаються
- `NOT IN` знаходить предмети, яких немає в цьому списку
- Допомагає виявити прогалини в покритті освітніх напрямків
- Корисно для планування залучення нових репетиторів

### 16. Студенти без бронювань

```sql
SELECT
    CONCAT_WS(' ', u.first_name, u.last_name) AS student_full_name,
    u.email as student_email
FROM "user" u
WHERE u.user_type = 'student'
AND u.user_id NOT IN (
    SELECT b.student_id
    FROM booking b
);
```

**Пояснення:**
- Знаходить неактивних студентів
- Може використовуватись для маркетингових кампаній
- Допомагає аналізувати конверсію реєстрації в активне використання

### 17. Завершені бронювання з відгуками (IN + підзапит)

```sql
SELECT
    b.booking_id,
    b.student_id,
    b.tutor_id,
    b.created_at
FROM booking b
WHERE b.status = 'completed'
AND b.booking_id IN (
    SELECT rev.booking_id
    FROM review rev
);
```

**Пояснення:**
- Знаходить завершені уроки, на які є відгук
- Показує рівень задоволення студентів
- Базовий запит для аналізу якості послуг

### 18. Відгуки з мінімальною оцінкою

```sql
SELECT
    r.rating,
    r.comment 
FROM review r 
WHERE r.rating = (
    SELECT MIN(rating)
    FROM review 
);
```

**Пояснення:**
- Підзапит знаходить найнижчу оцінку в системі
- Основний запит повертає всі відгуки з цією оцінкою
- Важливо для аналізу проблем та покращення сервісу

### 19. Пошук конкретного студента за ім'ям

```sql
SELECT 
    s.* 
FROM student s
WHERE student_id = (
    SELECT user_id 
    FROM "user" 
    WHERE first_name = 'Анна' AND last_name = 'Сідоренко'
);
```

**Пояснення:**
- Двоетапний пошук: спочатку знайти ID користувача, потім дані студента
- Підзапит повинен повертати точно один результат
- Демонструє зв'язок між таблицями `user` та `student`

### 20. Студенти старших класів (два варіанти)

```sql
-- Варіант з підзапитом
SELECT 
    u.* 
FROM "user" u
WHERE user_id IN (
    SELECT student_id 
    FROM student 
    WHERE school_grade > 9
);

-- Варіант з CTE (Common Table Expression)
WITH high_school_grade AS (
    SELECT student_id 
    FROM student 
    WHERE school_grade > 9
)
SELECT 
    u.* 
FROM "user" u
INNER JOIN high_school_grade ON high_school_grade.student_id = u.user_id;
```

**Пояснення:**
- Перший варіант використовує підзапит з `IN`
- Другий варіант використовує CTE для кращої читабельності
- `CTE` створює тимчасову іменовану таблицю
- Обидва запити дають однаковий результат
- CTE краще для складних запитів з повторним використанням підзапитів

---

## Складні аналітичні запити

### Ключові особливості OLAP запитів:

1. **Агрегація даних** - використання функцій `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
2. **Групування** - `GROUP BY` для аналізу по категоріях
3. **Фільтрація груп** - `HAVING` для умов після агрегації
4. **З'єднання таблиць** - `JOIN` для комплексного аналізу
5. **Підзапити** - для складних умов та багаторівневого аналізу
6. **CTE** - для структурування складних запитів

### Рекомендації по оптимізації:

- Використовуйте індекси на колонки, що часто використовуються в `WHERE` та `JOIN`
- Обмежуйте результати за допомогою `LIMIT` при тестуванні
- Використовуйте `EXPLAIN` для аналізу планів виконання запитів
- Розбивайте складні запити на менші частини для кращої читабельності

### Практичне застосування:

Ці запити використовуються для:
- Генерації звітів про діяльність платформи
- Аналізу ефективності репетиторів
- Виявлення трендів та паттернів
- Прийняття бізнес-рішень на основі даних
- Моніторингу KPI (Key Performance Indicators)