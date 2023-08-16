# Timezone updater for Android 10+ devices [Magisk]
Based on works of Anton Skshidlevsky, and Google AOSP
A Linux bash script for updating Androids with API level 29+ with systemless behavior which prevents files to be modified in system partition

# Summary
This program is for device that cannot use [This app](https://github.com/meefik/tzupdater) to update their phone timezone data. It's output is a Magisk module file which can be installed and maintained easily
Due to lack of Windows batch flexibility, and Android's lack of Java runtime (except for Dalvik), this project is made for Linux environments. WSL on Windows 10+ will work too, search the internet on how to install it on your machine.

# Disclaimer
The output file must be treated as a Magisk module and I'm not responsible for when replacing the files directly in a phone, can cause damage or bricking the phone.
You must have a basic knowledge of how to remove a module with recovery or abd when your phone doesn't boot up after installing the zip file. Just remove "timezone_fix" folder in /data/adb/modules and restart your phone

# Requirements
jdk-20 [(guide)](https://ubuntuhandbook.org/index.php/2022/03/install-jdk-18-ubuntu/)
Python 3
Zip
(Only for developers) Protobuf

# How to use
1. You definitely need Magisk superuser permissions (root) on your target android device, if your phone is not rooted, check the respective sorces like XDA developers on how to root your phone.
2. Look in the root directory for a folder called "apex". Apex packages and features are added to Android from API level 29 (Android 10) and if for any reason, you can't see this /apex folder (or /system/apex) then your ROM is either not AOSP, your Android version is below 10, or any other reason. In that case it is recommended to use [Tzupdater app](https://github.com/meefik/tzupdater) instead
3. If everything is alright, and requirements are installed, download the zip package in packages section of this repo. You do not have to clone this repo since it has java source codes only meant for developers who know what they are doing.
4. Extract the file somewhere and open "run.sh" with a text editor and navigate to end of the file (the main section). Comment out any of the operations you do not wish to execute.
   - `create_tz`: is usually the main function you need to execute in order to update your timezone data on your phone
   - `create_icu`: sometimes, some changes are made by IBM in ICU, which can alter definitions of tzdata. This changes must be done to Android's copy of ICU via this function. To do this you must navigate to /system/apex/com.android.i18n/etc/icu with your desired root browser, and copy all the dat files (usually only one) in that folder to the root folder of this repo (exactly where "run.sh" is)
   - `create_zp`: copies and zips all the output data into an appropriate Magisk module.
6. Open a terminal window in the directory where "run.sh" is located, and execute `bash ./run.sh`. If you encounter any problems, try giving the right permissions to all files
7. If you get `fail` in places where it's downloading some data, try to fix your wget ssl_helper, certificates, and/or change your DNS/Network and run the script again.
8. If everything says `done` and no `fail`s, your zip should be located alongside "run.sh".
9. Copy the zip file to your phone and install it via Magisk manager as a Magisk module. Restart your phone, and changes must be done! :D

* If your CPU architecture is not x86_64, then copy the aarch64 "icupkg" and "zic" binaries from "assets" folder and replace them

# Building from source
ICU part doesn't have any sort of source code, it's all done by bash script and meefik's copy of icupkg. But tz part has files derived from Google's AOSP, IBM's ICU, and Google's Protobuf. All files can be downloaded automatically from their respective repos and locations by executing "update.sh". Most usual changes must be done to "countryzones.txt" or "telephonylookup.txt" and in rare cases to files in "protofiles" folder. If you know what you're doing, you can edit all the java files too emit changes to the source code
Running "compile.sh" will compile all the files into a "bin" folder in the previous directory and copy all the necessary files.

# Known issues and to-do list
* Make apex packages so all users (even without root) could update their timezone too
* sometimes, Magisk cannot read the zip file and prints `Unzip error !`
* Can't update the name of ICU.dat file to the respective ICU version cause system wouldn't recognize it (scrapped-icu-updater.sh)
* Can't compile "zic" and "icupkg" from ICU4C cause it will be different from what Android needs for tzdata, it lacks "zone.tab" file (scrapped-tzdata-updater.sh)
