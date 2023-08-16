#!/bin/sh
# Script for making a Magisk timezone module zip file
# by DKMiner

#preparation
mkdir -p module/system/apex/com.android.tzdata/etc/tz
mkdir -p module/system/apex/com.android.tzdata/etc/icu
mkdir -p module/system/apex/com.android.i18n/etc/icu
TZDATA_FILES="tzdata tz_version telephonylookup.xml tzlookup.xml"

error()
{
printf "An error has occurred. Exiting.\n"
exit 1
}

cleanup()
{
printf "Cleaning ... "
rm -r module
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
return 0
}

#creating tz files
create_tz()
{
printf "Creating tz files ... (\n"
bash ./tz/bin/tzdata-updater.sh
[ $? -eq 0 ] && printf ") done\n" || { printf ") fail\n"; return 1; }
return 0
}

#creating icu files
create_icu()
{
printf "Creating icu files ... (\n"
DAT_FILES=$(ls *.dat)
if [ -n "${DAT_FILES}" ]; then
for dat in ${DAT_FILES}
do
	cp ${dat} ./icu/bin/${dat}
done
else
	{ printf "ICU data not found.\n"; exit 1; }
fi
bash ./icu/bin/icu-updater.sh
[ $? -eq 0 ] && printf ") done\n" || { printf ") fail\n"; return 1; }
return 0
}

#creating zip file
create_zip()
{
printf "Creating module zip file ... (\n"
printf "Copying tzdata files ... "
for file in ${TZDATA_FILES}
do
	cp -f tz/bin/out/${file} module/system/apex/com.android.tzdata/etc/tz
done
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
printf "Copying ICU files ... "
DAT_FILES=$(cd icu/bin/out; ls *.dat)
for dat in ${DAT_FILES}
do
	cp -f icu/bin/out/${dat} module/system/apex/com.android.i18n/etc/icu/${dat}
done
cp -f icu/bin/out/icu_overlay/icu_tzdata.dat module/system/apex/com.android.tzdata/etc/icu
[ $? -eq 0 ] && printf "done\n" || { printf "fail\n"; return 1; }
mkdir -p module/META-INF/com/google/android
wget -q -O module/META-INF/com/google/android/update-binary "https://raw.githubusercontent.com/topjohnwu/Magisk/master/scripts/module_installer.sh"
echo "#MAGISK" | cat > module/META-INF/com/google/android/update-script
TZ_VERSION=$(wget -q -O - "http://data.iana.org/time-zones/" | grep -o 'tzdb-[0-9]\{4\}[a-z]\{1\}' | grep -o '[0-9]\{4\}[a-z]\{1\}' | sort -u | tail -n1)
VERSION_CODE=$(echo $TZ_VERSION | perl -ne 'chomp;print map /[0-9]/ ? $_ : ord, split //')
echo -en "id=timezone_fix\nname=Timezone updater\nversion=v${TZ_VERSION}\nversionCode=${VERSION_CODE}\nauthor=DKMiner\ndescription=This module updates timezone presets in settings so you wouldn't have to change your clock time manually :D" | cat >> module/module.prop
cd module
zip -r ../timezone-${TZ_VERSION} *
cd ..
[ $? -eq 0 ] && printf ") done\n" || { printf ") fail\n"; return 1; }
return 0
}

#main
create_icu || { cleanup; error; }
create_tz || { cleanup; error; }
create_zip || { cleanup; error; }
cleanup || error