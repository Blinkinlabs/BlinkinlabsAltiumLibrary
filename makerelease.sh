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

set -e

DATE=`date +%Y-%m-%d`
NAME=$(basename -s .git $(git config --get remote.origin.url))
REV="RevA"

TITLE="${DATE} ${NAME} ${REV}"

CURRENTDIR=`pwd`
REPODIR=`git rev-parse --show-toplevel`
RELEASEDIR=${REPODIR}/releases
GERBERDIR="${RELEASEDIR}/${TITLE}"

ZIP="/c/Program\ Files\ \(x86\)/GnuWin32/bin/zip"


echo "Releasing '${TITLE}' to: ${RELEASEDIR}"

mkdir -p "${RELEASEDIR}"

cp Job1.pdf "${RELEASEDIR}/${TITLE}.pdf"
cp BOM/*.xls "${RELEASEDIR}/${TITLE} BOM.xls"
cp ExportSTEP/*.step "${RELEASEDIR}/${TITLE}.step"
cp "Pick Place/"*.txt "${RELEASEDIR}/${TITLE} Pick Place.txt"

mkdir "${GERBERDIR}"

GERBERFILES=(GTL GTO GTP GTS GBL GBO GBP GBS GM1 G1 G2 G3 G4)
for FILE in ${GERBERFILES[*]}; do
	if [ -e "Gerber/"*"${FILE}" ]; then
		cp "Gerber/"*"${FILE}" "${GERBERDIR}"
	fi
done

#TODO: If only one type of hole is present, then *.TXT should be used instead
DRILLFILES=(SlotHoles.TXT RoundHoles.TXT)
for FILE in ${DRILLFILES[*]}; do
	if [ -e "NC Drill/"*"${FILE}" ]; then
		cp "NC Drill/"*"${FILE}" "${GERBERDIR}"
	fi
done

pushd ${RELEASEDIR}
eval "$ZIP -r '${TITLE} Gerber.zip' '${TITLE}'"
popd

rm -rf "${GERBERDIR}"
