-- creation of the schema rdl
DROP SCHEMA IF EXISTS rdl ;

CREATE SCHEMA IF NOT EXISTS rdl
    AUTHORIZATION postgres;

-- creation of the table countries
DROP TABLE IF EXISTS rdl.countries;
CREATE TABLE rdl.countries
(
    country character varying(100) NOT NULL,
    continent character varying(100) NOT NULL,
    nationality character varying(100) NOT NULL,
    PRIMARY KEY (country),
    UNIQUE (nationality)
);

ALTER TABLE IF EXISTS rdl.countries
    OWNER to postgres;

--creation of the table drivers
DROP TABLE IF EXISTS rdl.drivers;
CREATE TABLE rdl.drivers
(
    driver_id bigint NOT NULL,
    driver_ref character varying(100) NOT NULL,
    code character varying(5) DEFAULT NULL,
    forename character varying(100) NOT NULL,
    surname character varying(100) NOT NULL,
    dob date NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (driver_id)
);

ALTER TABLE IF EXISTS rdl.drivers
    OWNER to postgres;

-- creation of the table driver_natonality
DROP TABLE IF EXISTS rdl.driver_nationality;
CREATE TABLE rdl.driver_nationality
(
    driver_id bigint NOT NULL,
    nationality character varying(100) NOT NULL,
    PRIMARY KEY (driver_id, nationality),
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (nationality)
        REFERENCES rdl.countries (nationality) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.driver_nationality
    OWNER to postgres;

-- creation of the table constructors
DROP TABLE IF EXISTS rdl.constructors;
CREATE TABLE rdl.constructors
(
    constructor_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (constructor_id)
);

ALTER TABLE IF EXISTS rdl.constructors
    OWNER to postgres;

-- creation of the table for constructor_nationality
DROP TABLE IF EXISTS rdl.constructor_nationality;
CREATE TABLE rdl.constructor_nationality
(
    constructor_id bigint NOT NULL,
    nationality character varying(100) NOT NULL,
    PRIMARY KEY (constructor_id, nationality),
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (nationality)
        REFERENCES rdl.countries (nationality) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.constructor_nationality
    OWNER to postgres;
    
-- creation of the table circuits
DROP TABLE IF EXISTS rdl.circuits;
CREATE TABLE rdl.circuits
(
    circuit_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    location character varying(100) NOT NULL,
    country character varying(100) NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    alt integer NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (circuit_id),
    FOREIGN KEY (country)
        REFERENCES rdl.countries (country) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.circuits
    OWNER to postgres;

-- creation of the table seasons
DROP TABLE IF EXISTS seasons;
CREATE TABLE rdl.seasons
(
    year integer NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (year)
);

ALTER TABLE IF EXISTS rdl.seasons
    OWNER to postgres;

-- creation of the table races
DROP TABLE IF EXISTS races;
CREATE TABLE rdl.races
(
    race_id bigint NOT NULL,
    year integer NOT NULL,
    round integer NOT NULL,
    circuit_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    date date NOT NULL,
    url character varying(100) NOT NULL,
    meeting_key bigint DEFAULT NULL,
    PRIMARY KEY (race_id),
    UNIQUE (meeting_key),
    FOREIGN KEY (year)
        REFERENCES rdl.seasons (year) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (circuit_id)
        REFERENCES rdl.circuits (circuit_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.races
    OWNER to postgres;

-- creation of the table constructors_standings
DROP TABLE IF EXISTS constructors_standings;
CREATE TABLE rdl.constructors_standings
(
    constructors_standings_id bigint NOT NULL,
    race_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    points integer NOT NULL DEFAULT 0,
    pos integer NOT NULL,
    wins integer NOT NULL DEFAULT 0,
    PRIMARY KEY (constructors_standings_id),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.constructors_standings
    OWNER to postgres;

-- creation of the table for constructor_results
DROP TABLE IF EXISTS constructors_results;
CREATE TABLE rdl.constructors_results
(
    constructors_results_id bigint NOT NULL,
    race_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    points integer NOT NULL DEFAULT 0,
    PRIMARY KEY (constructors_results_id),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.constructors_results
    OWNER to postgres;

-- creation of the table status
DROP TABLE IF EXISTS rdl.status;
CREATE TABLE rdl.status
(
    status_id bigint NOT NULL,
    status character varying(100) NOT NULL,
    PRIMARY KEY (status_id)
);

ALTER TABLE IF EXISTS rdl.status
    OWNER to postgres;

-- creation of the table drivers_standings
DROP TABLE IF EXISTS drivers_standings;
CREATE TABLE rdl.drivers_standings
(
    drivers_standings_id bigint NOT NULL,
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    points integer NOT NULL DEFAULT 0,
    pos integer NOT NULL,
    wins integer NOT NULL DEFAULT 0,
    PRIMARY KEY (drivers_standings_id),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.drivers_standings
    OWNER to postgres;

-- creation of the table lap_times
DROP TABLE IF EXISTS rdl.lap_times;
CREATE TABLE rdl.lap_times
(
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    lap_number integer NOT NULL,
    pos integer NOT NULL,
    milliseconds bigint NOT NULL DEFAULT 0,
    PRIMARY KEY (race_id, driver_id, lap_number),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.lap_times
    OWNER to postgres;

-- creation of the table pit_stops
DROP TABLE IF EXISTS rdl.pit_stops;
CREATE TABLE rdl.pit_stops
(
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    stop integer NOT NULL,
    lap integer NOT NULL,
    milliseconds bigint NOT NULL DEFAULT 0,
    PRIMARY KEY (race_id, driver_id, stop),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.pit_stops
    OWNER to postgres;

-- creation of the table qualifying
DROP TABLE IF EXISTS rdl.qualifying;
CREATE TABLE rdl.qualifying
(
    qualify_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    pos integer NOT NULL,
    q1 bigint DEFAULT NULL,
    q2 bigint DEFAULT NULL,
    q3 bigint DEFAULT NULL,
    PRIMARY KEY (qualify_id),
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.qualifying
    OWNER to postgres;

-- creation of the table race_results
DROP TABLE IF EXISTS race_results;
CREATE TABLE rdl.race_results
(
    result_id bigint NOT NULL,
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    num integer NOT NULL,
    grid integer NOT NULL,
    pos integer DEFAULT NULL,
    points integer NOT NULL DEFAULT 0,
    laps integer NOT NULL DEFAULT 0,
    milliseconds bigint DEFAULT NULL,
    fastest_lap integer DEFAULT NULL,
    rank integer DEFAULT NULL,
    fastest_lap_time bigint DEFAULT NULL,
    status_id bigint NOT NULL,
    PRIMARY KEY (result_id),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (status_id)
        REFERENCES rdl.status (status_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.race_results
    OWNER to postgres;

-- creation of the table sprint_results
DROP TABLE IF EXISTS rdl.sprint_results;
CREATE TABLE rdl.sprint_results
(
    result_id bigint NOT NULL,
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    num integer NOT NULL,
    grid integer NOT NULL,
    pos integer DEFAULT NULL,
    points integer NOT NULL DEFAULT 0,
    laps integer NOT NULL DEFAULT 0,
    milliseconds bigint DEFAULT NULL,
    fastest_lap integer DEFAULT NULL,
    fastest_lap_time bigint DEFAULT NULL,
    status_id bigint NOT NULL,
    PRIMARY KEY (result_id),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (constructor_id)
        REFERENCES rdl.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (status_id)
        REFERENCES rdl.status (status_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.sprint_results
    OWNER to postgres;

-- creation of the table sessions
DROP TABLE IF EXISTS rdl.sessions; 
CREATE TABLE rdl.sessions
(
    session_key bigint NOT NULL,
    race_id bigint NOT NULL,
    session_type character varying(50) NOT NULL,
    PRIMARY KEY (session_key),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.sessions
    OWNER to postgres;

-- creation of the table weather
DROP TABLE IF EXISTS rdl.weather;
CREATE TABLE rdl.weather
(
    date date NOT NULL,
    hour time without time zone NOT NULL,
    session_key bigint NOT NULL,
    race_id bigint NOT NULL,
    track_temperature double precision DEFAULT NULL,
    air_temperature double precision DEFAULT NULL,
    wind_direction integer DEFAULT NULL,
    wind_speed double precision DEFAULT NULL,
    rainfall boolean DEFAULT NULL,
    humidity integer DEFAULT NULL,
    pressure double precision DEFAULT NULL,
    PRIMARY KEY (date, hour),
    FOREIGN KEY (session_key)
        REFERENCES rdl.sessions (session_key) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.weather
    OWNER to postgres;

-- creation of the table race_lineup
DROP TABLE IF EXISTS rdl.race_lineup;
CREATE TABLE rdl.race_lineup
(
    race_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    driver_number integer NOT NULL,
    team_color character varying(10) NOT NULL,
    PRIMARY KEY (race_id, driver_number),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (driver_id)
        REFERENCES rdl.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.race_lineup
    OWNER to postgres;

--creation of the table speed
DROP TABLE IF EXISTS rdl.speed;
CREATE TABLE rdl.speed
(
    race_id bigint NOT NULL,
    driver_number bigint NOT NULL,
    session_key bigint NOT NULL,
    lap_number integer NOT NULL,
    st_speed integer NOT NULL DEFAULT 0,
    PRIMARY KEY (race_id, driver_number, lap_number),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (session_key)
        REFERENCES rdl.sessions (session_key) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (race_id, driver_number)
        REFERENCES rdl.race_lineup (race_id, driver_number) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.speed
    OWNER to postgres;

-- creation of the table stints
DROP TABLE IF EXISTS rdl.stints;
CREATE TABLE rdl.stints
(
    driver_number integer NOT NULL,
    race_id bigint NOT NULL,
    stint_number integer NOT NULL,
    compound character varying(50) NOT NULL,
    lap_start integer DEFAULT NULL,
    lap_end integer DEFAULT NULL,
    session_key bigint NOT NULL,
    tyre_age_at_start integer NOT NULL DEFAULT 0,
    PRIMARY KEY (driver_number, race_id, stint_number),
    FOREIGN KEY (race_id)
        REFERENCES rdl.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (session_key)
        REFERENCES rdl.sessions (session_key) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (race_id, driver_number)
        REFERENCES rdl.race_lineup (race_id, driver_number) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS rdl.stints
    OWNER to postgres;
