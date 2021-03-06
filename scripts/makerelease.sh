#!/bin/bash

# Rename and package Altium outputs to a standard release format
# Requirements:
# Altium
# Git Bash: 
# Zip: http://gnuwin32.sourceforge.net/packages/zip.htm
#
# 1. Add the included OutJob to your project, then use it to output the
#    'PDF' and 'Folder Structure' containers.
# 2. Open a 'Git Bash' terminal session, cd to the 'Project Outputs'
#    directory, then run:
#     ~/Blinkinlabs-Repos/Blinkinlabs-Altium-Library/makerelease.sh
# 3. Note that you will need to edit this file to set the revision (TODO)
# 4. Release files will be stored to the /releases folder of your git repo
# 5. Check the release files in, send to board house, etc
#

usage="$(basename "$0") [-h] [-n name] -r revision  -- Create a release package for an Altium project

where:
    -h  show this help text
    -r  Revision number (required, ex: RevA)
    -n  Project name (optional, defaults to git project name)"

while getopts ':h:r:n:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    r) REV="$OPTARG"
       ;;
    n) NAME="$OPTARG"
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done

if [ -e "$REV" ]; then
    echo "Missing revision argument"
    echo "$usage" >&2
    exit 1
fi

set -e

DATE=`date +%Y-%m-%d`

if [ -e "$NAME" ]; then
    NAME=$(basename -s .git $(git config --get remote.origin.url))
fi

TITLE="${DATE}_${NAME}_${REV}"

echo ${TITLE}

# CURRENTDIR=`pwd`
REPODIR=`git rev-parse --show-toplevel`
RELEASEDIR=${REPODIR}/releases
GERBERDIR="${RELEASEDIR}/${TITLE}"

ZIP="/c/Program\ Files\ \(x86\)/GnuWin32/bin/zip"

cd "Project Outputs for "*

echo "Releasing '${TITLE}' to: ${RELEASEDIR}"

mkdir -p "${RELEASEDIR}"

cp Job1.pdf "${RELEASEDIR}/${TITLE}.pdf"
cp "BOM/"*.xlsx "${RELEASEDIR}/${TITLE} BOM.xlsx"
cp ExportSTEP/*.step "${RELEASEDIR}/${TITLE}.step"
cp "Pick Place/"*.csv "${RELEASEDIR}/${TITLE} Pick Place.csv"

mkdir "${GERBERDIR}"

GERBERFILEEXTENSIONS=(GTL GTO GTP GTS GBL GBO GBP GBS GM1 G1 G2 G3 G4)
for EXTENSION in ${GERBERFILEEXTENSIONS[*]}; do
	if [ -e "Gerber/"*"${EXTENSION}" ]; then
		cp "Gerber/"*"${EXTENSION}" "${GERBERDIR}"
	fi
done

#TODO: If only one type of hole is present, then *.TXT should be used instead
DRILLFILEEXTENSIONS=(TXT)
for EXTENSION in ${DRILLFILEEXTENSIONS[*]}; do
    for FILE in "NC Drill/"*"${EXTENSION}"; do
		cp "NC Drill/"*"${EXTENSION}" "${GERBERDIR}"
    done
done

pushd "${RELEASEDIR}"
eval "$ZIP -r '${TITLE} Gerber.zip' '${TITLE}'"
popd

rm -rf "${GERBERDIR}"

explorer `cygpath -w "${RELEASEDIR}"`
