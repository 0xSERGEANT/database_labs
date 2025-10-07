create table if not exists "city" (
    city_id integer generated always as identity primary key,
    name varchar(100) not null,
    region varchar(100),
    country varchar(100) not null default 'Україна',
    
    constraint city_name_not_empty 
        check (trim(name) != ''),
    constraint city_country_not_empty 
        check (trim(country) != ''),
    constraint city_name_capitalized 
        check (left(trim(name), 1) = upper(left(trim(name), 1))),
    constraint city_country_capitalized 
        check (left(trim(country), 1) = upper(left(trim(country), 1))),
    
    constraint city_unique_location 
        unique (name, region, country)
);

create table if not exists "subject" (
    subject_id integer generated always as identity primary key,
    name varchar(100) not null unique,
    category varchar(50) not null,
    description text,
    
    constraint subject_name_not_empty 
        check (trim(name) != ''),
    constraint subject_valid_category 
        check (category in (
            'Точні науки', 
            'Природничі науки', 
            'Гуманітарні науки', 
            'Іноземні мови', 
            'Мистецтво'
        )),
    constraint subject_description_length 
        check (length(description) <= 500)
);

create table if not exists "teaching_level" (
    level_id integer generated always as identity primary key,
    name varchar(100) not null unique,
    position smallint not null unique,
    description text,
    
    constraint level_name_not_empty 
        check (trim(name) != ''),
    constraint level_position_positive 
        check (position > 0),
    constraint level_description_length 
        check (length(description) <= 300)
);

create table if not exists "user" (
    user_id integer generated always as identity primary key,
    email varchar(255) not null unique,
    password_hash varchar(255) not null,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    phone varchar(20),
    user_type varchar(10) not null,
    registration_date timestamp default current_timestamp,
    
    constraint user_valid_type 
        check (user_type in ('student', 'tutor')),
    constraint user_valid_email 
        check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    constraint user_first_name_not_empty 
        check (trim(first_name) != ''),
    constraint user_last_name_not_empty 
        check (trim(last_name) != ''),
    constraint user_phone_format 
        check (phone is null or phone ~* '^\+?[0-9\s\-\(\)]{10,20}$')
);

create table if not exists "student" (
    student_id integer primary key,
    city_id integer,
    age smallint,
    school_grade smallint,
    
    constraint student_user_fk 
        foreign key (student_id) references "user"(user_id) on delete cascade,
    constraint student_city_fk 
        foreign key (city_id) references "city"(city_id) on delete set null,
    
    constraint student_valid_age 
        check (age >= 5 and age <= 99),
    constraint student_valid_grade 
        check (school_grade between 1 and 11 or school_grade is null)
);

create table if not exists "tutor" (
    tutor_id integer primary key,
    city_id integer,
    age smallint not null,
    years_experience smallint not null default 0,
    education text not null,
    about_me text,
    online_available boolean not null default true,
    offline_available boolean not null default true,
    address text,
    average_rating decimal(3,2) default 0.00,
    total_reviews integer default 0,
    
    constraint tutor_user_fk 
        foreign key (tutor_id) references "user"(user_id) on delete cascade,
    constraint tutor_city_fk 
        foreign key (city_id) references "city"(city_id) on delete set null,
    
    constraint tutor_valid_age 
        check (age >= 18 and age <= 99),
    constraint tutor_valid_experience 
        check (years_experience >= 0 and years_experience <= (age - 16)),
    constraint tutor_valid_rating 
        check (average_rating >= 0.00 and average_rating <= 5.00),
    constraint tutor_positive_reviews 
        check (total_reviews >= 0),
    constraint tutor_availability_check 
        check (online_available = true or offline_available = true),
    constraint tutor_offline_requirements 
        check (
            offline_available = false or 
            (offline_available = true and city_id is not null and address is not null)
        ),
    constraint tutor_education_not_empty 
        check (trim(education) != ''),
    constraint tutor_about_me_length 
        check (length(about_me) <= 2000),
    constraint tutor_address_length 
        check (length(address) <= 500)
);

