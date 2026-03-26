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

-- Compute pool (account-level object, SFE_ prefix per naming convention)
CREATE COMPUTE POOL IF NOT EXISTS SFE_AGENT_MULTICONTEXT_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300
  COMMENT = 'DEMO: Agent multicontext compute pool (Expires: 2026-04-02)';

-- Required for services with public endpoints
USE ROLE ACCOUNTADMIN;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
GRANT USAGE, MONITOR ON COMPUTE POOL SFE_AGENT_MULTICONTEXT_POOL TO ROLE SYSADMIN;

-- Show the registry URL for the docker push step
SHOW IMAGE REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.AGENT_MULTICONTEXT;

SELECT
    'Image repository ready. Push your image to:' AS next_step,
    "repository_url" || '/agent-multicontext:latest' AS image_push_target
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
