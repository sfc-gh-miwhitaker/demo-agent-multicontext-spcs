/*==============================================================================
08 - SPCS INFRASTRUCTURE
Image repository, compute pool, and grants for Snowpark Container Services.
==============================================================================*/

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA AGENT_MULTICONTEXT;
USE WAREHOUSE SFE_AGENT_MULTICONTEXT_WH;

-- Image repository (lives inside the project schema)
CREATE IMAGE REPOSITORY IF NOT EXISTS IMAGES
  COMMENT = 'DEMO: Agent multicontext container images (Expires: 2026-04-02)';

-- Account-level operations require ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

CREATE COMPUTE POOL IF NOT EXISTS SFE_AGENT_MULTICONTEXT_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300
  COMMENT = 'DEMO: Agent multicontext compute pool (Expires: 2026-04-02)';

GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN;
GRANT USAGE, MONITOR ON COMPUTE POOL SFE_AGENT_MULTICONTEXT_POOL TO ROLE SYSADMIN;

-- Image repo URL is surfaced by deploy_all.sql after this script runs
