-- ROLL-UP: Compute the total points earned by each team per continent.
WITH circuit_races AS (
						SELECT race_id, cir.circuit_id, nation_id
						FROM dw.circuits cir INNER JOIN dw.races ra ON cir.circuit_id = ra.circuit_id
						),
	race_continent AS (
						SELECT race_id, continent
						FROM circuit_races cr INNER JOIN dw.countries c ON cr.nation_id = c.nation_id
						)
SELECT rr.constructor_id, c.name, rc.continent, SUM(rr.driver_points) AS total_point
FROM dw.race_results rr INNER JOIN race_continent rc ON rr.race_id = rc.race_id INNER JOIN dw.constructors c ON rr.constructor_id = c.constructor_id
GROUP BY rr.constructor_id, rc.continent, c.name
ORDER BY rr.constructor_id, rc.continent

-- SLICING: Compute the average points per driver in wet races
SELECT dr.driver_id, dr.name, dr.surname, aux.average_points
FROM (
		SELECT rr.driver_id, AVG(rr.driver_points) AS average_points
		FROM dw.race_results rr LEFT OUTER JOIN dw.weather w ON rr.weather_id = w.weather_id
		WHERE w.rainfall IS TRUE 
		GROUP BY rr.driver_id
	 ) AS aux
	 INNER JOIN dw.drivers dr ON aux.driver_id = dr.driver_id
ORDER BY aux.average_points DESC

-- SLICING/DICING/ROLL-UP: Compute the top 5 teams performing best in high/medium-altitude circuits
WITH circuit_races AS (
						SELECT r.race_id, c.circuit_id, c.alt_stage
						FROM dw.races r
						INNER JOIN dw.circuits c ON r.circuit_id = c.circuit_id
						WHERE c.alt_stage IN ('high', 'medium')
					),
	scores AS (
		SELECT rr.constructor_id, SUM(rr.driver_points) AS score
		FROM dw.race_results rr
		INNER JOIN circuit_races cr ON rr.race_id = cr.race_id
		GROUP BY rr.constructor_id
					),
	score_rank AS (
	    SELECT c.constructor_id, c.name, cs.score, RANK() OVER (ORDER BY cs.score DESC) AS rank
	    FROM scores cs INNER JOIN dw.constructors c ON cs.constructor_id = c.constructor_id
	)
SELECT name, score
FROM score_rank
WHERE rank <= 5
ORDER BY rank;

-- PIVOTING Compute the comparison of constructors by continent 
WITH race_continent AS (
						SELECT aux.race_id, aux.race_name, aux.circuit_id, aux.name, aux.nation_id, c.continent
						FROM (
								SELECT r.race_id, r.name AS race_name, c.circuit_id, c.name, c.nation_id
								FROM dw.races r INNER JOIN dw.circuits c ON r.circuit_id = c.circuit_id 
								) AS aux
								INNER JOIN dw.countries c ON aux.nation_id = c.nation_id
						ORDER BY c.continent
						)
SELECT c.name, SUM(CASE WHEN rc.continent = 'Europe'   THEN rr.driver_points ELSE 0 END) AS points_europe,
       SUM(CASE WHEN rc.continent = 'North America' OR rc.continent = 'South America'  THEN rr.driver_points ELSE 0 END) AS points_america,
       SUM(CASE WHEN rc.continent = 'Asia'     THEN rr.driver_points ELSE 0 END) AS points_asia,
       SUM(CASE WHEN rc.continent = 'Oceania'  THEN rr.driver_points ELSE 0 END) AS points_oceania,
       SUM(CASE WHEN rc.continent = 'Africa'   THEN rr.driver_points ELSE 0 END) AS points_africa
FROM   dw.race_results rr INNER JOIN race_continent rc ON rr.race_id = rc.race_id
	   INNER JOIN dw.constructors c ON rr.constructor_id = c.constructor_id
GROUP BY rr.constructor_id, c.name
ORDER BY rr.constructor_id, c.name

