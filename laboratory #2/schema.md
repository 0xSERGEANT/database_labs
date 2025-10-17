# Аналіз сутностей фізичної бази даних PostgreSQL системи пошуку персонального репетитора

## 1. Загальний огляд схеми

База даних системи пошуку персонального репетитора складається з **10 основних таблиць**, що реалізують функціональність пошуку, бронювання та оцінки послуг репетиторів. Схема підтримує різні типи користувачів (студенти та репетитори), географічне розміщення, багатопредметне викладання та систему відгуків.

## 2. Детальний опис таблиць

### 2.1 Таблиця `city` (Міста)
**Призначення:** Зберігання інформації про географічні локації для офлайн занять.

**Стовпці:**
- `city_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор міста
- `name` - VARCHAR(100), NOT NULL - назва міста
- `region` - VARCHAR(100), NULLABLE - область/регіон
- `country` - VARCHAR(100), NOT NULL, DEFAULT 'Україна' - країна

**Ключові обмеження:**
- `city_unique_location` - UNIQUE(name, region, country) - унікальність комбінації місто-регіон-країна

### 2.2 Таблиця `subject` (Предмети)
**Призначення:** Каталог навчальних предметів, що викладаються в системі.

**Стовпці:**
- `subject_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор предмета
- `name` - VARCHAR(100), NOT NULL, UNIQUE - назва предмета
- `category` - VARCHAR(50), NOT NULL - категорія предмета
- `description` - TEXT, NULLABLE - опис предмета

**Ключові обмеження:**
- `subject_valid_category` - категорія повинна бути одною з: 'Точні науки', 'Природничі науки', 'Гуманітарні науки', 'Іноземні мови', 'Мистецтво'
- `subject_description_length` - опис не може перевищувати 500 символів

### 2.3 Таблиця `teaching_level` (Рівні викладання)
**Призначення:** Визначення рівнів складності навчання та освітніх ступенів.

**Стовпці:**
- `level_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор рівня
- `name` - VARCHAR(100), NOT NULL, UNIQUE - назва рівня
- `position` - SMALLINT, NOT NULL, UNIQUE - позиція в ієрархії (для сортування)
- `description` - TEXT, NULLABLE - опис рівня

**Ключові обмеження:**
- `level_position_positive` - позиція повинна бути позитивним числом
- `level_description_length` - опис не може перевищувати 300 символів

### 2.4 Таблиця `user` (Користувачі)
**Призначення:** Базова таблиця для зберігання загальної інформації про всіх користувачів системи.

**Стовпці:**
- `user_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор користувача
- `email` - VARCHAR(255), NOT NULL, UNIQUE - електронна пошта
- `password_hash` - VARCHAR(255), NOT NULL - хеш пароля
- `first_name` - VARCHAR(100), NOT NULL - ім'я
- `last_name` - VARCHAR(100), NOT NULL - прізвище
- `phone` - VARCHAR(20), NULLABLE - номер телефону
- `user_type` - VARCHAR(10), NOT NULL - тип користувача
- `registration_date` - TIMESTAMP, DEFAULT CURRENT_TIMESTAMP - дата реєстрації

**Ключові обмеження:**
- `user_valid_type` - тип користувача може бути тільки 'student' або 'tutor'

**Індекси:**
- `idx_user_email` - на email для швидкого пошуку при авторизації
- `idx_user_type` - на user_type для фільтрації за типом користувача

### 2.5 Таблиця `student` (Студенти)
**Призначення:** Розширена інформація про користувачів-студентів.

**Стовпці:**
- `student_id` - INTEGER, PRIMARY KEY, FOREIGN KEY → user(user_id) - ідентифікатор студента
- `city_id` - INTEGER, NULLABLE, FOREIGN KEY → city(city_id) - місто проживання
- `age` - SMALLINT, NULLABLE - вік студента
- `school_grade` - SMALLINT, NULLABLE - клас навчання

**Зовнішні ключі:**
- `student_user_fk` - посилання на user(user_id) з CASCADE DELETE
- `student_city_fk` - посилання на city(city_id) з SET NULL DELETE

**Ключові обмеження:**
_Відсутні на рівні бази даних (валідація на рівні застосунку)_

