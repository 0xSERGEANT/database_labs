DO
$$
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
            CREATE TYPE user_type AS ENUM ('student', 'tutor');
        END IF;
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'subject_category') THEN
            CREATE TYPE subject_category AS ENUM ('Точні науки', 'Природничі науки', 'Гуманітарні науки', 'Іноземні мови', 'Мистецтво');
        END IF;
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'booking_format') THEN
            CREATE TYPE booking_format AS ENUM ('online', 'offline');
        END IF;
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
            CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
        END IF;
    END
$$;


CREATE TABLE IF NOT EXISTS "city"
(
    city_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    country VARCHAR(100) NOT NULL DEFAULT 'Україна',

    CONSTRAINT city_unique_location
        UNIQUE (name, region, country)
);

CREATE TABLE IF NOT EXISTS "subject"
(
    subject_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category subject_category NOT NULL,
    description TEXT,

    CONSTRAINT subject_description_length
        CHECK (LENGTH(description) <= 500)
);

CREATE TABLE IF NOT EXISTS "teaching_level"
(
    level_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    position SMALLINT NOT NULL UNIQUE,
    description TEXT,
  
    CONSTRAINT level_position_positive
        CHECK (position > 0),
    CONSTRAINT level_description_length
        CHECK (LENGTH(description) <= 300)
);

CREATE TABLE IF NOT EXISTS "user"
(
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    user_type user_type NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "student"
(
    student_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    age SMALLINT,
    school_grade SMALLINT,

    CONSTRAINT student_user_fk
        FOREIGN KEY (student_id) REFERENCES "user" (user_id) ON DELETE CASCADE,
    CONSTRAINT student_city_fk
        FOREIGN KEY (city_id) REFERENCES "city" (city_id) ON DELETE SET NULL,
);

CREATE TABLE IF NOT EXISTS "tutor"
(
    tutor_id INTEGER PRIMARY KEY,
    city_id INTEGER,
    age SMALLINT NOT NULL,
    years_experience SMALLINT NOT NULL DEFAULT 0,
    education TEXT NOT NULL,
    about_me TEXT,
    online_available BOOLEAN NOT NULL DEFAULT TRUE,
    offline_available BOOLEAN NOT NULL DEFAULT TRUE,
    address TEXT,
    average_rating DECIMAL(3, 2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,

    CONSTRAINT tutor_user_fk
        FOREIGN KEY (tutor_id) REFERENCES "user" (user_id) ON DELETE CASCADE,
    CONSTRAINT tutor_city_fk
        FOREIGN KEY (city_id) REFERENCES "city" (city_id) ON DELETE SET NULL,

    CONSTRAINT tutor_availability_check
        CHECK (online_available = TRUE OR offline_available = TRUE),
    CONSTRAINT tutor_offline_requirements
        CHECK (
            offline_available = FALSE OR
            (offline_available = TRUE AND city_id IS NOT NULL AND address IS NOT NULL)
            ),
    CONSTRAINT tutor_about_me_length
        CHECK (LENGTH(about_me) <= 2000),
    CONSTRAINT tutor_address_length
        CHECK (LENGTH(address) <= 500)
);

CREATE TABLE IF NOT EXISTS "tutor_subject"
(
    tutor_subject_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tutor_id INTEGER NOT NULL,
    subject_id INTEGER NOT NULL,
    level_id INTEGER NOT NULL,
    hourly_rate DECIMAL(8, 2) NOT NULL,

    CONSTRAINT ts_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id) ON DELETE CASCADE,
    CONSTRAINT ts_subject_fk
        FOREIGN KEY (subject_id) REFERENCES "subject" (subject_id) ON DELETE CASCADE,
    CONSTRAINT ts_level_fk
        FOREIGN KEY (level_id) REFERENCES "teaching_level" (level_id) ON DELETE CASCADE,

    CONSTRAINT ts_unique_combination
        UNIQUE (tutor_id, subject_id, level_id)
);

CREATE TABLE IF NOT EXISTS "schedule"
(
    schedule_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tutor_id INTEGER NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT schedule_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id) ON DELETE CASCADE,

    CONSTRAINT schedule_future_date
        CHECK (date >= current_date),
    CONSTRAINT schedule_valid_time_range
        CHECK (end_time > start_time),
    CONSTRAINT schedule_duration_60min
        CHECK (extract(epoch from (end_time - start_time)) / 60 = 60),
    CONSTRAINT schedule_unique_slot
        UNIQUE (tutor_id, date, start_time, end_time)
);