-- RANKING: Compute the best races for each constructor
WITH races_constructors AS (
								SELECT rr.constructor_id, rr.race_id, r.name AS race_name, c.name AS constructor_name, SUM(rr.driver_points) AS score
								FROM dw.race_results rr INNER JOIN dw.races r ON rr.race_id = r.race_id
									 INNER JOIN dw.constructors c ON rr.constructor_id = c.constructor_id
								GROUP BY rr.constructor_id, rr.race_id, r.name, c.name
								ORDER BY rr.constructor_id, score DESC
							),
			 score_rank AS (
								SELECT rc.constructor_id, rc.race_id, rc.race_name, rc.constructor_name, rc.score, DENSE_RANK() OVER (PARTITION BY rc.constructor_id ORDER BY rc.score DESC ) AS rank
								FROM races_constructors rc	
			 				)
SELECT sc.constructor_name, sc.race_name, sc.score
FROM score_rank sc
WHERE sc.rank = 1 AND NOT(score = 0)


-- RANKING:Compute the comparison between drivers’ nationalities and points scored across continents
WITH driver_nationality AS (
								SELECT d.driver_id, d.name, d.surname, c.nationality
								FROM dw.drivers d INNER JOIN dw.driver_nationality dn ON d.driver_id = dn.driver_id
									 INNER JOIN dw.countries c ON dn.nation_id = c.nation_id
							),
		 race_continent AS (
								SELECT r.race_id, r.name AS race_name, c.circuit_id, c.name AS circuit_name, co.continent
								FROM dw.races r INNER JOIN dw.circuits c ON r.circuit_id = c.circuit_id
									 INNER JOIN dw.countries co ON c.nation_id = co.nation_id
							)
SELECT dn.name, dn.surname, dn.nationality,
	   SUM(CASE WHEN rc.continent = 'Europe'  THEN rr.driver_points ELSE 0 END) AS europe_points,
       SUM(CASE WHEN rc.continent = 'North America' OR rc.continent = 'South America'  THEN rr.driver_points ELSE 0 END) AS america_points,
       SUM(CASE WHEN rc.continent = 'Asia'    THEN rr.driver_points ELSE 0 END) AS asia_points,
	   SUM(CASE WHEN rc.continent = 'Africa'    THEN rr.driver_points ELSE 0 END) AS africa_points,
	   SUM(CASE WHEN rc.continent = 'Oceania'    THEN rr.driver_points ELSE 0 END) AS oceania_points
FROM dw.race_results rr INNER JOIN driver_nationality dn ON rr.driver_id = dn.driver_id
	 INNER JOIN race_continent rc ON rr.race_id = rc.race_id
GROUP BY dn.driver_id, dn.name, dn.surname, dn.nationality
ORDER BY dn.surname

-- PIVOTING: For each team, compute points and podiums for decade
SELECT 
    c.name AS team,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 1950 AND 1959) AS points_1950s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 1950 AND 1959) AS podiums_1950s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 1960 AND 1969) AS points_1960s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 1960 AND 1969) AS podiums_1960s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 1970 AND 1979) AS points_1970s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 1970 AND 1979) AS podiums_1970s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 1980 AND 1989) AS points_1980s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 1980 AND 1989) AS podiums_1980s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 1990 AND 1999) AS points_1990s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 1990 AND 1999) AS podiums_1990s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 2000 AND 2009) AS points_2000s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 2000 AND 2009) AS podiums_2000s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 2010 AND 2019) AS points_2010s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 2010 AND 2019) AS podiums_2010s,
    SUM(rr.driver_points) FILTER (WHERE d.year BETWEEN 2020 AND 2029) AS points_2020s,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3 AND d.year BETWEEN 2020 AND 2029) AS podiums_2020s,
    -- Totals across all decades
    SUM(rr.driver_points) AS total_points,
    COUNT(*) FILTER (WHERE rr.driver_final_pos BETWEEN 1 AND 3) AS total_podiums
