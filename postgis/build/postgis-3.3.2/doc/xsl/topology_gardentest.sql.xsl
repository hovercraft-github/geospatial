<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:pgis="http://www.postgis.org/pgis">
<!-- ********************************************************************
 ********************************************************************
	 Copyright 2008-2010, Regina Obe
	 Modifications Copyright (c) 2017 - Present Pivotal Software, Inc. All Rights Reserved.
	 License: BSD
	 Purpose: This is an xsl transform that generates an sql test script from xml docs to test all the functions we have documented
			using a garden variety of geometries.  Its intent is to flag major crashes.
	 ******************************************************************** -->
	<xsl:output method="text" />
	<xsl:variable name='testversion'>3.3.0</xsl:variable>
	<xsl:variable name='fnexclude'>AddTopoGeometryColumn DropTopoGeometryColumn CreateTopology</xsl:variable>
	<!--This is just a place holder to state functions not supported in 1.3 or tested separately -->

	<xsl:variable name='var_srid'>3395</xsl:variable>
	<xsl:variable name='var_position'>1</xsl:variable>
	<xsl:variable name='var_integer1'>3</xsl:variable>
	<xsl:variable name='var_integer2'>5</xsl:variable>
	<xsl:variable name='var_float1'>0.5</xsl:variable>
	<xsl:variable name='var_float2'>0.75</xsl:variable>
	<xsl:variable name='var_distance'>100</xsl:variable>
	<xsl:variable name='var_version1'>1</xsl:variable>
	<xsl:variable name='var_version2'>2</xsl:variable>
	<xsl:variable name='var_NDRXDR'>XDR</xsl:variable>
	<xsl:variable name='var_text'>'monkey'</xsl:variable>
	<xsl:variable name='var_varchar'>'test'</xsl:variable>
	<xsl:variable name='var_spheroid'>'SPHEROID["GRS_1980",6378137,298.257222101]'</xsl:variable>
	<xsl:variable name='var_matrix'>'FF1FF0102'</xsl:variable>
	<xsl:variable name='var_boolean'>false</xsl:variable>
	<xsl:variable name='var_logtable'>postgis_topology_garden_log33</xsl:variable>
	<xsl:variable name='var_logupdatesql'>UPDATE <xsl:value-of select="$var_logtable" /> SET log_end = clock_timestamp()
		FROM (SELECT logid FROM <xsl:value-of select="$var_logtable" /> ORDER BY logid DESC limit 1) As foo
		WHERE <xsl:value-of select="$var_logtable" />.logid = foo.logid  AND <xsl:value-of select="$var_logtable" />.log_end IS NULL;</xsl:variable>

	<!-- for queries that result data, we first log the sql in our log table and then use query_to_xml to output it as xml for easy storage
	    with this approach our run statement is always exactly the same -->
	<xsl:variable name='var_logresultsasxml'>INSERT INTO <xsl:value-of select="$var_logtable" />_output(logid, log_output)
				SELECT logid, query_to_xml(log_sql, false,false,'') As log_output
				    FROM <xsl:value-of select="$var_logtable" /> ORDER BY logid DESC LIMIT 1;</xsl:variable>
	<pgis:gardens>
		<pgis:gset ID='POINT' GeometryType='POINT'>(SELECT ST_SetSRID(ST_Point(i,j),4326) As the_geom
		FROM (SELECT a*1.11111111 FROM generate_series(-10,50,10) As a) As i(i)
			CROSS JOIN generate_series(40,70, 15) j
			ORDER BY i,j
			)</pgis:gset>
		<pgis:gset ID='LINESTRING' GeometryType='LINESTRING'>(SELECT ST_MakeLine(ST_SetSRID(ST_Point(i,j),4326),ST_SetSRID(ST_Point(j,i),4326))  As the_geom
		FROM (SELECT a*1.11111111 FROM generate_series(-10,50,10) As a) As i(i)
			CROSS JOIN generate_series(40,70, 15) As j
			WHERE NOT(i = j)
			ORDER BY i, i*j)</pgis:gset>
		<pgis:gset ID='POLYGON' GeometryType='POLYGON'>(SELECT ST_Buffer(ST_SetSRID(ST_Point(i,j),4326), j*0.05)  As the_geom
		FROM (SELECT a*1.11111111 FROM generate_series(-10,50,10) As a) As i(i)
			CROSS JOIN generate_series(40,70, 20) As j
			ORDER BY i, i*j, j)</pgis:gset>
		<pgis:gset ID='POINTM' GeometryType='POINTM'>(SELECT ST_SetSRID(ST_MakePointM(i,j,m),4326) As the_geom
		FROM generate_series(-10,50,10) As i
			CROSS JOIN generate_series(50,70, 20) AS j
			CROSS JOIN generate_series(1,2) As m
			ORDER BY i, j, i*j*m)</pgis:gset>
		<pgis:gset ID='LINESTRINGM' GeometryType='LINESTRINGM'>(SELECT ST_MakeLine(ST_SetSRID(ST_MakePointM(i,j,m),4326),ST_SetSRID(ST_MakePointM(j,i,m),4326))  As the_geom
		FROM generate_series(-10,50,10) As i
			CROSS JOIN generate_series(50,70, 20) As j
			CROSS JOIN generate_series(1,2) As m
			WHERE NOT(i = j)
			ORDER BY i, j, m, i*j*m)</pgis:gset>
