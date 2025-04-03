/*
29. Выбрать id, фамилию, имя, отчество клиента и, если
клиент обладает скидкой, то название категории скидки. Результат
отсортировать по фамилии, имени, отчеству клиента в
лексикографическом порядке.
*/
select 
	c.clientid, 
	c.firstname, 
	c.lastname, 
	c.middlename, 
	c.discounttypes,
	coalesce(d.description,'Не имеет скидки') as discount_info
from 
	clients c 
left join 
	discounttypes d 
on 
	c.discounttypes=d.discounttypeid 
order by 1,2,3;

/*
30. Выбрать фамилию, имя, отчество мастера, фамилию,
имя, отчество клиента, название вида услуги и стоимость для
заказов сегодняшнего дня, если услуга предполагает
использование каких-либо материалов, то название этих
материалов.
*/

select
    e.lastname as employeelastname,
    e.firstname  as employeefirstname,
    e.middlename as employeemiddlename,
    c.lastname as clientlastname,
    c.firstname  as clientfirstname,
    c.middlename as clientmiddlename,
    s."name" as servicename,
    st."name" as servicetypename,
    p2."cost",
    string_agg(m.name, ', ') as materialnames
from
    appointments a
join
    employees e on a.employees  = e.employeeid 
join 
    clients c on a.clients = c.clientid 
join 
    provided2 p2 on a.services  = p2.services and a.employees  = p2.employees
join 
    services s on p2.services = s.serviceid
join 
    servicetypes st on s.servicetypes = st.servicetypeid
left join
    uses u on p2.services = u.services
left join
    materials m on u.materials = m.materialid
where
    a.date = current_date
group by
    e.lastname, e.firstname, e.middlename,
    c.lastname, c.firstname, c.middlename,
    s."name", st."name", p2."cost";

--31. Выбрать данные о клиенте(ах), которые сделали заказы на наибольшую сумму.

select 
	a.clients,
	c.firstname,
	c.lastname,
	c.middlename,
	sum(p."cost") as all_price
from 
	appointments a
join 
	clients c on c.clientid=a.clients
join 
	provided2 p on a.employees = p.employees and a.services =p.services
where 
	a.status = 'Completed'
group by 
	a.clients,
	c.firstname,
	c.lastname,
	c.middlename
order by 
	sum(p."cost" ) desc
limit 2

--32.Выбрать информацию об акциях с одним и тем же названием, но разными сроками за последние 5 лет.
select 
    p1.name as promotionname,
    p1.startdate as startdate1,
    p1.enddate as enddate1,
    p2.startdate as startdate2,
    p2.enddate as enddate2
from 
	promotions p1
join 
	promotions p2 
on 
	p1.name = p2.name and (p1.startdate != p2.startdate OR p1.enddate != p2.enddate) and p1.promotionid  < p2.promotionid 
where 
	p1.startdate >= now() - interval '5 years' and p2.startdate >= now() - interval '5 years'
order by 
	p1.name, p1.startdate, p2.startdate;

/*
33.Выбрать информацию о клиентах, не имеющих однофамильцев с совпадающими отчествами среди мастеров.(вывести клиентов, у которых нет однофамильцев с мастерами, 
но есть одинаковое отчество с любым из мастеров)
*/
	
select 
    c.lastname,
    c.firstname,
    c.middlename
from 
    clients c
where not exists (
    select 1
    from employees e
    where e.lastname = c.lastname
    and e.middlename = c.middlename
)

--34. Найти мастеров, работавших вчера в одну смену.

select distinct
    e1.lastname as employee1lastname,
    e1.firstname as employee1firstname,
    e1.middlename as employee1middlename,
    e2.lastname as employee2lastname,
    e2.firstname as employee2firstname,
    e2.middlename as employee2middlename
from
    employees e1
join
    employees e2 on e1.employeeid < e2.employeeid 
join
    appointments a1 on e1.employeeid = a1.employees 
join
    appointments a2 on e2.employeeid = a2.employees
where
    e1.schedule = e2.schedule
    and a1.date = date(now() - interval '1 days') 
    and a2.date = date(now() - interval '1 days') 
order by
    e1.lastname, e2.lastname;


--35(28). Выбрать информацию о самой дорогой услуге.

select  
	p2.services , 
	s.name as servicename,
	p2.cost
from 
	provided2 p2
join 
	services s on p2.services = s.serviceid
order by 
	p2.cost desc
limit 1;

--36.  Выбрать клиентов, которые пользовались услугами всех мастеров в одном салоне.

with salonmasters as (
    select
        s.salonid,
        count(distinct e.employeeid) as totalmasters
    from
        salons s
    join
        employees e on s.salonid = e.salons
    group by
        s.salonid
),
clientmasters as (
    select
        a.clients ,
        s.salonid,
        count(distinct a.employees ) as mastersused
    from
        appointments a
    join
        employees e on a.employees = e.employeeid
    join
        salons s on e.salons  = s.salonid
    group by
        a.clients , s.salonid
)
select
    c.clientid,
    c.firstname,
    c.lastname,
    c.middlename,
    cm.salonid
