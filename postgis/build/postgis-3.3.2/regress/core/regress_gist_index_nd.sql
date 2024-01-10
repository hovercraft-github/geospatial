set client_min_messages = warning;

-- ORCA does not support index scans
set optimizer = off;

CREATE OR REPLACE FUNCTION qnodes(q text) RETURNS text
LANGUAGE 'plpgsql' AS
$$
DECLARE
  exp TEXT;
  mat TEXT[];
  ret TEXT;
BEGIN
  FOR exp IN EXECUTE 'EXPLAIN ' || q
  LOOP
    --RAISE NOTICE 'EXP: %', exp;
    mat := regexp_matches(exp, ' *(?:-> *)?(.*Scan)');
    --RAISE NOTICE 'MAT: %', mat;
    IF mat IS NOT NULL THEN
      ret := mat[1];
    END IF;
    --RAISE NOTICE 'RET: %', ret;
  END LOOP;
  RETURN ret;
END;
$$;

-------------------------------------------------------------------------------

create table tbl_geomcollection_nd (
	k serial,
	g geometry
) DISTRIBUTED REPLICATED;

\copy tbl_geomcollection_nd from 'regress_gist_index_nd.data';
-------------------------------------------------------------------------------

set enable_indexscan = off;
set enable_bitmapscan = off;
set enable_seqscan = on;

select '&&&', count(*), qnodes('select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g &&& t2.g') from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g &&& t2.g;
select '~~', count(*), qnodes('select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~ t2.g') from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~ t2.g;
select '@@', count(*), qnodes('select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g @@ t2.g') from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g @@ t2.g;
select '~~=', count(*), qnodes('select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~= t2.g') from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~= t2.g;

------------------------------------------------------------------------------

create index tbl_geomcollection_nd_gist_nd_idx on tbl_geomcollection_nd using gist(g gist_geometry_ops_nd);

set enable_indexscan = on;
set enable_bitmapscan = off;
set enable_seqscan = off;

select (select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g &&& t2.g ) gistidx,
qnodes(' select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g &&& t2.g ') gidxscan;

select (select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~  t2.g ) gistidx,
qnodes(' select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~  t2.g ') gidxscan;

select (select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g @@ t2.g ) gistidx,
qnodes(' select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g @@ t2.g ') gidxscan;

select (select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~= t2.g ) gistidx,
qnodes(' select count(*) from tbl_geomcollection_nd t1, tbl_geomcollection_nd t2 where t1.g ~~= t2.g ') gidxscan;

-------------------------------------------------------------------------------

-- Test if gist indices are employed for spatial index aware functions.
-- st_contains, st_dwithin, st_intersects, st_overlaps
set enable_indexscan = off;
set enable_bitmapscan = on;
set enable_seqscan = on;

create table test_spatial_index_funcs(id integer, g geometry);
create index gist_idx on test_spatial_index_funcs using gist(g);
insert into test_spatial_index_funcs (select id, ST_SetSRID(ST_MakePoint(50-random()*100, 50-random()*100), 4326) from generate_series(1,1000) t(id));

select 'st_contains', qnodes('select * from test_spatial_index_funcs where ST_Contains(ST_SetSRID(ST_MakePolygon(ST_GeomFromText(''LINESTRING(0 0,1 0,1 2.5,6 2.5,6 4,7 4,7 5,5 5,5 3,0 3,0 0)'')), 4326), g)');
select 'st_dwithin', qnodes('select * from test_spatial_index_funcs where ST_DWithin(ST_SetSRID(ST_MakePolygon(ST_GeomFromText(''LINESTRING(0 3, 3 5, 5 2, 0 3)'')), 4326), g, 2);');
set enable_indexscan = on;
set enable_bitmapscan = off;
select 'st_intersects', qnodes('select * from test_spatial_index_funcs where ST_Intersects(ST_SetSRID(ST_MakePolygon(ST_GeomFromText(''LINESTRING(0 3, 3 5, 5 2, 0 3)'')), 4326), g);');
select 'st_overlaps', qnodes('select * from test_spatial_index_funcs where ST_Overlaps(ST_SetSRID(ST_MakePolygon(ST_GeomFromText(''LINESTRING(0 0,1 0,1 2.5,6 2.5,6 4,7 4,7 5,5 5,5 3,0 3,0 0)'')), 4326), g)');


DROP TABLE tbl_geomcollection_nd CASCADE;
set client_min_messages = notice;
DROP FUNCTION qnodes (text);

reset optimizer;