CREATE TABLE IF NOT EXISTS "booking"
(
    booking_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER NOT NULL,
    tutor_id INTEGER NOT NULL,
    subject_id INTEGER NOT NULL,
    level_id INTEGER NOT NULL,
    schedule_id INTEGER NOT NULL,
    format booking_format NOT NULL,
    status booking_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,

    CONSTRAINT booking_student_fk
        FOREIGN KEY (student_id) REFERENCES "student" (student_id) ON DELETE CASCADE,
    CONSTRAINT booking_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id) ON DELETE CASCADE,
    CONSTRAINT booking_subject_fk
        FOREIGN KEY (subject_id) REFERENCES "subject" (subject_id) ON DELETE CASCADE,
    CONSTRAINT booking_level_fk
        FOREIGN KEY (level_id) REFERENCES "teaching_level" (level_id) ON DELETE CASCADE,
    CONSTRAINT booking_schedule_fk
        FOREIGN KEY (schedule_id) REFERENCES "schedule" (schedule_id) ON DELETE CASCADE,

    CONSTRAINT booking_notes_length
        CHECK (length(notes) <= 500)
);

CREATE TABLE IF NOT EXISTS "review"
(
    review_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE,
    student_id INTEGER NOT NULL,
    tutor_id INTEGER NOT NULL,
    rating SMALLINT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT review_booking_fk
        FOREIGN KEY (booking_id) REFERENCES "booking" (booking_id) ON DELETE CASCADE,
    CONSTRAINT review_student_fk
        FOREIGN KEY (student_id) REFERENCES "student" (student_id) ON DELETE CASCADE,
    CONSTRAINT review_tutor_fk
        FOREIGN KEY (tutor_id) REFERENCES "tutor" (tutor_id) ON DELETE CASCADE,

    CONSTRAINT review_comment_length
        CHECK (length(comment) <= 1500)
);


CREATE INDEX IF NOT EXISTS idx_user_email ON "user" (email);
CREATE INDEX IF NOT EXISTS idx_user_type ON "user" (user_type);

CREATE INDEX IF NOT EXISTS idx_student_city ON student (city_id);
CREATE INDEX IF NOT EXISTS idx_student_age ON student (age);

