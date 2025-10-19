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
        FOREIGN KEY (city_id) REFERENCES "city" (city_id) ON DELETE SET NULL
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