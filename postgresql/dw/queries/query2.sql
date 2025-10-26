SELECT rr.driver_id,drivers.name, drivers.surname, races.name, date.year, SUM(rr.driver_points) as tot_points 
FROM dw.weather as weather, dw.race_results as rr, dw.races as races, dw.date as date, dw.drivers as drivers
WHERE date.date_id = races.date_id AND races.race_id = rr.race_id AND weather.weather_id = rr.race_id AND drivers.driver_id = rr.driver_id
		AND (date.year = 2023 OR date.year=2024)
		AND (weather.stage_air_temperature = 'high' OR weather.stage_air_temperature = 'medium')
		AND weather.stage_track_temperature = 'high'
		AND weather.stage_air_humidity = 'high'
GROUP BY rr.driver_id,drivers.name,drivers.surname,races.name,date.year
ORDER BY  date.year,tot_points DESC


