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



						