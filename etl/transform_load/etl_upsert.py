# requirements: psycopg2-binary>=2.9
import csv
import os
import glob
import psycopg2
from psycopg2 import sql

# ---- CONFIG ----
PG_DSN = "postgresql://postgres:password@localhost:5432/DMProject"
CSV_DIR = "testdata/staging"
DEFAULT_SCHEMA = "rdl"
STRIP_SUFFIX = "_staging"       # strip suffix from filenames if present
FORCE_TARGET_SCHEMA = None      # e.g., "rdl" to force all loads to that schema
# ----------------

# Load order 
LOAD_ORDER = [
    "countries",
    "drivers",
    "driver_nationality",
    "constructors",
    "constructor_nationality",
    "circuits",
    "seasons",
    "races",
    "constructors_standings",
    "constructors_results",
    "status",
    "drivers_standings",
    "lap_times",
    "pit_stops",
    "qualifying",
    "race_results",
    "sprint_results",
    "sessions",
    "weather",
    "race_lineup",
    "speed",
    "stints",
]

UPSERT_KEYS = {

    "countries": ["country"],
    "drivers": ["driver_id"],
    "driver_nationality": ["driver_id", "nationality"],
    "constructors": ["constructor_id"],
    "constructor_nationality": ["constructor_id", "nationality"],
    "circuits": ["circuit_id"],
    "seasons": ["year"],
    "status": ["status_id"],
    "races": ["race_id"],
    "constructors_standings": ["constructors_standings_id"],
    "constructors_results": ["constructors_results_id"],
    "drivers_standings": ["drivers_standings_id"],
    "sessions": ["session_key"],
    "weather": ["date", "hour"],
    "race_results": ["result_id"],
    "sprint_results": ["result_id"],
    "qualifying": ["qualify_id"],
    "lap_times": ["race_id", "driver_id", "lap_number"],
    "pit_stops": ["race_id", "driver_id", "stop"],
    "race_lineup": ["race_id", "driver_number"],
    "speed": ["race_id", "driver_number", "lap_number"],
    "stints": ["driver_number", "race_id", "stint_number"],
}

CASTS = {
    "countries": {
        "country": "text",
        "continent": "text",
        "nationality": "text",
    },
    "drivers": {
        "driver_id": "bigint",
        "driver_ref": "text",
        "code": "text",
        "forename": "text",
        "surname": "text",
        "dob": "date",
        "url": "text",
    },
    "driver_nationality": {
        "driver_id": "bigint",
        "nationality": "text",
    },
    "constructors": {
        "constructor_id": "bigint",
        "name": "text",
        "url": "text",
    },
    "constructor_nationality": {
        "constructor_id": "bigint",
        "nationality": "text",
    },
    "circuits": {
        "circuit_id": "bigint",
        "name": "text",
        "location": "text",
        "country": "text",
        "lat": "double precision",
        "lng": "double precision",
        "alt": "integer",
        "url": "text",
    },
    "seasons": {
        "year": "integer",
        "url": "text",
    },
    "races": {
        "race_id": "bigint",
        "year": "integer",
        "round": "integer",
        "circuit_id": "bigint",
        "name": "text",
        "date": "date",
        "url": "text",
        "meeting_key": "bigint",
    },
    "constructors_standings": {
        "constructors_standings_id": "bigint",
        "race_id": "bigint",
        "constructor_id": "bigint",
        "points": "integer",
        "pos": "integer",
        "wins": "integer",
    },
    "constructors_results": {
        "constructors_results_id": "bigint",
        "race_id": "bigint",
        "constructor_id": "bigint",
        "points": "integer",
    },
    "status": {
        "status_id": "bigint",
        "status": "text",
    },
    "drivers_standings": {
        "drivers_standings_id": "bigint",
        "race_id": "bigint",
        "driver_id": "bigint",
        "points": "integer",
        "pos": "integer",
        "wins": "integer",
    },
    "sessions": {
        "session_key": "bigint",
        "race_id": "bigint",
        "session_name": "text",   
    },
    "weather": {
        "date": "date",
        "hour": "time",
        "session_key": "bigint",
        "race_id": "bigint",
        "track_temperature": "double precision",
        "air_temperature": "double precision",
        "wind_direction": "integer",
        "wind_speed": "double precision",
        "rainfall": "boolean",
        "humidity": "integer",
        "pressure": "double precision",
    },
    "race_results": {
        "result_id": "bigint",
        "race_id": "bigint",
        "driver_id": "bigint",
        "constructor_id": "bigint",
        "num": "integer",
        "grid": "integer",
        "pos": "integer",
        "points": "integer",
        "laps": "integer",
        "milliseconds": "bigint",
        "fastest_lap": "integer",
        "rank": "integer",
        "fastest_lap_time": "bigint",
        "status_id": "bigint",
    },
    "sprint_results": {
        "result_id": "bigint",
        "race_id": "bigint",
        "driver_id": "bigint",
        "constructor_id": "bigint",
        "num": "integer",
        "grid": "integer",
        "pos": "integer",
        "points": "integer",
        "laps": "integer",
        "milliseconds": "bigint",
        "fastest_lap": "integer",
        "fastest_lap_time": "bigint",
        "status_id": "bigint",
    },
    "qualifying": {
        "qualify_id": "bigint",
        "constructor_id": "bigint",
        "race_id": "bigint",
        "driver_id": "bigint",
        "pos": "integer",
        "q1": "bigint",
        "q2": "bigint",
        "q3": "bigint",
    },
    "lap_times": {
        "race_id": "bigint",
        "driver_id": "bigint",
        "lap_number": "integer",
        "pos": "integer",
        "milliseconds": "bigint",
    },
    "pit_stops": {
        "race_id": "bigint",
        "driver_id": "bigint",
        "stop": "integer",
        "lap": "integer",
        "milliseconds": "bigint",
    },
    "race_lineup": {
        "race_id": "bigint",
        "driver_id": "bigint",
        "driver_number": "integer",
        "team_color": "text",
    },
    "speed": {
        "race_id": "bigint",
        "driver_number": "bigint",
        "session_key": "bigint",
        "lap_number": "integer",
        "st_speed": "integer",
    },
    "stints": {
        "driver_number": "integer",
        "race_id": "bigint",
        "stint_number": "integer",
        "compound": "text",
        "lap_start": "integer",
        "lap_end": "integer",
        "session_key": "bigint",
        "tyre_age_at_start": "integer",
    },
}


