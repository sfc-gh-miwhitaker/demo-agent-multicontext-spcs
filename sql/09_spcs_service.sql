/*==============================================================================
09 - SPCS SERVICE
Create the containerized web application.
Run AFTER pushing the Docker image (tools/05_build_and_push.sh).
==============================================================================*/

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA AGENT_MULTICONTEXT;
USE WAREHOUSE SFE_AGENT_MULTICONTEXT_WH;

-- Drop previous version if redeploying
DROP SERVICE IF EXISTS AGENT_APP;

CREATE SERVICE AGENT_APP
  IN COMPUTE POOL SFE_AGENT_MULTICONTEXT_POOL
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1
  EXTERNAL_ACCESS_INTEGRATIONS = ()
  COMMENT = 'DEMO: Agent multicontext web app (Expires: 2026-04-02)'
  FROM SPECIFICATION $$
spec:
  containers:
  - name: app
    image: /SNOWFLAKE_EXAMPLE/AGENT_MULTICONTEXT/IMAGES/agent-multicontext:latest
    env:
      PORT: "8080"
    readinessProbe:
      port: 8080
      path: /health
    resources:
      requests:
        cpu: 0.5
        memory: 512M
      limits:
        cpu: 1
        memory: 1G
  endpoints:
  - name: app
    port: 8080
    public: true
serviceRoles:
- name: app_user
  endpoints:
  - app
$$;

-- Grant access to the public endpoint
GRANT SERVICE ROLE AGENT_APP!app_user TO ROLE SYSADMIN;
GRANT SERVICE ROLE AGENT_APP!app_user TO ROLE TV_ADMIN_ROLE;
GRANT SERVICE ROLE AGENT_APP!app_user TO ROLE TV_VIEWER_ROLE;

-- Show the public endpoint URL
SELECT SYSTEM$GET_SERVICE_STATUS('SNOWFLAKE_EXAMPLE.AGENT_MULTICONTEXT.AGENT_APP') AS service_status;
SHOW ENDPOINTS IN SERVICE AGENT_APP;
