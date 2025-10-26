-- creation of the table status
DROP TABLE IF EXISTS dw.status;
CREATE TABLE dw.status
(
    status_id bigint NOT NULL,
    description character varying(100),
    PRIMARY KEY (status_id)
);

ALTER TABLE IF EXISTS dw.status
    OWNER to postgres;

-- creation of table season
DROP TABLE IF EXISTS dw.season;
CREATE TABLE dw.season
(
    season_id serial NOT NULL,
    year integer NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (season_id)
);

ALTER TABLE IF EXISTS dw.season
    OWNER to postgres;

-- creation of table weather
DROP TABLE IF EXISTS dw.weather;
CREATE TABLE dw.weather
(
    weather_id bigint NOT NULL,
    rainfall boolean DEFAULT NULL,
    avg_air_temperature double precision,
    stage_air_temperature character varying(50) COLLATE pg_catalog."default",
    avg_track_temperature double precision,
    stage_track_temperature character varying(50) COLLATE pg_catalog."default",
    avg_air_humidity double precision,
    stage_air_humidity character varying(50) COLLATE pg_catalog."default",
    avg_atm_pressure double precision,
    avg_wind_speed double precision,
    stage_wind_speed character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT weather_pkey PRIMARY KEY (weather_id)
);

ALTER TABLE IF EXISTS dw.weather
    OWNER to postgres;

-- creation of table countries
DROP TABLE IF EXISTS dw.countries;

CREATE TABLE dw.countries (
    nation_id serial PRIMARY KEY,
    country varchar(100) NOT NULL,
    continent varchar(100) NOT NULL,
    nationality varchar(100) NOT NULL
);

ALTER TABLE IF EXISTS dw.countries
    OWNER to postgres;

-- creation of table constructors
DROP TABLE IF EXISTS dw.constructors;

CREATE TABLE dw.constructors
(
    constructor_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    nation_id integer NOT NULL,
    PRIMARY KEY (constructor_id),
    FOREIGN KEY (nation_id)
        REFERENCES dw.countries (nation_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS dw.constructors
    OWNER to postgres;

-- creation of table date
DROP TABLE IF EXISTS dw.date;

CREATE TABLE dw.date (
    date_id serial NOT NULL,
    calendar_date date NOT NULL,
    year integer NOT NULL,
    quarter integer NOT NULL,
    month integer NOT NULL,
    week integer NOT NULL,
    day integer NOT NULL,
    day_of_week integer NOT NULL,
    day_name varchar(20),
    month_name varchar(20),
    CONSTRAINT date_dim_pkey PRIMARY KEY (date_id)
);

-- creation of table drivers
DROP TABLE IF EXISTS dw.drivers;
CREATE TABLE dw.drivers
(
    driver_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    surname character varying(100) NOT NULL,
    dob integer NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (driver_id),
    FOREIGN KEY (dob)
        REFERENCES dw.date (date_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS dw.drivers
    OWNER to postgres;

-- creation of table driver_nationality
DROP TABLE IF EXISTS dw.driver_nationality;

CREATE TABLE dw.driver_nationality
(
    driver_id bigint NOT NULL,
    nation_id bigint NOT NULL,
    PRIMARY KEY (driver_id, nation_id),
    FOREIGN KEY (driver_id)
        REFERENCES dw.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (nation_id)
        REFERENCES dw.countries (nation_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS dw.driver_nationality
    OWNER to postgres;

-- creation of table circuits
DROP TABLE IF EXISTS dw.circuits;

CREATE TABLE dw.circuits
(
    circuit_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    location character varying(100) NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    alt integer NOT NULL,
    alt_stage character varying(20) NOT NULL,
    url character varying(100) NOT NULL,
    nation_id bigint NOT NULL,
    PRIMARY KEY (circuit_id),
    FOREIGN KEY (nation_id)
        REFERENCES dw.countries (nation_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS dw.circuits
    OWNER to postgres;

-- creation of table races
DROP TABLE IF EXISTS races;
CREATE TABLE dw.races
(
    race_id bigint NOT NULL,
    date_id integer NOT NULL,
    circuit_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    round integer NOT NULL,
    url character varying(100) NOT NULL,
    PRIMARY KEY (race_id),
    FOREIGN KEY (date_id)
        REFERENCES dw.date (date_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (circuit_id)
        REFERENCES dw.circuits (circuit_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID 
);

ALTER TABLE IF EXISTS dw.races
    OWNER to postgres;

-- creation of the table race_results
DROP TABLE IF EXISTS dw.race_results;
CREATE TABLE dw.race_results
(
    race_result_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    race_id bigint NOT NULL,
    constructor_id bigint NOT NULL,
    status_id bigint NOT NULL,
    weather_id bigint NOT NULL,
    driver_initial_pos integer,
    driver_final_pos integer,
    driver_points integer,
    driver_fastest_lap integer,
    driver_avg_lap_time integer,
    number_of_stints integer,
    number_of_pits integer,
    completed_laps integer,
    starting_compound character varying(50),
    starting_tyre_age integer,
    PRIMARY KEY (race_result_id),
    FOREIGN KEY (driver_id)
        REFERENCES dw.drivers (driver_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (race_id)
        REFERENCES dw.races (race_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (constructor_id)
        REFERENCES dw.constructors (constructor_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (status_id)
        REFERENCES dw.status (status_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    FOREIGN KEY (weather_id)
        REFERENCES dw.weather (weather_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE IF EXISTS dw.race_results
    OWNER to postgres;
