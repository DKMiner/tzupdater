#!/bin/sh
# ICU data updater for Android
# (c) 2015 Anton Skshidlevsky <meefik@gmail.com>, GPLv3

TZ_VERSION="$1"
[ -n "${ENV_DIR}" ] || ENV_DIR="$(dirname "$(readlink -f "$0")")"
DAT_FILE=$(cd ${ENV_DIR}; ls *.dat)
[ -n "${DAT_FILE}" ] || { printf "ICU data not found.\n"; exit 1; }
TMP_DIR="${ENV_DIR}/tmp"
OUTPUT_DIR="${ENV_DIR}/out"
ICU_EXTRACTED="${ENV_DIR}/extracted"
ICU_RES_DIR="${TMP_DIR}/icu/overlay_res"

icu_version()
{
REPO_URL="https://api.github.com/repos/unicode-org/icu-data/contents/tzdata/icunew"
if [ -z "${TZ_VERSION}" ]; then
   printf "Getting latest version ... "
   TZ_VERSION=$(wget -q -O - ${REPO_URL} | grep '"name"' | grep -o '[0-9]\{4\}[a-z]\{1\}' | sort -u | tail -n1)
   [ -n "${TZ_VERSION}" ] && printf "done\n" || { printf "fail\n"; return 1; }
fi
ICU_VERSION=$(wget -q -O - "https://repo1.maven.org/maven2/com/ibm/icu/icu4j/maven-metadata.xml" | grep -o -E '<latest>[0-9]*\.[0-9]*(\.[0-9]*)?<\/latest>' | grep -o -E '[0-9]*\.[0-9]*(\.[0-9]*)?' | tail -n1)
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

extract()
{
printf "Extracting ${DAT_FILE} file ... "
DAT_NAME="icudt${ICU_VERSION%.*}l.dat"
[ -d "${ICU_EXTRACTED}" ] || mkdir -p ${ICU_EXTRACTED}
${ENV_DIR}/icupkg -l -o ${ENV_DIR}/list.txt ${ENV_DIR}/"$DAT_FILE"
${ENV_DIR}/icupkg -x ${ENV_DIR}/"$DAT_FILE" -d ${ICU_EXTRACTED} ${ENV_DIR}/"$DAT_FILE"
for res in ${RES_FILES}
do
	cp -f ${ICU_RES_DIR}/${res} ${ICU_EXTRACTED}
done
printf "done\n"
return 0
}

update()
{
printf "Creating new $DAT_NAME file ... "
${ENV_DIR}/icupkg -tl -a ${ENV_DIR}/list.txt -s ${ICU_EXTRACTED} new ${ENV_DIR}/"$DAT_NAME"
[ -d "${OUTPUT_DIR}" ] || mkdir -p ${OUTPUT_DIR}
mv ${ENV_DIR}/${DAT_NAME} ${OUTPUT_DIR}/${DAT_NAME}
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
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
[ -d "${ICU_EXTRACTED}" ] && rm -r "${ICU_EXTRACTED}"
[ -f "${ENV_DIR}/list.txt" ] && rm -r "${ENV_DIR}/list.txt"
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
extract || { cleanup; error; }
update || { cleanup; error; }
icu_overlay || { cleanup; error; }
cleanup

sync

exit 0
