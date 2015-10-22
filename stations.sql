DROP TABLE IF EXISTS stations CASCADE;

CREATE TABLE stations (
    region VARCHAR,
    site_code VARCHAR,
    location_number VARCHAR,
    station_number VARCHAr,
    state_code VARCHAR,
    site_name VARCHAR,
    latitude REAL,
    longitude REAL,
    method VARCHAR,
    sampling_agency VARCHAR,
    historical_data VARCHAR);

\copy stations FROM 'stations.csv' WITH (FORMAT csv, HEADER TRUE); 

ALTER TABLE stations 
    ADD COLUMN id SERIAL PRIMARY KEY,
    ADD geom GEOMETRY(Point, 4326);

UPDATE stations SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326);