<!--		<pgis:gset ID='PolygonMSet' GeometryType='POLYGONM'>(SELECT ST_MakePolygon(ST_AddPoint(ST_AddPoint(ST_MakeLine(ST_SetSRID(ST_MakePointM(i+m,j,m),4326),ST_SetSRID(ST_MakePointM(j+m,i-m,m),4326)),ST_SetSRID(ST_MakePointM(i,j,m),4326)),ST_SetSRID(ST_MakePointM(i+m,j,m),4326)))  As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(50,70, 20) As j
			CROSS JOIN generate_series(1,2) As m
			ORDER BY i, j, m, i*j*m
			)</pgis:gset>-->
		<pgis:gset ID='POLYGONM' GeometryType='POLYGONM'>(SELECT geom  As the_geom
FROM (VALUES ( ST_GeomFromEWKT('SRID=4326;POLYGONM((-71.1319 42.2503 1,-71.132 42.2502 3,-71.1323 42.2504 -2,-71.1322 42.2505 1,-71.1319 42.2503 0))') ),
	( ST_GeomFromEWKT('SRID=4326;POLYGONM((-71.1319 42.2512 0,-71.1318 42.2511 20,-71.1317 42.2511 -20,-71.1317 42.251 5,-71.1317 42.2509 4,-71.132 42.2511 6,-71.1319 42.2512 30))') )
		)	As g(geom))</pgis:gset>

		<pgis:gset ID='POINTZ' GeometryType='POINTZ'>(SELECT ST_SetSRID(ST_MakePoint(i,j,k),4326) As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(40,70, 20) j
			CROSS JOIN generate_series(1,2) k
			ORDER BY i,i*j, j*k, i + j + k)</pgis:gset>
		<pgis:gset ID='LINESTRINGZ' GeometryType='LINESTRINGZ'>(SELECT ST_SetSRID(ST_MakeLine(ST_MakePoint(i,j,k), ST_MakePoint(i+k,j+k,k)),4326) As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(40,70, 20) j
			CROSS JOIN generate_series(1,2) k
			ORDER BY i, j, i+j+k, k, i*j*k)</pgis:gset>
<!--		<pgis:gset ID='PolygonSet3D' GeometryType='POLYGONZ'>(SELECT ST_SetSRID(ST_MakePolygon(ST_AddPoint(ST_AddPoint(ST_MakeLine(ST_MakePoint(i+m,j,m),ST_MakePoint(j+m,i-m,m)),ST_MakePoint(i,j,m)),ST_MakePointM(i+m,j,m))),4326)  As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(50,70, 20) As j
			CROSS JOIN generate_series(1,2) As m
			ORDER BY i, j, i+j+m, m, i*j*m)</pgis:gset>-->
		<pgis:gset ID='POLYGONZ' GeometryType='POLYGONZ'>(SELECT geom  As the_geom
FROM (VALUES ( ST_GeomFromEWKT('SRID=4326;POLYGON((-71.0771 42.3866 1,-71.0767 42.3872 1,-71.0767 42.3863 1,-71.0771 42.3866 1))') ),
	( ST_GeomFromEWKT('SRID=4326;POLYGON((-71.0775 42.386 2,-71.0773 42.3863 1.75,-71.0773 42.3859 1.75,-71.0775 42.386 2))') )
		)	As g(geom))</pgis:gset>

		<pgis:gset ID='POLYGONZM' GeometryType='POLYGONZM'>(SELECT geom  As the_geom
FROM (VALUES ( ST_GeomFromEWKT('SRID=4326;POLYGON((-71.0771 42.3866 1 2,-71.0767 42.3872 1 2.3,-71.0767 42.3863 1 2.3,-71.0771 42.3866 1 2))') ),
	( ST_GeomFromEWKT('SRID=4326;POLYGON((-71.0775 42.386 2 1.5,-71.0773 42.3863 1.75 1.5,-71.0773 42.3859 1.75 1.5,-71.0775 42.386 2 1.5))') )
		)	As g(geom))</pgis:gset>


