-- TEMPORARY WORKAROUND - signaling schema, created on first database start.
--
-- The released signaling image does not run Liquibase: its pom has only
-- liquibase-core and no Spring Boot Liquibase module (upstream bug in
-- qsp-signaling-server, to be fixed there). So the schema from
-- qsp-signaling-server/src/main/resources/db/changelog/00000_initial.yaml is
-- DUPLICATED BY HAND here and may drift from it.
--
-- * This script only runs on a fresh database volume. After a schema change,
--   run `docker compose down -v` (this deletes the data).
-- * Once the upstream image runs Liquibase again, REMOVE this script (otherwise
--   Liquibase fails with "table already exists") and set on the signaling service:
--   SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE=signaling_databasechangelog
--   SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_LOCK_TABLE=signaling_databasechangeloglock
--   (plus the SPRING_LIQUIBASE_URL/USER/PASSWORD settings).
CREATE TABLE station
(
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    main_qrz VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    CONSTRAINT pk_station PRIMARY KEY (id),
    CONSTRAINT uq_station_main_qrz UNIQUE (main_qrz)
);

CREATE TABLE agent
(
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    station_id UUID NOT NULL,
    display_name VARCHAR(30) NOT NULL,
    secret VARCHAR(256),
    CONSTRAINT pk_agent PRIMARY KEY (id),
    CONSTRAINT uq_agent_station_id_display_name UNIQUE (station_id, display_name)
);
