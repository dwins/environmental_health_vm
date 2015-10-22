# Organizing Environmental Health Data with PostGIS

## Data
* Data provided in .xslx format with many tables
* Manual reformatting applied to station locations (table 3), metal
  concentrations (table 13), spill incident data (table 8-2), and wastewater
  compounds concentration data (table 19).
* Cleaned tables provided in CSV format.

## Postgres (Importing)
* Set up VM on Ubuntu using Vagrant/Virtualbox
* Install the following packages:
    - postgresql-9.3
    - postgresql-9.3-postgis-2.1
    - postgresql-9.3-postgis-2.1-scripts
    - postgresql-client-9.3
* Can access Postgres databases with 'sudo -u postgres psql <database>' (Will discuss QGIS access in later section)
* Enter following shell commands to set up a spatial database for environmental health data:

  ```
  $ sudo -u postgres createdb environmental_health
  $ sudo -u postgres psql environmental_health -c 'create extension postgis'
  ```
* Create SQL scripts for importing CSV.  The general sequence of operations is:
  1. Use 'DROP TABLE IF EXISTS' SQL command to ensure we start with an empty
     table each time.  This makes it easier to iterate on the import process if
     any errors arise, and also ensures that we don't run into problems with
     having multiple copies of the data if the script is run multiple times.
  2. Use 'CREATE TABLE' SQL command to create a table defining the types of all
     columns.  Most columns will fit into 'VARCHAR' (free text), 'INTEGER'
     (whole numbers) or 'REAL' (fractional numbers) data types.  It is also
     useful to create a 'serial primary key' in each table which will ensure
     that every row has a unique identifier, and we use the 'geometry' type for
     the location information (needed for QGIS and for Shapefile export.)
  3. Use 'COPY FROM' SQL command to read in the CSV file and add each row as a
     SQL record. The '\copy' psql command can help with permissions problems here.
  4. Some additional manipulation may be appropriate after CSV import.
     For example:
     * Some of the technicians performing manual cleanup ALSO performed a
       manual join with the stations table leading to redundant columns that
       could be safely removed.
     * Columns with the GEOMETRY type cannot be imported directly from CSV and must be
       created in a postprocessing step.

* In this directory each cleaned CSV file is accompanied with a .sql file for
  importing to Postgres.  These can be executed from the command line with
  psql.  For example, to import the stations table, the command is:
  ```
  $ sudo -u postgres psql environmental_health -f stations.sql
  ```

## Postgres (Querying)
* With the tables imported to postgres, it is possible to list values from the table meeting certain criteria:
  * Show the types of the columns of a table:
    ```
environmental_health=# \d stations;
                                    Table "public.stations"
     Column      |         Type         |                       Modifiers                       
-----------------+----------------------+-------------------------------------------------------
 region          | character varying    | 
 site_code       | character varying    | 
 location_number | character varying    | 
 station_number  | character varying    | 
 state_code      | character varying    | 
 site_name       | character varying    | 
 latitude        | real                 | 
 longitude       | real                 | 
 method          | character varying    | 
 sampling_agency | character varying    | 
 historical_data | character varying    | 
 id              | integer              | not null default nextval('stations_id_seq'::regclass)
 geom            | geometry(Point,4326) | 
Indexes:
    "stations_pkey" PRIMARY KEY, btree (id)
    ```

  * Show all fields for all stations: 
    ```
    SELECT * FROM STATIONS;
    ```
  
  * Show the site name and number for the 10 stations with the highest station numbers:
    ```
environmental_health=# SELECT site_name, station_number FROM stations ORDER BY station_number DESC LIMIT 10;
                 site_name                  | station_number  
--------------------------------------------+-----------------
 Peconic Bay east of Robins Island, NY      | 405822072270001
 Flanders Bay southeast of Reeves Creek, NY | 405531072360701
 Flanders Bay near Red Cedar Point, NY      | 405448072343101
 Upper NY Harbor EPA REMAP site UH451       | 405417073550601
 Upper NY Harbor EPA REMAP site UH465       | 405335073560401
 Upper NY Harbor EPA REMAP site UH469       | 405229073554901
 Upper NY Harbor EPA REMAP site UH404       | 405155073562101
 Hudson River at Englewood Cliffs, NJ       | 405135073570401
 Upper NY Harbor EPA REMAP site UH459       | 405124073565001
 Upper NY Harbor EPA REMAP site UH411       | 405101073570201
(10 rows)
    ```
  * List all unique values of the 'region' field in the stations table:
    ```
environmental_health=# SELECT DISTINCT region FROM stations;
           region           
----------------------------
 Northeast New Jersey shore
 Lower Harbor/Raritan Bay
 Great Bay
 Newark Bay
 Atlantic City
 Barnegat Bay
 Cape May
 Great South Bay
 Peconic Bay
 Upper Harbor
 Jamaica Bay
 Western Bays
(12 rows)

    ```

  * List the site codes and aluminum levels of the sites with the 10 highest aluminum levels:
    ```
environmental_health=# select site_code, aluminum from metals order by aluminum limit 10;
 site_code | aluminum 
-----------+----------
 FB01      |     2994
 FB03      |     4495
 NOAA4     |     4614
 BB01      |     6395
 MB01      |     8154
 NOAA8     |     9760
 GSB07     |     9833
 NOAA2     |     9851
 NOAA7     |    10432
 GSB01     |    10680
(10 rows)
    ```
  