FROM dw.race_results rr, dw.races r , dw.date d, dw.constructors c
WHERE rr.race_id = r.race_id AND r.date_id = d.date_id AND rr.constructor_id = c.constructor_id
GROUP BY c.name
ORDER BY total_points DESC,total_podiums DESC;

--DICING/ROLL-UP: Rank drivers by computing achieved points in hot and humid races for seasons 2023 and 2024 
SELECT rr.driver_id,drivers.name, drivers.surname, races.name, date.year, SUM(rr.driver_points) as tot_points 
FROM dw.weather as weather, dw.race_results as rr, dw.races as races, dw.date as date, dw.drivers as drivers
WHERE date.date_id = races.date_id AND races.race_id = rr.race_id AND weather.weather_id = rr.race_id AND drivers.driver_id = rr.driver_id
		AND (date.year = 2023 OR date.year=2024)
		AND (weather.stage_air_temperature = 'high' OR weather.stage_air_temperature = 'medium')
		AND weather.stage_track_temperature = 'high'
		AND weather.stage_air_humidity = 'high'
GROUP BY rr.driver_id,drivers.name,drivers.surname,races.name,date.year
ORDER BY  date.year,tot_points DESC

--SLICING: Compute the podiums with constructors, drivers and circuits of the same nation/nationality
SELECT dw.drivers.name,dw.drivers.surname,dw.constructors.name,dw.circuits.location,dw.races.name,dw.date.year
FROM dw.races,dw.race_results,dw.circuits,dw.drivers,dw.date,dw.constructors
WHERE dw.race_results.driver_final_pos = 1 AND
	  dw.constructors.constructor_id = dw.race_results.constructor_id AND
	  dw.date.date_id = dw.races.date_id AND
	  dw.race_results.race_id = dw.races.race_id AND
	  dw.races.circuit_id = dw.circuits.circuit_id AND
	  dw.drivers.driver_id = dw.race_results.driver_id AND
	  (dw.circuits.circuit_id,dw.race_results.constructor_id,dw.race_results.driver_id) in ( SELECT DISTINCT circuits.circuit_id,constructors.constructor_id,nn.driver_id
															FROM dw.circuits as circuits, dw.constructors as constructors, dw.driver_nationality as nn	 
															WHERE circuits.nation_id = constructors.nation_id AND nn.nation_id = circuits.nation_id AND nn.nation_id = constructors.nation_id
														  )
ORDER BY dw.drivers.name,dw.drivers.surname

--RANKING: List drivers ranked by the total position delta (final position − starting position), considering only finished races, including also the average position delta, and only drivers with at least 50 completed races are considered.
SELECT DISTINCT d.driver_id, d.name, d.surname , SUM(rr.driver_initial_pos-rr.driver_final_pos) as delta_pos, AVG(rr.driver_initial_pos-rr.driver_final_pos) as mean_delta_pos
FROM dw.race_results as rr, dw.drivers as d
WHERE rr.driver_id = d.driver_id AND rr.status_id = 1
GROUP BY d.driver_id,d.name,d.surname
HAVING COUNT(DISTINCT rr.race_id) >= 50
ORDER BY delta_pos DESC

--RANKING: List circuits ranked by the average number of overtakes, considering only circuits that have hosted at least 10 races.
SELECT 
    c.circuit_id,
    c.name AS circuit_name,
    COUNT(DISTINCT rr.race_id) AS races_held,
    SUM(ABS(rr.driver_initial_pos - rr.driver_final_pos)) / 2.0 AS total_abs_delta,
    SUM(ABS(rr.driver_initial_pos - rr.driver_final_pos)) / (2.0 * COUNT(DISTINCT rr.race_id)) AS mean_abs_delta_per_race
FROM dw.race_results AS rr
JOIN dw.races AS r 
    ON rr.race_id = r.race_id
JOIN dw.circuits AS c 
    ON r.circuit_id = c.circuit_id
WHERE rr.status_id = 1   
GROUP BY c.circuit_id, c.name
HAVING  COUNT(DISTINCT rr.race_id) > 10
ORDER BY mean_abs_delta_per_race DESC;
						