def parse_table_from_filename(path: str):
    base = os.path.basename(path)
    stem = os.path.splitext(base)[0]
    parts = stem.split(".")
    if len(parts) == 1:
        schema, table = DEFAULT_SCHEMA, parts[0]
    elif len(parts) == 2:
        schema, table = parts[0], parts[1]
    else:
        raise ValueError(f"Unexpected filename format: {base}")
    if STRIP_SUFFIX and table.endswith(STRIP_SUFFIX):
        table = table[: -len(STRIP_SUFFIX)]
    if FORCE_TARGET_SCHEMA:
        schema = FORCE_TARGET_SCHEMA
    return schema, table

def table_exists(conn, schema, table) -> bool:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema=%s AND table_name=%s
            LIMIT 1
        """, (schema, table))
        return cur.fetchone() is not None

def get_table_columns(conn, schema, table):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema=%s AND table_name=%s
            ORDER BY ordinal_position
        """, (schema, table))
        return [r[0] for r in cur.fetchall()]

def get_primary_key_columns(conn, schema: str, table: str):
    """
    Fallback: auto-detect PK columns from the DB if not provided in UPSERT_KEYS.
    """
    sql_pk = """
    SELECT a.attname
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ANY(i.indkey)
    WHERE i.indisprimary = TRUE
      AND n.nspname = %s
      AND c.relname = %s
    ORDER BY array_position(i.indkey, a.attnum);
    """
    with conn.cursor() as cur:
        cur.execute(sql_pk, (schema, table))
        return [r[0] for r in cur.fetchall()]

def sort_key(path):
    _, table = parse_table_from_filename(path)
    try:
        return LOAD_ORDER.index(table)
    except ValueError:
        return len(LOAD_ORDER)  

def copy_csv_to_temp(conn, header, csv_path, temp_name):
    cols_sql = sql.SQL(", ").join(sql.SQL("{} text").format(sql.Identifier(c)) for c in header)
    with conn.cursor() as cur:
        cur.execute(sql.SQL("DROP TABLE IF EXISTS {}").format(sql.Identifier(temp_name)))
        cur.execute(sql.SQL("CREATE TEMP TABLE {} ({})").format(sql.Identifier(temp_name), cols_sql))
        with open(csv_path, "r", newline="", encoding="utf-8") as f:
            cur.copy_expert(
                sql.SQL("COPY {} ({}) FROM STDIN WITH (FORMAT csv, HEADER true, NULL '\\N')")
                .format(sql.Identifier(temp_name), sql.SQL(", ").join(map(sql.Identifier, header))),
                f
            )

