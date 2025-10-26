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