<!-- MULTIs start here -->
		<pgis:gset ID='MULTIPOINT' GeometryType='MULTIPOINT'>(SELECT ST_Collect(s.the_geom) As the_geom
		FROM (SELECT ST_SetSRID(ST_Point(i,j),4326) As the_geom
		FROM generate_series(-10,50,15) As i
			CROSS JOIN generate_series(40,70, 15) j
			) As s)</pgis:gset>

		<pgis:gset ID='MULTILINESTRING' GeometryType='MULTILINESTRING'>(SELECT ST_Collect(s.the_geom) As the_geom
		FROM (SELECT ST_MakeLine(ST_SetSRID(ST_Point(i,j),4326),ST_SetSRID(ST_Point(j,i),4326))  As the_geom
		FROM generate_series(-10,50,10) As i
			CROSS JOIN generate_series(40,70, 15) As j
			WHERE NOT(i = j)) As s)</pgis:gset>

		<pgis:gset ID='MULTIPOLYGON' GeometryType='MULTIPOLYGON'>(SELECT ST_Multi(ST_Union(ST_Buffer(ST_SetSRID(ST_Point(i,j),4326), j*0.05)))  As the_geom
		FROM generate_series(-10,50,10) As i
			CROSS JOIN generate_series(40,70, 25) As j)</pgis:gset>

		<pgis:gset ID='MULTIPOINTZ' GeometryType='MULTIPOINTZ'>(SELECT ST_Collect(ST_SetSRID(ST_MakePoint(i,j,k),4326)) As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(40,70, 25) j
			CROSS JOIN generate_series(1,3) k
			)</pgis:gset>

		<pgis:gset ID='MULTILINESTRINGZ' GeometryType='MULTILINESTRINGZ'>(SELECT ST_Multi(ST_Union(ST_SetSRID(ST_MakeLine(ST_MakePoint(i,j,k), ST_MakePoint(i+k,j+k,k)),4326))) As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(40,70, 25) j
			CROSS JOIN generate_series(1,2) k
			)</pgis:gset>

<!--		<pgis:gset ID='MultiPolySet3D' GeometryType='MULTIPOLYGONZ'>(SELECT ST_Multi(ST_Union(s.the_geom)) As the_geom
		FROM (SELECT ST_MakePolygon(ST_AddPoint(ST_AddPoint(ST_MakeLine(ST_SetSRID(ST_MakePoint(i+m,j,m),4326),ST_SetSRID(ST_MakePoint(j+m,i-m,m),4326)),ST_SetSRID(ST_MakePoint(i,j,m),4326)),ST_SetSRID(ST_MakePoint(i+m,j,m),4326)))  As the_geom
		FROM generate_series(-10,50,20) As i
			CROSS JOIN generate_series(50,70, 25) As j
			CROSS JOIN generate_series(1,2) As m
			) As s)</pgis:gset>-->
		<pgis:gset ID='MULTIPOLYGONZ' GeometryType='MULTIPOLYGONZ'>(SELECT geom  As the_geom
FROM (VALUES ( ST_GeomFromEWKT('SRID=4326;MULTIPOLYGON(((-71.0821 42.3036 2,-71.0822 42.3036 2,-71.082 42.3038 2,-71.0819 42.3037 2,-71.0821 42.3036 2)))') ),
	( ST_GeomFromEWKT('SRID=4326;MULTIPOLYGON(((-71.1261 42.2703 1,-71.1257 42.2703 1,-71.1257 42.2701 1,-71.126 42.2701 1,-71.1261 42.2702 1,-71.1261 42.2703 1)))') )
		)	As g(geom))</pgis:gset>


		<pgis:gset ID='MULTIPOINTM' GeometryType='MULTIPOINTM'>(SELECT ST_Collect(s.the_geom) As the_geom
		FROM (SELECT ST_SetSRID(ST_MakePointM(i - 0.0821,j + 0.3036,m),4326) As the_geom
		FROM generate_series(-71,50,15) As i
			CROSS JOIN generate_series(42,70, 25) AS j
			CROSS JOIN generate_series(1,2) As m
			) As s)</pgis:gset>

		<pgis:gset ID='MULTILINESTRINGM' GeometryType='MULTILINESTRINGM'>(SELECT ST_Collect(s.the_geom) As the_geom
		FROM (SELECT ST_MakeLine(ST_SetSRID(ST_MakePointM(i - 0.0821,j + 0.3036,m),4326),ST_SetSRID(ST_MakePointM(j,i,m),4326))  As the_geom
		FROM generate_series(-71,50,15) As i
			CROSS JOIN generate_series(50,70, 25) As j
			CROSS JOIN generate_series(1,2) As m
			WHERE NOT(i = j)) As s)</pgis:gset>

		<pgis:gset ID='MULTIPOLYGONM' GeometryType='MULTIPOLYGONM'>(
			SELECT ST_GeomFromEWKT('SRID=4326;MULTIPOLYGONM(((0 0 2,10 0 1,10 10 -2,0 10 -5,0 0 -5),(5 5 6,7 5 6,7 7 6,5 7 10,5 5 -2)))')  As the_geom
			)</pgis:gset>



	<!-- TODO: Finish off MULTI list -->
	</pgis:gardens>


        <!-- We deal only with the reference chapter -->
        <xsl:template match="/">
<!-- Create logging tables -->
DROP TABLE IF EXISTS <xsl:value-of select="$var_logtable" />;
CREATE TABLE <xsl:value-of select="$var_logtable" />(logid serial PRIMARY KEY, log_label text, spatial_class text, func text, g1 text, g2 text, log_start timestamp, log_end timestamp, log_sql text);
DROP TABLE IF EXISTS <xsl:value-of select="$var_logtable" />_output;
CREATE TABLE <xsl:value-of select="$var_logtable" />_output(logid integer PRIMARY KEY, log_output xml);

                <xsl:apply-templates select="/book/chapter[@id='Topology']" />
        </xsl:template>

	<xsl:template match='chapter'>
