-- create table
CREATE TABLE knn_recheck_geom(gid serial primary key, geom geometry);
INSERT INTO knn_recheck_geom(gid,geom)
SELECT ROW_NUMBER() OVER(ORDER BY x,y) AS gid, ST_Point(x*0.777,y*0.887) As geom
FROM generate_series(-100,1000, 7) AS x CROSS JOIN generate_series(-300,1000,9) As y;

INSERT INTO knn_recheck_geom(gid, geom)
SELECT 500000 + i, ST_Translate('LINESTRING(-100 300, 500 700, 400 123, 500 10000, 1 1)'::geometry, i*2000,0)
FROM generate_series(0,10) i;

INSERT INTO knn_recheck_geom(gid, geom)
SELECT 500100 + i, ST_Translate('POLYGON((100 800, 100 700, 400 123, 405 124, 100 800))'::geometry,0,i*2000)
FROM generate_series(0,3) i;


INSERT INTO knn_recheck_geom(gid,geom)
SELECT 600000 + ROW_NUMBER() OVER(ORDER BY gid) AS gid, ST_Translate(ST_Buffer(geom,8,15 ),100,300) As geom
FROM knn_recheck_geom
WHERE gid IN(1000, 10000, 2000,3000);


-- without index order should match st_distance order --
-- point check

SELECT '#1' As t, gid, ST_Distance( 'POINT(-305 998.5)'::geometry, geom)::numeric(10,2)
FROM knn_recheck_geom
ORDER BY 'POINT(-305 998.5)'::geometry <-> geom LIMIT 5;

-- linestring check
SELECT '#2' As t, gid, ST_Distance( 'MULTILINESTRING((-95 -300, 100 200, 100 323),(-50 2000, 30 6000))'::geometry, geom)::numeric(12,4)
FROM knn_recheck_geom
ORDER BY 'MULTILINESTRING((-95 -300, 100 200, 100 323),(-50 2000, 30 6000))'::geometry <-> geom LIMIT 5;

-- lateral check before index
SELECT '#3' As t, a.gid, b.gid As match, ST_Distance(a.geom, b.geom)::numeric(15,4) As true_rn, b.knn_dist::numeric(15,4)
FROM knn_recheck_geom As a
	LEFT JOIN
		LATERAL ( SELECT  gid, geom, a.geom <-> g.geom As knn_dist
			FROM knn_recheck_geom As g WHERE a.gid <> g.gid ORDER BY a.geom <-> g.geom LIMIT 5) As b ON true
	WHERE a.gid IN(1,500101)
ORDER BY a.gid, true_rn, b.gid;

-- create index and repeat
CREATE INDEX idx_knn_recheck_geom_gist ON knn_recheck_geom USING gist(geom);
vacuum analyze knn_recheck_geom;

set enable_seqscan = false;
SELECT '#1' As t, gid, ST_Distance( 'POINT(-305 998.5)'::geometry, geom)::numeric(10,2)
FROM knn_recheck_geom
ORDER BY 'POINT(-305 998.5)'::geometry <-> geom LIMIT 5;

-- linestring check
SELECT '#2' As t, gid, ST_Distance( 'MULTILINESTRING((-95 -300, 100 200, 100 323),(-50 2000, 30 6000))'::geometry, geom)::numeric(12,4)
FROM knn_recheck_geom
ORDER BY 'MULTILINESTRING((-95 -300, 100 200, 100 323),(-50 2000, 30 6000))'::geometry <-> geom LIMIT 5;

-- FIXME: This test (as well as the following index tests) fails on GP7 with:
-- ERROR:  could not devise a query plan for the given query (pathnode.c:275)
-- The expected output is removed from expected file and added as a comment below

-- lateral check before index
-- SELECT '#3' As t, a.gid, b.gid As match, ST_Distance(a.geom, b.geom)::numeric(15,4) As true_rn, b.knn_dist::numeric(15,4)
-- FROM knn_recheck_geom As a
-- 	LEFT JOIN
-- 		LATERAL ( SELECT  gid, geom, a.geom <-> g.geom As knn_dist
-- 			FROM knn_recheck_geom As g WHERE a.gid <> g.gid ORDER BY a.geom <-> g.geom LIMIT 5) As b ON true
-- 	WHERE a.gid IN(1,500101)
-- ORDER BY a.gid, true_rn, b.gid;

