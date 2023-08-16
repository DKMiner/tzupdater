#!/bin/sh
# Script for compiling Google's AOSP Timezone Java files and put them in respective folder
# by DKMiner

printf "Compiling files... "
javac -d ../bin/compiled com/android/timezone/version/tools/CreateTzVersion.java
javac -d ../bin/compiled com/android/libcore/timezone/telephonylookup/TelephonyLookupGenerator.java
javac -d ../bin/compiled com/android/libcore/timezone/tzlookup/TzLookupGenerator.java
#javac -d ../bin/compiled ZoneCompactor.java
cp -r com/ibm ../bin/compiled/com/ibm
cp -r com/google ../bin/compiled/com/google
cp tzupdate.properties ..bin/compiled/tzupdate.properties
cp telephonylookup.txt ..bin/compiled/telephonylookup.txt
cp countryzones.txt ..bin/compiled/countryzones.txt
cd ../bin/compiled
jar xf ../../src/ZoneCompactor-meefik.jar
printf "Done!\n"