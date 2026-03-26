/*==============================================================================
DEPLOY SPCS - Agent Multicontext Demo
Pair-programmed by SE Community + Cortex Code | Expires: 2026-04-02

Creates the Snowpark Container Services service for the web application.
Run AFTER deploy_all.sql and tools/push.sh.

INSTRUCTIONS: Open in Snowsight -> Click "Run All"
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

-- Check service status + surface the app URL
CALL SYSTEM$WAIT_FOR_SERVICES(300, 'SNOWFLAKE_EXAMPLE.AGENT_MULTICONTEXT.AGENT_APP');

SHOW ENDPOINTS IN SERVICE AGENT_APP
  ->> SELECT
        'Open this URL in your browser:' AS next_step,
        "ingress_url"                    AS app_url
      FROM $1
      WHERE "name" = 'app';