CREATE INDEX IF NOT EXISTS idx_tutor_city ON tutor (city_id);
CREATE INDEX IF NOT EXISTS idx_tutor_rating ON tutor (average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_tutor_experience ON tutor (years_experience DESC);
CREATE INDEX IF NOT EXISTS idx_tutor_availability ON tutor (online_available, offline_available);

CREATE INDEX IF NOT EXISTS idx_tutor_subject_lookup ON tutor_subject (subject_id, level_id, hourly_rate);
CREATE INDEX IF NOT EXISTS idx_tutor_subject_tutor ON tutor_subject (tutor_id);

CREATE INDEX IF NOT EXISTS idx_schedule_availability ON schedule (tutor_id, date, is_available);
CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule (date) WHERE is_available = true;

CREATE INDEX IF NOT EXISTS idx_booking_student ON booking (student_id);
CREATE INDEX IF NOT EXISTS idx_booking_tutor ON booking (tutor_id);
CREATE INDEX IF NOT EXISTS idx_booking_status ON booking (status);
CREATE INDEX IF NOT EXISTS idx_booking_created ON booking (created_at);

CREATE INDEX IF NOT EXISTS idx_review_tutor ON review (tutor_id);
CREATE INDEX IF NOT EXISTS idx_review_rating ON review (rating);
CREATE INDEX IF NOT EXISTS idx_review_created ON review (created_at);


-- Sample DML data insertion (uncomment to use)
-- INSERT INTO city (name, region, country)
-- VALUES ('Київ', NULL, 'Україна'),
--        ('Харків', 'Харківська область', 'Україна'),
--        ('Одеса', 'Одеська область', 'Україна'),
--        ('Запоріжжя', 'Запорізька область', 'Україна'),
--        ('Дніпро', 'Дніпропетровська область', 'Україна'),
--        ('Львів', 'Львівська область', 'Україна'),
--        ('Вінниця', 'Вінницька область', 'Україна'),
--        ('Полтава', 'Полтавська область', 'Україна');

-- INSERT INTO subject (name, category, description)
-- VALUES ('Математика', 'Точні науки', 'Алгебра, геометрія, математичний аналіз, підготовка до олімпіади'),
--        ('Фізика', 'Точні науки', 'Загальна програма, підготовка до олімпіади'),
--        ('Англійська мова', 'Іноземні мови', 'Граматика, лексика, розмовна практика'),
--        ('Українська мова', 'Гуманітарні науки', 'Загальна програма, написання есе, підготовка до олімпіади'),
--        ('Хімія', 'Природничі науки', 'Неорганічна та органічна хімія, підготовка до олімпіади'),
--        ('Біологія', 'Природничі науки', 'Ботаніка, анатомія, підготовка до олімпіади'),
--        ('Історія України', 'Гуманітарні науки', 'Історія з стародавніх часів до сучасності'),
--        ('Географія', 'Природничі науки', 'Фізична та економічна географія'),
--        ('Німецька мова', 'Іноземні мови', 'Граматика, лексика, розмовна практика');

-- INSERT INTO teaching_level (name, position, description)
-- VALUES ('1-4 класи (початкова школа)', 1, 'Базові навички та знання'),
--        ('5-9 класи (середня школа)', 2, 'Поглиблене вивчення предметів'),
--        ('10-11 класи (старша школа)', 3, 'Підготовка до випускних екзаменів'),
--        ('Підготовка до ДПА', 4, 'Державна підсумкова атестація'),
--        ('Підготовка до ЄВІ', 5, 'Єдиний вступний іспит до магістратури'),
--        ('Університетський рівень', 6, 'Допомога студентам ВНЗ'),
--        ('Дорослі', 7, 'Навчання для дорослих');

-- INSERT INTO "user" (email, password_hash, first_name, last_name, phone, user_type)
-- VALUES ('ivan.petrenko@gmail.com', 'qwerty123', 'Іван', 'Петренко', '+380671234567', 'tutor'),
--        ('maria.kovalenko@gmail.com', 'maria2024', 'Марія', 'Коваленко', '+380672345678', 'tutor'),
--        ('oleksandr.shevchenko@gmail.com', 'alex_sher', 'Олександр', 'Шевченко', '+380673456789', 'tutor'),
--        ('tetiana.bondarenko@gmail.com', 'tanya456', 'Тетяна', 'Бондаренко', '+380674567890', 'tutor'),
--        ('andriy.lysenko@gmail.com', 'andy2024', 'Андрій', 'Лисенко', '+380675678901', 'tutor'),

--        ('anna.sidorenko@gmail.com', 'anna123', 'Анна', 'Сідоренко', '+380676789012', 'student'),
--        ('maksym.tkachenko@gmail.com', 'max_tkach', 'Максим', 'Ткаченко', '+380677890123', 'student'),
--        ('sofia.morozova@gmail.com', 'sofia2024', 'Софія', 'Морозова', '+380678901234', 'student'),
--        ('dmytro.boyko@gmail.com', 'dima_boy', 'Дмитро', 'Бойко', '+380679012345', 'student'),
--        ('oksana.savchenko@gmail.com', 'oks_sav', 'Оксана', 'Савченко', '+380670123456', 'student'),
--        ('viktor.petrenko@gmail.com', 'vova_pet', 'Віктор', 'Петренко', '+380671234568', 'student'),
--        ('yulia.kravchenko@gmail.com', 'yulia789', 'Юлія', 'Кравченко', '+380672345679', 'student');

-- INSERT INTO tutor (tutor_id, city_id, age, years_experience, education, about_me, online_available, offline_available,
--                    address, average_rating, total_reviews)
-- VALUES (1, 1, 35, 12, 'КНУ ім. Шевченка, механіко-математичний факультет, кандидат фізико-математичних наук',
--         'Досвідчений викладач математики з 12-річним стажем. Спеціалізуюся на підготовці до ДПА та олімпіад.', TRUE,
--         TRUE, 'вул. Хрещатик, 25, кв. 15', 4.8, 45),
--        (2, 2, 28, 6, 'ХНУ ім. Каразіна, філологічний факультет, магістр філології',
--         'Викладаю англійську мову всіх рівнів. Маю сертифікати TESOL та Cambridge CELTA.', TRUE, TRUE,
--         'вул. Сумська, 12, кв. 8', 4.9, 32),
--        (3, 3, 42, 18, 'ОНУ ім. Мечникова, фізичний факультет, доктор фізико-математичних наук',
--         'Професор фізики з великим досвідом. Готую до вступу у ВНЗ та олімпіад.', TRUE, FALSE, NULL, 4.7, 67),
--        (4, 1, 31, 8, 'НПУ ім. Драгоманова, хімічний факультет, кандидат хімічних наук',
--         'Спеціалізуюся на органічній та неорганічній хімії. Готую до ДПА та ЄВІ.', TRUE, TRUE,
--         'вул. Володимирська, 88, кв. 22', 4.6, 28),
--        (5, 4, 26, 4, 'ЗНУ, історичний факультет, магістр історії',
--         'Молодий але досвідчений викладач історії України та всесвітньої історії.', TRUE, TRUE,
--         'вул. Соборна, 45, кв. 12', 4.5, 18);

-- INSERT INTO student (student_id, city_id, age, school_grade)
-- VALUES (6, 1, 17, 11),
--        (7, 2, 15, 7),
--        (8, 3, 16, 10),
--        (9, 1, 14, 8),
--        (10, 5, 18, 11),
--        (11, 1, 8, 2),
--        (12, 2, 22, 5);

-- INSERT INTO tutor_subject (tutor_id, subject_id, level_id, hourly_rate)
-- VALUES (1, 1, 2, 350.00),
--        (1, 1, 3, 450.00),
--        (1, 1, 4, 550.00),

--        (2, 3, 1, 300.00),
--        (2, 3, 2, 400.00),
--        (2, 3, 3, 500.00),
--        (2, 3, 5, 600.00),

--        (3, 2, 2, 400.00),
--        (3, 2, 3, 500.00),
--        (3, 2, 5, 650.00),
--        (3, 2, 6, 700.00),

--        (4, 5, 2, 380.00),
--        (4, 5, 3, 480.00),
--        (4, 5, 4, 520.00),
--        (4, 5, 5, 580.00),

--        (5, 7, 2, 320.00),
--        (5, 7, 3, 420.00),
--        (5, 7, 4, 470.00),
--        (5, 7, 5, 520.00);

-- INSERT INTO schedule (tutor_id, date, start_time, end_time, is_available)
-- VALUES (1, '2025-11-15', '09:00:00', '10:00:00', TRUE),
--        (1, '2025-11-15', '10:00:00', '11:00:00', FALSE),
--        (1, '2025-11-16', '14:00:00', '15:00:00', TRUE),

--        (2, '2025-11-15', '16:00:00', '17:00:00', TRUE),
--        (2, '2025-11-16', '11:00:00', '12:00:00', FALSE),
--        (2, '2025-11-17', '09:00:00', '10:00:00', TRUE),

--        (3, '2025-11-15', '13:00:00', '14:00:00', TRUE),
--        (3, '2025-11-16', '15:00:00', '16:00:00', TRUE),

--        (4, '2025-11-18', '10:00:00', '11:00:00', FALSE),
--        (4, '2025-11-19', '14:00:00', '15:00:00', TRUE),

--        (5, '2025-11-20', '16:00:00', '17:00:00', TRUE),
--        (5, '2025-11-21', '12:00:00', '13:00:00', TRUE);

-- INSERT INTO booking (student_id, tutor_id, subject_id, level_id, schedule_id, format, status, notes)
-- VALUES (6, 1, 1, 4, 3, 'online', 'completed', 'Підготовка до ДПА з математики'),
--        (7, 2, 3, 2, 5, 'offline', 'completed', 'Покращення граматики'),
--        (8, 4, 5, 3, 9, 'online', 'completed', 'Органічна хімія'),
--        (9, 1, 1, 2, 10, 'online', 'pending', 'Алгебра 8 клас'),
--        (10, 3, 2, 5, 7, 'offline', 'confirmed', 'Механіка для ЄВІ');

-- INSERT INTO review (booking_id, student_id, tutor_id, rating, comment, is_anonymous)
-- VALUES (1, 6, 1, 5, 'Відмінний репетитор! Пояснює дуже зрозуміло, допоміг підготуватися до ДПА.', FALSE),
--        (2, 7, 2, 5, 'Марія дуже терпляча і професійна. Англійська стала набагато зрозумілішою.', FALSE),
--        (3, 8, 4, 4, 'Хороше пояснення матеріалу, але хотілося б більше практичних завдань.', TRUE);


-- To drop all tables (if needed), uncomment the block below
-- DO
-- $$
--     DECLARE
--         r RECORD;
--     BEGIN
--         FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
--             LOOP
--                 EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
--             END LOOP;
--     END
-- $$;

-- To drop all custom types (if needed), uncomment the block below
-- DO
-- $$
--     DECLARE
--         r RECORD;
--     BEGIN
--         FOR r IN (SELECT t.typname, t.typtype
--                   FROM pg_type t
--                            JOIN pg_namespace n ON t.typnamespace = n.oid
--                   WHERE n.nspname = 'public'
--                     AND t.typtype IN (
--                                       'e',
--                                       'd',
--                                       'c',
--                                       'r',
--                                       'b'
--                       )
--                     AND NOT EXISTS (SELECT 1 FROM pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
--                     AND NOT EXISTS (SELECT 1
--                                     FROM pg_class c
--                                     WHERE c.relname = t.typname AND c.relkind IN ('r', 'v', 'm')))
--             LOOP
--                 EXECUTE 'DROP TYPE IF EXISTS ' || quote_ident(r.typname) || ' CASCADE';
--             END LOOP;
--     END
-- $$;