def upsert_from_temp(conn, schema, table, temp_name, csv_cols, pk_cols):
    if not pk_cols:
        pk_cols = UPSERT_KEYS.get(table) or UPSERT_KEYS.get(f"{schema}.{table}") or []
    if not pk_cols:
        pk_cols = get_primary_key_columns(conn, schema, table)
    if not pk_cols:
        raise SystemExit(f"[ERROR] No UPSERT key for {schema}.{table} and no PK found in DB.")

    target_cols = get_table_columns(conn, schema, table)
    common = [c for c in target_cols if c in csv_cols]
    if not common:
        raise SystemExit(f"[ERROR] No overlapping columns between CSV and {schema}.{table}.")

    non_pk = [c for c in common if c not in pk_cols]
    cast_map = CASTS.get(table, {})

    with conn.cursor() as cur:
        target_ident = sql.SQL("{}.{}").format(sql.Identifier(schema), sql.Identifier(table))
        cols_list = sql.SQL(", ").join(map(sql.Identifier, common))

        select_elems = []
        for c in common:
            if c in cast_map:
                select_elems.append(
                    sql.SQL("NULLIF(NULLIF({col}, ''), '\\N')::{typ}").format(
                        col=sql.Identifier(c),
                        typ=sql.SQL(cast_map[c])
                    )
                )
            else:
                select_elems.append(sql.Identifier(c))
        select_list = sql.SQL(", ").join(select_elems)

        set_list = sql.SQL(", ").join(
            sql.SQL("{} = EXCLUDED.{}").format(sql.Identifier(c), sql.Identifier(c)) for c in non_pk
        )


        changed_pred = (
            sql.SQL(" OR ").join(
                sql.SQL("{}.{} IS DISTINCT FROM EXCLUDED.{}").format(
                    target_ident, sql.Identifier(c), sql.Identifier(c)
                )
                for c in non_pk
            ) if non_pk else sql.SQL("FALSE")
        )

        upsert_sql = sql.SQL("""
            INSERT INTO {target} ({cols})
            SELECT {select_cols} FROM {stg}
            ON CONFLICT ({pk}) DO {action}
        """).format(
            target=target_ident,
            cols=cols_list,
            select_cols=select_list,
            stg=sql.Identifier(temp_name),
            pk=sql.SQL(", ").join(map(sql.Identifier, pk_cols)),
            action=(
                sql.SQL("UPDATE SET {set_list} WHERE {changed}")
                .format(set_list=set_list, changed=changed_pred)
                if non_pk else sql.SQL("NOTHING")
            )
        )

        cur.execute(upsert_sql)

def load_csv_incremental(conn, schema, table, csv_path):
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = [h.strip() for h in next(reader)]

    table_cols = set(get_table_columns(conn, schema, table))
    csv_cols = set(header)
    missing = table_cols - csv_cols
    extra = csv_cols - table_cols
    if missing:
        print(f"[INFO] {schema}.{table}: columns missing in CSV (kept as defaults): {sorted(missing)}")
    if extra:
        print(f"[INFO] {schema}.{table}: extra CSV columns ignored by target: {sorted(extra)}")

  
    temp_name = f"stg_{schema}_{table}"
    copy_csv_to_temp(conn, header, csv_path, temp_name)

    
    pk_cols = UPSERT_KEYS.get(table) or UPSERT_KEYS.get(f"{schema}.{table}") or []
    upsert_from_temp(conn, schema, table, temp_name, header, pk_cols)

def main():
    csvs = glob.glob(os.path.join(CSV_DIR, "*.csv"))
    csvs = sorted(csvs, key=lambda p: LOAD_ORDER.index(parse_table_from_filename(p)[1])
                  if parse_table_from_filename(p)[1] in LOAD_ORDER else len(LOAD_ORDER))

    if not csvs:
        raise SystemExit(f"No CSVs found in {CSV_DIR}")

    with psycopg2.connect(PG_DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SET CONSTRAINTS ALL DEFERRED;")

        for path in csvs:
            schema, table = parse_table_from_filename(path)
            if not table_exists(conn, schema, table):
                print(f"[WARN] Skipping {path}: target table {schema}.{table} does not exist.")
                continue
            print(f"Loading {path} -> {schema}.{table}")
            try:
                load_csv_incremental(conn, schema, table, path)
            except Exception as e:
                raise SystemExit(f"[ERROR] Failed loading {path} into {schema}.{table}: {e}")

if __name__ == "__main__":
    main()