from
    clients c
join
    clientmasters cm on c.clientid = cm.clients 
join
    salonmasters sm on cm.salonid = sm.salonid
where
    cm.mastersused = sm.totalmasters;

--37. Выбрать информацию о клиентах, заказавших наибольшее количество услуг за один день.

with dailyorders as (
    select
        a.clients,
        a.date,
        count(*) as servicesordered
    from
        appointments a
    group by
        a.clients, a.date
)
select
    c.clientid,
    c.firstname,
    c.lastname,
    c.middlename,
    dlo.date,
    dlo.servicesordered
from
    clients c
join
    dailyorders dlo on c.clientid = dlo.clients
where dlo.servicesordered=(select
        max(servicesordered) as maxservices
    from
        dailyorders)

--38. Выбрать пятерку наиболее часто посещающих салоны клиентов.

select 
	a.clients,
	c.lastname,
	c.firstname,
	c.middlename,
	count(*) as count
from 
	appointments a 
join 
	clients c on a.clients = c.clientid
group by 
	a.clients, 
	c.lastname,
	c.firstname,
	c.middlename
order by 
	count(*) desc
limit 5

--39. Выбрать id_услуг, в которых используется один и тот же набор расходных материалов.

with servicematerials as (
    select
        u.services as service_id,
        string_agg(u.materials::text, ',' order by u.materials) as material_set
    from
        uses u
    group by
        u.services
)
select
    sm1.service_id as service_id_1,
    sm2.service_id as service_id_2
from
    servicematerials sm1
join
    servicematerials sm2 on sm1.material_set = sm2.material_set
    and sm1.service_id < sm2.service_id; 

--40. Выбрать фамилию, имя, отчество клиента, который не заказывал ни одной услуги более одного раза.

with dailyorders as (
    select
        a.clients,
        a.services,
        count(*) as servicesordered
    from
        appointments a
    group by
        a.clients, a.services
    having count(*)<=1
)
select 
    c.clientid,
    c.firstname,
    c.lastname,
    c.middlename,
    dlo.services,
    dlo.servicesordered
from
    clients c
join
    dailyorders dlo on c.clientid = dlo.clients

--41.Выбрать названия видов услуг на будущую неделю, для которых ни разу не поставлялись материалы.

with futureappointments as (
    select
        a.services
    from
        appointments a
    where
        a.date between current_date and current_date + interval '7 days'
),
serviceswithoutmaterials as (
    select
        s.serviceid
    from
        services s
    left join
        uses u on s.serviceid = u.services
    where
        u.materials is null
)
select
    st.servicetypeid,
    st.name
from
    servicetypes st
join
    services s on st.servicetypeid = s.servicetypes
join
    futureappointments fa on s.serviceid = fa.services
join
    serviceswithoutmaterials swm on s.serviceid = swm.serviceid
group by
    st.servicetypeid, st.name;

/*
42(27).Выбрать не обладающих скидками клиентов,
получивших услуги на сумму более 10 000 за последний месяц.
Результат отсортировать по сумме в порядке убывания и фамилии,
имени, отчеству в лексикографическом порядке.
*/

with betweenappointments as (
	select
        a.clients,
        sum(p.cost) as cost_services
    from
        appointments a
    join 
        provided2 p on a.services = p.services and a.employees  = p.employees 
    where
        a.date between  current_date - interval '30 days' and current_date
        and a.status = 'Completed'
    group by 
        a.clients
)
select distinct
    c.firstname,
    c.lastname,
    c.middlename,
    ba.cost_services
from 
    clients c 
join 
    betweenappointments ba on c.clientid = ba.clients
    and ba.cost_services > 10000 
where 
    c.discounttypes is null 
order by
    c.lastname,
    c.middlename,
    ba.cost_services desc;
group by 

/*43. Для каждого поставщика вывести количество расходных
материалов, им поставляемых. Результат отсортировать по
количеству в порядке возрастания и по названию поставщика в
лексикографическом порядке.
*/

select
    s.supplierid,
    s.name,
    string_agg(m2."name", ', ') as materialID,
    count(m2.materialid) as materialcount
from
    suppliers s
join
    supplies s1 on s.supplierid  = s1.suppliers 
join 
	members m on s1.supplyid = m.supplies
join 
	materials m2 on m.materials=m2.materialid
group by
    s.supplierid,
    s.name
order by 
	materialcount,
	s.name
	
--44. Вывести все данные об акциях, для которых еще не определен набор услуг.
select p.*
from 
	promotions p
where not exists (
    select 1
    from works1 w
    where w.promotions = p.promotionid 
);


