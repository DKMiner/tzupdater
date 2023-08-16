#!/bin/sh
# Script for downloading Java files from AOSP repo automatically and getting all other necessary files ready for compile.sh
# by DKMiner


#download or fix google protobuf
#(These files must use protobuf 3.23.2, until later is specified. For now no need to download the latest version, (uncomment latest_proto to download)
latest_proto()
{
PROTO_VERSION=$(wget -q -O - "https://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/maven-metadata.xml" | grep -o '<latest>.*<\/latest>' | grep -o -P "(?<=<latest>).*(?=<\/latest>)" | tail -n1)
curl -s "https://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/${PROTO_VERSION}/protobuf-java-${PROTO_VERSION}.jar" "protobuf-java-${PROTO_VERSION}.jar" | jar xf "protobuf-java-${PROTO_VERSION}.jar"
}
#latest_proto
if [ -e "./protobuf-java-${PROTO_VERSION}.jar" ]; then
	jar xf "protobuf-java-${PROTO_VERSION}.jar"
else
	printf "Couldn't find protobuf-java-${PROTO_VERSION}.jar"
fi


#download or fix icu4j
ICU_VERSION=$(wget -q -O - "https://repo1.maven.org/maven2/com/ibm/icu/icu4j/maven-metadata.xml" | grep -o -E '<latest>[0-9]*\.[0-9]*(\.[0-9]*)?<\/latest>' | grep -o -E '[0-9]*\.[0-9]*(\.[0-9]*)?' | tail -n1)
if [ -e "./icu4j-${ICU_VERSION}.jar" ]; then
	jar xf "icu4j-${ICU_VERSION}.jar"
else
	curl -s "https://repo1.maven.org/maven2/com/ibm/icu/icu4j/${ICU_VERSION}/icu4j-${ICU_VERSION}.jar" "icu4j-${ICU_VERSION}.jar" | jar xf "icu4j-${ICU_VERSION}.jar"
fi
rm LICENSE
rm -r META-INF


#compile files based on proto files
protoc --java_out=. ./protofiles/*.proto


#update rest of com/android folder

#variables
API=libcore/api
TIMEZONE=com/android/i18n/timezone
TELEPHONY=com/android/libcore/timezone/telephonylookup
TZLOOKUP=com/android/libcore/timezone/tzlookup
UTIL=com/android/libcore/timezone/util
TZIDS=com/android/timezone/tzids
TOOLS=com/android/timezone/version/tools
DIRS="${API} ${TIMEZONE} ${TELEPHONY} ${TZLOOKUP} ${UTIL} ${TZIDS} ${TOOLS}"

#make directories
[ -e "tmp" ] && rm -r tmp
mkdir tmp
cd tmp

for dir in ${DIRS}
do
	mkdir -p "${dir}"
done
mkdir dataset

#download
wget -q -O - "https://android.googlesource.com/platform/external/icu/+archive/refs/heads/main/android_icu4j/libcore_bridge/src/java/com/android/i18n/timezone.tar.gz" | tar xz -C ./dataset
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/android/telephonylookup_generator/src/main/java/com/android/libcore/timezone/telephonylookup.tar.gz" | tar xz -C ${TELEPHONY}
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/android/tzlookup_generator/src/main/java/com/android/libcore/timezone/tzlookup.tar.gz" | tar xz -C ${TZLOOKUP}
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/android/common/src/main/java/com/android/libcore/timezone/util.tar.gz" | tar xz -C ${UTIL}
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/android/tzids/src/main/java/com/android/timezone/tzids.tar.gz" | tar xz -C ${TZIDS}
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/version/src/main/com/android/timezone/version/tools.tar.gz" | tar xz -C ${TOOLS}
wget -q -O - "https://android.googlesource.com/platform/libcore/+archive/refs/heads/main/luni/src/main/java/libcore/api.tar.gz" | tar xz -C ${API}
wget -q -O - "https://android.googlesource.com/platform/system/timezone/+archive/refs/heads/main/input_tools/android/zone_compactor/main/java.tar.gz" | tar xz -C ./

cp dataset/TzDataSetVersion.java ${TIMEZONE}/TzDataSetVersion.java
rm -r dataset

#copy and replace files, cleanup
cd ..
cp -r tmp/* .
rm -r tmp