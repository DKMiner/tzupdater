#!/bin/sh
# Time zones updater for Android
# (c) 2015 Anton Skshidlevsky <meefik@gmail.com>, GPLv3
# Edited by DKMiner

TZ_VERSION="$1"
[ -n "${ENV_DIR}" ] || ENV_DIR="$(dirname "$(readlink -f "$0")")"
OUTPUT_DIR="${ENV_DIR}/tmp"
TZ_EXTRACTED="${OUTPUT_DIR}/extracted"
TZ_COMPILED="${OUTPUT_DIR}/compiled"
TZ_SETUP="${OUTPUT_DIR}/setup"

tz_version()
{
if [ -z "${TZ_VERSION}" ]; then
   printf "Getting latest version ... "
   TZ_VERSION=$(wget -q -O - "http://data.iana.org/time-zones/" | grep -o 'tzdb-[0-9]\{4\}[a-z]\{1\}' | grep -o '[0-9]\{4\}[a-z]\{1\}' | sort -u | tail -n1)
   [ -n "${TZ_VERSION}" ] && printf "done\n" || { printf "fail\n"; return 1; }
fi
printf "Found IANA tz version: ${TZ_VERSION}\n"
export VERSION=${TZ_VERSION}
return 0
}

download()
{
printf "Downloading tzdata${TZ_VERSION}.tar.gz ... "
[ -e "${TZ_EXTRACTED}" ] || mkdir -p ${TZ_EXTRACTED}
wget -q -O - "http://data.iana.org/time-zones/releases/tzdata${TZ_VERSION}.tar.gz" | tar xz -C ${TZ_EXTRACTED}
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

scan_files()
{
printf "Scaning timezone files ... "
TZ_FILES=$(find ${TZ_EXTRACTED} -type f ! -name 'backzone' | LC_ALL=C sort |
while read f
do
   if [ $(grep -c '^Link' $f) -gt 0 -o $(grep -c '^Zone' $f) -gt 0 ]; then
      echo $f
   fi
done)
[ -n "${TZ_FILES}" ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

setup_file()
{
printf "Generating setup file ... "
(cat ${TZ_FILES} | grep '^Link' | awk '{print $1" "$2" "$3}'
(cat ${TZ_FILES} | grep '^Zone' | awk '{print $2}'
cat ${TZ_FILES} | grep '^Link' | awk '{print $3}') | LC_ALL=C sort) > ${TZ_SETUP}
[ -e "${TZ_SETUP}" ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

compile()
{
printf "Compiling timezones ... "
[ -e "${TZ_COMPILED}" ] || mkdir -p ${TZ_COMPILED}
for tzfile in ${TZ_FILES}
do
   [ "${tzfile##*/}" == "backward" ] && continue
   ${ENV_DIR}/zic -d ${TZ_COMPILED} ${tzfile}
   [ $? -ne 0 ] && { printf "fail\n"; return 1; }
done
printf "done\n"
return 0
}


update()
{
printf "Updating tzdata ... "
[ -e "${ZONEINFO_DIR}" ] || mkdir ${ZONEINFO_DIR}
cd ${ENV_DIR}/compiled
java ZoneCompactor ${TZ_SETUP} ${TZ_COMPILED} ${TZ_EXTRACTED}/zone.tab ${ZONEINFO_DIR} ${TZ_VERSION}
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
printf "Creating tzversion ... "
sed -i "/rules.version=/c\rules.version=${TZ_VERSION}" tzupdate.properties
sed -i '/revision=/c\revision=1' tzupdate.properties
sed -i '/output.version.file=/c\output.version.file=tz_version' tzupdate.properties
java com/android/timezone/version/tools/CreateTzVersion tzupdate.properties
mv -f tz_version ${ZONEINFO_DIR}
[ $? -eq 0 ] || { printf "fail\n"; return 1; }
printf "Generating Telephonylookup ...\n"
java com/android/libcore/timezone/telephonylookup/TelephonyLookupGenerator telephonylookup.txt ${ZONEINFO_DIR}/telephonylookup.xml
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
printf "Generating Tzlookup ...\n"
java com/android/libcore/timezone/tzlookup/TzLookupGenerator countryzones.txt ${TZ_EXTRACTED}/zone.tab ${ZONEINFO_DIR}/tzlookup.xml ${ZONEINFO_DIR}/tzids.prototxt
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
cd ..
return 0
}

cleanup()
{
printf "Cleaning ... "
rm -r "${OUTPUT_DIR}"
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

error()
{
printf "An error has occurred. Exiting.\n"
exit 1
}

#main
ZONEINFO_DIR=${ENV_DIR}/out
TZDATA_FILES="tzdata"
tz_version || error
download || { cleanup; error; }
scan_files || { cleanup; error; }
setup_file || { cleanup; error; }
compile || { cleanup; error; }
update || { cleanup; error; }
cleanup

sync

exit 0