/*
45. Выбрать названия видов работ, по которым услуги в
этом году(в 2024) заказываются чаще других, а в прошлом году(в 2023) заказов на
эту услугу было не более 3.
*/

with a_2024 as (
    select 
        a.services,
        count(*) as count_appointment_2024
    from 
        appointments a 
    where 
        date_part('year', a."date") = 2024
    group by 1
),
a_2023 as (
    select 
        a.services,
        count(*) as count_appointment_2023
    from 
        appointments a 
    where 
        date_part('year', a."date") = 2023
    group by 1
    having count(*) <= 3
)
select 
    s2."name" as service_type_name,
    sum(a.count_appointment_2024) as total_orders_2024
from 
    a_2024 a
join 
    a_2023 aa on a.services = aa.services
join 
    services s on a.services = s.serviceid
join 
    servicetypes s2 on s2.servicetypeid = s.servicetypes
where 
    a.count_appointment_2024 = (
        select max(count_appointment_2024) 
        from a_2024
    )
group by 
    s2."name"
order by 
    total_orders_2024 desc;

/*
46. Выбрать имя, которое встречается реже других, как
среди клиентов, так и среди мастеров, а также имя, которое
встречается чаще других.
*/

select firstname, count, category from (
    (
        select 
            firstname, 
            count(*) as count,
            'rarest' as category
        from (
            select firstname from clients
            union all
            select firstname from employees
        ) all_names
        group by firstname
        order by count asc
        limit 1
    )
    
    union all
    (
        select 
            firstname, 
            count(*) as count,
            'most common' as category
        from (
            select firstname from clients
            union all
            select firstname from employees
        ) all_names
        group by firstname
        order by count desc
        limit 1
    )
) result;



--47. Выбрать фамилию, имя, отчество клиента, который заказал наибольшее количество услуг за последний месяц.

select
	c.lastname, c.firstname, c.middlename,
	count(a.services)
from
	appointments a
join 
	clients c on a.clients  = c.clientid
where
	a.date between current_date - interval '30 days' and current_date
	and a.status = 'Completed'
group by 1,2,3
order by 4 desc
limit 1
        
        
/*
 48. Вывести в одном столбце фамилии мастеров и клиентов.
Для мастеров во втором столбце результирующей таблицы
указать «мастер».
*/
select 
    lastname,
    'мастер' as type
from 
    employees

union all

select 
    lastname,
    'клиент' as type
from 
    clients
order by  
    lastname;
--49. Найти id и фамилии, имена, отчества клиентов, которые не посещали салон более двух лет.

select c.*
from 
	clients c
where not exists (
    select 1
    from appointments a
    where a.clients  = c.clientid and a."date" > now() - interval '2 years'
);

--50. Найти виды работ, которые не заказывались последний год.
select ss.*
from 
	services s 
join 
	servicetypes ss on s.servicetypes =ss.servicetypeid
where not exists (
    select 1
    from appointments a
    where a.services   = s.serviceid and a."date" > now() - interval '1 years'
);
--51(26). Выбрать названия вида работ и стоимость услуг, которые не требуют расходных материалов.

select 
	ss.name,
	p."cost",
	p.employees,
	s."name"
from 
	services s 
join 
	servicetypes ss on s.servicetypes =ss.servicetypeid
join 
	provided2 p on s.serviceid =p.services
where not exists (
    select 1
    from uses u
    where u.services = s.serviceid
);

--52. Выбрать даты прошлого месяца, в которые не оказывалась услуга 2(Педикюр).(рекурсивная CTE)

with recursive 
date_range as (
    select 
        date_trunc('month', current_date - interval '1 month')::date as date
    union all
    select 
        date + 1
    from 
        date_range
    where 
        date < date_trunc('month', current_date)::date - 1
),

pedicure_dates as (
    select distinct
        a.date
    from 
        appointments a
    where 
        a.services = 2
        and date >= date_trunc('month', current_date - interval '1 month')::date
        and date < date_trunc('month', current_date)::date
)
select 
    d.date
from 
    date_range d
left join 
    pedicure_dates p on d.date = p.date
where 
    p.date is null
order by 
    d.date;

--53. Выбрать название салона красоты, количество услуг(количество записей на услуги),оказанных в прошлом году салоном, и процент услуг от количества услуг, оказанных всеми салонами.(на оконные)

select distinct
    s.name as salon_name,
    count(a.appointmentid) over (partition by s.salonid) as salon_appointments,
    count(a.appointmentid) over () as total_appointments,
    round(
        count(a.appointmentid) over (partition by s.salonid) * 100.0 / 
        count(a.appointmentid) over (), 
    2
    ) as percentage_of_total
from 
    appointments a
join 
    employees e on a.employees = e.employeeid
join 
    salons s on e.salons = s.salonid
where 
    a.date >= date_trunc('year', current_date - interval '1 year')::date
    and a.date < date_trunc('year', current_date)::date
order by 
    salon_appointments desc;
