-- 1-Вывести к каждому самолету класс обслуживания и количество мест этого класса
select
	ad.model,
	count(s.seat_no) as total_seats,
	s.fare_conditions
from
	aircrafts_data ad
join seats s on
	ad.aircraft_code = s.aircraft_code
group by
	ad.model,
	s.fare_conditions;

-- 2-Найти 3 самых вместительных самолета (модель + кол-во мест)
select
	ad.model,
	count(s.seat_no) as total_seats
from
	seats s
join aircrafts_data ad on
	s.aircraft_code = ad.aircraft_code
group by
	ad.model
order by
	total_seats desc
limit 3;

-- 3-Найти все рейсы, которые задерживались более 2 часов
select
	f.flight_no
from
	flights f
where
	(f.actual_departure - f.scheduled_departure) > interval '2 hour'
	or (f.actual_arrival - f.scheduled_arrival) > interval '2 hour';

-- 4-Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select
	b.book_date,
	t.passenger_name,
	t.contact_data,
	tf.fare_conditions
from
	bookings b
join tickets t on
	b.book_ref = t.book_ref
join ticket_flights tf on
	t.ticket_no = tf.ticket_no
where
	tf.fare_conditions = 'Business'
order by
	b.book_date
limit 10;

-- 5-Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select
	f.flight_no
from
	flights f
join ticket_flights tf on
	f.flight_id = tf.flight_id
where
	tf.fare_conditions != 'Business'
group by
	f.flight_no
having
	count (tf.fare_conditions) = 0;


-- 6-Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой
select
	ad.airport_name,
	ad.city
from
	airports_data ad
join flights f on
	ad.airport_code = f.arrival_airport
where
	f.status = 'Delayed';

-- 7-Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select
	ad.airport_code,
	ad.airport_name,
	count(f.flight_id) as total_flights
from
	airports_data ad
join flights f on
	ad.airport_code = f.departure_airport
group by
	ad.airport_code
order by
	total_flights desc;

-- 8-Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select
	f.flight_no,
	f.departure_airport,
	f.arrival_airport,
	f.actual_arrival,
	f.scheduled_arrival
from
	flights f
where
	scheduled_arrival != actual_arrival;

-- 9-Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select
	ad.aircraft_code,
	ad.model,
	s.seat_no
from
	aircrafts_data ad
join seats s on
	ad.aircraft_code = s.aircraft_code
where
	ad.model::text like '%Аэробус A321-200%'
	and s.fare_conditions != 'Economy'
order by
	s.seat_no;

-- 10-Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select
	ad.airport_code,
	ad.airport_name,
	ad.city
from
	airports_data ad
where
	ad.city in (
	select
		ad.city
	from
		airports_data ad
	group by
		ad.city
	having
		count(ad.city) > 1
);

-- 11-Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
select
	t.passenger_id,
	t.passenger_name
from
	tickets t
join bookings b on
	t.book_ref = b.book_ref
group by
	t.passenger_id,
	t.passenger_name
having
	sum(b.total_amount) > (
	select
		avg(total_amount)
	from
		bookings)
order by
	t.passenger_name;

-- 12-Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
select
	f.flight_no,
	f.scheduled_departure,
	f.departure_airport,
	f.status
from
	flights f
join airports_data ad on
	f.departure_airport = ad.airport_code
where
	ad.city::text like '%Moscow%'
	and f.status::text = 'On Time'
order by
	f.scheduled_departure
limit 1;

-- 13-Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
select
	t.ticket_no,
	b.total_amount
from
	tickets t
join bookings b on
	t.book_ref = b.book_ref
where
	t.ticket_no = (
	select
		cheapest.ticket_no
	from
		(
		select
			t.ticket_no,
			b.total_amount
		from
			tickets t
		join bookings b on
			t.book_ref = b.book_ref
		order by
			b.total_amount asc
		limit 1
) as cheapest
)
	or 
t.ticket_no = (
	select
		expensive.ticket_no
	from
		(
		select
			t.ticket_no,
			b.total_amount
		from
			tickets t
		join bookings b on
			t.book_ref = b.book_ref
		order by
			b.total_amount desc
		limit 1
) as expensive
);

-- 14-Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
create table if not exists customers (
	id uuid,
	first_name varchar(40),
	last_name varchar(40),
	email text,
	phone json
);

alter table customers add constraint customers_primary_key primary key (id);

alter table customers add constraint customers_unique_id unique (id);

alter table customers alter column id set
not null;

alter table customers alter column first_name set
not null;

alter table customers alter column last_name set
not null;

alter table customers add constraint customers_unique_email unique (email);

alter table customers add constraint customers_check_email check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

alter table customers alter column email set
not null;

alter table customers add constraint customers_check_phone check ((phone ->> 'phone')::text ~* '^\+?\d{1,3}[-.\s]?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})$');

alter table customers alter column phone set
not null;

-- 15-Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
create table if not exists orders (
	id uuid,
	customer_id uuid,
	quantity bigint
);

alter table orders add constraint orders_primary_key primary key (id);

alter table orders add constraint orders_unique_id unique (id);

alter table orders alter column id set
not null;

alter table orders add constraint orders_customer_key foreign key (customer_id) references customers (id);

alter table orders alter column customer_id set
not null;

alter table orders add constraint orders_unique_customer_id unique (customer_id);

alter table orders alter column quantity set
not null;

-- 16-Написать 5 insert в эти таблицы
insert
	into
	customers(id,
	first_name ,
	last_name ,
	email,
	phone)
values ('1944dca7-16b1-43d9-a2f3-f3eab2a03cec', 'Дарья', 'Макаровна', 'dasha22@mail.ru', '375442237513'),
('260209ec-4f5c-4ced-8687-63ee56f2c20c', 'Максим', 'Борисович', 'maximbor95@gmail.com', '375294387523'),
('e9917753-2e1d-4d84-918a-e87bd54b5403', 'Роман', 'Ярославович', 'yar3125@yandex.by', '375297845262'),
('8f9e30bf-5e7c-4dbc-b0ec-28fe99f4dcce', 'София', 'Марковна', 'sofia_markovna@mail.ru', '375335951822'),
('10eff1ca-3f9a-4dcc-893b-c2130c59eb09', 'Вадим', 'Максимович', 'vm1992@gmail.com', '375445552356');

insert
	into
	orders(id,
	customer_id,
	quantity)
values ('401f6458-3b71-4575-9fa6-1ca13713d65c', '1944dca7-16b1-43d9-a2f3-f3eab2a03cec', 2),
('2367e46f-b215-40db-a4fb-639f7def0941', '260209ec-4f5c-4ced-8687-63ee56f2c20c', 21),
('8cb268f0-0eec-4e0d-a198-5c0dbda9da52', 'e9917753-2e1d-4d84-918a-e87bd54b5403', 44),
('16981634-0fc1-4e22-a938-e5d184b2643f', '8f9e30bf-5e7c-4dbc-b0ec-28fe99f4dcce', 7),
('650922d2-51b3-4727-81b3-fafc1c366f8a', '10eff1ca-3f9a-4dcc-893b-c2130c59eb09', 9);

-- 17-Удалить таблицы
drop table if exists orders;

drop table if exists customers;
