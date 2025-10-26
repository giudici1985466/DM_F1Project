-- data population
INSERT INTO dw.date (
    calendar_date, 
    year, 
    quarter, 
    month, 
    week, 
    day, 
    day_of_week, 
    day_name, 
    month_name
)
SELECT 
    d::date AS calendar_date,
    EXTRACT(YEAR FROM d)::integer AS year,
    EXTRACT(QUARTER FROM d)::integer AS quarter,
    EXTRACT(MONTH FROM d)::integer AS month,
    EXTRACT(WEEK FROM d)::integer AS week,
    EXTRACT(DAY FROM d)::integer AS day,
    EXTRACT(DOW FROM d)::integer AS day_of_week, -- 0=Sunday, 1=Monday ...
    TO_CHAR(d, 'Day') AS day_name,
    TO_CHAR(d, 'Month') AS month_name
FROM generate_series('1800-01-01'::date, '2025-12-31'::date, interval '1 day') AS d;

-- status population
INSERT INTO dw.status (status_id, description)
SELECT * FROM rdl.status;

-- season population
INSERT INTO dw.season (year, url)
SELECT * FROM rdl.seasons;

-- country population
INSERT INTO dw.countries (country,continent,nationality) 
SELECT country,continent,nationality
FROM rdl.countries;

-- circuits population
INSERT INTO dw.circuits (
    circuit_id, name, location, lat, lng, alt, alt_stage, url, nation_id
)
SELECT c.circuit_id,
       c.name,
       c.location,
       c.lat,
       c.lng,
       c.alt,
       CASE
           WHEN c.alt < 200 THEN 'low'
           WHEN c.alt >= 200 AND c.alt < 600 THEN 'medium'
           WHEN c.alt >= 600 THEN 'high'
           ELSE NULL
       END AS alt_stage,
       c.url,
       d.nation_id
FROM rdl.circuits c, dw.countries d 
WHERE c.country = d.country;

-- weather population
INSERT INTO dw.weather(
	weather_id, rainfall, avg_air_temperature, stage_air_temperature, avg_track_temperature, stage_track_temperature, avg_air_humidity, stage_air_humidity, avg_atm_pressure, avg_wind_speed, stage_wind_speed
)
SELECT
    r.race_id AS weather_id,
	BOOL_OR(w.rainfall) AS rainfall,
    AVG(w.air_temperature) FILTER (WHERE w.air_temperature IS NOT NULL) AS avg_air_temperature,
   
    CASE
        WHEN AVG(w.air_temperature) FILTER (WHERE w.air_temperature IS NOT NULL) < 15 THEN 'low'
        WHEN AVG(w.air_temperature) FILTER (WHERE w.air_temperature IS NOT NULL) < 25 THEN 'medium'
        WHEN AVG(w.air_temperature) FILTER (WHERE w.air_temperature IS NOT NULL) >=25 THEN 'high'
		ELSE NULL
    END AS stage_air_temperature,

	AVG(w.track_temperature)      FILTER (WHERE w.track_temperature      IS NOT NULL) AS avg_track_temperature,
	
    CASE
        WHEN AVG(w.track_temperature) FILTER (WHERE w.track_temperature IS NOT NULL) < 25 THEN 'low'
        WHEN AVG(w.track_temperature) FILTER (WHERE w.track_temperature IS NOT NULL) < 35 THEN 'medium'
		WHEN AVG(w.track_temperature) FILTER (WHERE w.track_temperature IS NOT NULL) >= 35 THEN 'high'
        ELSE NULL
    END AS stage_track_temperature,

	
    AVG(w.humidity)      FILTER (WHERE w.humidity      IS NOT NULL) AS avg_air_humidity,
	CASE
        WHEN AVG(w.humidity) FILTER (WHERE w.humidity IS NOT NULL) < 30 THEN 'low'
        WHEN AVG(w.humidity) FILTER (WHERE w.humidity IS NOT NULL) < 60 THEN 'medium'
		WHEN AVG(w.humidity) FILTER (WHERE w.humidity IS NOT NULL) >= 60 THEN 'high'
        ELSE NULL
    END AS stage_air_humidity,

	AVG(w.pressure)       FILTER (WHERE w.pressure       IS NOT NULL) AS avg_atm_pressure,
	
	AVG(w.wind_speed)       FILTER (WHERE w.wind_speed       IS NOT NULL) AS avg_wind_speed,
   CASE
        WHEN AVG(w.wind_speed) FILTER (WHERE w.wind_speed IS NOT NULL) < 2 THEN 'low'
        WHEN AVG(w.wind_speed) FILTER (WHERE w.wind_speed IS NOT NULL) < 3 THEN 'medium'
		WHEN AVG(w.wind_speed) FILTER (WHERE w.wind_speed IS NOT NULL) >= 3 THEN 'high'
        ELSE NULL
    END AS stage_wind_speed

