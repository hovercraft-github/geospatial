/**********************************************************************
 *
 * PostGIS - Spatial Types for PostgreSQL
 * http://postgis.net
 *
 * PostGIS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * PostGIS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PostGIS.  If not, see <http://www.gnu.org/licenses/>.
 *
 **********************************************************************
 *
 * Copyright (C) 2006 Refractions Research Inc.
 * Modifications Copyright (c) 2017 - Present Pivotal Software, Inc. All Rights Reserved.
 *
 **********************************************************************/


#include "postgres.h"
#include "access/xact.h"
#include "executor/spi.h"       /* this is what you need to work with SPI */
#include "commands/trigger.h"   /* ... and triggers */
#include "utils/lsyscache.h"	/* for get_namespace_name() */
#include "utils/rel.h"
#include "../postgis_config.h"
#include "lwgeom_pg.h"

#define ABORT_ON_AUTH_FAILURE 1

Datum check_authorization(PG_FUNCTION_ARGS);
Datum getTransactionID(PG_FUNCTION_ARGS);

/*
 * This trigger will check for authorization before
 * allowing UPDATE or DELETE of specific rows.
 * Rows are identified by the provided column.
 * Authorization info is extracted by the
 * "authorization_table"
 *
 */
PG_FUNCTION_INFO_V1(check_authorization);
Datum check_authorization(PG_FUNCTION_ARGS)
{
	TriggerData *trigdata = (TriggerData *) fcinfo->context;
	char *colname;
	HeapTuple rettuple_ok;
	HeapTuple rettuple_fail;
	TupleDesc tupdesc;
	int SPIcode;
	char query[1024];
	const char *pk_id = NULL;
	SPITupleTable *tuptable;
	HeapTuple tuple;
	char *lockcode;
	char *authtable = "authorization_table";
	const char *op;
	char err_msg[256];


	/* Make sure trigdata is pointing at what I expect */
	if ( ! CALLED_AS_TRIGGER(fcinfo) )
	{
		elog(ERROR,"check_authorization: not fired by trigger manager");
	}

	if ( ! TRIGGER_FIRED_BEFORE(trigdata->tg_event) )
	{
		elog(ERROR,"check_authorization: not fired *before* event");
	}

	if ( TRIGGER_FIRED_BY_UPDATE(trigdata->tg_event) )
	{
		rettuple_ok = trigdata->tg_newtuple;
		rettuple_fail = NULL;
		op = "UPDATE";
	}
	else if ( TRIGGER_FIRED_BY_DELETE(trigdata->tg_event) )
	{
		rettuple_ok = trigdata->tg_trigtuple;
		rettuple_fail = NULL;
		op = "DELETE";
	}
	else
	{
		elog(ERROR,"check_authorization: not fired by update or delete");
		PG_RETURN_NULL();
	}


	tupdesc = trigdata->tg_relation->rd_att;

	/* Connect to SPI manager */
	SPIcode = SPI_connect();

	if (SPIcode  != SPI_OK_CONNECT)
	{
		elog(ERROR,"check_authorization: could not connect to SPI");
		PG_RETURN_NULL() ;
	}

	colname  = trigdata->tg_trigger->tgargs[0];
	pk_id = SPI_getvalue(trigdata->tg_trigtuple, tupdesc,
	                     SPI_fnumber(tupdesc, colname));

	POSTGIS_DEBUG(3, "check_authorization called");

	snprintf(query, sizeof(query), "SELECT authid FROM \"%s\" WHERE expires >= now() AND toid = '%d' AND rid = '%s'", authtable, trigdata->tg_relation->rd_id, pk_id);

	POSTGIS_DEBUGF(3 ,"about to execute :%s", query);

	SPIcode = SPI_exec(query,0);
	if (SPIcode !=SPI_OK_SELECT )
		elog(ERROR,"couldnt execute to test for lock :%s",query);

	if (!SPI_processed )
	{
		POSTGIS_DEBUGF(3, "there is NO lock on row '%s'", pk_id);

		SPI_finish();
		return PointerGetDatum(rettuple_ok);
	}

	/* there is a lock - check to see if I have rights to it! */

	tuptable = SPI_tuptable;
	tupdesc = tuptable->tupdesc;
	tuple = tuptable->vals[0];
	lockcode = SPI_getvalue(tuple, tupdesc, 1);

	POSTGIS_DEBUGF(3, "there is a lock on row '%s' (auth: '%s').", pk_id, lockcode);

	/*
	 * check to see if temp_lock_have_table table exists
	 * (it might not exist if they own no locks)
	 */
	snprintf(query, sizeof(query), "SELECT * FROM pg_class WHERE relname = 'temp_lock_have_table'");
	SPIcode = SPI_exec(query,0);
	if (SPIcode != SPI_OK_SELECT )
		elog(ERROR,"couldnt execute to test for lockkey temp table :%s",query);
	if (SPI_processed==0)
	{
		goto fail;
	}

	snprintf(query, sizeof(query), "SELECT * FROM temp_lock_have_table WHERE xideq( transid, getTransactionID() ) AND lockcode ='%s'", lockcode);

	POSTGIS_DEBUGF(3, "about to execute :%s", query);

	SPIcode = SPI_exec(query,0);
	if (SPIcode != SPI_OK_SELECT )
		elog(ERROR, "couldnt execute to test for lock acquire: %s", query);

	if (SPI_processed >0)
	{
		POSTGIS_DEBUG(3, "I own the lock - I can modify the row");

		SPI_finish();
		return PointerGetDatum(rettuple_ok);
	}

fail:

	snprintf(err_msg, sizeof(err_msg), "%s where \"%s\" = '%s' requires authorization '%s'",
	         op, colname, pk_id, lockcode);
	err_msg[sizeof(err_msg)-1] = '\0';

#ifdef ABORT_ON_AUTH_FAILURE
	elog(ERROR, "%s", err_msg);
#else
	elog(NOTICE, "%s", err_msg);
#endif

	SPI_finish();
	return PointerGetDatum(rettuple_fail);


}

PG_FUNCTION_INFO_V1(getTransactionID);
Datum getTransactionID(PG_FUNCTION_ARGS)
{
	TransactionId xid = GetCurrentTransactionId();
	PG_RETURN_DATUM( TransactionIdGetDatum(xid) );
}