create table if not exists "tutor_subject" (
    tutor_subject_id integer generated always as identity primary key,
    tutor_id integer not null,
    subject_id integer not null,
    level_id integer not null,
    hourly_rate decimal(8,2) not null,
    
    constraint ts_tutor_fk 
        foreign key (tutor_id) references "tutor"(tutor_id) on delete cascade,
    constraint ts_subject_fk 
        foreign key (subject_id) references "subject"(subject_id) on delete cascade,
    constraint ts_level_fk 
        foreign key (level_id) references "teaching_level"(level_id) on delete cascade,

    constraint ts_hourly_rate_range_check 
        check (hourly_rate > 0 and hourly_rate <= 10000.00),
    constraint ts_unique_combination 
        unique (tutor_id, subject_id, level_id)
);

create table if not exists "schedule" (
    schedule_id integer generated always as identity primary key,
    tutor_id integer not null,
    date date not null,
    start_time time not null,
    end_time time not null,
    is_available boolean not null default true,
    created_at timestamp default current_timestamp,
    
    constraint schedule_tutor_fk 
        foreign key (tutor_id) references "tutor"(tutor_id) on delete cascade,
    
    constraint schedule_future_date 
        check (date >= current_date),
    constraint schedule_valid_time_range 
		check (end_time > start_time),
	constraint schedule_duration_60min 
		check (extract(epoch from (end_time - start_time))/60 = 60),
    constraint schedule_unique_slot 
        unique (tutor_id, date, start_time, end_time),
);

create table if not exists "booking" (
    booking_id integer generated always as identity primary key,
    student_id integer not null,
    tutor_id integer not null,
    subject_id integer not null,
    level_id integer not null,
    schedule_id integer not null,
    format varchar(10) not null,
    status varchar(20) not null default 'pending',
    created_at timestamp default current_timestamp,
    notes text,
    
    constraint booking_student_fk 
        foreign key (student_id) references "student"(student_id) on delete cascade,
    constraint booking_tutor_fk 
        foreign key (tutor_id) references "tutor"(tutor_id) on delete cascade,
    constraint booking_subject_fk 
        foreign key (subject_id) references "subject"(subject_id),
    constraint booking_level_fk 
        foreign key (level_id) references "teaching_level"(level_id),
    constraint booking_schedule_fk 
        foreign key (schedule_id) references "schedule"(schedule_id) on delete cascade,

    constraint booking_valid_format 
        check (format in ('online', 'offline')),
    constraint booking_valid_status 
        check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
    constraint booking_notes_length 
        check (length(notes) <= 500)
);

create table if not exists "review" (
    review_id integer generated always as identity primary key,
    booking_id integer not null unique,
    student_id integer not null,
    tutor_id integer not null,
    rating smallint not null,
    comment text,
    created_at timestamp default current_timestamp,
    is_anonymous boolean not null default false,
    
    constraint review_booking_fk 
        foreign key (booking_id) references "booking"(booking_id) on delete cascade,
    constraint review_student_fk 
        foreign key (student_id) references "student"(student_id) on delete cascade,
    constraint review_tutor_fk 
        foreign key (tutor_id) references "tutor"(tutor_id) on delete cascade,
    
    constraint review_valid_rating 
        check (rating >= 1 and rating <= 5),
    constraint review_comment_length 
        check (length(comment) <= 1500)
);


create index idx_user_email on "user"(email);
create index idx_user_type on "user"(user_type);

create index idx_student_city on student(city_id);
create index idx_student_age on student(age);

create index idx_tutor_city on tutor(city_id);
create index idx_tutor_rating on tutor(average_rating desc);
create index idx_tutor_experience on tutor(years_experience desc);
create index idx_tutor_availability on tutor(online_available, offline_available);

create index idx_tutor_subject_lookup on tutor_subject(subject_id, level_id, hourly_rate);
create index idx_tutor_subject_tutor on tutor_subject(tutor_id);

create index idx_schedule_availability on schedule(tutor_id, date, is_available);
create index idx_schedule_date on schedule(date) where is_available = true;

create index idx_booking_student on booking(student_id);
create index idx_booking_tutor on booking(tutor_id);
create index idx_booking_status on booking(status);
create index idx_booking_created on booking(created_at);

create index idx_review_tutor on review(tutor_id);
create index idx_review_rating on review(rating);
create index idx_review_created on review(created_at);


