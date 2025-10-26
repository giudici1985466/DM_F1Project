DO $$
DECLARE
  r record;
  ins_name text;
  upd_name text;
  del_name text;
BEGIN
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
      AND table_schema IN ('rdl')
  LOOP
    ins_name := format('tr_%s_log_ins_%s',
                       left(r.table_name, 24),
                       substr(md5(r.table_schema||'.'||r.table_name), 1, 6));
    upd_name := format('tr_%s_log_upd_%s',
                       left(r.table_name, 24),
                       substr(md5(r.table_schema||'.'||r.table_name), 1, 6));
    del_name := format('tr_%s_log_del_%s',
                       left(r.table_name, 24),
                       substr(md5(r.table_schema||'.'||r.table_name), 1, 6));

    -- INSERT
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',
                   ins_name, r.table_schema, r.table_name);
    EXECUTE format($fmt$
      CREATE TRIGGER %I
      AFTER INSERT ON %I.%I
      REFERENCING NEW TABLE AS newtab
      FOR EACH STATEMENT
      EXECUTE FUNCTION meta.log_dml()
    $fmt$, ins_name, r.table_schema, r.table_name);

    -- UPDATE
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',
                   upd_name, r.table_schema, r.table_name);
    EXECUTE format($fmt$
      CREATE TRIGGER %I
      AFTER UPDATE ON %I.%I
      REFERENCING OLD TABLE AS oldtab NEW TABLE AS newtab
      FOR EACH STATEMENT
      EXECUTE FUNCTION meta.log_dml()
    $fmt$, upd_name, r.table_schema, r.table_name);

    -- DELETE
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',
                   del_name, r.table_schema, r.table_name);
    EXECUTE format($fmt$
      CREATE TRIGGER %I
      AFTER DELETE ON %I.%I
      REFERENCING OLD TABLE AS oldtab
      FOR EACH STATEMENT
      EXECUTE FUNCTION meta.log_dml()
    $fmt$, del_name, r.table_schema, r.table_name);
  END LOOP;
END$$;