**Індекси:**
- `idx_student_city` - на city_id для географічного пошуку
- `idx_student_age` - на age для вікової фільтрації

### 2.6 Таблиця `tutor` (Репетитори)
**Призначення:** Розширена інформація про користувачів-репетиторів.

**Стовпці:**
- `tutor_id` - INTEGER, PRIMARY KEY, FOREIGN KEY → user(user_id) - ідентифікатор репетитора
- `city_id` - INTEGER, NULLABLE, FOREIGN KEY → city(city_id) - місто роботи
- `age` - SMALLINT, NOT NULL - вік репетитора
- `years_experience` - SMALLINT, NOT NULL, DEFAULT 0 - роки досвіду
- `education` - TEXT, NOT NULL - освіта
- `about_me` - TEXT, NULLABLE - опис "про себе"
- `online_available` - BOOLEAN, NOT NULL, DEFAULT TRUE - доступність онлайн
- `offline_available` - BOOLEAN, NOT NULL, DEFAULT TRUE - доступність офлайн
- `address` - TEXT, NULLABLE - адреса для офлайн занять
- `average_rating` - DECIMAL(3,2), DEFAULT 0.00 - середній рейтинг
- `total_reviews` - INTEGER, DEFAULT 0 - кількість відгуків

**Зовнішні ключі:**
- `tutor_user_fk` - посилання на user(user_id) з CASCADE DELETE
- `tutor_city_fk` - посилання на city(city_id) з SET NULL DELETE

**Ключові обмеження:**
- `tutor_availability_check` - принаймні один тип доступності повинен бути TRUE
- `tutor_offline_requirements` - для офлайн репетиторів обов'язкові місто та адреса
- `tutor_about_me_length` - опис не більше 2000 символів
- `tutor_address_length` - адреса не більше 500 символів

**Індекси:**
- `idx_tutor_city` - на city_id для географічного пошуку
- `idx_tutor_rating` - на average_rating (DESC) для сортування за рейтингом
- `idx_tutor_experience` - на years_experience (DESC) для сортування за досвідом
- `idx_tutor_availability` - на (online_available, offline_available) для фільтрації доступності

### 2.7 Таблиця `tutor_subject` (Предмети репетиторів)
**Призначення:** Проміжна таблиця для відображення зв'язку багато-до-багатьох між репетиторами та предметами з додатковою інформацією.

**Стовпці:**
- `tutor_subject_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор зв'язку
- `tutor_id` - INTEGER, NOT NULL, FOREIGN KEY → tutor(tutor_id) - репетитор
- `subject_id` - INTEGER, NOT NULL, FOREIGN KEY → subject(subject_id) - предмет
- `level_id` - INTEGER, NOT NULL, FOREIGN KEY → teaching_level(level_id) - рівень
- `hourly_rate` - DECIMAL(8,2), NOT NULL - ціна за годину

**Зовнішні ключі:**
- `ts_tutor_fk` - посилання на tutor(tutor_id) з CASCADE DELETE
- `ts_subject_fk` - посилання на subject(subject_id) з CASCADE DELETE
- `ts_level_fk` - посилання на teaching_level(level_id) з CASCADE DELETE

**Ключові обмеження:**
- `ts_unique_combination` - UNIQUE(tutor_id, subject_id, level_id) - унікальність комбінації

**Індекси:**
- `idx_tutor_subject_lookup` - на (subject_id, level_id, hourly_rate) для пошуку за предметом
- `idx_tutor_subject_tutor` - на tutor_id для отримання предметів репетитора

### 2.8 Таблиця `schedule` (Розклад)
**Призначення:** Зберігання вільних годин репетиторів для бронювання.

**Стовпці:**
- `schedule_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор слоту
- `tutor_id` - INTEGER, NOT NULL, FOREIGN KEY → tutor(tutor_id) - репетитор
- `date` - DATE, NOT NULL - дата
- `start_time` - TIME, NOT NULL - час початку
- `end_time` - TIME, NOT NULL - час закінчення
- `is_available` - BOOLEAN, NOT NULL, DEFAULT TRUE - доступність слоту
- `created_at` - TIMESTAMP, DEFAULT CURRENT_TIMESTAMP - час створення

