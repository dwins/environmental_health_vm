DROP TABLE IF EXISTS spills;
CREATE TABLE spills (
    site_code VARCHAR,
    map_location_number INTEGER,
    source VARCHAR,
    equipment_failure INTEGER,
    human_error INTEGER,
    other INTEGER,
    storm INTEGER,
    tank_test_failure INTEGER,
    unknown INTEGER,
    station_number VARCHAR,
    state_code VARCHAR,
    site_name VARCHAR,
    latitude REAL,
    longitude REAL,
    method VARCHAR,
    agency VARCHAR,
    associated_historical_data VARCHAR);

\copy spills FROM 'spills.csv' WITH (HEADER true, FORMAT csv);

ALTER TABLE spills
    ADD COLUMN id SERIAL PRIMARY KEY,
    DROP COLUMN state_code,
    DROP COLUMN latitude,
    DROP COLUMN longitude,
    DROP COLUMN method,
    DROP COLUMN agency,
    DROP COLUMN associated_historical_data;
