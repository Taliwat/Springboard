/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, and revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name
FROM Facilities
WHERE membercost > 0.0

/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(membercost)
FROM Facilities
WHERE membercost = 0.0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid AS facility_id, name AS facility_name, membercost AS member_cost, monthlymaintenance AS monthly_maint
FROM Facilities
WHERE membercost < (0.2 * monthlymaintenance);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
FROM Facilities
WHERE facid IN (1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name AS facility_name, monthlymaintenance,
	CASE
		WHEN monthlymaintenance > 100 THEN 'Expensive'
		ELSE 'Cheap'
	END AS maintenance_status
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname AS first_name, surname AS last_name
FROM Members
WHERE joindate = (
    SELECT MAX(joindate)
    FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT sub.court, CONCAT( sub.firstname,  ' ', sub.surname ) AS name
FROM (
SELECT Facilities.name AS court, Members.firstname AS firstname, Members.surname AS surname
FROM Bookings
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
AND Facilities.name LIKE  'Tennis Court%'
INNER JOIN Members ON Bookings.memid = Members.memid
) sub
GROUP BY sub.court, sub.firstname, sub.surname
ORDER BY name
;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT Facilities.name AS facility, CONCAT( Members.firstname,  ' ', Members.surname ) AS name, 
CASE WHEN Bookings.memid =0
THEN Facilities.guestcost * Bookings.slots
ELSE Facilities.membercost * Bookings.slots
END AS cost
FROM Bookings
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
AND Bookings.starttime LIKE  '2012-09-14%'
AND (((Bookings.memid =0) AND (Facilities.guestcost * Bookings.slots >30))
OR ((Bookings.memid !=0) AND (Facilities.membercost * Bookings.slots >30)))
INNER JOIN Members ON Bookings.memid = Members.memid
ORDER BY cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT * 
FROM (
SELECT Facilities.name AS facility, CONCAT( Members.firstname,  ' ', Members.surname ) AS name, 
CASE WHEN Bookings.memid =0
THEN Facilities.guestcost * Bookings.slots
ELSE Facilities.membercost * Bookings.slots
END AS cost
FROM Bookings
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
AND Bookings.starttime LIKE  '2012-09-14%'
INNER JOIN Members ON Bookings.memid = Members.memid
)sub
WHERE sub.cost >30
ORDER BY sub.cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
# On Jupyter Notebook as well :)
cur.execute('SELECT name AS facility_name, total_revenue FROM (SELECT name, SUM(	CASE WHEN Bookings.memid = 0 THEN Facilities.guestcost * slots ELSE Facilities.membercost * slots END) as total_revenue	FROM Bookings JOIN Members ON Bookings.memid = Members.memid JOIN Facilities ON Bookings.facid = Facilities.facid GROUP BY name) as Facilities_Revenue WHERE total_revenue < 1000 ORDER BY total_revenue DESC;')
column_names = [description[0] for description in cur.description]
rows = cur.fetchall()
query1 = pd.DataFrame(rows, columns=column_names)
print(query1)

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
cur.execute('SELECT m1.surname AS member_lastname, m1.firstname AS member_firstname, m2.surname AS rec_lastname, m2.firstname AS rec_firstname FROM Members AS m1 LEFT JOIN Members AS m2 ON m1.recommendedby = m2.memid WHERE m1.recommendedby != 0 ORDER BY m1.surname, m1.firstname;');
column_names = [description[0] for description in cur.description]
rows = cur.fetchall()
query_df2 = pd.DataFrame(rows, columns=column_names)
print(query_df2)

/* Q12: Find the facilities with their usage by member, but not guests */
cur.execute('SELECT name AS facility_name, COUNT(memid) AS member_usage FROM Bookings JOIN Facilities ON Bookings.facid = Facilities.facid WHERE memid != 0 GROUP BY name ORDER BY member_usage DESC;')
column_names = [description[0] for description in cur.description]
rows = cur.fetchall()
query_df3 = pd.DataFrame(rows, columns=column_names)
print(query_df3)

/* Q13: Find the facilities usage by month, but not guests */
cur.execute("SELECT f.name AS facility, SUM(CASE WHEN strftime('%m', b.starttime) = '01' THEN 1 ELSE 0 END) AS January, SUM(CASE WHEN strftime('%m', b.starttime) = '02' THEN 1 ELSE 0 END) AS February, SUM(CASE WHEN strftime('%m', b.starttime) = '03' THEN 1 ELSE 0 END) AS March, SUM(CASE WHEN strftime('%m', b.starttime) = '04' THEN 1 ELSE 0 END) AS April, SUM(CASE WHEN strftime('%m', b.starttime) = '05' THEN 1 ELSE 0 END) AS May, SUM(CASE WHEN strftime('%m', b.starttime) = '06' THEN 1 ELSE 0 END) AS June, SUM(CASE WHEN strftime('%m', b.starttime) = '07' THEN 1 ELSE 0 END) AS July, SUM(CASE WHEN strftime('%m', b.starttime) = '08' THEN 1 ELSE 0 END) AS August, SUM(CASE WHEN strftime('%m', b.starttime) = '09' THEN 1 ELSE 0 END) AS September, SUM(CASE WHEN strftime('%m', b.starttime) = '10' THEN 1 ELSE 0 END) AS October, SUM(CASE WHEN strftime('%m', b.starttime) = '11' THEN 1 ELSE 0 END) AS November, SUM(CASE WHEN strftime('%m', b.starttime) = '12' THEN 1 ELSE 0 END) AS December FROM Bookings AS b INNER JOIN Facilities AS f ON b.facid = f.facid INNER JOIN Members AS m ON b.memid = m.memid WHERE m.firstname NOT LIKE 'GUEST' AND m.surname NOT LIKE 'GUEST' GROUP BY f.name ORDER BY facility");
column_names = [description[0] for description in cur.description]
rows = cur.fetchall()
query_df5 = pd.DataFrame(rows, columns=column_names)
print(query_df5)
