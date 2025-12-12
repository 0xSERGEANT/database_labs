import { prisma } from './db';
import { logger } from './logger';

async function truncateDatabase() {
	const tables = [
		'review', 'payment', 'booking', 'schedule', 
		'tutor_subject', 'student', 'tutor', 'user', 
		'city', 'subject', 'teaching_level'
	] as const;
	
	for (const table of tables) {
		await (prisma[table] as any).deleteMany();
	}
}

async function seedData() {
	const [kyiv] = await prisma.city.createManyAndReturn({
		data: [
			{ name: 'Київ', country: 'Україна' },
			{ name: 'Львів', country: 'Україна' },
			{ name: 'Одеса', country: 'Україна' }
		]
	});

	const [math] = await prisma.subject.createManyAndReturn({
		data: [
			{ name: 'Математика', category: 'Точні науки' },
			{ name: 'Англійська мова', category: 'Мови' },
			{ name: 'Фізика', category: 'Природничі науки' }
		]
	});

	const [, middleSchool] = await prisma.teaching_level.createManyAndReturn({
		data: [
			{ name: '1-4 класи (початкова школа)', position: 1 },
			{ name: '5-9 класи (середня школа)', position: 2 },
			{ name: '10-11 класи (старша школа)', position: 3 }
		]
	});

	const student = await prisma.user.create({
		data: {
			first_name: 'Студент',
			last_name: 'Студентович',
			email: 'student@test.com',
			password_hash: '$2a$10$abcdefghijklmnopqrstuvwxyz',
			phone: '+380123456789',
			user_type: 'student',
			date_of_birth: new Date('2005-03-15'),
			student: {
				create: {
					city_id: kyiv.city_id,
					school_grade: 10
				}
			}
		},
		include: { student: true }
	});

	const tutor = await prisma.user.create({
		data: {
			first_name: 'Препод',
			last_name: 'Преподович',
			email: 'tutor@test.com',
			password_hash: '$2a$10$zyxwvutsrqponmlkjihgfedcba',
			phone: '+380987654321',
			user_type: 'tutor',
			date_of_birth: new Date('1990-07-20'),
			tutor: {
				create: {
					city_id: kyiv.city_id,
					years_experience: 5,
					education: 'Київський національний університет, магістр математики',
					about_me: 'Досвідчений репетитор з математики та фізики',
					address: 'вул. Хрещатик, 1',
					tutor_subject: {
						create: {
							subject_id: math.subject_id,
							level_id: middleSchool.level_id,
							hourly_rate: 350.00
						}
					}
				}
			}
		},
		include: {
			tutor: {
				include: { tutor_subject: true }
			}
		}
	});

	const schedule = await prisma.schedule.create({
		data: {
			tutor_id: tutor.tutor!.tutor_id,
			date: new Date('2025-12-15'),
			start_time: new Date('2025-12-15T14:00:00'),
			end_time: new Date('2025-12-15T15:00:00')
		}
	});

	await prisma.booking.create({
		data: {
			student_id: student.student!.student_id,
			tutor_subject_id: tutor.tutor!.tutor_subject[0].tutor_subject_id,
			schedule_id: schedule.schedule_id,
			format: 'online',
			status: 'confirmed',
			payment: {
				create: {
					amount: 350.00,
					status: 'success'
				}
			},
			review: {
				create: {
					rating: 5,
					comment: 'Чудовий репетитор! Все зрозуміло пояснює.'
				}
			}
		}
	});
}

async function logData() {
	logger.info('');
    
    const logTable = async (name: string, query: Promise<any[]>, formatter: (item: any) => string) => {
		const items = await query;
		logger.info(`${name} (${items.length}):`);
		items.forEach(item => logger.info(`  ${formatter(item)}`));
		logger.info('');
	};

	await logTable('Users', prisma.user.findMany(), 
		u => `${u.first_name} ${u.last_name} (${u.user_type}) - ${u.email}`);

	await logTable('Cities', prisma.city.findMany(), 
		c => `${c.name}, ${c.country}`);

	await logTable('Subjects', prisma.subject.findMany(), 
		s => `${s.name} (${s.category})`);

	const levels = await prisma.teaching_level.findMany({ orderBy: { position: 'asc' } });
	logger.info(`Teaching Levels (${levels.length}):`);
	levels.forEach(l => logger.info(`  ${l.position}. ${l.name}`));
	logger.info('');

	const tutors = await prisma.tutor.findMany({
		include: {
			user: true,
			city: true,
			tutor_subject: { include: { subject: true, teaching_level: true } }
		}
	});

	logger.info(`Tutors (${tutors.length}):`);
	tutors.forEach(t => {
		logger.info(`  ${t.user.first_name} ${t.user.last_name} (${t.years_experience} years)`);
		logger.info(`    City: ${t.city?.name || 'N/A'}`);
		logger.info(`    Subjects:`);
		t.tutor_subject.forEach(ts => {
			logger.info(`      - ${ts.subject.name} (${ts.teaching_level.name}) - ${ts.hourly_rate} UAH/hour`);
		});
	});
	logger.info('');

	const bookings = await prisma.booking.findMany({
		include: {
			student: { include: { user: true, city: true } },
			tutor_subject: {
				include: {
					tutor: { include: { user: true } },
					subject: true,
					teaching_level: true
				}
			},
			schedule: true,
			payment: true,
			review: true
		}
	});

	logger.info(`Bookings (${bookings.length}):`);
	bookings.forEach(b => {
		logger.info(`  Booking #${b.booking_id} (${b.status})`);
		logger.info(`    Student: ${b.student.user.first_name} ${b.student.user.last_name} from ${b.student.city?.name || 'N/A'}`);
		logger.info(`    Tutor: ${b.tutor_subject.tutor.user.first_name} ${b.tutor_subject.tutor.user.last_name}`);
		logger.info(`    Subject: ${b.tutor_subject.subject.name} (${b.tutor_subject.teaching_level.name})`);
		logger.info(`    Schedule: ${b.schedule.date.toISOString().split('T')[0]}`);
		logger.info(`    Format: ${b.format}`);
		if (b.payment) logger.info(`    Payment: ${b.payment.amount} UAH (${b.payment.status})`);
		if (b.review) logger.info(`    Review: ${b.review.rating}/5 - "${b.review.comment}"`);
	});
	
    logger.info('');
}

async function main() {
	try {
		await prisma.$connect();
		logger.info('Database connection established.');

		await truncateDatabase();
		await seedData();
		await logData();

		logger.info('✓ All queries executed successfully');
	} catch (error) {
		logger.error(error, 'An error occurred');
		process.exit(1);
	} finally {
		await prisma.$disconnect();
	}
}

main();