#
# Eltrun web site creation and data validation
#
# (C) Copyright 2005 Diomidis Spinellis
#
# $Id$
#

MEMBERFILES=$(wildcard data/members/*.xml)
GROUPFILES=$(wildcard data/groups/*.xml)
PROJECTFILES=$(wildcard data/projects/*.xml)
PUBFILE=build/pubs.xml
BIBFILES=$(wildcard data/publications/*.bib)

# Database containing all the above
DB=build/db.xml
# XSLT file for public data
PXSLT=schema/eltrun-public.xslt
# XSLT file for fetching the ids
IDXSLT=schema/eltrun-ids.xslt
# Today' date in ISO format
TODAY=$(shell date +'%Y%m%d')
# Fetch the ids
GROUPIDS=$(shell xml tr ${IDXSLT} -s category=group ${DB})
PROJECTIDS=$(shell xml tr ${IDXSLT} -s category=project ${DB})
MEMBERIDS=$(shell xml tr ${IDXSLT} -s category=member ${DB})
# HTML output directory
HTML=public_html

all: html

$(DB): ${MEMBERFILES} ${GROUPFILES} ${PROJECTFILES} $(BIBFILES) tools/makepub.pl
	echo '<eltrun>' >$@
	echo '<group_list>' >>$@
	cat ${GROUPFILES} >>$@
	echo '</group_list>' >>$@
	echo '<member_list>' >>$@
	cat ${MEMBERFILES} >>$@
	echo '</member_list>' >>$@
	echo '<project_list>' >>$@
	cat ${PROJECTFILES} >>$@
	echo '</project_list>' >>$@
	perl -n tools/makepub.pl $(BIBFILES) >>$@
	echo '</eltrun>' >>$@

clean:
	-rm -f  build/* \
		${HTML}/groups/* \
		${HTML}/images/* \
		${HTML}/projects/* \
		${HTML}/publications/* 2>/dev/null

val: ${DB}
	xml val -d schema/eltrun.dtd $(DB)

html: ${DB}
	# For all groups and the empty group
	for group in $(GROUPIDS) '' ; \
	do \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=completed-projects ${DB} >${HTML}/groups/$$group-completed-projects.html ; \
		xml tr ${PXSLT} -s today=${TODAY} -s ogroup=$$group -s what=current-projects ${DB} >${HTML}/groups/$$group-current-projects.html ; \
	done
	for project in $(PROJECTIDS) ; \
	do \
		xml tr ${PXSLT} -s oproject=$$project -s what=project-details ${DB} >${HTML}/projects/$$project.html ; \
		xml tr ${PXSLT} -s oproject=$$project -s what=project-publications ${DB} >${HTML}/publications/$$project.html ; \
	done
	for member in $(MEMBERIDS) ; \
	do \
		xml tr ${PXSLT} -s omember=$$member -s what=member-publications ${DB} >${HTML}/publications/$$member.html ; \
	done
