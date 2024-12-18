-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.

-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

1871 through 2016

SELECT
	MIN(yearid),
	MAX(yearid)
FROM allstarfull
LEFT JOIN appearances
	USING (yearid)
LEFT JOIN awardsmanagers
	USING (yearid)
LEFT JOIN awardsplayers
	USING (yearid)
LEFT JOIN awardssharemanagers
	USING (yearid)
LEFT JOIN awardsshareplayers
	USING (yearid)
LEFT JOIN batting
	USING (yearid)
LEFT JOIN battingpost
	USING (yearid)
LEFT JOIN collegeplaying
	USING (yearid)
LEFT JOIN fielding
	USING (yearid)
LEFT JOIN fieldingof
	USING (yearid)
LEFT JOIN fieldingofsplit
	USING (yearid)
LEFT JOIN fieldingpost
	USING (yearid)
LEFT JOIN halloffame
	USING (yearid)
LEFT JOIN managers
	USING (yearid)
LEFT JOIN managershalf
	USING (yearid)
LEFT JOIN people
	ON people.playerid = managershalf.playerid
LEFT JOIN pitching
	USING (yearid)
LEFT JOIN pitchingpost
	USING (yearid)
LEFT JOIN salaries
	USING (yearid)
LEFT JOIN schools
	USING (schoolid)
LEFT JOIN seriespost
	USING (yearid)
LEFT JOIN teams
	USING (yearid)
LEFT JOIN teamshalf
	USING (yearid)
;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT MIN(height)
FROM people;

SELECT *
FROM people
WHERE height = 43;

SELECT
	p.namefirst,
	p.namelast,
	p.namegiven,
	p.height,
	a.g_all AS total_games,
	t.name
FROM people AS p
FULL JOIN appearances AS a
	USING(playerid)
FULL JOIN teams AS t
	USING(teamid)
WHERE height =	(SELECT MIN(height) FROM people)
LIMIT 1;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vand_players AS	(SELECT 
							DISTINCT p.playerid,
							namefirst,
							namelast
						FROM schools AS s
						LEFT JOIN collegeplaying AS cp
							ON s.schoolid = cp.schoolid
						LEFT JOIN people AS p
							ON cp.playerid = p.playerid
						WHERE schoolname ILIKE ('vand%')
						GROUP BY p.playerid)
SELECT
	namefirst,
	namelast,
	SUM(salary)::NUMERIC::MONEY AS total_salary
FROM vand_players
LEFT JOIN salaries AS sal
	ON vand_players.playerid = sal.playerid
GROUP BY namefirst, namelast
ORDER BY total_salary DESC NULLS LAST;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	CASE	WHEN pos IN ('OF') THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
			ELSE '' END AS position_group,
	SUM(po) AS sum_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY sum_putouts DESC;
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT *
FROM teams
ORDER BY yearid DESC;

SELECT
	CASE	WHEN yearid::text::NUMERIC BETWEEN 1920 AND 1929 THEN 1920
			WHEN yearid::text::NUMERIC BETWEEN 1930 AND 1939 THEN 1930
			WHEN yearid::text::NUMERIC BETWEEN 1940 AND 1949 THEN 1940
			WHEN yearid::text::NUMERIC BETWEEN 1950 AND 1959 THEN 1950
			WHEN yearid::text::NUMERIC BETWEEN 1960 AND 1969 THEN 1960
			WHEN yearid::text::NUMERIC BETWEEN 1970 AND 1979 THEN 1970
			WHEN yearid::text::NUMERIC BETWEEN 1980 AND 1989 THEN 1980
			WHEN yearid::text::NUMERIC BETWEEN 1990 AND 1999 THEN 1990
			WHEN yearid::text::NUMERIC BETWEEN 2000 AND 2009 THEN 2000
			WHEN yearid::text::NUMERIC BETWEEN 2010 AND 2019 THEN 2010
			END AS decade,
	ROUND(AVG(soa),2) AS avg_strikeouts,
	ROUND(AVG(hr),2) AS avg_homerun
FROM teams
WHERE yearid IS NOT NULL
GROUP BY decade
ORDER BY decade
LIMIT 10;

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

WITH steal_attempts_table AS	(SELECT 
									playerid,
									(SUM(sb)::NUMERIC+SUM(cs)) AS steal_attempts 
									FROM batting
									WHERE yearid = 2016
									GROUP BY playerid)
SELECT
	namefirst,
	namelast,
	sb,
	steal_attempts,
	ROUND((sb::NUMERIC/steal_attempts),2)*100 AS steal_success_percent
FROM people
INNER JOIN batting
	USING(playerid)
INNER JOIN steal_attempts_table AS sa
	USING(playerid)
WHERE steal_attempts >= 20
	AND batting.yearid = 2016
GROUP BY namefirst, namelast, sb, steal_attempts, steal_success_percent
ORDER BY steal_success_percent DESC NULLS LAST;

SELECT * FROM batting;

WITH stealing_bases AS
	(SELECT CONCAT(namefirst,' ', namelast) AS player,sb,cs, SUM(sb+cs) AS total_attempts
	FROM people
	INNER JOIN batting
	USING(playerid)
	WHERE yearid='2016'
	GROUP BY player,sb,cs
	ORDER BY total_attempts DESC)