<!--Start Test table creation, insert, analyze crash test, drop -->
		<xsl:for-each select="document('')//pgis:gardens/pgis:gset[not(contains(@createtable,'false'))]">
			<xsl:variable name='log_label'>table Test <xsl:value-of select="@GeometryType" /></xsl:variable>
SELECT '<xsl:value-of select="$log_label" />: Start Testing';
<xsl:variable name='var_sql'>CREATE TABLE pgis_garden (gid serial);
	SELECT AddGeometryColumn('pgis_garden','the_geom',ST_SRID(the_geom),GeometryType(the_geom),ST_CoordDim(the_geom))
			FROM (<xsl:value-of select="." />) As foo limit 1;
	SELECT AddGeometryColumn('pgis_garden','the_geom_multi',ST_SRID(the_geom),GeometryType(ST_Multi(the_geom)),ST_CoordDim(the_geom))
			FROM (<xsl:value-of select="." />) As foo limit 1;</xsl:variable>
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start, log_sql)
VALUES('<xsl:value-of select="$log_label" /> AddGeometryColumn','AddGeometryColumn', '<xsl:value-of select="@GeometryType" />', clock_timestamp(),
    '<xsl:call-template name="escapesinglequotes"><xsl:with-param name="arg1"><xsl:value-of select="$var_sql" /></xsl:with-param></xsl:call-template>');
BEGIN;
	<xsl:value-of select="$var_sql" />
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;

SELECT '<xsl:value-of select="$log_label" /> Geometry index: Start Testing <xsl:value-of select="@ID" />';
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start) VALUES('<xsl:value-of select="$log_label" /> gist index Geometry','CREATE gist index geometry', '<xsl:value-of select="@ID" />', clock_timestamp());
BEGIN;
	CREATE INDEX idx_pgis_geom_gist ON pgis_garden USING gist(the_geom);
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT '<xsl:value-of select="$log_label" /> geometry index: End Testing <xsl:value-of select="@ID" />';

INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start)
VALUES('<xsl:value-of select="$log_label" /> insert data Geometry','insert data', '<xsl:value-of select="@ID" />', clock_timestamp());

BEGIN;
	INSERT INTO pgis_garden(the_geom, the_geom_multi)
	SELECT the_geom, ST_Multi(the_geom)
	FROM (<xsl:value-of select="." />) As foo;
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;

INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start)
VALUES('<xsl:value-of select="$log_label" /> UpdateGeometrySRID','UpdateGeometrySRID', '<xsl:value-of select="@GeometryType" />', clock_timestamp());
BEGIN;
	SELECT UpdateGeometrySRID('pgis_garden', 'the_geom', 4269);
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;

INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start)
VALUES('<xsl:value-of select="$log_label" /> vacuum analyze Geometry','vacuum analyze Geometry', '<xsl:value-of select="@ID" />', clock_timestamp());
VACUUM ANALYZE pgis_garden;
<xsl:value-of select="$var_logupdatesql" />

INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start)
VALUES('<xsl:value-of select="$log_label" /> DropGeometryColumn','DropGeometryColumn', '<xsl:value-of select="@GeometryType" />', clock_timestamp());

BEGIN;
	SELECT DropGeometryColumn ('pgis_garden','the_geom');
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start)
VALUES('<xsl:value-of select="$log_label" /> DropGeometryTable','DropGeometryTable', '<xsl:value-of select="@ID" />', clock_timestamp());

BEGIN;
	SELECT DropGeometryTable ('pgis_garden');
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT '<xsl:value-of select="$log_label" />: End Testing  <xsl:value-of select="@ID" />';
	<xsl:text>

	</xsl:text>
SELECT '<xsl:value-of select="$log_label" /> Geography: Start Testing <xsl:value-of select="@ID" />';
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start) VALUES('<xsl:value-of select="$log_label" /> Create Table / Add data - Geography','CREATE TABLE geography', '<xsl:value-of select="@ID" />', clock_timestamp());
BEGIN;
	CREATE TABLE pgis_geoggarden (gid serial PRIMARY KEY, the_geog geography(<xsl:value-of select="@GeometryType" />, 4326));
	INSERT INTO pgis_geoggarden(the_geog)
	SELECT the_geom
	FROM (<xsl:value-of select="." />) As foo;
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT '<xsl:value-of select="$log_label" /> Geography: End Testing <xsl:value-of select="@ID" />';

SELECT '<xsl:value-of select="$log_label" /> Geography index: Start Testing <xsl:value-of select="@ID" />';
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start) VALUES('<xsl:value-of select="$log_label" /> gist index Geography','CREATE gist index geography', '<xsl:value-of select="@ID" />', clock_timestamp());
BEGIN;
	CREATE INDEX idx_pgis_geoggarden_geog_gist ON pgis_geoggarden USING gist(the_geog);
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT '<xsl:value-of select="$log_label" /> Geography index: End Testing <xsl:value-of select="@ID" />';