insert into city (name, region, country) values
('Київ', null, 'Україна'),
('Харків', 'Харківська область', 'Україна'),
('Одеса', 'Одеська область', 'Україна'),
('Запоріжжя', 'Запорізька область', 'Україна'),
('Дніпро', 'Дніпропетровська область', 'Україна'),
('Львів', 'Львівська область', 'Україна'),
('Вінниця', 'Вінницька область', 'Україна'),
('Полтава', 'Полтавська область', 'Україна');

insert into subject (name, category, description) values
('Математика', 'Точні науки', 'Алгебра, геометрія, математичний аналіз, підготовка до олімпіади'),
('Фізика', 'Точні науки', 'Загальна програма, підготовка до олімпіади'),
('Англійська мова', 'Іноземні мови', 'Граматика, лексика, розмовна практика'),
('Українська мова', 'Гуманітарні науки', 'Загальна програма, написання есе, підготовка до олімпіади'),
('Хімія', 'Природничі науки', 'Неорганічна та органічна хімія, підготовка до олімпіади'),
('Біологія', 'Природничі науки', 'Ботаніка, анатомія, підготовка до олімпіади'),
('Історія України', 'Гуманітарні науки', 'Історія з стародавніх часів до сучасності'),
('Географія', 'Природничі науки', 'Фізична та економічна географія'),
('Німецька мова', 'Іноземні мови', 'Граматика, лексика, розмовна практика');

insert into teaching_level (name, position, description) values
('1-4 класи (початкова школа)', 1, 'Базові навички та знання'),
('5-9 класи (середня школа)', 2, 'Поглиблене вивчення предметів'),
('10-11 класи (старша школа)', 3, 'Підготовка до випускних екзаменів'),
('Підготовка до ДПА', 4, 'Державна підсумкова атестація'),
('Підготовка до ЄВІ', 5, 'Єдиний вступний іспит до магістратури'),
('Університетський рівень', 6, 'Допомога студентам ВНЗ'),
('Дорослі', 7, 'Навчання для дорослих');

insert into "user" (email, password_hash, first_name, last_name, phone, user_type) values
('ivan.petrenko@gmail.com', 'qwerty123', 'Іван', 'Петренко', '+380671234567', 'tutor'),
('maria.kovalenko@gmail.com', 'maria2024', 'Марія', 'Коваленко', '+380672345678', 'tutor'),
('oleksandr.shevchenko@gmail.com', 'alex_sher', 'Олександр', 'Шевченко', '+380673456789', 'tutor'),
('tetiana.bondarenko@gmail.com', 'tanya456', 'Тетяна', 'Бондаренко', '+380674567890', 'tutor'),
('andriy.lysenko@gmail.com', 'andy2024', 'Андрій', 'Лисенко', '+380675678901', 'tutor'),

('anna.sidorenko@gmail.com', 'anna123', 'Анна', 'Сідоренко', '+380676789012', 'student'),
('maksym.tkachenko@gmail.com', 'max_tkach', 'Максим', 'Ткаченко', '+380677890123', 'student'),
('sofia.morozova@gmail.com', 'sofia2024', 'Софія', 'Морозова', '+380678901234', 'student'),
('dmytro.boyko@gmail.com', 'dima_boy', 'Дмитро', 'Бойко', '+380679012345', 'student'),
('oksana.savchenko@gmail.com', 'oks_sav', 'Оксана', 'Савченко', '+380670123456', 'student'),
('viktor.petrenko@gmail.com', 'vova_pet', 'Віктор', 'Петренко', '+380671234568', 'student'),
('yulia.kravchenko@gmail.com', 'yulia789', 'Юлія', 'Кравченко', '+380672345679', 'student');

