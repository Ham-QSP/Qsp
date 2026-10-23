-- Signaling server schema, created on first database start.
-- The signaling image (Spring Boot 4.1) currently does not run its Liquibase
-- changelog at startup, so the tables are created here (same as its own docs).
-- TODO(maintainer): if the signaling image starts running Liquibase again, remove
-- this file and set SPRING_LIQUIBASE_DATABASE_CHANGE_LOG_TABLE=signaling_databasechangelog
-- (and ..._LOCK_TABLE=signaling_databasechangeloglock) on the signaling service so
-- it does not share tracking tables with the auth service.
CREATE TABLE IF NOT EXISTS station
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    main_qrz VARCHAR(20) NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS agent
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id UUID NOT NULL,
    display_name VARCHAR(30) NOT NULL,
    secret VARCHAR(256),
    UNIQUE (station_id, display_name)
);
