# Звіт по нормалізації бази даних системи пошуку персонального репетитора

## Зміст
1. [Вступ](#1-вступ)
2. [Оригінальний дизайн таблиць (до нормалізації)](#2-оригінальний-дизайн-таблиць-до-нормалізації)
3. [Перероблений дизайн таблиць (після нормалізації)](#3-перероблений-дизайн-таблиць-після-нормалізації)
4. [ALTER TABLE команди для кожної зміненої таблиці](#4-alter-table-команди-для-кожної-зміненої-таблиці)
5. [Функціональні залежності](#5-функціональні-залежності)
6. [Покрокове пояснення нормалізації](#6-покрокове-пояснення-нормалізації)

---

## 1. Вступ

Цей документ описує процес нормалізації бази даних системи пошуку персонального репетитора з метою приведення схеми до **третьої нормальної форми (3НФ)**. Нормалізація проводилась для:

- Усунення надмірності даних
- Запобігання аномаліям вставки, оновлення та видалення
- Забезпечення цілісності та узгодженості даних
- Покращення структури бази даних відповідно до принципів реляційної моделі

**Історія змін:** Нормалізація виконана у 7 комітах (від `bd0e321` до `0e991b7`), включаючи:
- Коментування полів, що порушують нормалізацію
- Видалення надмірних атрибутів із таблиць `student`, `tutor`, `booking`, `review`
- Додавання обчислюваних атрибутів до відповідних таблиць
- Оновлення ER-діаграми

---

## 2. Оригінальний дизайн таблиць (до нормалізації)

### 2.1 Таблиця `user` (Користувачі)

**Структура:**
```sql
CREATE TABLE IF NOT EXISTS "user"
(
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    birth_date DATE,                    -- ⚠️ ПРОБЛЕМА: похідний атрибут для age
    phone VARCHAR(20),
    user_type user_type NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Проблеми:**
- `birth_date` був відсутній, але `age` зберігався окремо в `student` та `tutor`
- Порушення DRY-принципу: вік може бути обчислений з дати народження

---

### 2.2 Таблиця `student` (Студенти)

**Структура:**
```sql
CREATE TABLE IF NOT EXISTS "student"
(
    student_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    age SMALLINT,                       -- ⚠️ ПРОБЛЕМА: транзитивна залежність
    school_grade SMALLINT,
    
    CONSTRAINT student_user_fk
        FOREIGN KEY (student_id) 
        REFERENCES "user" (user_id) 
        ON DELETE CASCADE
);
```

**Проблеми:**
- `age` є похідним атрибутом від `birth_date` з таблиці `user`
- Транзитивна залежність: `student_id → user_id → birth_date → age`
- Надмірність: вік потрібно оновлювати вручну або через тригери

---

### 2.3 Таблиця `tutor` (Репетитори)

**Структура:**
```sql
CREATE TABLE IF NOT EXISTS "tutor"
(
    tutor_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    age SMALLINT NOT NULL,              -- ⚠️ ПРОБЛЕМА: транзитивна залежність
    years_experience SMALLINT NOT NULL DEFAULT 0,
    education TEXT NOT NULL,
    about_me TEXT,
    online_available BOOLEAN NOT NULL DEFAULT TRUE,
    offline_available BOOLEAN NOT NULL DEFAULT TRUE,
    address TEXT,
    average_rating DECIMAL(3, 2) DEFAULT 0.00,    -- ⚠️ ПРОБЛЕМА: агрегатне значення
    total_reviews INTEGER DEFAULT 0,              -- ⚠️ ПРОБЛЕМА: агрегатне значення
    
    CONSTRAINT tutor_user_fk
        FOREIGN KEY (tutor_id) 
        REFERENCES "user" (user_id) 
        ON DELETE CASCADE
);
```

**Проблеми:**
- `age` — транзитивна залежність від `birth_date`
- `average_rating` — обчислюване значення з таблиці `review`
- `total_reviews` — обчислюване значення з таблиці `review`
- Функціональна залежність: `tutor_id → review.rating → AVG(rating), COUNT(*)`

---

### 2.4 Таблиця `booking` (Бронювання)

**Структура:**
```sql
CREATE TABLE IF NOT EXISTS "booking"
(
    booking_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER NOT NULL,
    tutor_id INTEGER NOT NULL,          -- ⚠️ ПРОБЛЕМА: дублювання
    subject_id INTEGER NOT NULL,        -- ⚠️ ПРОБЛЕМА: дублювання
    level_id INTEGER NOT NULL,          -- ⚠️ ПРОБЛЕМА: дублювання
    schedule_id INTEGER NOT NULL UNIQUE,
    format booking_format NOT NULL,
    status booking_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,                          -- ДОДАТКОВО: в даному полі немає сенсу 
    
    CONSTRAINT booking_student_fk
        FOREIGN KEY (student_id) REFERENCES "student" (student_id),
    CONSTRAINT booking_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id),
    CONSTRAINT booking_subject_fk
        FOREIGN KEY (subject_id) REFERENCES "subject" (subject_id),
    CONSTRAINT booking_level_fk
        FOREIGN KEY (level_id) REFERENCES "teaching_level" (level_id)
);
```

**Проблеми:**
- `tutor_id`, `subject_id`, `level_id` дублюють інформацію з `tutor_subject_id`
- Порушення 2НФ: часткові залежності неключових атрибутів

---

### 2.5 Таблиця `review` (Відгуки)

**Структура:**
```sql
CREATE TABLE IF NOT EXISTS "review"
(
    review_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE,
    student_id INTEGER NOT NULL,        -- ⚠️ ПРОБЛЕМА: транзитивна залежність
    tutor_id INTEGER NOT NULL,          -- ⚠️ ПРОБЛЕМА: транзитивна залежність
    rating SMALLINT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT review_booking_fk
        FOREIGN KEY (booking_id) REFERENCES "booking" (booking_id),
    CONSTRAINT review_student_fk
        FOREIGN KEY (student_id) REFERENCES "student" (student_id),
    CONSTRAINT review_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id)
);
```

**Проблеми:**
- `student_id` та `tutor_id` можуть бути отримані з `booking`
- Транзитивна залежність: `review_id → booking_id → (student_id, tutor_id)`
- Порушення 3НФ: неключові атрибути залежать від інших неключових атрибутів

---

## 3. Перероблений дизайн таблиць (після нормалізації)

### 3.1 Таблиця `user` (Користувачі)

**Оновлена структура:**
```sql
CREATE TABLE IF NOT EXISTS "user"
(
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    date_of_birth DATE,                 -- ДОДАНО: джерело для обчислення віку
    phone VARCHAR(20),
    user_type user_type NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Покращення:**
- Додано `date_of_birth` для зберігання базової інформації
- Вік тепер може бути обчислений динамічно через VIEW або на рівні застосунку
- Усунено дублювання віку в дочірніх таблицях

---

### 3.2 Таблиця `student` (Студенти)

**Оновлена структура:**
```sql
CREATE TABLE IF NOT EXISTS "student"
(
    student_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    school_grade SMALLINT,              -- age ВИДАЛЕНО
    
    CONSTRAINT student_user_fk
        FOREIGN KEY (student_id) 
        REFERENCES "user" (user_id) 
        ON DELETE CASCADE
);
```

**Покращення:**
- Видалено `age` — тепер обчислюється з `user.date_of_birth`
- Усунено транзитивну залежність
- Таблиця містить тільки атрибути, що безпосередньо залежать від `student_id`

---

### 3.3 Таблиця `tutor` (Репетитори)

**Оновлена структура:**
```sql
CREATE TABLE IF NOT EXISTS "tutor"
(
    tutor_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    years_experience SMALLINT NOT NULL DEFAULT 0,
    education TEXT NOT NULL,
    about_me TEXT,
    online_available BOOLEAN NOT NULL DEFAULT TRUE,
    offline_available BOOLEAN NOT NULL DEFAULT TRUE,
    address TEXT,
    -- age, average_rating, total_reviews ВИДАЛЕНО
    
    CONSTRAINT tutor_user_fk
        FOREIGN KEY (tutor_id) 
        REFERENCES "user" (user_id) 
        ON DELETE CASCADE
);
```

**Покращення:**
- Видалено `age` — обчислюється з `user.date_of_birth`
- Видалено `average_rating` та `total_reviews` — агрегатні значення з `review`
- Рейтинг та кількість відгуків обчислюються через VIEW або агрегатні запити
- Усунено функціональні залежності між неключовими атрибутами

---

### 3.4 Таблиця `booking` (Бронювання)

**Оновлена структура:**
```sql
CREATE TABLE IF NOT EXISTS "booking"
(
    booking_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER NOT NULL,
    tutor_subject_id INTEGER NOT NULL,  -- Єдине посилання на предмет репетитора
    schedule_id INTEGER NOT NULL UNIQUE,
    format booking_format NOT NULL,
    status booking_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- tutor_id, subject_id, level_id, notes ВИДАЛЕНО
    
    CONSTRAINT booking_student_fk
        FOREIGN KEY (student_id) 
        REFERENCES "student" (student_id) 
        ON DELETE CASCADE,
    
    CONSTRAINT booking_tutor_subject_fk
        FOREIGN KEY (tutor_subject_id) 
        REFERENCES "tutor_subject" (tutor_subject_id)
        ON DELETE CASCADE,
    
    CONSTRAINT booking_schedule_fk
        FOREIGN KEY (schedule_id) 
        REFERENCES "schedule" (schedule_id) 
        ON DELETE CASCADE
);
```

**Покращення:**
- Видалено `tutor_id`, `subject_id`, `level_id` — доступні через `tutor_subject_id`
- Видалено `notes` — не є критичним для моделі даних
- Усунено транзитивні залежності
- Залишено лише атрибути, що повністю залежать від `booking_id`

---

### 3.5 Таблиця `review` (Відгуки)

**Оновлена структура:**
```sql
CREATE TABLE IF NOT EXISTS "review"
(
    review_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE,
    rating SMALLINT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    -- student_id, tutor_id ВИДАЛЕНО
    
    CONSTRAINT review_booking_fk
        FOREIGN KEY (booking_id) 
        REFERENCES "booking" (booking_id) 
        ON DELETE CASCADE
);
```

**Покращення:**
- Видалено `student_id` та `tutor_id` — доступні через `booking`
- Усунено транзитивні залежності
- Таблиця тепер відповідає 3НФ

---

## 4. ALTER TABLE команди для кожної зміненої таблиці

### 4.1 Таблиця `user`

```sql
-- Додавання поля date_of_birth для зберігання дати народження
-- Замість зберігання віку окремо, він обчислюється з цієї дати
ALTER TABLE "user" 
ADD COLUMN IF NOT EXISTS date_of_birth DATE;
```

**Обґрунтування:**
- Додано базову інформацію, з якої похідний атрибут `age` може бути обчислений
- Уникнення дублювання та несинхронізованих даних
- Дата народження є незмінною, на відміну від віку

---

### 4.2 Таблиця `student`

```sql
-- Видалення поля age, оскільки воно є похідним від user.date_of_birth
-- Транзитивна залежність: student_id → user_id → date_of_birth → age
ALTER TABLE "student" 
DROP COLUMN IF EXISTS age;
```

**Обґрунтування:**
- Усунення транзитивної залежності `student_id → user_id → age`
- Вік обчислюється динамічно: `EXTRACT(YEAR FROM AGE(CURRENT_DATE, user.date_of_birth))`
- Автоматична актуальність даних без необхідності оновлення

---

### 4.3 Таблиця `tutor`

```sql
-- Видалення трьох полів, що порушують 3НФ:
-- 1. age - транзитивна залежність від user.date_of_birth
-- 2. average_rating - агрегатне значення, обчислюване з review
-- 3. total_reviews - агрегатне значення, обчислюване з review
ALTER TABLE "tutor" 
DROP COLUMN IF EXISTS age,
DROP COLUMN IF EXISTS average_rating, 
DROP COLUMN IF EXISTS total_reviews;
```

**Обґрунтування:**
- `age`: Транзитивна залежність `tutor_id → user_id → date_of_birth → age`
- `average_rating`: Функціональна залежність `tutor_id → review → AVG(rating)`
- `total_reviews`: Функціональна залежність `tutor_id → review → COUNT(*)`
- Агрегатні значення створюються через VIEW або обчислюються на льоту

---

### 4.4 Таблиця `booking`

```sql
-- Видалення чотирьох полів та додавання одного для відповідності 3НФ:
-- ВИДАЛЕННЯ:
-- 1. tutor_id, subject_id, level_id - доступні через tutor_subject_id
-- 2. notes - не є функціонально залежним від booking_id
-- ДОДАВАННЯ:
-- 1. tutor_subject_id - відновлення зв'язку після видалення надмірних полів

ALTER TABLE "booking" 
DROP COLUMN IF EXISTS tutor_id,
DROP COLUMN IF EXISTS subject_id,
DROP COLUMN IF EXISTS level_id,
DROP COLUMN IF EXISTS notes,
ADD COLUMN IF NOT EXISTS tutor_subject_id INTEGER NOT NULL,
ADD CONSTRAINT booking_tutor_subject_fk
    FOREIGN KEY (tutor_subject_id) 
    REFERENCES "tutor_subject" (tutor_subject_id)
    ON DELETE CASCADE;
```

**Обґрунтування:**
- Транзитивна залежність: `booking_id → tutor_subject_id → (tutor_id, subject_id, level_id)`
- Інформація про репетитора, предмет та рівень доступна через JOIN з `tutor_subject`
- `notes` видалено як необов'язковий атрибут, що не додає функціональної цінності
- `tutor_subject_id` забезпечує єдине джерело істини для бронювання

---

### 4.5 Таблиця `review`

```sql
-- Видалення student_id та tutor_id, оскільки вони доступні через booking
-- Транзитивні залежності:
-- review_id → booking_id → student_id
-- review_id → booking_id → tutor_subject_id → tutor_id
ALTER TABLE "review" 
DROP COLUMN IF EXISTS student_id,
DROP COLUMN IF EXISTS tutor_id;
```

**Обґрунтування:**
- Транзитивні залежності через `booking`:
  - `review_id → booking_id → student_id`
  - `review_id → booking_id → tutor_subject_id → tutor_id`
- Дані доступні через JOIN з таблицею `booking`
- Усунення дублювання та забезпечення консистентності

---

## 5. Функціональні залежності

### 5.1 Таблиця `user`

**Функціональні залежності (ФЗ):**
```
user_id → first_name, last_name, email, password_hash, date_of_birth, phone, user_type, registration_date
email → user_id (через UNIQUE)
```

**Аналіз:**
- **1НФ**: Всі атрибути атомарні
- **2НФ**: Первинний ключ простий, часткових залежностей немає
- **3НФ**: Немає транзитивних залежностей між неключовими атрибутами

---

### 5.2 Таблиця `student`

**До нормалізації:**
```
student_id → city_id, age, school_grade
student_id → user_id → date_of_birth → age  ⚠️ Транзитивна залежність
```

**Після нормалізації:**
```
student_id → city_id, school_grade
```

**Аналіз:**
- **1НФ**: Атомарні значення
- **2НФ**: Простий первинний ключ
- **3НФ**: Видалено `age`, усунуто транзитивну залежність

---

### 5.3 Таблиця `tutor`

**До нормалізації:**
```
tutor_id → city_id, age, years_experience, education, about_me, online_available, 
           offline_available, address, average_rating, total_reviews

tutor_id → user_id → date_of_birth → age              ⚠️ Транзитивна
tutor_id → {review} → AVG(rating) → average_rating    ⚠️ Агрегат
tutor_id → {review} → COUNT(*) → total_reviews        ⚠️ Агрегат
```

**Після нормалізації:**
```
tutor_id → city_id, years_experience, education, about_me, online_available, 
           offline_available, address
```

**Аналіз:**
- **1НФ**: Атомарні значення
- **2НФ**: Простий первинний ключ
- **3НФ**: Видалено `age`, `average_rating`, `total_reviews`

---

### 5.4 Таблиця `booking`

**До нормалізації:**
```
booking_id → student_id, tutor_subject_id, tutor_id, subject_id, level_id, 
             schedule_id, format, status, created_at, notes

booking_id → tutor_subject_id → (tutor_id, subject_id, level_id)  ⚠️ Транзитивні
```

**Після нормалізації:**
```
booking_id → student_id, tutor_subject_id, schedule_id, format, status, created_at
```

**Аналіз:**
- **1НФ**: Атомарні значення
- **2НФ**: Первинний ключ простий (автоінкрементний)
- **3НФ**: Видалено `tutor_id`, `subject_id`, `level_id`, `notes`

---

### 5.5 Таблиця `review`

**До нормалізації:**
```
review_id → booking_id, student_id, tutor_id, rating, comment, created_at, is_anonymous

review_id → booking_id → student_id     ⚠️ Транзитивна
review_id → booking_id → tutor_id       ⚠️ Транзитивна
```

**Після нормалізації:**
```
review_id → booking_id, rating, comment, created_at, is_anonymous
booking_id → review_id (через UNIQUE)
```

**Аналіз:**
- **1НФ**: Атомарні значення
- **2НФ**: Простий первинний ключ
- **3НФ**: Видалено `student_id` та `tutor_id`

---

### 5.6 Таблиці, що не потребували змін

#### Таблиця `city`
```
city_id → name, region, country
(name, region, country) → city_id (через UNIQUE)
```
Вже у 3НФ

#### Таблиця `subject`
```
subject_id → name, category, description
name → subject_id (через UNIQUE)
```
Вже у 3НФ

#### Таблиця `teaching_level`
```
level_id → name, position, description
name → level_id (через UNIQUE)
position → level_id (через UNIQUE)
```
Вже у 3НФ

#### Таблиця `tutor_subject`
```
tutor_subject_id → tutor_id, subject_id, level_id, hourly_rate
(tutor_id, subject_id, level_id) → tutor_subject_id (через UNIQUE)
```
Вже у 3НФ

#### Таблиця `schedule`
```
schedule_id → tutor_id, date, start_time, end_time, is_available, created_at
(tutor_id, date, start_time, end_time) → schedule_id (через UNIQUE)
```
Вже у 3НФ

---

## 6. Покрокове пояснення нормалізації

### 6.1 Перша нормальна форма (1НФ)

**Визначення:** Таблиця у 1НФ, якщо:
- Всі атрибути містять тільки атомарні (неподільні) значення
- Немає повторюваних груп або масивів значень
- Кожен рядок унікальний (є первинний ключ)

**Статус до нормалізації:**
Всі таблиці вже були у 1НФ:
- Використовуються прості типи даних (INTEGER, VARCHAR, DATE, BOOLEAN)
- Немає масивів або JSON-полів
- Кожна таблиця має первинний ключ
- Відсутні повторювані групи

**Приклад дотримання 1НФ (таблиця `user`):**
```sql
-- ПРАВИЛЬНО (1НФ)
user_id | first_name | last_name | email
--------|-----------|-----------|------------------
1       | Іван      | Петренко  | ivan@example.com
2       | Марія     | Коваль    | maria@example.com

-- НЕПРАВИЛЬНО (порушення 1НФ)
user_id | full_name        | emails
--------|------------------|--------------------------------
1       | Іван Петренко    | ivan@example.com, ivan2@gmail.com
```

---

### 6.2 Друга нормальна форма (2НФ)

**Визначення:** Таблиця у 2НФ, якщо:
- Вона у 1НФ
- Немає часткових залежностей неключових атрибутів від частини складеного ключа

**Застосування до нашої БД:**

Більшість таблиць мають прості (несоставні) первинні ключі, тому 2НФ виконується автоматично. Проте, таблиця `booking` мала проблему:

#### 6.2.1 Таблиця `booking` — аналіз 2НФ

**До нормалізації:**
```sql
booking_id | student_id | tutor_subject_id | tutor_id | subject_id | level_id | ...
-----------|------------|------------------|----------|------------|----------|-----
1          | 5          | 3                | 2        | 1          | 4        | ...
```

**Проблема:**
Хоча первинний ключ простий (`booking_id`), атрибути `tutor_id`, `subject_id`, `level_id` фактично залежать від `tutor_subject_id`:

```
Функціональні залежності:
booking_id → tutor_subject_id
tutor_subject_id → (tutor_id, subject_id, level_id)

Транзитивна залежність:
booking_id → tutor_subject_id → (tutor_id, subject_id, level_id)
```

Це створює **часткову надмірність**, коли інформація про репетитора та предмет дублюється.

**Після нормалізації:**
```sql
booking_id | student_id | tutor_subject_id | schedule_id | format  | status
-----------|------------|------------------|-------------|---------|----------
1          | 5          | 3                | 8           | online  | confirmed
```

Тепер `tutor_id`, `subject_id`, `level_id` отримуються через JOIN з `tutor_subject`.

---

### 6.3 Третя нормальна форма (3НФ)

**Визначення:** Таблиця у 3НФ, якщо:
- Вона у 2НФ
- Немає транзитивних залежностей (неключові атрибути не залежать від інших неключових атрибутів)

**Правило:** Кожен неключовий атрибут повинен залежати **безпосередньо** від первинного ключа, а не через інші атрибути.

---

#### 6.3.1 Таблиця `student` — нормалізація до 3НФ

**КРОК 1: Ідентифікація порушення 3НФ**

```sql
-- До нормалізації (порушення 3НФ)
student_id | city_id | age | school_grade
-----------|---------|-----|-------------
1          | 3       | 17  | 11

Функціональні залежності:
student_id → user_id → date_of_birth → age  ⚠️ ТРАНЗИТИВНА
```

**Проблема:** `age` залежить від `date_of_birth`, який зберігається в `user`, а не безпосередньо від `student_id`.

**КРОК 2: Усунення транзитивної залежності**

1. Додати `date_of_birth` до таблиці `user` (базова інформація)
2. Видалити `age` з `student` (похідна інформація)

```sql
-- user (джерело даних)
user_id | date_of_birth
--------|---------------
1       | 2007-05-15

-- student (після нормалізації 3НФ)
student_id | city_id | school_grade
-----------|---------|-------------
1          | 3       | 11
```

**КРОК 3: Обчислення віку динамічно**

```sql
-- Запит для отримання віку студента
SELECT 
    s.student_id,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.date_of_birth)) AS age,
    s.school_grade
FROM student s
JOIN "user" u ON s.student_id = u.user_id;
```

**Переваги:**
- Вік завжди актуальний
- Немає необхідності оновлювати щороку
- Усунуто аномалію оновлення

---

#### 6.3.2 Таблиця `tutor` — нормалізація до 3НФ

**КРОК 1: Ідентифікація порушень 3НФ**

```sql
-- До нормалізації (порушення 3НФ)
tutor_id | age | average_rating | total_reviews | years_experience | ...
---------|-----|----------------|---------------|------------------|-----
2        | 35  | 4.75           | 8             | 10               | ...

Транзитивні залежності:
1. tutor_id → user_id → date_of_birth → age
2. tutor_id → {review} → AVG(rating) → average_rating
3. tutor_id → {review} → COUNT(*) → total_reviews
```

**Проблема 1:** `age` — похідний атрибут від `date_of_birth`  
**Проблема 2:** `average_rating` та `total_reviews` — агрегатні значення з таблиці `review`

**Аномалії:**
- **Оновлення:** Потрібно оновлювати рейтинг при додаванні/видаленні відгуку
- **Вставки:** Новий репетитор має рейтинг 0.00, що може бути некоректним
- **Видалення:** При видаленні всіх відгуків рейтинг залишається

**КРОК 2: Усунення транзитивних залежностей**

```sql
ALTER TABLE "tutor" 
DROP COLUMN age,
DROP COLUMN average_rating, 
DROP COLUMN total_reviews;
```

**Переваги:**
- Рейтинг завжди актуальний
- Немає дублювання даних
- Усунуто аномалії оновлення та видалення

---

#### 6.3.3 Таблиця `booking` — нормалізація до 3НФ

**КРОК 1: Ідентифікація порушення 3НФ**

```sql
-- До нормалізації (порушення 3НФ)
booking_id | tutor_subject_id | tutor_id | subject_id | level_id | notes
-----------|------------------|----------|------------|----------|-------
1          | 3                | 2        | 5          | 4        | ...

Транзитивні залежності:
booking_id → tutor_subject_id → (tutor_id, subject_id, level_id)
```

**Проблема:** Інформація про репетитора, предмет і рівень дублюється. Вона вже є в таблиці `tutor_subject`.

**КРОК 2: Усунення дублювання**

```sql
ALTER TABLE "booking" 
DROP COLUMN tutor_id,
DROP COLUMN subject_id,
DROP COLUMN level_id,
DROP COLUMN notes;  -- Додатково: необов'язковий атрибут

-- booking (після нормалізації 3НФ)
booking_id | student_id | tutor_subject_id | schedule_id | format  | status
-----------|------------|------------------|-------------|---------|----------
1          | 5          | 3                | 8           | online  | confirmed
```

**КРОК 3: Отримання повної інформації через JOIN**

```sql
SELECT 
    b.booking_id,
    b.student_id,
    ts.tutor_id,
    ts.subject_id,
    ts.level_id,
    s.name AS subject_name,
    tl.name AS level_name
FROM booking b
JOIN tutor_subject ts ON b.tutor_subject_id = ts.tutor_subject_id
JOIN subject s ON ts.subject_id = s.subject_id
JOIN teaching_level tl ON ts.level_id = tl.level_id;
```

**Переваги:**
- Єдине джерело істини для інформації про предмет
- Зміни в `tutor_subject` автоматично відображаються
- Зменшення обсягу даних

---

#### 6.3.4 Таблиця `review` — нормалізація до 3НФ

**КРОК 1: Ідентифікація порушення 3НФ**

```sql
-- До нормалізації (порушення 3НФ)
review_id | booking_id | student_id | tutor_id | rating | comment
----------|------------|------------|----------|--------|----------
1         | 5          | 7          | 2        | 5      | Відмінно!

Транзитивні залежності:
review_id → booking_id → student_id
review_id → booking_id → tutor_subject_id → tutor_id
```

**Проблема:** `student_id` та `tutor_id` можуть бути отримані з таблиці `booking`.

**КРОК 2: Усунення дублювання**

```sql
ALTER TABLE "review" 
DROP COLUMN student_id,
DROP COLUMN tutor_id;

-- review (після нормалізації 3НФ)
review_id | booking_id | rating | comment         | created_at
----------|------------|--------|-----------------|---------------------
1         | 5          | 5      | Відмінно!       | 2025-11-20 14:30:00
```

**КРОК 3: Отримання повної інформації через JOIN**

```sql
SELECT 
    r.review_id,
    r.booking_id,
    b.student_id,
    ts.tutor_id,
    r.rating,
    r.comment
FROM review r
JOIN booking b ON r.booking_id = b.booking_id
JOIN tutor_subject ts ON b.tutor_subject_id = ts.tutor_subject_id;
```

**Переваги:**
- Консистентність даних: зміни в `booking` автоматично відображаються
- Неможливість несинхронізації `student_id` або `tutor_id`
- Зменшення обсягу даних та індексів

---

### 6.4 Підсумок переходу по нормальних формах

| Таблиця | 1НФ | 2НФ | 3НФ (до) | 3НФ (після) | Зміни |
|---------|-----|-----|----------|-------------|-------|
| `user` | ✅ | ✅ | ✅ | ✅ | Додано `date_of_birth` |
| `student` | ✅ | ✅ | ❌ | ✅ | Видалено `age` |
| `tutor` | ✅ | ✅ | ❌ | ✅ | Видалено `age`, `average_rating`, `total_reviews` |
| `booking` | ✅ | ✅ | ❌ | ✅ | Видалено `tutor_id`, `subject_id`, `level_id`, `notes` |
| `review` | ✅ | ✅ | ❌ | ✅ | Видалено `student_id`, `tutor_id` |
| `city` | ✅ | ✅ | ✅ | ✅ | Без змін |
| `subject` | ✅ | ✅ | ✅ | ✅ | Без змін |
| `teaching_level` | ✅ | ✅ | ✅ | ✅ | Без змін |
| `tutor_subject` | ✅ | ✅ | ✅ | ✅ | Без змін |
| `schedule` | ✅ | ✅ | ✅ | ✅ | Без змін |

---