* It is also possible to perform queries that join data from multiple tables.

  * List the site codes, aluminum levels, and latitude/longitude coordinates of the sites with the 10 highest aluminum levels:
    ```
environmental_health=# select m.site_code, m.aluminum, s.latitude, s.longitude from metals AS m JOIN stations AS s ON s.site_code = m.site_code order by m.aluminum limit 10;
 site_code | aluminum | latitude | longitude 
-----------+----------+----------+-----------
 FB01      |     2994 |  40.9231 |  -72.5878
 FB03      |     4495 |  40.9254 |  -72.6021
 NOAA4     |     4614 |   39.949 |  -74.1911
 BB01      |     6395 |    40.04 |  -74.0522
 MB01      |     8154 |   40.753 |  -72.8303
 NOAA8     |     9760 |  40.6448 |   -73.251
 GSB07     |     9833 |   40.622 |   -73.415
 NOAA2     |     9851 |   40.399 |  -73.9811
 NOAA7     |    10432 |  40.6474 |  -73.1669
 GSB01     |    10680 |   40.732 |  -72.9598
(10 rows)

    ```

  * The same, but also include 2,6-Dimethylnaphthalene levels from the wastewater compounds table:
    ```
environmental_health=# select m.site_code, m.aluminum, s.latitude, s.longitude, x."2,6-Dimethylnaphthalene" from metals AS m JOIN stations AS s ON s.site_code = m.site_code JOIN wastewater_compounds AS x on s.site_code = x.site_code order by m.aluminum limit 10;
 site_code | aluminum | latitude | longitude | 2,6-Dimethylnaphthalene 
-----------+----------+----------+-----------+-------------------------
 FB01      |     2994 |  40.9231 |  -72.5878 |                       0
 FB03      |     4495 |  40.9254 |  -72.6021 |                       0
 NOAA4     |     4614 |   39.949 |  -74.1911 |                    44.1
 BB01      |     6395 |    40.04 |  -74.0522 |                      41
 MB01      |     8154 |   40.753 |  -72.8303 |                      49
 NOAA8     |     9760 |  40.6448 |   -73.251 |                      49
 GSB07     |     9833 |   40.622 |   -73.415 |                       0
 NOAA2     |     9851 |   40.399 |  -73.9811 |                       0
 NOAA2     |     9851 |   40.399 |  -73.9811 |                      41
 NOAA7     |    10432 |  40.6474 |  -73.1669 |                       0
(10 rows)

    ```

* Any query can be dumped to a CSV file using psql with the \copy command:
  ```
  # \copy (select * from metals) to 'metal_dump.csv' using (format csv, header true)
  ```

* Any selection with a spatial component can be dumped to Shapefile format with the pgsql2shp command. For example, this gets the results of a join to give aluminum levels with site codes and locations:
  ```
  $ pgsql2shp -f stations.shp -upostgres environmental_health "select geom, site_code, aluminum from stations join metals using (site_code)" 
  ```

  A table name may be given instead of a full select statement to get all fields from a single table.