**Зовнішні ключі:**
- `schedule_tutor_fk` - посилання на tutor(tutor_id) з CASCADE DELETE

**Ключові обмеження:**
- `schedule_future_date` - дата не може бути в минулому
- `schedule_valid_time_range` - час закінчення повинен бути пізніше часу початку
- `schedule_duration_60min` - тривалість слоту рівно 60 хвилин
- `schedule_unique_slot` - UNIQUE(tutor_id, date, start_time, end_time) - унікальність слоту

**Індекси:**
- `idx_schedule_availability` - на (tutor_id, date, is_available) для пошуку вільних слотів
- `idx_schedule_date` - на date WHERE is_available = true для оптимізації запитів

### 2.9 Таблиця `booking` (Бронювання)
**Призначення:** Записи на заняття між студентами та репетиторами.

**Стовпці:**
- `booking_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор бронювання
- `student_id` - INTEGER, NOT NULL, FOREIGN KEY → student(student_id) - студент
- `tutor_id` - INTEGER, NOT NULL, FOREIGN KEY → tutor(tutor_id) - репетитор
- `subject_id` - INTEGER, NOT NULL, FOREIGN KEY → subject(subject_id) - предмет
- `level_id` - INTEGER, NOT NULL, FOREIGN KEY → teaching_level(level_id) - рівень
- `schedule_id` - INTEGER, NOT NULL, FOREIGN KEY → schedule(schedule_id) - слот розкладу
- `format` - VARCHAR(10), NOT NULL - формат заняття
- `status` - VARCHAR(20), NOT NULL, DEFAULT 'pending' - статус бронювання
- `created_at` - TIMESTAMP, DEFAULT CURRENT_TIMESTAMP - час створення
- `notes` - TEXT, NULLABLE - додаткові примітки

**Зовнішні ключі:**
- `booking_student_fk` - посилання на student(student_id) з CASCADE DELETE
- `booking_tutor_fk` - посилання на tutor(tutor_id) з CASCADE DELETE
- `booking_subject_fk` - посилання на subject(subject_id) без CASCADE
- `booking_level_fk` - посилання на teaching_level(level_id) без CASCADE
- `booking_schedule_fk` - посилання на schedule(schedule_id) з CASCADE DELETE

**Ключові обмеження:**
- `booking_valid_format` - формат може бути 'online' або 'offline'
- `booking_valid_status` - статус може бути 'pending', 'confirmed', 'completed', 'cancelled'
- `booking_notes_length` - примітки не більше 500 символів

**Індекси:**
- `idx_booking_student` - на student_id для історії студента
- `idx_booking_tutor` - на tutor_id для історії репетитора
- `idx_booking_status` - на status для фільтрації за статусом
- `idx_booking_created` - на created_at для сортування за датою

### 2.10 Таблиця `review` (Відгуки)
**Призначення:** Відгуки та оцінки репетиторів від студентів.

**Стовпці:**
- `review_id` - INTEGER GENERATED ALWAYS AS IDENTITY, PRIMARY KEY - унікальний ідентифікатор відгуку
- `booking_id` - INTEGER, NOT NULL, UNIQUE, FOREIGN KEY → booking(booking_id) - пов'язане бронювання
- `student_id` - INTEGER, NOT NULL, FOREIGN KEY → student(student_id) - автор відгуку
- `tutor_id` - INTEGER, NOT NULL, FOREIGN KEY → tutor(tutor_id) - репетитор
- `rating` - SMALLINT, NOT NULL - оцінка (1-5)
- `comment` - TEXT, NULLABLE - текст відгуку
- `created_at` - TIMESTAMP, DEFAULT CURRENT_TIMESTAMP - дата створення
- `is_anonymous` - BOOLEAN, NOT NULL, DEFAULT FALSE - анонімність відгуку

**Зовнішні ключі:**
- `review_booking_fk` - посилання на booking(booking_id) з CASCADE DELETE
- `review_student_fk` - посилання на student(student_id) з CASCADE DELETE
- `review_tutor_fk` - посилання на tutor(tutor_id) з CASCADE DELETE

**Ключові обмеження:**
- `review_comment_length` - коментар не більше 1500 символів
- UNIQUE на booking_id - один відгук на бронювання

**Індекси:**
- `idx_review_tutor` - на tutor_id для відгуків репетитора
- `idx_review_rating` - на rating для фільтрації за оцінкою
- `idx_review_created` - на created_at для сортування за датою

## 3. Ключові архітектурні рішення

### 3.1 Наслідування типів користувачів
Система використовує підхід "table-per-type", де базова таблиця `user` містить загальну інформацію, а спеціалізовані таблиці `student` та `tutor` - специфічні атрибути.

### 3.2 Гнучка система предметів та рівнів
Зв'язок багато-до-багатьох між репетиторами та предметами через таблицю `tutor_subject` дозволяє:
- Репетитору викладати декілька предметів
- Один предмет може викладатися на різних рівнях
- Індивідуальні ціни за годину для кожної комбінації предмет-рівень

### 3.3 Система бронювання
Процес бронювання передбачає:
1. Репетитор створює слоти в `schedule`
2. Студент бронює слот через `booking`
3. Після заняття студент може залишити відгук в `review`

### 3.4 Підтримка онлайн та офлайн занять
Система підтримує обидва формати з відповідними валідаціями:
- Офлайн репетитори повинні мати місто та адресу
- Принаймні один тип доступності повинен бути активним

## 4. Система валідацій та обмежень

### 4.1 Розподіл валідації між рівнями

Система використовує гібридний підхід до валідації даних, де обмеження розподілені між рівнем бази даних та рівнем застосунку залежно від їх природи та призначення.

**Валідація на рівні застосунку:**

Більшість валідацій форматів, діапазонів значень та бізнес-правил обробляються на рівні застосунку, що забезпечує:
- Гнучкість у зміні правил без міграцій БД
- Детальніші та зрозуміліші повідомлення про помилки
- Можливість реалізації складної контекстної валідації
- Підтримку локалізації повідомлень
- Кращу продуктивність при масових операціях

Застосунок відповідає за валідацію:
- Форматів даних (email, телефон, капіталізація)
- Діапазонів числових значень (вік, досвід, рейтинг, ціна)
- Перевірки на порожні значення обов'язкових текстових полів
- Бізнес-правил (вік репетитора ≥ 18, досвід ≤ вік - 16)
- Оцінок та рейтингів (1-5 зірок)

### 4.2 Обмеження на рівні бази даних:

*Бізнес-логічні обмеження:*
- Тривалість заняття фіксована - 60 хвилин (`schedule_duration_60min`)
- Можливість створювати слоти тільки на майбутні дати (`schedule_future_date`)
- Час закінчення пізніше часу початку (`schedule_valid_time_range`)
- Принаймні один тип доступності репетитора (`tutor_availability_check`)
- Вимоги для офлайн репетиторів (`tutor_offline_requirements`)

*Обмеження довжини тексту:*
- Опис предмета ≤ 500 символів (`subject_description_length`)
- Опис рівня ≤ 300 символів (`level_description_length`)
- "Про себе" репетитора ≤ 2000 символів (`tutor_about_me_length`)
- Адреса репетитора ≤ 500 символів (`tutor_address_length`)
- Примітки до бронювання ≤ 500 символів (`booking_notes_length`)
- Коментар відгуку ≤ 1500 символів (`review_comment_length`)

### 4.3 Цілісність даних
- Каскадне видалення забезпечує цілісність при видаленні користувачів
- SET NULL для необов'язкових зв'язків (наприклад, місто)
- Унікальні обмеження запобігають дублюванню

## 5. Оптимізація продуктивності

Створено **15 індексів** для оптимізації найчастіших запитів:
- Пошук репетиторів за локацією, предметом, рейтингом
- Авторизація користувачів
- Перегляд розкладу та бронювань
- Аналіз відгуків та рейтингів

## 6. Тестові дані

База даних заповнена тестовими даними:
- 8 міст України
- 9 навчальних предметів у 5 категоріях
- 7 рівнів викладання
- 12 користувачів (5 репетиторів, 7 студентів)
- 19 комбінацій предмет-рівень для репетиторів
- 12 слотів розкладу
- 5 бронювань
- 3 відгуки