insert into tutor (tutor_id, city_id, age, years_experience, education, about_me, online_available, offline_available, address, average_rating, total_reviews) values
(1, 1, 35, 12, 'КНУ ім. Шевченка, механіко-математичний факультет, кандидат фізико-математичних наук', 'Досвідчений викладач математики з 12-річним стажем. Спеціалізуюся на підготовці до ДПА та олімпіад.', true, true, 'вул. Хрещатик, 25, кв. 15', 4.8, 45),
(2, 2, 28, 6, 'ХНУ ім. Каразіна, філологічний факультет, магістр філології', 'Викладаю англійську мову всіх рівнів. Маю сертифікати TESOL та Cambridge CELTA.', true, true, 'вул. Сумська, 12, кв. 8', 4.9, 32),
(3, 3, 42, 18, 'ОНУ ім. Мечникова, фізичний факультет, доктор фізико-математичних наук', 'Професор фізики з великим досвідом. Готую до вступу у ВНЗ та олімпіад.', true, false, null, 4.7, 67),
(4, 1, 31, 8, 'НПУ ім. Драгоманова, хімічний факультет, кандидат хімічних наук', 'Спеціалізуюся на органічній та неорганічній хімії. Готую до ДПА та ЄВІ.', true, true, 'вул. Володимирська, 88, кв. 22', 4.6, 28),
(5, 4, 26, 4, 'ЗНУ, історичний факультет, магістр історії', 'Молодий але досвідчений викладач історії України та всесвітньої історії.', true, true, 'вул. Соборна, 45, кв. 12', 4.5, 18);

insert into student (student_id, city_id, age, school_grade) values
(6, 1, 17, 11),
(7, 2, 15, 7),
(8, 3, 16, 10),
(9, 1, 14, 8),
(10, 5, 18, 11),
(11, 1, 8, 2),
(12, 2, 22, 5);

insert into tutor_subject (tutor_id, subject_id, level_id, hourly_rate) values
(1, 1, 2, 350.00),
(1, 1, 3, 450.00),
(1, 1, 4, 550.00),

(2, 3, 1, 300.00),
(2, 3, 2, 400.00),
(2, 3, 3, 500.00),
(2, 3, 5, 600.00),

(3, 2, 2, 400.00),
(3, 2, 3, 500.00),
(3, 2, 5, 650.00),
(3, 2, 6, 700.00),

(4, 5, 2, 380.00),
(4, 5, 3, 480.00),
(4, 5, 4, 520.00),
(4, 5, 5, 580.00),

(5, 7, 2, 320.00),
(5, 7, 3, 420.00),
(5, 7, 4, 470.00),
(5, 7, 5, 520.00);

insert into schedule (tutor_id, date, start_time, end_time, is_available) values
(1, '2025-11-15', '09:00:00', '10:00:00', true),
(1, '2025-11-15', '10:00:00', '11:00:00', false),
(1, '2025-11-16', '14:00:00', '15:00:00', true),

(2, '2025-11-15', '16:00:00', '17:00:00', true),
(2, '2025-11-16', '11:00:00', '12:00:00', false),
(2, '2025-11-17', '09:00:00', '10:00:00', true),

(3, '2025-11-15', '13:00:00', '14:00:00', true),
(3, '2025-11-16', '15:00:00', '16:00:00', true),

(4, '2025-11-18', '10:00:00', '11:00:00', false),
(4, '2025-11-19', '14:00:00', '15:00:00', true),

(5, '2025-11-20', '16:00:00', '17:00:00', true),
(5, '2025-11-21', '12:00:00', '13:00:00', true);

insert into booking (student_id, tutor_id, subject_id, level_id, schedule_id, format, status, notes) values
(6, 1, 1, 4, 3, 'online', 'completed', 'Підготовка до ДПА з математики'),
(7, 2, 3, 2, 5, 'offline', 'completed', 'Покращення граматики'),
(8, 4, 5, 3, 9, 'online', 'completed', 'Органічна хімія'),
(9, 1, 1, 2, 10, 'online', 'pending', 'Алгебра 8 клас'),
(10, 3, 2, 5, 7, 'offline', 'confirmed', 'Механіка для ЄВІ');

insert into review (booking_id, student_id, tutor_id, rating, comment, is_anonymous) values
(1, 6, 1, 5, 'Відмінний репетитор! Пояснює дуже зрозуміло, допоміг підготуватися до ДПА.', false),
(2, 7, 2, 5, 'Марія дуже терпляча і професійна. Англійська стала набагато зрозумілішою.', false),
(3, 8, 4, 4, 'Хороше пояснення матеріалу, але хотілося б більше практичних завдань.', true);