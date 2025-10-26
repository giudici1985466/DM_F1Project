SELECT DISTINCT d.driver_id, d.name, d.surname , SUM(rr.driver_initial_pos-rr.driver_final_pos) as delta_pos, AVG(rr.driver_initial_pos-rr.driver_final_pos) as mean_delta_pos
FROM dw.race_results as rr, dw.drivers as d
WHERE rr.driver_id = d.driver_id AND rr.status_id = 1
GROUP BY d.driver_id,d.name,d.surname
HAVING COUNT(DISTINCT rr.race_id) >= 50
ORDER BY delta_pos DESC