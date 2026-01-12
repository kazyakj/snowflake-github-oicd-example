-- Cost Cop enforcement: sets policy across warehouses matching COST_COP_DEMO_WH_%.
EXECUTE IMMEDIATE $$
DECLARE
  run_ts VARCHAR;
BEGIN
  run_ts := TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS');
  SHOW WAREHOUSES LIKE 'COST_COP_DEMO_WH_%';

  LET res RESULTSET := (SELECT "name" as wh_name FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  LET cur CURSOR FOR res;

  FOR wh IN cur DO
    BEGIN
      LET sql_cmd VARCHAR := 'ALTER WAREHOUSE IF EXISTS "' || wh.wh_name || '" SET ' ||
        'AUTO_SUSPEND = 60 ' ||
        'COMMENT = ''Policed by Cost Cop via GitHub OIDC at ' || :run_ts || '''';
        
      EXECUTE IMMEDIATE :sql_cmd;
  
    EXCEPTION
      WHEN OTHER THEN
        -- for demo lets not worry about errors
        NULL;
    END;
  END FOR;

  RETURN 'Warehouses have been successfully policed at ' || :run_ts;
END;
$$
;

SET stmt =
$$
BEGIN
  SHOW WAREHOUSES LIKE 'COST_COP_DEMO_WH_%';
  LET res RESULTSET := (SELECT "name" name, "type" type, "auto_suspend" auto_suspend FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  
  RETURN TABLE(res);
END;
$$
;

EXECUTE IMMEDIATE $stmt;
