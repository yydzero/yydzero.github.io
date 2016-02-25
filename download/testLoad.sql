\timing

-- create two tables
DROP TABLE IF EXISTS point_table;
DROP TABLE IF EXISTS line_table;
CREATE TEMPORARY TABLE point_table (id serial, num smallint, geom geometry) DISTRIBUTED BY(id);
CREATE TEMPORARY TABLE line_table (id serial, num smallint, geom geometry) DISTRIBUTED BY(id);

INSERT INTO point_table (SELECT i, round(random()*10000),
                            ST_Point(119.0 + r + random()/10, 39.0 + r + random()/10)
                    FROM generate_series(1,10000) as i, random() as r);

INSERT INTO line_table (SELECT i, round(random()*10000),
                        ST_MakeLine(
                            ST_Point(119.0 + r + random()/10, 39.0 + r + random()/10),
                            ST_Point(119.0 + r + random()/10, 39.0 + r + random()/10))
                    FROM generate_series(1,10000) as i, random() as r);

-- show some rows
SELECT id, num, st_astext(geom) FROM point_table ORDER BY id LIMIT 3;
SELECT id, num, st_astext(geom) FROM line_table ORDER BY id LIMIT 3;

-- expert each 10 rows to file
COPY (SELECT id, num, st_astext(geom) FROM point_table ORDER BY id LIMIT 10) 
	TO '/tmp/point.txt'
	WITH HEADER CSV;
COPY (SELECT id, num, st_astext(geom) FROM line_table ORDER BY id LIMIT 10) 
	TO '/tmp/line.txt'
	WITH HEADER CSV;


-- create two similar tables
DROP TABLE IF EXISTS point_table_new;
DROP TABLE IF EXISTS line_table_new;
CREATE TEMPORARY TABLE point_table_new (id serial, num smallint, geom geometry) DISTRIBUTED BY(id);
CREATE TEMPORARY TABLE line_table_new (id serial, num smallint, geom geometry) DISTRIBUTED BY(id);

-- load data from files
-- expert each 10 rows to file
COPY point_table_new FROM '/tmp/point.txt' WITH HEADER CSV;
COPY line_table_new FROM '/tmp/line.txt' WITH HEADER CSV;

-- show some rows
SELECT id, num, st_astext(geom) FROM point_table_new ORDER BY id LIMIT 3;
SELECT id, num, st_astext(geom) FROM line_table_new ORDER BY id LIMIT 3;

-- start gpfdist
\! gpfdist -d /tmp -p 9000 -l /tmp/geom.log &

-- load data using gpfdist
DROP EXTERNAL TABLE IF EXISTS point_table_external_read;
DROP EXTERNAL TABLE IF EXISTS line_table_external_read;
CREATE READABLE EXTERNAL TABLE point_table_external_read(id serial, num smallint, geom geometry)
	LOCATION('gpfdist://localhost:9000/point.txt') FORMAT 'CSV' (HEADER);
CREATE READABLE EXTERNAL TABLE line_table_external_read(id serial, num smallint, geom geometry)
	LOCATION('gpfdist://localhost:9000/line.txt') FORMAT 'CSV' (HEADER);
SELECT id, num, st_astext(geom) FROM point_table_external_read ORDER BY id LIMIT 3;
SELECT id, num, st_astext(geom) FROM line_table_external_read ORDER BY id LIMIT 3;