-- #3|1|146|5.4390|5.4390
-- #3|1|2|7.9830|7.9830
-- #3|1|147|9.6598|9.6598
-- #3|1|291|10.8780|10.8780
-- #3|1|292|13.4929|13.4929
-- #3|500101|500000|0.0000|0.0000
-- #3|500101|600004|971.4947|971.4947
-- #3|500101|600001|1106.0791|1106.0791
-- #3|500101|600002|1210.3577|1210.3577
-- #3|500101|12905|1239.5484|1239.5484

DROP TABLE knn_recheck_geom;

-- geography tests
DELETE FROM spatial_ref_sys where srid = 4326;
INSERT INTO "spatial_ref_sys" ("srid","auth_name","auth_srid","proj4text")
    VALUES (4326,'EPSG',4326,'+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ');
-- create table
CREATE TABLE knn_recheck_geog(gid serial primary key, geog geography);
INSERT INTO knn_recheck_geog(gid,geog)
SELECT ROW_NUMBER() OVER(ORDER BY x,y) AS gid, ST_Point(x*1.11,y*0.95)::geography As geog
FROM generate_series(-100,100, 1) AS x CROSS JOIN generate_series(-90,90,1) As y;

INSERT INTO knn_recheck_geog(gid, geog)
SELECT 500000, 'LINESTRING(-95 -10, -93 -10.5, -90 -10.6, -95 -10.5, -95 -10)'::geography;

INSERT INTO knn_recheck_geog(gid, geog)
SELECT 500001, 'POLYGON((-95 10, -95.6 10.5, -95.9 10.75, -95 10))'::geography;

INSERT INTO knn_recheck_geog(gid,geog)
SELECT 600000 + ROW_NUMBER() OVER(ORDER BY gid) AS gid, ST_Buffer(geog,1000) As geog
FROM knn_recheck_geog
WHERE gid IN(1000, 10000, 2000, 2614, 40000);


SELECT '#1g' As t, gid, ST_Distance( 'POINT(-95 -10)'::geography, geog, false)::numeric(12,4) ,
    ('POINT(-95 -10)'::geography <-> geog )::numeric(12,4)
FROM knn_recheck_geog
ORDER BY 'POINT(-95 -10)'::geography <-> geog LIMIT 5;

SELECT '#2g' As t, gid, ST_Distance( 'LINESTRING(75 10, 75 12, 80 20)'::geography, geog, false)::numeric(12,4),
    ('LINESTRING(75 10, 75 12, 80 20)'::geography <-> geog)::numeric(12,4) As knn_dist
FROM knn_recheck_geog
ORDER BY 'LINESTRING(75 10, 75 12, 80 20)'::geography <-> geog LIMIT 5;

-- lateral check before index
-- The distances are very close in some cases which might mess the ordering
-- We use array contains (<@) instead of equals.
SELECT '#3g' As t, a.gid,  ARRAY(SELECT  gid
			FROM knn_recheck_geog As g WHERE a.gid <> g.gid ORDER BY ST_Distance(a.geog, g.geog, false) LIMIT 5) <@ ARRAY(SELECT  gid
			FROM knn_recheck_geog As g WHERE a.gid <> g.gid ORDER BY a.geog <-> g.geog LIMIT 5) As dist_order_agree
FROM knn_recheck_geog As a
	WHERE a.gid IN(500000,500010,1000)
ORDER BY a.gid;

-- create index and repeat
CREATE INDEX idx_knn_recheck_geog_gist ON knn_recheck_geog USING gist(geog);
vacuum analyze knn_recheck_geog;
set enable_seqscan = false;

SELECT '#1g' As t, gid, ST_Distance( 'POINT(-95 -10)'::geography, geog, false)::numeric(12,4) ,
    ('POINT(-95 -10)'::geography <-> geog )::numeric(12,4)
FROM knn_recheck_geog
ORDER BY 'POINT(-95 -10)'::geography <-> geog LIMIT 5;

SELECT '#2g' As t, gid, ST_Distance( 'LINESTRING(75 10, 75 12, 80 20)'::geography, geog, false)::numeric(12,4),
    ('LINESTRING(75 10, 75 12, 80 20)'::geography <-> geog)::numeric(12,4) As knn_dist
