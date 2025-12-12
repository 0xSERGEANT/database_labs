# Примітки до міграцій бази даних

Даний документ містить детальну інформацію про всі міграції, застосовані до бази даних системи пошуку персонального репетитора.

## Зміст

1. [Міграція 1: init](#міграція-1-init)
2. [Міграція 2: add_payment_table](#міграція-2-add_payment_table)
3. [Міграція 3: add_user_avatar](#міграція-3-add_user_avatar)
4. [Міграція 4: drop_city_region](#міграція-4-drop_city_region)

---

## Міграція 1: init

**Ім'я міграції:** `20251211221650_init`

### Опис змін

Початкова міграція бази даних. Створено всі базові таблиці та зв'язки системи:

- **Створено таблиці:**
  - `user` - користувачі системи (студенти та репетитори)
  - `student` - профілі студентів
  - `tutor` - профілі репетиторів
  - `city` - міста для оффлайн занять
  - `subject` - предмети викладання
  - `teaching_level` - рівні викладання
  - `tutor_subject` - зв'язок між репетиторами, предметами та рівнями
  - `schedule` - розклад доступності репетиторів
  - `booking` - бронювання занять
  - `review` - відгуки про заняття

- **Створено enum типи:**
  - `user_type` - тип користувача (student, tutor)
  - `booking_format` - формат заняття (online, offline)
  - `booking_status` - статус бронювання (pending, confirmed, completed, cancelled)

- **Додано check constraints:**
  - `level_position_positive` - позиція рівня повинна бути додатною
  - `tutor_availability_check` - репетитор повинен бути доступний онлайн або оффлайн
  - `tutor_offline_requirements` - для оффлайн занять обов'язкові місто та адреса
  - `schedule_future_date` - заняття не можуть бути у минулому
  - `schedule_valid_time_range` - час закінчення повинен бути пізніше початку
  - `schedule_duration_60min` - тривалість заняття рівно 60 хвилин

### Стан схеми Prisma

```prisma
model user {
  user_id           Int       @id @default(autoincrement())
  first_name        String    @db.VarChar(100)
  last_name         String    @db.VarChar(100)
  email             String    @unique @db.VarChar(255)
  password_hash     String    @db.VarChar(255)
  phone             String?   @unique @db.VarChar(20)
  user_type         user_type
  date_of_birth     DateTime? @db.Date
  registration_date DateTime? @default(now()) @db.Timestamptz(6)
  student           student?
  tutor             tutor?
}

model city {
  city_id Int       @id @default(autoincrement())
  name    String    @db.VarChar(100)
  region  String?   @db.VarChar(100)
  country String    @default("Україна") @db.VarChar(100)
  student student[]
  tutor   tutor[]

  @@unique([name, region, country], map: "city_unique_location")
}

model booking {
  booking_id       Int            @id @default(autoincrement())
  student_id       Int
  tutor_subject_id Int
  schedule_id      Int            @unique
  format           booking_format
  status           booking_status @default(pending)
  created_at       DateTime?      @default(now()) @db.Timestamptz(6)
  schedule         schedule       @relation(...)
  student          student        @relation(...)
  tutor_subject    tutor_subject  @relation(...)
  review           review?
}
```

---

## Міграція 2: add_payment_table

**Ім'я міграції:** `20251211222200_add_payment_table`

### Опис змін

Додано функціонал обробки платежів:

- **Створено таблицю `payment`** з полями:
  - `payment_id` - первинний ключ
  - `booking_id` - унікальний зв'язок з бронюванням
  - `amount` - сума платежу (Decimal 10,2)
  - `payment_date` - дата та час платежу
  - `status` - статус платежу (за замовчуванням "success")

- **Додано зв'язок:**
  - `payment.booking_id` → `booking.booking_id` (CASCADE)

- **Оновлено модель `booking`:**
  - Додано зв'язок `payment?` (один до одного)

### Знімки Prisma схеми

#### До:

```prisma
model booking {
  booking_id       Int            @id @default(autoincrement())
  student_id       Int
  tutor_subject_id Int
  schedule_id      Int            @unique
  format           booking_format
  status           booking_status @default(pending)
  created_at       DateTime?      @default(now()) @db.Timestamptz(6)
  schedule         schedule       @relation(...)
  student          student        @relation(...)
  tutor_subject    tutor_subject  @relation(...)
  review           review?
}

// Модель payment не існувала
```

#### Після:

```prisma
model booking {
  booking_id       Int            @id @default(autoincrement())
  student_id       Int
  tutor_subject_id Int
  schedule_id      Int            @unique
  format           booking_format
  status           booking_status @default(pending)
  created_at       DateTime?      @default(now()) @db.Timestamptz(6)
  schedule         schedule       @relation(...)
  student          student        @relation(...)
  tutor_subject    tutor_subject  @relation(...)
  payment          payment?       // ← Додано
  review           review?
}

model payment {                    // ← Нова модель
  payment_id   Int      @id @default(autoincrement())
  booking_id   Int      @unique
  amount       Decimal  @db.Decimal(10, 2)
  payment_date DateTime @default(now()) @db.Timestamptz(6)
  status       String   @default("success") @db.VarChar(50)
  
  booking      booking  @relation(fields: [booking_id], references: [booking_id], onDelete: Cascade)  
}
```

---

## Міграція 3: add_user_avatar

**Ім'я міграції:** `20251211222359_add_user_avatar`

### Опис змін

Додано можливість зберігання URL аватара користувача:

- **Додано поле `avatar_url`** до таблиці `user`:
  - Тип: VARCHAR(500)
  - Nullable: так
  - Призначення: зберігання посилання на зображення профілю користувача

### Знімки Prisma схеми

#### До:

```prisma
model user {
  user_id           Int       @id @default(autoincrement())
  first_name        String    @db.VarChar(100)
  last_name         String    @db.VarChar(100)
  email             String    @unique @db.VarChar(255)
  password_hash     String    @db.VarChar(255)
  phone             String?   @unique @db.VarChar(20)
  user_type         user_type
  date_of_birth     DateTime? @db.Date
  registration_date DateTime? @default(now()) @db.Timestamptz(6)
  student           student?
  tutor             tutor?
}
```

#### Після:

```prisma
model user {
  user_id           Int       @id @default(autoincrement())
  first_name        String    @db.VarChar(100)
  last_name         String    @db.VarChar(100)
  email             String    @unique @db.VarChar(255)
  password_hash     String    @db.VarChar(255)
  avatar_url        String?   @db.VarChar(500)  // ← Додано
  phone             String?   @unique @db.VarChar(20)
  user_type         user_type
  date_of_birth     DateTime? @db.Date
  registration_date DateTime? @default(now()) @db.Timestamptz(6)
  student           student?
  tutor             tutor?
}
```

---

## Міграція 4: drop_city_region

**Ім'я міграції:** `20251211222528_drop_city_region`

### Опис змін

Спрощено структуру таблиці міст, видалено поле `region`:

- **Оновлено унікальний індекс:**
  - Було: `[name, region, country]`
  - Стало: `[name, country]`

### Знімки Prisma схеми

#### До:

```prisma
model city {
  city_id Int       @id @default(autoincrement())
  name    String    @db.VarChar(100)
  region  String?   @db.VarChar(100)        // ← Видалено
  country String    @default("Україна") @db.VarChar(100)
  student student[]
  tutor   tutor[]

  @@unique([name, region, country], map: "city_unique_location")  // ← Змінено
}
```

#### Після:

```prisma
model city {
  city_id Int       @id @default(autoincrement())
  name    String    @db.VarChar(100)
  country String    @default("Україна") @db.VarChar(100)
  student student[]
  tutor   tutor[]

  @@unique([name, country], map: "city_unique_location")
}