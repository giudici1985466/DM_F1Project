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