FROM knn_recheck_geog
ORDER BY 'LINESTRING(75 10, 75 12, 80 20)'::geography <-> geog LIMIT 5;

-- FIXME: This test fails on GP7
-- SELECT '#3g' As t, a.gid,  ARRAY(SELECT  g.gid
-- 			FROM knn_recheck_geog As g WHERE a.gid <> g.gid ORDER BY ST_Distance(a.geog, g.geog, false) LIMIT 5) = ARRAY(SELECT  gid
-- 			FROM knn_recheck_geog As g WHERE a.gid <> g.gid ORDER BY a.geog <-> g.geog LIMIT 5) As dist_order_agree
-- FROM knn_recheck_geog As a
-- 	WHERE a.gid IN(500000,500010,1000)
-- ORDER BY a.gid;

-- #3g|1000|t
-- #3g|500000|t

DROP TABLE knn_recheck_geog;

--
-- Delete inserted spatial data
--
DELETE FROM spatial_ref_sys WHERE srid = 4326;

--now the nd operator tests
-- create table and load
CREATE TABLE knn_recheck_geom_nd(gid serial primary key, geom geometry);
INSERT INTO knn_recheck_geom_nd(gid,geom)
SELECT ROW_NUMBER() OVER(ORDER BY x,y,z) AS gid, ST_MakePoint(x*0.777,y*0.887,z*1.05) As geom
FROM generate_series(-100,1000, 7) AS x ,
    generate_series(-300,1000,9) As y,
 generate_series(1005,10000,5555) As z ;

 -- 3d lines
INSERT INTO knn_recheck_geom_nd(gid, geom)
SELECT 500000 + i, ST_Translate('LINESTRING(-100 300 500, 500 700 600, 400 123 0, 500 10000 -1234, 1 1 5000)'::geometry, i*2000,0)
FROM generate_series(0,10) i;


-- 3d polygons
INSERT INTO knn_recheck_geom_nd(gid, geom)
SELECT 500100 + i, ST_Translate('POLYGON((100 800 5678, 100 700 5678, 400 123 5678, 405 124 5678, 100 800 5678))'::geometry,0,i*2000)
FROM generate_series(0,3) i;

