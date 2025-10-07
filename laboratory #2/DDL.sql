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