SELECT player, total_attempts,(MAX(sb)::NUMERIC/total_attempts::NUMERIC)*100 AS percentage_success
FROM stealing_bases
WHERE total_attempts>=20
GROUP BY player,total_attempts
ORDER BY percentage_success DESC;

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT *
FROM teams;

WITH max_min_played AS	(SELECT 
							yearid,
							MAX(w) AS most_wins,
							MIN(w) AS least_wins
						FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
							OR yearid BETWEEN 1995 AND 2016
						GROUP BY yearid
						ORDER BY yearid),
	wins_with_wswin AS	(SELECT
							yearid,
							most_wins,
							least_wins,
							CASE	WHEN w = most_wins AND wswin = 'Y' THEN 'Y'
									ELSE 'N' END AS most_wins_wswin
						FROM max_min_played
						INNER JOIN teams
							USING(yearid)
						GROUP BY yearid, most_wins, least_wins, most_wins_wswin
						ORDER BY most_wins DESC),
		count_y_n AS	(SELECT
							COUNT(most_wins_wswin) AS count_y_n,
							CASE WHEN most_wins_wswin = 'Y' THEN COUNT(most_wins_wswin)
							END AS most_wins_y,
							CASE WHEN most_wins_wswin = 'N' THEN COUNT(most_wins_wswin)
							END AS most_wins_n
						FROM wins_with_wswin
						GROUP BY most_wins_wswin)
SELECT
	ROUND(((SUM(most_wins_y) / SUM(count_y_n)) * 100),2) AS percent_wswin_win_over_loss
FROM count_y_n;

7 ANSWER:	Most wins w/o wswin was in 2001 with 116 wins.
			Least wins w/ wswin was in 2007 with 96 wins (after excluding 1994.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT year, COUNT(year)
FROM homegames
GROUP BY year
ORDER BY year DESC;

SELECT *
FROM homegames;

SELECT *
FROM teams
WHERE teamid = ('BS1');

SELECT *
FROM parks;

SELECT *
FROM teams;

SELECT
	park_name,
	name,
	(homegames.attendance / games) AS avg_attendance
FROM homegames
LEFT JOIN parks
	USING(park)
LEFT JOIN teams
	ON homegames.team = teams.teamid
	AND homegames.year = teams.yearid
WHERE year = 2016
	AND games >= 10
GROUP BY park_name, name, avg_attendance
ORDER BY avg_attendance DESC
LIMIT 5;

SELECT
	park_name,
	name,
	(homegames.attendance / games) AS avg_attendance
FROM homegames
LEFT JOIN parks
	USING(park)
LEFT JOIN teams
	ON homegames.team = teams.teamid
	AND homegames.year = teams.yearid
WHERE year = 2016
	AND games >= 10
GROUP BY park_name, name, avg_attendance
ORDER BY avg_attendance
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT *
FROM managers;

SELECT *
FROM awardsmanagers;

SELECT *
FROM teams;

SELECT
	namefirst,
	namelast,
	name AS team_name,
	aw.lgid AS league_id,
	aw.yearid
FROM managers AS m
LEFT JOIN awardsmanagers AS aw
	USING(playerid)
LEFT JOIN people AS p
	USING(playerid)
LEFT JOIN teams AS t
	USING(teamid)
WHERE awardid ILIKE ('%tsn manager%')
	AND aw.lgid = 'AL';

WITH tsn_al_nl_table AS	((SELECT
							namefirst,
							namelast,
							teamid
						FROM managers AS m
						LEFT JOIN awardsmanagers AS aw
							USING(playerid)
						LEFT JOIN people AS p
							USING(playerid)
						WHERE awardid ILIKE ('%tsn manager%')
							AND aw.lgid = 'AL')
						INTERSECT
						(SELECT
							namefirst,
							namelast,
							teamid
						FROM managers AS m
						LEFT JOIN awardsmanagers AS aw
							USING(playerid)
						LEFT JOIN people AS p
							USING(playerid)
						WHERE awardid ILIKE ('%tsn manager%')
							AND aw.lgid = 'NL'))
SELECT
	namefirst,
	namelast,
	name
FROM tsn_al_nl_table
LEFT JOIN teams
	USING(teamid)
GROUP BY namefirst, namelast, name
ORDER BY namefirst;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.asdf

WITH max_hr_table AS	(SELECT
							playerid,
							MAX(hr) AS max_hr,
							COUNT(yearid) AS count_yearid
						FROM batting
						GROUP BY playerid)
SELECT 
	namefirst,
	namelast,
	max_hr
FROM max_hr_table
LEFT JOIN batting
	USING(playerid)
LEFT JOIN people
	USING(playerid)
WHERE max_hr = batting.hr
	AND yearid = 2016
	AND hr > 0
	AND count_yearid::NUMERIC >= 10
ORDER BY max_hr DESC;

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

SELECT *
FROM salaries;

SELECT *
FROM teams;

SELECT
	AVG(w)
FROM teams;

SELECT 
	teams.yearid,
	teams.name,
	teams.w AS wins,
	SUM(salary)::NUMERIC::MONEY AS SUM_salary	
FROM teams
INNER JOIN salaries
	USING(lgid)
WHERE teams.yearid >= 2000
GROUP BY teams.yearid, teams.name, teams.w
ORDER BY sum_salary DESC, teams.name, teams.yearid;



-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>

Matthew completed this one for the team.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

Anagha completed this one for the team.