<!-- vacuum analyze can't be put in a commit so we can't completely tell if it completes if it doesn't crash -->
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start, log_sql) VALUES('<xsl:value-of select="$log_label" /> vacuum analyze Geography','analyze geography table', '<xsl:value-of select="@ID" />', clock_timestamp(),
    'VACUUM ANALYZE pgis_geoggarden;');
VACUUM ANALYZE pgis_geoggarden;
	<xsl:value-of select="$var_logupdatesql" />

INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start) VALUES('<xsl:value-of select="$log_label" /> drop Geography table','drop geography table', '<xsl:value-of select="@ID" />', clock_timestamp());
BEGIN;
    SELECT 'BEFORE DROP' As look_at, * FROM geography_columns;
	DROP TABLE pgis_geoggarden;
	SELECT 'AFTER DROP' As look_at, * FROM geography_columns;
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT '<xsl:value-of select="$log_label" /> Geography: End Testing';
	<xsl:text>

	</xsl:text>
		</xsl:for-each>
<!--End Test table creation, insert, drop  -->

<!--Start test on operators  -->
	<xsl:for-each select="sect1[contains(@id,'Operator') and not(contains($fnexclude,funcdef/function))]/refentry">
		<xsl:sort select="@id"/>
		<xsl:for-each select="refsynopsisdiv/funcsynopsis/funcprototype">
			<xsl:variable name='fnname'><xsl:value-of select="funcdef/function"/></xsl:variable>
			<xsl:variable name='fndef'><xsl:value-of select="." /></xsl:variable>
			<xsl:for-each select="document('')//pgis:gardens/pgis:gset">
			<!--Store first garden sql geometry from -->
					<xsl:variable name="from1"><xsl:value-of select="." /></xsl:variable>
					<xsl:variable name='geom1type'><xsl:value-of select="@GeometryType"/></xsl:variable>
					<xsl:variable name='geom1id'><xsl:value-of select="@ID"/></xsl:variable>
					<xsl:variable name='log_label'><xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="$geom1id" /> against other types</xsl:variable>
		SELECT '<xsl:value-of select="$log_label" />: Start Testing ';
		<xsl:for-each select="document('')//pgis:gardens/pgis:gset">
		<xsl:choose>
			  <xsl:when test="contains($fndef, 'geography')">
			  INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, g2, log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> Geography <xsl:value-of select="$geom1id" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />','<xsl:value-of select="$fnname" />', '<xsl:value-of select="$geom1id" />','<xsl:value-of select="@ID" />', clock_timestamp(),
			  	'<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT ST_AsEWKT(foo1.the_geom) as ewktgeog1, ST_AsEWKT(foo2.the_geom) as ewktgeog2, geography(foo1.the_geom) <xsl:value-of select="$fnname" /> geography(foo2.the_geom) As geog1_op_geog2
					FROM (<xsl:value-of select="$from1" />) As foo1 CROSS JOIN (<xsl:value-of select="." />) As foo2
					WHERE (geography(foo1.the_geom) <xsl:value-of select="$fnname" /> geography(foo2.the_geom)) = true OR
						(geography(foo1.the_geom) <xsl:value-of select="$fnname" /> geography(foo2.the_geom)) = false;</xsl:with-param>
</xsl:call-template>');

			SELECT 'Geography <xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />: Start Testing <xsl:value-of select="$geom1id" />, <xsl:value-of select="@ID" />';
			BEGIN;
			    <xsl:value-of select="$var_logresultsasxml" />
				<xsl:value-of select="$var_logupdatesql" />
			COMMIT;
			</xsl:when>
			<xsl:otherwise>
			SELECT 'Geometry <xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />: Start Testing <xsl:value-of select="$geom1id" />, <xsl:value-of select="@ID" />';
			 INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, g2, log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> Geometry <xsl:value-of select="$geom1id" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />','<xsl:value-of select="$fnname" />', '<xsl:value-of select="$geom1id" />','<xsl:value-of select="@ID" />', clock_timestamp(),
			  	'<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT ST_AsEWKT(foo1.the_geom) as ewktgeom1, ST_AsEWKT(foo2.the_geom) as ewktgeom2, foo1.the_geom <xsl:value-of select="$fnname" /> foo2.the_geom As geom1_op_geom2
						FROM (<xsl:value-of select="$from1" />) As foo1 CROSS JOIN (<xsl:value-of select="." />) As foo2
						WHERE (foo1.the_geom <xsl:value-of select="$fnname" /> foo2.the_geom) = true OR
						(foo1.the_geom <xsl:value-of select="$fnname" /> foo2.the_geom) = false;</xsl:with-param></xsl:call-template>');

			BEGIN;
				<xsl:value-of select="$var_logresultsasxml" />
				<xsl:value-of select="$var_logupdatesql" />
			COMMIT;
			</xsl:otherwise>
		</xsl:choose>
					</xsl:for-each>
		SELECT '<xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />: End Testing <xsl:value-of select="@GeometryType" /> against other types';
				</xsl:for-each>
			</xsl:for-each>
	</xsl:for-each>