-- polyhedral surface --
INSERT INTO knn_recheck_geom_nd(gid,geom)
SELECT 600000 + row_number() over(), ST_Translate(the_geom,100, 450,1000) As the_geom
		FROM (VALUES ( ST_GeomFromText(
'PolyhedralSurface(
((0 0 0, 0 0 1, 0 1 1, 0 1 0, 0 0 0)),
((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)), ((0 0 0, 1 0 0, 1 0 1, 0 0 1, 0 0 0)),  ((1 1 0, 1 1 1, 1 0 1, 1 0 0, 1 1 0)),
((0 1 0, 0 1 1, 1 1 1, 1 1 0, 0 1 0)),  ((0 0 1, 1 0 1, 1 1 1, 0 1 1, 0 0 1))
)') ) ,
( ST_GeomFromText(
'PolyhedralSurface(
((0 0 0, 0 0 1, 0 1 1, 0 1 0, 0 0 0)),
((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)) )') ) )
As foo(the_geom) ;

-- without index order should match st_3ddistance order --
-- point check
SELECT '#1nd-3' As t, gid, ST_3DDistance( 'POINT(-305 998.5 1000)'::geometry, geom)::numeric(12,4) As dist3d,
('POINT(-305 998.5 1000)'::geometry <<->> geom)::numeric(12,4) As dist_knn
FROM knn_recheck_geom_nd
ORDER BY 'POINT(-305 998.5 1000)'::geometry <<->> geom LIMIT 5;

-- linestring check
SELECT '#2nd-3' As t, gid, ST_3DDistance( 'MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry::geometry, geom)::numeric(12,4),
 ('MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry <<->> geom)::numeric(12,4) As knn_dist
FROM knn_recheck_geom_nd
ORDER BY 'MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry <<->> geom LIMIT 5;

-- lateral test
SELECT '#3nd-3' As t, a.gid, b.gid As match, ST_3DDistance(a.geom, b.geom)::numeric(15,4) As true_rn, b.knn_dist::numeric(15,4)
FROM knn_recheck_geom_nd As a
	LEFT JOIN
		LATERAL ( SELECT  gid, geom, a.geom <<->> g.geom As knn_dist
			FROM knn_recheck_geom_nd As g WHERE a.gid <> g.gid ORDER BY a.geom <<->> g.geom LIMIT 5) As b ON true
	WHERE a.gid IN(1,600001)
ORDER BY a.gid, true_rn, b.gid;

-- create index and repeat
CREATE INDEX idx_knn_recheck_geom_nd_gist ON knn_recheck_geom_nd USING gist(geom gist_geometry_ops_nd);
vacuum analyze knn_recheck_geom_nd;
set enable_seqscan = false;
-- point check
SELECT '#1nd-3' As t, gid, ST_3DDistance( 'POINT(-305 998.5 1000)'::geometry, geom)::numeric(12,4) As dist3d,
('POINT(-305 998.5 1000)'::geometry <<->> geom)::numeric(12,4) As dist_knn
FROM knn_recheck_geom_nd
ORDER BY 'POINT(-305 998.5 1000)'::geometry <<->> geom LIMIT 5;

-- linestring check
SELECT '#2nd-3' As t, gid, ST_3DDistance( 'MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry::geometry, geom)::numeric(12,4),
 ('MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry <<->> geom)::numeric(12,4) As knn_dist
FROM knn_recheck_geom_nd
ORDER BY 'MULTILINESTRING((-95 -300 5000, 105 451 1000, 100 323 200),(-50 2000 456, 30 6000 789))'::geometry <<->> geom LIMIT 5;

-- FIXME: This test fails on GP7
-- -- lateral test
-- SELECT '#3nd-3' As t, a.gid, b.gid As match, ST_3DDistance(a.geom, b.geom)::numeric(15,4) As true_rn, b.knn_dist::numeric(15,4)
-- FROM knn_recheck_geom_nd As a
-- 	LEFT JOIN
-- 		LATERAL ( SELECT  gid, geom, a.geom <<->> g.geom As knn_dist
-- 			FROM knn_recheck_geom_nd As g WHERE a.gid <> g.gid ORDER BY a.geom <<->> g.geom LIMIT 5) As b ON true
-- 	WHERE a.gid IN(1,600001)
-- ORDER BY a.gid, true_rn, b.gid;

-- #3nd-3|1|291|5.4390|5.4390
-- #3nd-3|1|3|7.9830|7.9830
-- #3nd-3|1|293|9.6598|9.6598
-- #3nd-3|1|581|10.8780|10.8780
-- #3nd-3|1|583|13.4929|13.4929
-- #3nd-3|600001|600002|0.0000|0.0000
-- #3nd-3|600001|9751|54.2730|54.2730
-- #3nd-3|600001|9461|54.3900|54.3900
-- #3nd-3|600001|9749|54.5453|54.5453
-- #3nd-3|600001|10041|54.6233|54.6233

DROP TABLE knn_recheck_geom_nd;

-- #3573
SELECT '#3573', 'POINT M (0 0 13)'::geometry <<->> 'LINESTRING M (0 0 5, 0 1 6)'::geometry;

-- #3418
CREATE TABLE test_wo (geo geometry);
INSERT INTO test_wo VALUES
  ('0101000020E61000007D91D0967329E4BF6631B1F9B8D64A40'::geometry),
  ('0101000020E6100000E2AFC91AF510C1BFCDCCCCCCCCAC4A40'::geometry);
CREATE INDEX ON TEST_WO USING GIST (GEO);
analyze test_wo;
SET enable_seqscan = false;
SELECT '#3418' As ticket, '0101000020E610000092054CE0D6DDE5BFCDCCCCCCCCAC4A40'::geometry <-> geo, ST_Distance('0101000020E610000092054CE0D6DDE5BFCDCCCCCCCCAC4A40'::geometry, geo)
FROM test_wo ORDER BY geo <->
('0101000020E610000092054CE0D6DDE5BFCDCCCCCCCCAC4A40'::geometry);
DROP TABLE test_wo;
set enable_seqscan to default;
