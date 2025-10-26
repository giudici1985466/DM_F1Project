CREATE OR REPLACE FUNCTION meta.log_dml()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_start   timestamp := clock_timestamp();
    v_rows    bigint    := 0;
BEGIN
    -- Count affected rows via transition tables (statement-level)
    IF TG_OP = 'INSERT' THEN
        SELECT count(*) INTO v_rows FROM newtab;
    ELSIF TG_OP = 'UPDATE' THEN
        SELECT count(*) INTO v_rows FROM newtab;
    ELSIF TG_OP = 'DELETE' THEN
        SELECT count(*) INTO v_rows FROM oldtab;
    END IF;

    INSERT INTO meta.log_table (
        table_name,
        operation_type,
        start_time,
        rows_affected,
        status,
        error_message,
        end_time,
        inserted_at
    )
    VALUES (
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        TG_OP,
        v_start,
        v_rows,
        'SUCCESS',
        NULL,
        clock_timestamp(),   -- end_time (timestamp)
        clock_timestamp()    -- inserted_at (timestamp)
    );

    RETURN NULL;  -- statement-level trigger

EXCEPTION WHEN OTHERS THEN
    INSERT INTO meta.log_table (
        table_name,
        operation_type,
        start_time,
        rows_affected,
        status,
        error_message,
        end_time,
        inserted_at
    )
    VALUES (
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        TG_OP,
        v_start,
        v_rows,
        'FAILURE',
        SQLERRM,
        clock_timestamp(),
        clock_timestamp()
    );
    RAISE;  -- keep if you want failures to bubble up
END;
$$;