<!--End test on operators -->
<!-- Start regular function checks excluding operators -->
		<xsl:for-each select="sect1[not(contains(@id,'Operator'))]/refentry">
		<xsl:sort select="@id"/>

			<xsl:for-each select="refsynopsisdiv/funcsynopsis/funcprototype">
<!--Create dummy parameters to be used later -->
				<xsl:variable name='fnfakeparams'><xsl:call-template name="replaceparams"><xsl:with-param name="func" select="." /></xsl:call-template></xsl:variable>
				<xsl:variable name='fnargs'><xsl:call-template name="listparams"><xsl:with-param name="func" select="." /></xsl:call-template></xsl:variable>
				<xsl:variable name='fnname'><xsl:value-of select="funcdef/function"/></xsl:variable>
				<xsl:variable name='fndef'><xsl:value-of select="funcdef"/></xsl:variable>
				<xsl:variable name='numparams'><xsl:value-of select="count(paramdef/parameter)" /></xsl:variable>
				<xsl:variable name='numparamgeoms'><xsl:value-of select="count(paramdef/type[contains(text(),'geometry') or contains(text(),'geography') or contains(text(),'box') or contains(text(), 'bytea')]) + count(paramdef/parameter[contains(text(),'WKT')]) + count(paramdef/parameter[contains(text(),'geomgml')])" /></xsl:variable>
				<xsl:variable name='numparamgeogs'><xsl:value-of select="count(paramdef/type[contains(text(),'geography')] )" /></xsl:variable>
				<xsl:variable name='log_label'><xsl:value-of select="funcdef/function" />(<xsl:value-of select="$fnargs" />)</xsl:variable>

				<xsl:variable name="geoftype">
				  <!--Conditionally instantiate a value to be assigned to the variable -->
				  <xsl:choose>
					<xsl:when test="$numparamgeoms > '0'">
					  <xsl:value-of select="'Geometry'"/>
					</xsl:when>
					<xsl:when test="$numparamgeogs > '0'">
					  <xsl:value-of select="'Geography'"/>
					</xsl:when>
					<xsl:otherwise>
					  <xsl:value-of select="'Other'"/>
					</xsl:otherwise>
				  </xsl:choose>
				</xsl:variable>
				<!-- For each function prototype generate a test sql statement -->
				<xsl:choose>
<!--Test functions that take no arguments and take no geometries/geographies -->
	<xsl:when test="($numparamgeoms = '0' and $numparamgeogs = '0') and not(contains($fnexclude,funcdef/function))">SELECT  'Starting <xsl:value-of select="funcdef/function" />(<xsl:value-of select="$fnargs" />)';
INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> <xsl:value-of select="$geoftype" />','<xsl:value-of select="$fnname" />', clock_timestamp(),
			  	    '<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT  <xsl:value-of select="funcdef/function" />(<xsl:value-of select="$fnfakeparams" />) As output;</xsl:with-param></xsl:call-template>');

BEGIN;
    <xsl:value-of select="$var_logresultsasxml" />
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
SELECT  'Ending <xsl:value-of select="funcdef/function" />(<xsl:value-of select="$fnargs" />)';
	</xsl:when>
<!--Start Test aggregate and unary functions for both geometry and geography -->
<!-- put functions that take only one geometry/geography no need to cross with another geom collection, these are unary geom, aggregates, and so forth -->
	<xsl:when test="($numparamgeoms = '1' or $numparamgeogs = '1')  and not(contains($fnexclude,funcdef/function))" >
		<xsl:for-each select="document('')//pgis:gardens/pgis:gset">
		SELECT '<xsl:value-of select="$geoftype" /> <xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />: Start Testing';

	INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> <xsl:value-of select="$geoftype" />  <xsl:text> </xsl:text><xsl:value-of select="@ID" /><xsl:text> </xsl:text>','<xsl:value-of select="$fnname" />', '<xsl:value-of select="@ID" />', clock_timestamp(),
			  	'<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT <xsl:value-of select="$fnname" />(<xsl:value-of select="$fnfakeparams" />) As result
							FROM (<xsl:value-of select="." />) As foo1
				LIMIT 3;</xsl:with-param></xsl:call-template>');
BEGIN;
    <xsl:value-of select="$var_logresultsasxml" />
	<xsl:value-of select="$var_logupdatesql" />
COMMIT;
			SELECT '<xsl:value-of select="$geoftype" /> <xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />: End Testing';
		</xsl:for-each>
	</xsl:when>

<!--Functions more than 1 args not already covered this will cross every geometry type with every other -->
	<xsl:when test="not(contains($fnexclude,funcdef/function))">
		<xsl:for-each select="document('')//pgis:gardens/pgis:gset">
	<!--Store first garden sql geometry from -->
			<xsl:variable name="from1"><xsl:value-of select="." /></xsl:variable>
			<xsl:variable name='geom1type'><xsl:value-of select="@GeometryType"/></xsl:variable>
			<xsl:variable name='geom1id'><xsl:value-of select="@ID"/></xsl:variable>
