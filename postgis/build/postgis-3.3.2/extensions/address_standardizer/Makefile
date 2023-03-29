include ../upgradeable_versions.mk
OBJS = \
    address_parser.o \
    address_standardizer.o \
    std_pg_hash.o \
    analyze.o \
    err_param.o \
    export.o \
    gamma.o \
    hash.o \
    lexicon.o \
    pagc_tools.o \
    parseaddress-api.o \
    standard.o \
    tokenize.o

OBJS_test_main = \
    test_main.o \
    analyze.o \
    err_param.o \
    export.o \
    gamma.o \
    hash.o \
    lexicon.o \
    pagc_tools.o \
    standard.o \
    tokenize.o

POSTGIS_PGSQL_VERSION=120
# SQL preprocessor
SQLPP = /usr/bin/cpp -traditional-cpp -w -P
GREP=/usr/bin/grep
PERL=/usr/local/bin/perl
EXTVERSION    = 2.5.4
MINORVERSION  = 2.5
MODULE_big = address_standardizer
EXTENSION = address_standardizer
DATA = sql/$(EXTENSION).sql sql/$(EXTENSION)_data_us.sql

DATA_built = \
	$(EXTENSION).control \
	$(EXTENSION)_data_us.control \
	$(NULL)

all:  sql/address_standardizer.sql sql/address_standardizer--1.0--$(EXTVERSION).sql sql/address_standardizer--$(EXTVERSION).sql sql/$(EXTENSION)--ANY--$(EXTVERSION).sql \
 sql/$(EXTENSION)_data_us.sql sql/address_standardizer--2.5.4.sql sql/$(EXTENSION)_data_us--2.5.4.sql  sql/$(EXTENSION)_data_us--$(EXTVERSION)--$(EXTVERSION)next.sql \
sql/$(EXTENSION)_data_us--$(EXTVERSION)next--$(EXTVERSION).sql \
sql/test-init-extensions.sql sql/test-parseaddress.sql sql/test-standardize_address_1.sql sql/test-standardize_address_2.sql

