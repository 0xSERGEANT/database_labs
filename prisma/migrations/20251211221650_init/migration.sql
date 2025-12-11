-- CreateEnum
CREATE TYPE "booking_format" AS ENUM ('online', 'offline');

-- CreateEnum
CREATE TYPE "booking_status" AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "user_type" AS ENUM ('student', 'tutor');

-- CreateTable
CREATE TABLE "booking" (
    "booking_id" SERIAL NOT NULL,
    "student_id" INTEGER NOT NULL,
    "tutor_subject_id" INTEGER NOT NULL,
    "schedule_id" INTEGER NOT NULL,
    "format" "booking_format" NOT NULL,
    "status" "booking_status" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_pkey" PRIMARY KEY ("booking_id")
);

-- CreateTable
CREATE TABLE "city" (
    "city_id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "region" VARCHAR(100),
    "country" VARCHAR(100) NOT NULL DEFAULT 'Україна',

    CONSTRAINT "city_pkey" PRIMARY KEY ("city_id")
);

-- CreateTable
CREATE TABLE "review" (
    "review_id" SERIAL NOT NULL,
    "booking_id" INTEGER NOT NULL,
    "rating" SMALLINT NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "is_anonymous" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "review_pkey" PRIMARY KEY ("review_id")
);

-- CreateTable
CREATE TABLE "schedule" (
    "schedule_id" SERIAL NOT NULL,
    "tutor_id" INTEGER NOT NULL,
    "date" DATE NOT NULL,
    "start_time" TIME(6) NOT NULL,
    "end_time" TIME(6) NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "schedule_pkey" PRIMARY KEY ("schedule_id")
);

-- CreateTable
CREATE TABLE "student" (
    "student_id" INTEGER NOT NULL,
    "city_id" INTEGER,
    "school_grade" SMALLINT,

    CONSTRAINT "student_pkey" PRIMARY KEY ("student_id")
);

-- CreateTable
CREATE TABLE "subject" (
    "subject_id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "category" VARCHAR(100) NOT NULL,
    "description" TEXT,

    CONSTRAINT "subject_pkey" PRIMARY KEY ("subject_id")
);

-- CreateTable
CREATE TABLE "teaching_level" (
    "level_id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "position" SMALLINT NOT NULL,
    "description" TEXT,

    CONSTRAINT "teaching_level_pkey" PRIMARY KEY ("level_id")
);

-- CreateTable
CREATE TABLE "tutor" (
    "tutor_id" INTEGER NOT NULL,
    "city_id" INTEGER,
    "years_experience" SMALLINT NOT NULL DEFAULT 0,
    "education" TEXT NOT NULL,
    "about_me" TEXT,
    "online_available" BOOLEAN NOT NULL DEFAULT true,
    "offline_available" BOOLEAN NOT NULL DEFAULT true,
    "address" TEXT,

    CONSTRAINT "tutor_pkey" PRIMARY KEY ("tutor_id")
);

-- CreateTable
CREATE TABLE "tutor_subject" (
    "tutor_subject_id" SERIAL NOT NULL,
    "tutor_id" INTEGER NOT NULL,
    "subject_id" INTEGER NOT NULL,
    "level_id" INTEGER NOT NULL,
    "hourly_rate" DECIMAL(8,2) NOT NULL,

    CONSTRAINT "tutor_subject_pkey" PRIMARY KEY ("tutor_subject_id")
);

-- CreateTable
CREATE TABLE "user" (
    "user_id" SERIAL NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "user_type" "user_type" NOT NULL,
    "date_of_birth" DATE,
    "registration_date" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_pkey" PRIMARY KEY ("user_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "booking_schedule_id_key" ON "booking"("schedule_id");

-- CreateIndex
CREATE UNIQUE INDEX "city_unique_location" ON "city"("name", "region", "country");

-- CreateIndex
CREATE UNIQUE INDEX "review_booking_id_key" ON "review"("booking_id");

-- CreateIndex
CREATE UNIQUE INDEX "schedule_unique_slot" ON "schedule"("tutor_id", "date", "start_time", "end_time");

-- CreateIndex
CREATE UNIQUE INDEX "subject_name_key" ON "subject"("name");

-- CreateIndex
CREATE UNIQUE INDEX "teaching_level_name_key" ON "teaching_level"("name");

-- CreateIndex
CREATE UNIQUE INDEX "teaching_level_position_key" ON "teaching_level"("position");

-- CreateIndex
CREATE UNIQUE INDEX "ts_unique_combination" ON "tutor_subject"("tutor_id", "subject_id", "level_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_email_key" ON "user"("email");

-- CreateIndex
CREATE UNIQUE INDEX "user_phone_key" ON "user"("phone");

-- AddForeignKey
ALTER TABLE "booking" ADD CONSTRAINT "booking_schedule_fk" FOREIGN KEY ("schedule_id") REFERENCES "schedule"("schedule_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking" ADD CONSTRAINT "booking_student_fk" FOREIGN KEY ("student_id") REFERENCES "student"("student_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking" ADD CONSTRAINT "booking_tutor_subject_fk" FOREIGN KEY ("tutor_subject_id") REFERENCES "tutor_subject"("tutor_subject_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "review" ADD CONSTRAINT "review_booking_fk" FOREIGN KEY ("booking_id") REFERENCES "booking"("booking_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "schedule" ADD CONSTRAINT "schedule_tutor_fk" FOREIGN KEY ("tutor_id") REFERENCES "tutor"("tutor_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student" ADD CONSTRAINT "student_city_fk" FOREIGN KEY ("city_id") REFERENCES "city"("city_id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student" ADD CONSTRAINT "student_user_fk" FOREIGN KEY ("student_id") REFERENCES "user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tutor" ADD CONSTRAINT "tutor_city_fk" FOREIGN KEY ("city_id") REFERENCES "city"("city_id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tutor" ADD CONSTRAINT "tutor_user_fk" FOREIGN KEY ("tutor_id") REFERENCES "user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tutor_subject" ADD CONSTRAINT "ts_level_fk" FOREIGN KEY ("level_id") REFERENCES "teaching_level"("level_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tutor_subject" ADD CONSTRAINT "ts_subject_fk" FOREIGN KEY ("subject_id") REFERENCES "subject"("subject_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tutor_subject" ADD CONSTRAINT "ts_tutor_fk" FOREIGN KEY ("tutor_id") REFERENCES "tutor"("tutor_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddCheckConstraint
ALTER TABLE "teaching_level" ADD CONSTRAINT "level_position_positive" CHECK (position > 0);

-- AddCheckConstraint
ALTER TABLE "tutor" ADD CONSTRAINT "tutor_availability_check" CHECK (online_available = TRUE OR offline_available = TRUE);

-- AddCheckConstraint
ALTER TABLE "tutor" ADD CONSTRAINT "tutor_offline_requirements" CHECK (offline_available = FALSE OR (offline_available = TRUE AND city_id IS NOT NULL AND address IS NOT NULL));

-- AddCheckConstraint
ALTER TABLE "schedule" ADD CONSTRAINT "schedule_future_date" CHECK (date >= CURRENT_DATE);

-- AddCheckConstraint
ALTER TABLE "schedule" ADD CONSTRAINT "schedule_valid_time_range" CHECK (end_time > start_time);

-- AddCheckConstraint
ALTER TABLE "schedule" ADD CONSTRAINT "schedule_duration_60min" CHECK (EXTRACT(EPOCH FROM (end_time - start_time)) / 60 = 60);