SELECT '<xsl:value-of select="$fnname" /> <xsl:text> </xsl:text><xsl:value-of select="@ID" />(<xsl:value-of select="$fnargs" />): Start Testing <xsl:value-of select="$geom1id" /> against other types';
				<xsl:for-each select="document('')//pgis:gardens/pgis:gset">
			<xsl:choose>
			  <xsl:when test="($numparamgeogs > '0' or $numparamgeoms > '0')">
	INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, g2,  log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> <xsl:value-of select="$geoftype" /> <xsl:text> </xsl:text> <xsl:value-of select="@ID" />','<xsl:value-of select="$fnname" />','<xsl:value-of select="$geom1id" />', '<xsl:value-of select="@ID" />', clock_timestamp(),
			  			'<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT <xsl:value-of select="$fnname" />(<xsl:value-of select="$fnfakeparams" />) As result, ST_AsText(foo1.the_geom) As ref1_geom, ST_AsText(foo2.the_geom) As ref2_geom
	FROM (<xsl:value-of select="$from1" />) As foo1 CROSS JOIN (<xsl:value-of select="." />) As foo2
			LIMIT 2;</xsl:with-param></xsl:call-template>');

			BEGIN;
				 <xsl:value-of select="$var_logresultsasxml" />
				 <xsl:value-of select="$var_logupdatesql" />
			COMMIT;
			</xsl:when>
			  <xsl:otherwise>
			  	INSERT INTO <xsl:value-of select="$var_logtable" />(log_label, func, g1, g2, log_start, log_sql)
			  	VALUES('<xsl:value-of select="$log_label" /> Other <xsl:text> </xsl:text><xsl:value-of select="$geom1id" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />','<xsl:value-of select="$fnname" />', '<xsl:value-of select="$geom1id" />','<xsl:value-of select="@DI" />', clock_timestamp(),
			  	'<xsl:call-template name="escapesinglequotes">
 <xsl:with-param name="arg1">SELECT <xsl:value-of select="$fnname" />(<xsl:value-of select="$fnfakeparams" />)</xsl:with-param></xsl:call-template>');

				SELECT 'Other <xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />(<xsl:value-of select="$fnargs" />): Start Testing <xsl:value-of select="$geom1id" />, <xsl:value-of select="@GeometryType" />';
				BEGIN;
				 <xsl:value-of select="$var_logresultsasxml" />
				 <xsl:value-of select="$var_logupdatesql" />
				COMMIT;
			  </xsl:otherwise>
			</xsl:choose>

	SELECT '<xsl:value-of select="$fnname" />(<xsl:value-of select="$fnargs" />) <xsl:text> </xsl:text> <xsl:value-of select="@ID" />: End Testing <xsl:value-of select="$geom1id" />, <xsl:value-of select="@GeometryType" />';
		<xsl:text>

		</xsl:text>
			</xsl:for-each>
SELECT '<xsl:value-of select="$fnname" /><xsl:text> </xsl:text><xsl:value-of select="@ID" />(<xsl:value-of select="$fnargs" />): End Testing <xsl:value-of select="@GeometryType" /> against other types';
		</xsl:for-each>
		</xsl:when>
	</xsl:choose>
			</xsl:for-each>
		</xsl:for-each>
		<!-- flag primary grouping the functions belong in -->
		UPDATE <xsl:value-of select="$var_logtable" /> SET spatial_class = 'geography' WHERE (log_label ILIKE '%geography%' or log_sql ILIKE '%geography%') AND spatial_class IS NULL;
		UPDATE <xsl:value-of select="$var_logtable" /> SET spatial_class = 'geometry' WHERE log_label ILIKE '%geometry%' or log_label ILIKE '%other%' AND spatial_class IS NULL;

	</xsl:template>

	<!--macro to replace func args with dummy var args -->
	<xsl:template name="replaceparams">
		<xsl:param name="func" />
		<xsl:for-each select="$func">
			<xsl:for-each select="paramdef">
				<xsl:choose>
					<xsl:when test="contains(parameter, 'matrix') or contains(parameter, 'Matrix')">
						<xsl:value-of select="$var_matrix" />
					</xsl:when>
					<xsl:when test="contains(parameter, 'distance')">
						<xsl:value-of select="$var_distance" />
					</xsl:when>
					<xsl:when test="contains(parameter, 'srid')">
						<xsl:value-of select="$var_srid" />
					</xsl:when>
					<xsl:when test="contains(parameter, 'position')">
						<xsl:value-of select="$var_position" />
					</xsl:when>
					<xsl:when test="contains(parameter, 'NDR')">
						'<xsl:value-of select="$var_NDRXDR" />'
					</xsl:when>
					<xsl:when test="contains(parameter, 'gj_version')">
						<xsl:value-of select="$var_gj_version" />
					</xsl:when>
					<xsl:when test="contains(parameter, 'version') and position() = 2">
						<xsl:value-of select="$var_version1" />
					</xsl:when>
					<xsl:when test="(contains(parameter, 'version'))">
						<xsl:value-of select="$var_version2" />
					</xsl:when>
					<xsl:when test="(contains(parameter,'geomgml'))">
						<xsl:text>ST_AsGML(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="(contains(parameter,'geomkml'))">
						<xsl:text>ST_AsKML(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="(contains(type,'box') or type = 'geometry' or type = 'geometry ' or contains(type,'geometry set')) and (position() = 1 or count($func/paramdef/type[contains(text(),'geometry') or contains(text(),'box') or contains(text(), 'WKT') or contains(text(), 'bytea')]) = '1')">
						<xsl:text>foo1.the_geom</xsl:text>
					</xsl:when>
					<xsl:when test="(type = 'geography' or type = 'geography ' or contains(type,'geography set')) and (position() = 1 or count($func/paramdef/type[contains(text(),'geography')]) = '1' )">
						<xsl:text>geography(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(type,'box') or type = 'geometry' or type = 'geometry '">
						<xsl:text>foo2.the_geom</xsl:text>
					</xsl:when>
					<xsl:when test="type = 'geography' or type = 'geography '">
						<xsl:text>geography(foo2.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(type, 'geometry[]') and count($func/paramdef/type[contains(text(),'geometry') or contains(text(),'box') or contains(text(), 'WKT') or contains(text(), 'bytea')]) = '1'">
						ARRAY[foo1.the_geom]
					</xsl:when>
					<xsl:when test="contains(type, 'geometry[]')">
						ARRAY[foo2.the_geom]
					</xsl:when>
					<xsl:when test="contains(parameter, 'EWKT')">
						<xsl:text>ST_AsEWKT(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(parameter, 'WKT')">
						<xsl:text>ST_AsText(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(parameter, 'EWKB')">
						<xsl:text>ST_AsEWKB(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(type, 'bytea')">
						<xsl:text>ST_AsBinary(foo1.the_geom)</xsl:text>
					</xsl:when>
					<xsl:when test="contains(type, 'float') or contains(type, 'double')">
						<xsl:value-of select="$var_float1" />
					</xsl:when>
					<xsl:when test="contains(type, 'spheroid')">
						<xsl:value-of select="$var_spheroid" />
					</xsl:when>
					<xsl:when test="contains(type, 'integer') and position() = 2">
						<xsl:value-of select="$var_integer1" />
					</xsl:when>
					<xsl:when test="contains(type, 'integer')">
						<xsl:value-of select="$var_integer2" />
					</xsl:when>
					<xsl:when test="contains(type, 'text')">
						<xsl:value-of select="$var_text" />
					</xsl:when>
					<xsl:when test="contains(type, 'varchar')">
						<xsl:value-of select="$var_varchar" />
					</xsl:when>
					<xsl:when test="contains(type,'timestamp') or type = 'date'">
						<xsl:text>'2009-01-01'</xsl:text>
					</xsl:when>
					<xsl:when test="contains(type,'boolean')">
						<xsl:value-of select="$var_boolean" />
					</xsl:when>
				</xsl:choose>
				<xsl:if test="position()&lt;last()"><xsl:text>, </xsl:text></xsl:if>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!--macro to pull out function parameter names so we can provide a pretty arg list prefix for each function -->
	<xsl:template name="listparams">
		<xsl:param name="func" />
		<xsl:for-each select="$func">
			<xsl:if test="count(paramdef/parameter) &gt; 0"> </xsl:if>
			<xsl:for-each select="paramdef">
				<xsl:choose>
					<xsl:when test="count(parameter) &gt; 0">
						<xsl:value-of select="parameter" />
					</xsl:when>
				</xsl:choose>
				<xsl:if test="position()&lt;last()"><xsl:text>, </xsl:text></xsl:if>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- copied from http://www.thedumbterminal.co.uk/php/knowledgebase/?action=view&id=94 -->
    <xsl:template name="escapesinglequotes">
     <xsl:param name="arg1"/>
     <xsl:variable name="apostrophe">'</xsl:variable>
     <xsl:choose>
      <!-- this string has at least on single quote -->
      <xsl:when test="contains($arg1, $apostrophe)">
      <xsl:if test="string-length(normalize-space(substring-before($arg1, $apostrophe))) > 0"><xsl:value-of select="substring-before($arg1, $apostrophe)" disable-output-escaping="yes"/>''</xsl:if>
       <xsl:call-template name="escapesinglequotes">
        <xsl:with-param name="arg1"><xsl:value-of select="substring-after($arg1, $apostrophe)" disable-output-escaping="yes"/></xsl:with-param>
       </xsl:call-template>
      </xsl:when>
      <!-- no quotes found in string, just print it -->
      <xsl:when test="string-length(normalize-space($arg1)) > 0"><xsl:value-of select="normalize-space($arg1)"/></xsl:when>
     </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
