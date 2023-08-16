#!/bin/sh
# ICU data updater for Android
# (c) 2015 Anton Skshidlevsky <meefik@gmail.com>, GPLv3
# Edited by DKMiner

TZ_VERSION="$1"
[ -n "${ENV_DIR}" ] || ENV_DIR="$(dirname "$(readlink -f "$0")")"
DAT_FILES=$(cd ${ENV_DIR}; ls *.dat)
[ -n "${DAT_FILES}" ] || { printf "ICU data not found.\n"; exit 1; }
TMP_DIR="${ENV_DIR}/tmp"
OUTPUT_DIR="${ENV_DIR}/out"
ICU_RES_DIR="${TMP_DIR}/icu/overlay_res"

icu_version()
{
REPO_URL="https://api.github.com/repos/unicode-org/icu-data/contents/tzdata/icunew"
if [ -z "${TZ_VERSION}" ]; then
   printf "Getting latest version ... "
   TZ_VERSION=$(wget -q -O - ${REPO_URL} | grep '"name"' | grep -o '[0-9]\{4\}[a-z]\{1\}' | sort -u | tail -n1)
   ICU_VERSION=$(wget -q -O - "https://repo1.maven.org/maven2/com/ibm/icu/icu4j/maven-metadata.xml" | grep -o -E '<latest>[0-9]*\.[0-9]*(\.[0-9]*)?<\/latest>' | grep -o -E '[0-9]*\.[0-9]*(\.[0-9]*)?' | tail -n1)
   [ -n "${TZ_VERSION}" ] && [ -n "${ICU_VERSION}" ] && printf "done\n" || { printf "fail\n"; return 1; }
fi
printf "Found ICU version: ${ICU_VERSION}\n"
ICU_URL="https://raw.githubusercontent.com/unicode-org/icu-data/master/tzdata/icunew/${TZ_VERSION}/44/le"
RES_FILES="zoneinfo64.res windowsZones.res timezoneTypes.res metaZones.res"
return 0
}

download()
{
[ -d "${ICU_RES_DIR}" ] || mkdir -p ${ICU_RES_DIR}
for res in ${RES_FILES}
do
   printf "Downloading ${res} ... "
   wget -q ${ICU_URL}/${res} -O ${ICU_RES_DIR}/${res}
   [ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
done
return 0
}

update()
{
[ -d "${OUTPUT_DIR}" ] || mkdir -p ${OUTPUT_DIR}
for dat in ${DAT_FILES}
do
   printf "Updating ${dat} ... "
   for res in ${RES_FILES}
   do
      ${ENV_DIR}/icupkg -s ${ICU_RES_DIR} -a ${res} ${ENV_DIR}/${dat}
      [ $? -eq 0 ] || { printf "fail\n"; return 1; }
   done
   mv -f ${ENV_DIR}/${dat} ${OUTPUT_DIR}/${dat}
   printf "done\n"
done
return 0
}

icu_overlay()
{
#you can download latest icu4c for ubuntu from https://github.com/unicode-org/icu/releases/latest and place it in bin
printf "Creating icu_overlay ... \n"
tar -C ${TMP_DIR} -xf ${ENV_DIR}/icu4c-73_2.tgz ./icu/usr/local/lib/
tar -C ${TMP_DIR} -xf ${ENV_DIR}/icu4c-73_2.tgz ./icu/usr/local/bin/
mv -f ${TMP_DIR}/icu/usr/local/lib ${TMP_DIR}/icu/lib
mv -f ${TMP_DIR}/icu/usr/local/bin ${TMP_DIR}/icu/bin
rm -r ${TMP_DIR}/icu/usr
python3 ${ENV_DIR}/icu_overlay.py
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

cleanup()
{
printf "Cleaning ... "
[ -d "${TMP_DIR}" ] && rm -r "${TMP_DIR}"
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

error()
{
printf "An error has occurred. Exiting.\n"
exit 1
}

icu_version || error
download || { cleanup; error; }
update || { cleanup; error; }
icu_overlay || { cleanup; error; }
cleanup

sync

exit 0
