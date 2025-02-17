include ../upgradeable_versions.mk

EXTENSION    = postgis_sfcgal
EXTVERSION    = 3.3.2
MINORVERSION  = 3.3
GREP = /usr/bin/grep
PERL = /usr/local/bin/perl

MICRO_NUMBER  = $(shell echo $(EXTVERSION) | \
						$(PERL) -pe 's/\d.\d.(\d+)[a-zA-Z]*\d*/$1/'

PREREL_NUMBER = $(shell echo $(EXTVERSION) | \
                        $(PERL) -pe 's/\d\.\d\.(.*)/\1/' | \
                        $(GREP) "[a-zA-Z]" | \
                        $(PERL) -pe 's/\d+[a-zA-Z]+(\d+)/\1/'

MICRO_PREV    = $(shell if test "$(MICRO_NUMBER)x" != "x"; then expr $(MICRO_NUMBER) - 1; fi)
PREREL_PREV   = $(shell if test "$(PREREL_NUMBER)x" != "x"; then expr $(PREREL_NUMBER) - 1; fi)

PREREL_PREFIX = $(shell echo $(EXTVERSION) | \
                        $(PERL) -pe 's/\d\.\d\.(.*)/\1/' | \
                        $(GREP) "[a-zA-Z]" | \
                        $(PERL) -pe 's/(\d+[a-zA-Z]+)\d*/\1/'

DATA_built = \
	$(EXTENSION).control \
	sql/$(EXTENSION)--$(EXTVERSION).sql \
	sql/$(EXTENSION)--unpackaged--$(EXTVERSION).sql \
	$(NULL)

# Scripts making up the extension minor upgrade file
# NOTE: order matters
EXTENSION_UPGRADE_SCRIPTS = \
	sql_bits/sfcgal_upgrade_minor.sql

# Scripts making up the extension upgrade-from-unpackaged file
# NOTE: order matters
EXTENSION_UNPACKAGED_UPGRADE_SCRIPTS = \
	sql_bits/sfcgal.sql \
	../../utils/create_unpackaged.pl

PG_CONFIG    =  /usr/local/gpdb/bin/pg_config

SQL_BITS     = $(wildcard sql_bits/*.sql)
EXTRA_CLEAN += sql/*.sql ${SQL_BITS}

all: sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION)--unpackaged--$(EXTVERSION).sql sql/$(EXTENSION)--ANY--$(EXTVERSION).sql

sql:
	mkdir -p $@

$(EXTENSION).control: $(EXTENSION).control.in Makefile
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		> $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	mkdir -p sql
	cp $< $@

sql/$(EXTENSION).sql: sql_bits/sfcgal.sql  sql_bits/sfcgal_comments.sql
	mkdir -p sql
	cat $^ > $@

#this is a cludge to allow upgrading from same SVN to same SVN
sql/$(EXTENSION)--$(EXTVERSION)--$(EXTVERSION)next.sql: sql_bits/sfcgal_upgrade_minor.sql
	mkdir -p sql
	cat $^ > $@
sql/$(EXTENSION)--$(EXTVERSION)next--$(EXTVERSION).sql: sql/$(EXTENSION)--$(EXTVERSION)--$(EXTVERSION)next.sql
	mkdir -p sql
	cp $< $@

sql_bits/sfcgal.sql: ../../postgis/sfcgal.sql
	mkdir -p sql_bits
	$(PERL) -pe 's/BEGIN\;//g ; s/COMMIT\;//g' $< > $@

../../doc/sfcgal_comments.sql:
	$(MAKE) -C ../../doc comments

sql_bits/sfcgal_comments.sql: ../../doc/sfcgal_comments.sql
	mkdir -p sql_bits
	cp $< $@

#grep all lines that start with CREATE OR REPLACE FUNCTION, TRIGGER...
#then replace CREATE OR REPLACE .. with ALTER EXTENSION..;
#then remove default values and extra junk
sql/$(EXTENSION)--unpackaged--$(EXTVERSION).sql: $(EXTENSION_UNPACKAGED_UPGRADE_SCRIPTS) sql/$(EXTENSION)--ANY--$(EXTVERSION).sql ../../utils/create_unpackaged.pl Makefile | sql
	# Ensure version is correct
	cat sql/$(EXTENSION)--ANY--$(EXTVERSION).sql > $@
	cat $(EXTENSION_UNPACKAGED_UPGRADE_SCRIPTS) \
		| $(PERL) ../../utils/create_unpackaged.pl ${EXTENSION} \
		>> $@

sql_bits/sfcgal_upgrade.sql : ../../postgis/sfcgal_upgrade.sql
	mkdir -p sql_bits
	$(PERL) -pe 's/BEGIN\;//g ; s/COMMIT\;//g' $< > $@

sql_bits/sfcgal_upgrade_minor.sql: ../postgis_extension_helper.sql sql_bits/sfcgal_upgrade.sql ../../doc/sfcgal_comments.sql ../postgis_extension_helper_uninstall.sql
	mkdir -p sql_bits
	printf '\\echo Use "CREATE EXTENSION $(EXTENSION)" to load this file. \\quit\n' > $@
	cat $^ >> $@

sql/$(EXTENSION)--ANY--$(EXTVERSION).sql: $(EXTENSION_UPGRADE_SCRIPTS)
	cat $(EXTENSION_UPGRADE_SCRIPTS) > $@

include ../upgrade-paths-rules.mk

distclean: clean
	rm Makefile

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
PERL = /usr/local/bin/perl
