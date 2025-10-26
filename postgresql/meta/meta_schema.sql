-- creation of the schema meta

DROP SCHEMA IF EXISTS meta;
CREATE SCHEMA IF NOT EXISTS meta
    AUTHORIZATION postgres;

DROP TABLE IF EXISTS meta.log_table;
CREATE TABLE meta.log_table
(
    log_id bigserial NOT NULL,
    table_name character varying(50) NOT NULL,
    operation_type character varying(50) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    rows_affected bigint NOT NULL,
    status character varying(100) NOT NULL,
    error_message text DEFAULT NULL,
    inserted_at time without time zone NOT NULL,
    PRIMARY KEY (log_id)
);

ALTER TABLE IF EXISTS meta.log_table
    OWNER to postgres;