EXTRA_CLEAN += sql/*.sql

DOCS = README.address_standardizer
PG_CPPFLAGS = -g -O2  -I/usr/local/Cellar/geos/3.11.1/include -I/usr/local/Cellar/proj@7/7.2.1//include -DACCEPT_USE_OF_DEPRECATED_PROJ_API_H=1  -I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include  -I/usr/local/Cellar/json-c/0.16//include -I/usr/local/Cellar/pcre/8.45//include -I/usr/local/include/

SHLIB_LINK =  -L/usr/local/Cellar/geos/3.11.1/lib -L/usr/local/Cellar/proj@7/7.2.1//lib -lgeos_c -lproj -L/usr/local/Cellar/json-c/0.16//lib -ljson-c  -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lxml2 -lz -lpthread -licucore -lm  -L/usr/local/Cellar/pcre/8.45//lib  -L/usr/local/Cellar/gettext/0.21.1/lib -lpcre
EXTRA_CLEAN = usps-st-city-name.txt mk-st-regexp mk-city-regex test_main
REGRESS = test-init-extensions test-parseaddress test-standardize_address_1 test-standardize_address_2

# PGXS information
PG_CONFIG = /usr/local/gpdb/bin/pg_config

PGVER := $(shell $(PG_CONFIG) --version)


# Set PERL _after_ the include of PGXS
PERL=/usr/local/bin/perl

# Borrow the $libdir substitution from PGXS but customise by running the preprocessor
# and adding the version number
sql/%.sql: %.sql.in
	mkdir -p sql
	$(SQLPP) -I../libpgcommon $< | grep -v '^#' | \
	$(PERL) -lpe "s'MODULE_PATHNAME'\$$libdir/${EXTENSION}'g" > $@

%.control: %.control.in Makefile
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		> $@

sql/address_standardizer--2.5.4.sql: sql/address_standardizer_types.sql \
    sql/address_standardizer_functions.sql
	mkdir -p sql
	cat $^ > $@

sql/address_standardizer.sql: sql/address_standardizer_types.sql \
    sql/address_standardizer_functions.sql
	mkdir -p sql
	cat $^ > $@

sql/address_standardizer--1.0--$(EXTVERSION).sql:  sql/address_standardizer_functions.sql
	mkdir -p sql
	cat $^ > $@

# Scripts making up the extension minor upgrade file
# NOTE: order matters
EXTENSION_UPGRADE_SCRIPTS = \
	sql/address_standardizer_functions.sql


sql/$(EXTENSION)--ANY--$(EXTVERSION).sql: $(EXTENSION_UPGRADE_SCRIPTS)
	cat $(EXTENSION_UPGRADE_SCRIPTS) > $@

include ../upgrade-paths-rules.mk

# build us data extension
sql/$(EXTENSION)_data_us--$(EXTVERSION).sql: us_lex.sql us_gaz.sql us_rules.sql sql_bits/address_standardizer_data_us_mark_editable_objects.sql.in
	mkdir -p sql
	cat $^ > $@

sql/$(EXTENSION)_data_us.sql: us_lex.sql us_gaz.sql us_rules.sql sql_bits/address_standardizer_data_us_mark_editable_objects.sql.in
	mkdir -p sql
	cat $^ > $@

# upgrade logic for us data extension (to go to next cludge for dev upgrading)
sql/$(EXTENSION)_data_us--$(EXTVERSION)--$(EXTVERSION)next.sql: sql/$(EXTENSION)_data_us--$(EXTVERSION).sql
	mkdir -p sql
	cat $^ > $@

# upgrade logic for us data extension (to go to original round-robin yoyo cludge for dev upgrading)
sql/$(EXTENSION)_data_us--$(EXTVERSION)next--$(EXTVERSION).sql: sql/$(EXTENSION)_data_us--$(EXTVERSION).sql
	mkdir -p sql
	cat $^ > $@

mk-st-regexp: mk-st-regexp.pl
	$(PERL) -c mk-st-regexp.pl
	rm -f mk-st-regexp
	echo "#! " $(PERL) > mk-st-regexp
	cat mk-st-regexp.pl >> mk-st-regexp
	chmod ugo+x mk-st-regexp

mk-city-regex: mk-city-regex.pl usps-st-city-name.txt
	$(PERL) -c mk-city-regex.pl
	rm -f mk-city-regex
	echo "#! " $(PERL) > mk-city-regex
	cat mk-city-regex.pl >> mk-city-regex
	chmod ugo+x mk-city-regex

usps-st-city-name.txt: usps-st-city-orig.txt usps-st-city-adds.txt
	cat usps-st-city-orig.txt usps-st-city-adds.txt | sort -u >usps-st-city-name.txt

#parseaddress-stcities.h: mk-city-regex
#	./mk-city-regex > parseaddress-stcities.h

#parseaddress-regex.h: mk-st-regexp
#	./mk-st-regexp > parseaddress-regex.h

dist-clean:
	rm -f mk-st-regexp mk-city-regex usps-st-city-name.txt test_main Makefile


test_main: $(OBJS_test_main)
	gcc -o test_main $(OBJS_test_main) $(LDFLAGS) $(LIBS)

test_main.o: test_main.c pagc_api.h pagc_std_api.h

address_parser.o: address_parser.c parseaddress-api.h

address_standardizer.o: address_standardizer.c std_pg_hash.h pagc_api.h pagc_std_api.h

analyze.o: analyze.c pagc_api.h

err_param.o: err_param.c pagc_api.h

export.o: export.c pagc_api.h pagc_tools.h

gamma.o: gamma.c pagc_api.h pagc_std_api.h gamma.h

hash.o: hash.c hash.h khash.h

lexicon.o: lexicon.c pagc_api.h pagc_std_api.h

pagc_tools.o: pagc_tools.c pagc_tools.h pagc_common.h

parseaddress-api.o: parseaddress-api.c parseaddress-api.h parseaddress-stcities.h parseaddress-regex.h

standard.o: standard.c pagc_api.h

tokenize.o: tokenize.c pagc_api.h

std_pg_hash.o: std_pg_hash.c std_pg_hash.h pagc_api.h pagc_std_api.h

#only extension files
DATA += $(wildcard sql/*--*.sql)
EXTRA_CLEAN += sql/*.sql
EXTRA_CLEAN += $(wildcard expected/*--*.out)
EXTRA_CLEAN += sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION)--unpackaged--$(EXTVERSION).sql
EXTRA_CLEAN += sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION)--unpackaged--$(EXTVERSION).sql *.a *.so *.dll

distclean: clean
	rm Makefile

PGXS := /usr/local/gpdb/lib/postgresql/pgxs/src/makefiles/pgxs.mk
include $(PGXS)
PERL = /usr/local/bin/perl