FROM rdl.races r LEFT OUTER JOIN rdl.weather w ON r.race_id = w.race_id
GROUP BY r.race_id
ORDER BY r.race_id

-- constructors
INSERT INTO dw.constructors(constructor_id, name, nation_id)
SELECT constructor_id, name, nation_id
FROM (
		SELECT constructor_id, name, nationality
		FROM rdl.constructor_nationality NATURAL JOIN rdl.constructors) AS aux
		NATURAL JOIN dw.countries;

-- drivers
INSERT INTO dw.drivers(driver_id, name, surname, dob, url)

SELECT driver_id, forename, surname, date_id, url
FROM rdl.drivers INNER JOIN dw.date ON dob = calendar_date;

-- driver_nationality
INSERT INTO dw.driver_nationality(driver_id, nation_id)
SELECT driver_id, nation_id
FROM rdl.driver_nationality NATURAL JOIN dw.countries;

-- races
INSERT INTO dw.races(race_id, date_id, circuit_id, name, round, url)
WITH race_date AS (
				SELECT race_id, date_id
				FROM rdl.races INNER JOIN dw.date ON date = calendar_date)
				
SELECT race_id, date_id, circuit_id, name, round, url
FROM rdl.races NATURAL JOIN race_date;


-- race results
INSERT INTO dw.race_results(race_result_id, driver_id, race_id, constructor_id, status_id, weather_id, driver_initial_pos, driver_final_pos, driver_points, driver_fastest_lap, driver_avg_lap_time, number_of_stints, number_of_pits, completed_laps, starting_compound, starting_tyre_age)

WITH number_of_stints AS (
							SELECT driver_id, race_id,COUNT(*) AS number_of_stints
							FROM rdl.stints NATURAL JOIN rdl.race_lineup
							GROUP BY driver_id, race_id
							),
			avg_speed AS (
							SELECT driver_id, race_id, AVG(st_speed) AS driver_avg_lap_speed
							FROM rdl.speed NATURAL JOIN rdl.race_lineup
							GROUP BY driver_id, race_id
						  ),
			general_info AS (
							SELECT result_id, driver_id, race_id, constructor_id, status_id, grid, pos, points, fastest_lap_time, laps
							FROM rdl.race_results
						  ),
			compound AS (
							SELECT d.driver_id,rl.race_id,s.compound,s.tyre_age_at_start
							FROM rdl.drivers as d,rdl.race_lineup as rl,rdl.stints as s
							WHERE d.driver_id = rl.driver_id AND (rl.race_id,rl.driver_number) = (s.race_id,s.driver_number) AND s.stint_number = 1 
							ORDER BY rl.race_id,d.driver_id
						),
			avg_lap_times_info AS (
							SELECT rr.driver_id,rr.race_id,AVG(lt.milliseconds) AS avg_lap_time
							FROM rdl.race_results as rr, rdl.lap_times as lt
							WHERE rr.driver_id = lt.driver_id AND rr.race_id = lt.race_id
							GROUP BY rr.driver_id,rr.race_id
							ORDER BY rr.driver_id,rr.race_id
						),
			pit_count AS (
							SELECT rr.driver_id,rr.race_id, COUNT(*) as pit_count
							FROM rdl.race_results as rr, rdl.pit_stops as ps
							WHERE rr.driver_id = ps.driver_id AND rr.race_id = ps.race_id
							GROUP BY rr.driver_id, rr.race_id
							ORDER BY rr.driver_id, rr.race_id
						)
SELECT  g.result_id, g.driver_id, g.race_id, g.constructor_id, g.status_id, g.race_id AS weather_id, g.grid, g.pos, g.points, g.fastest_lap_time,avgt.avg_lap_time, ns.number_of_stints, pc.pit_count, g.laps, c.compound, c.tyre_age_at_start
FROM general_info g LEFT OUTER JOIN number_of_stints ns ON (g.driver_id = ns.driver_id AND g.race_id = ns.race_id)
     LEFT OUTER JOIN avg_speed avgs ON (g.driver_id = avgs.driver_id AND g.race_id = avgs.race_id)
     LEFT OUTER JOIN compound c ON (g.driver_id = c.driver_id AND g.race_id = c.race_id)
     LEFT OUTER JOIN avg_lap_times_info avgt ON (g.driver_id = avgt.driver_id AND g.race_id = avgt.race_id)
     LEFT OUTER JOIN pit_count pc ON (g.driver_id = pc.driver_id AND g.race_id = pc.race_id)

			

			

