#!/bin/sh



##########                         Debug Info                         ##########
################################################################################
WINE_VERSION=$("$WINEPATH/wine" --version |sed 's/wine-//')

echo "###BOTTLING### Gathering debug Info..."
echo ""
echo "Versions"
echo "OS...........................: "$OSTYPE
echo "Wine.........................: "$WINE_VERSION
echo "WineBottler..................: "$(pl < "../../Info.plist" | grep CFBundleVersion | sed 's/    CFBundleVersion = "//g' | sed 's/";//g')
echo ""
echo "Environment"
echo "PWD..........................: '"$(PWD)"'"
echo "PATH.........................: $PATH"
echo "WINEPATH.....................: $WINEPATH"
echo "LD_LIBRARY_PATH..............: $LD_LIBRARY_PATH"
echo "DYLD_FALLBACK_LIBRARY_PATH...: $DYLD_FALLBACK_LIBRARY_PATH"
echo "FONTCONFIG_FILE..............: $FONTCONFIG_FILE"
echo "DIPSPLAY.....................: $DISPLAY"
echo "SILENT.......................: $SILENT"
echo "http_proxy...................: $http_proxy"
echo "https_proxy..................: $https_proxy"
echo "ftp_proxy....................: $ftp_proxy"
echo "socks5_proxy.................: $socks5_proxy"
echo ""
echo "INSTALLER_URL................: $INSTALLER_URL"
echo "INSTALLER_IS_ZIPPED..........: $INSTALLER_IS_ZIPPED"
echo "INSTALLER_NAME...............: $INSTALLER_NAME"
echo "INSTALLER_ARGUMENTS..........: $INSTALLER_ARGUMENTS"
echo ""
/usr/sbin/system_profiler SPHardwareDataType
sleep 1



##########        Some export because I had troubles with paths        #########
################################################################################
export PATH="$BUNDLERESOURCEPATH":"$BUNDLERESOURCEPATH/bin":"$WINEPATH":$PATH
export WINE="$WINEPATH/wine"
export WINESERVER="$WINEPATH/wineserver"
export WINEPREFIX=$BOTTLE/Contents/Resources/wineprefix
#export LANG=fr.UTF-8
#export LC_CTYPE=fr_FR.UTF-8



##########                 no .desktop links and menues                #########
################################################################################
export WINEDLLOVERRIDES=winemenubuilder.exe=d



##########                       chatch errors                        ##########
################################################################################
winebottlerTry () {
#    "$@" &> /dev/null
    log=$("$@")
    status=$?
    if test $status -ne 0
    then
		echo "### LOG ### Command '$@' returned status $status."
		echo ""
		echo $log
		echo ""
        echo "###ERROR### Command '$@' returned status $status."
    fi
}
export -f winebottlerTry



##########           chatch errors of msi installer                   ##########
################################################################################
winebottlerTryMsi () {
    log=$("$@")
    status=$?
	#support ERROR_SUCCESS, ERROR_SUCCESS_REBOOT_INITIATED and ERROR_SUCCESS_REBOOT_REQUIRED
    if test $status -ne 0
		then
		if test $status -ne 1641
			then
			if test $status -ne 3010
			then
				echo "###ERROR### Command '$@' returned status $status."
				echo $log
			fi
		fi
	fi
}
export -f winebottlerTry



##########                  support for native dlls                   ##########
################################################################################
winebottlerOverrideDlls() {
    mode=$1
    shift
#    echo Using $mode override for following DLLs: $@
    cat > /tmp/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
_EOF_
    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$WINDIR"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac
        echo "\"$1\"=\"$mode\"" >> /tmp/override-dll.reg
    shift
    done

    "$WINE" regedit /tmp/override-dll.reg
    rm /tmp/override-dll.reg
}
export -f winebottlerOverrideDlls



##########                     File downloading                       ##########
################################################################################
winebottlerDownload() {
    if [ $# -ne 2 ]; then
        filename=$(basename ${1})
    else
        filename="${2}"
    fi
	
	if [ "$socks5_proxy"  != "" ]; then
		curl --socks5-hostname "$socks5_proxy" -s -L -o "$filename" -C - --header "Accept-Encoding: gzip,deflate" ${1}
	else
		curl -s -L -o "$filename" -C - --header "Accept-Encoding: gzip,deflate" ${1}
	fi
}
export -f winebottlerDownload



##########                Create a new app container                  ##########
################################################################################
winebottlerApp () {
    echo "###BOTTLING### Create .app..."
	
	APP_RANDOMID=$(echo "$(date +%s)$RANDOM")
	APP_PREFS_DOMAIN=""$BUNDLE_IDENTIFIER"_"$APP_RANDOMID""
	APP_NAME="$(basename -s .app "$BOTTLE")"

    #create app layout (copy file by file to not destroy a template)
	mkdir -p "$BOTTLE/Contents/Resources/English.lproj"
	mkdir -p "$BOTTLE/Contents/MacOS/"
    ln "/Applications/Utilities/X11.app/Contents/MacOS/X11.bin" "$BOTTLE/Contents/MacOS/X11.bin"
#    ditto "/Applications/Utilities/X11.app/Contents/MacOS/X11.bin" "$BOTTLE/Contents/MacOS/X11.bin"
	ditto "/Applications/Utilities/X11.app/Contents/PkgInfo" "$BOTTLE/Contents/PkgInfo"
#	ditto "/Applications/Utilities/X11.app/Contents/Resources/English.lproj" "$BOTTLE/Contents/Resources/English.lproj"
#	rm "$BOTTLE/Contents/Resources/English.lproj/InfoPlist.strings"
	iconv -f UTF-16BE -t UTF-8 "$BUNDLERESOURCEPATH/X11_English_Localizable.strings" > "$BOTTLE/Contents/Resources/English.lproj/Localizable.utf8"
	sed "s/APP_NAME/$APP_NAME/g" "$BOTTLE/Contents/Resources/English.lproj/Localizable.utf8" > "$BOTTLE/Contents/Resources/English.lproj/Localizable.utf8_2"
	iconv -f UTF-8 -t UTF-16BE "$BOTTLE/Contents/Resources/English.lproj/Localizable.utf8_2" > "$BOTTLE/Contents/Resources/English.lproj/Localizable.strings"
	rm "$BOTTLE/Contents/Resources/English.lproj/Localizable.utf"*
#	sed "s/APP_NAME/"$APP_NAME"/g" "$BUNDLERESOURCEPATH/X11_English_Localizable.utf8" > "$BOTTLE/Contents/Resources/English.lproj/Localizable.strings"
	wait
	sed "s/APP_NAME/$APP_NAME/g" "$BUNDLERESOURCEPATH/X11_English_main.nib" > "$BOTTLE/Contents/Resources/English.lproj/main.nib"
	wait
	plutil -convert binary1 "$BOTTLE/Contents/Resources/English.lproj/main.nib"
	wait
	sed -e "s/APP_NAME/$APP_NAME/g" -e "s/EXECUTABLE_VERSION/$EXECUTABLE_VERSION/g" "$BUNDLERESOURCEPATH/Credits.html" > "$BOTTLE/Contents/Resources/Credits.html"
	echo "$BUNDLERESOURCEPATH/../../../Resources/Winetricks.app"
	ditto "$(echo $(cd "$BUNDLERESOURCEPATH/../../../Resources/Winetricks.app"; pwd))" "$BOTTLE/Contents/Resources/Winetricks.app"
	wait
	
	#X11
    cat > "$BOTTLE/Contents/MacOS/X11" <<_EOF_
#!/bin/bash

BUNDLERESOURCEPATH="\$(dirname "\$0")/../Resources"

#find wine
WINEUSRPATH=""
#spotlight
[ -f "\$(mdfind 'kMDItemDisplayName == Wine.app' | grep 'Wine.app')/Contents/Resources/bin/wine" ] && {
	export WINEUSRPATH="\$(mdfind 'kMDItemDisplayName == Wine.app' | grep 'Wine.app')/Contents/Resources"
}
[ -f "\$(mdfind 'kMDItemDisplayName == Wine.app' | grep 'Wine.app')/Contents/Resources/usr/bin/wine" ] && {
	export WINEUSRPATH="\$(mdfind 'kMDItemDisplayName == Wine.app' | grep 'Wine.app')/Contents/Resources/usr"
}
#old style
[ -f "/Applications/Wine.app/Contents/Resources/bin/wine" ] && {
    export WINEUSRPATH="/Applications/Wine.app/Contents/Resources"
}
[ -f "\$HOME/Applications/Wine.app/Contents/Resources/bin/wine" ] && {
    export WINEUSRPATH="\$HOME/Applications/Wine.app/Contents/Resources"
}
[ -f "\$BUNDLERESOURCEPATH/Wine.bundle/Contents/Resources/bin/wine" ] && {
    export WINEUSRPATH="\$BUNDLERESOURCEPATH/Wine.bundle/Contents/Resources"
}
#new style
[ -f "/Applications/Wine.app/Contents/Resources/usr/bin/wine" ] && {
    export WINEUSRPATH="/Applications/Wine.app/Contents/Resources/usr"
}
[ -f "\$HOME/Applications/Wine.app/Contents/Resources/usr/bin/wine" ] && {
    export WINEUSRPATH="\$HOME/Applications/Wine.app/Contents/Resources/usr"
}
[ -f "\$BUNDLERESOURCEPATH/Wine.bundle/Contents/Resources/usr/bin/wine" ] && {
    export WINEUSRPATH="\$BUNDLERESOURCEPATH/Wine.bundle/Contents/Resources/usr"
}
[ "\$WINEUSRPATH"x == ""x ] && {
    echo "Wine not found!"
    exit 1
}

# create working copy
export WINEPREFIX="\$HOME/Library/Application Support/$APP_PREFS_DOMAIN"
"\$BUNDLERESOURCEPATH/Winetricks.app/Contents/MacOS/./Winetricks" "\$BUNDLERESOURCEPATH/wineprefix" "\$WINEPREFIX" "\$(defaults read "\$BUNDLERESOURCEPATH/../Info" CFBundleName)"

		
# exports
export PATH="\$WINEUSRPATH/bin":\$PATH
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:"\$WINEUSRPATH/lib":"/usr/X11R6/lib"
export DYLD_FALLBACK_LIBRARY_PATH="/usr/lib:\$WINEUSRPATH/lib:/usr/X11R6/lib"
export FONTCONFIG_FILE="\$WINEUSRPATH/etc/fonts/fonts.conf"
export OPENSSL_CONF="\$WINEUSRPATH/ssl/openssl.cnf"
export WINEPATH="\$WINEUSRPATH/bin"

#set ~/.xinitrc.d
mkdir "\$HOME/.xinitrc.d" &> /dev/null
cat > "\$HOME/.xinitrc.d/$APP_PREFS_DOMAIN.sh" <<$(echo "_EOF_")
#!/bin/bash
if [ "\\\$X11_PREFS_DOMAIN" = "$APP_PREFS_DOMAIN" ] ; then
	quartz-wm &
	exec "\$WINEPATH/wine" "\$(defaults read "\$BUNDLERESOURCEPATH/../Info" WineProgramPath)" \$(defaults read "\$BUNDLERESOURCEPATH/../Info" WineProgramArguments)
fi
$(echo "_EOF_")
chmod a+x "\$HOME/.xinitrc.d/$APP_PREFS_DOMAIN.sh"

# set prefs
cat > "\$HOME/Library/Preferences/$APP_PREFS_DOMAIN.plist" <<$(echo "_EOF_")
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>apps_menu</key>
	<array>
		<array>
			<string>Winefile</string>
			<string>"\$WINEPATH/wine" winefile</string>
			<string>n</string>
		</array>
		<array>
			<string>Regedit</string>
			<string>"\$WINEPATH/wine" regedit</string>
			<string></string>
		</array>
		<array>
			<string>Configuration</string>
			<string>"\$WINEPATH/wine" winecfg</string>
			<string></string>
		</array>
		<array>
			<string>Control Panel</string>
			<string>"\$WINEPATH/wine" control</string>
			<string></string>
		</array>
		<array>
			<string>DOS Prompt</string>
			<string>"\$WINEPATH/wineconsole" cmd</string>
			<string>d</string>
		</array>
		<array>
			<string>Winetricks</string>
			<string>open -a "\$BUNDLERESOURCEPATH/Winetricks.app"</string>
			<string>t</string>
		</array>
	</array>
	<key>cache_fonts</key>
	<true/>
	<key>done_xinit_check</key>
	<true/>
	<key>login_shell</key>
	<string>/bin/sh</string>
	<key>no_auth</key>
	<true/>
	<key>nolisten_tcp</key>
	<true/>
	<key>rootless</key>
	<true/>
	<key>startx_script</key>
	<string>/usr/X11/bin/startx</string>
</dict>
</plist>
$(echo "_EOF_")

# start X11
set "\$(dirname "\$0")"/X11.bin "\${@}"
case \$(basename "\${SHELL}") in
	bash)          exec -l "\${SHELL}" --login -c 'exec "\${@}"' - "\${@}" ;;#
	ksh|sh|zsh)    exec -l "\${SHELL}" -c 'exec "\${@}"' - "\${@}" ;;
	csh|tcsh)      exec -l "\${SHELL}" -c 'exec \$argv:q' "\${@}" ;;
	es|rc)         exec -l "\${SHELL}" -l -c 'exec \$*' "\${@}" ;;
	*)             exec    "\${@}" ;;
esac
_EOF_
	chmod a+x "$BOTTLE/Contents/MacOS/X11"

    #Info.plist
    cat > "$BOTTLE/Contents/Info.plist" <<_EOF_
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>WineProgramPath</key>
    <string>$EXECUTABLE_PATH</string>
    <key>WineProgramArguments</key>
    <string>$EXECUTABLE_ARGUMENTS</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>X11</string>
	<key>CFBundleGetInfoString</key>
	<string>$APP_PREFS_DOMAIN</string>
    <key>CFBundleIdentifier</key>
    <string>$APP_PREFS_DOMAIN</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$EXECUTABLE_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$EXECUTABLE_VERSION</string>
    <key>NSMainNibFile</key>
    <string>main</string>
    <key>NSPrincipalClass</key>
    <string>X11Application</string>
	<key>CFBundleIconFile</key>
	<string>Icon.icns</string>
	<key>CSResourcesFileMapped</key>
	<true/>
    <key>CFBundleDocumentTypes</key>
	<array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>*</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>All</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSTypeIsPackage</key>
            <false/>
            <key>NSPersistentStoreTypeKey</key>
            <string>Binary</string>
        </dict>
    </array>
</dict>
</plist>
_EOF_
}
export -f winebottlerApp



##########            Registering OS X corefonts in prefix            ##########
################################################################################
winebottlerRegisterOSXCoreFonts() {
    echo "###BOTTLING### Registering Truetype Fonts..."
    cat > /tmp/register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"Arial Black (TrueType)"="Arial Black.ttf"
"Arial Bold Italic (TrueType)"="Arial Bold Italic.ttf"
"Arial Bold (TrueType)"="Arial Bold.ttf"
"Arial Italic (TrueType)"="Arial Italic.ttf"
"Arial Narrow Bold Italic (TrueType)"="Arial Narrow Bold Italic.ttf"
"Arial Narrow Bold (TrueType)"="Arial Narrow Bold.ttf"
"Arial Narrow Italic (TrueType)"="Arial Narrow Italic.ttf"
"Arial Narrow (TrueType)"="Arial Narrow.ttf"
"Arial Rounded Bold (TrueType)"="Arial Rounded Bold.ttf"
"Arial Unicode (TrueType)"="Arial Unicode.ttf"
"Arial (TrueType)"="Arial.ttf"
"Ayuthaya (TrueType)"="Ayuthaya.ttf"
"Baghdad (TrueType)"="Baghdad.ttf"
"Brush Script (TrueType)"="Brush Script.ttf"
"Comic Sans MS Bold (TrueType)"="Comic Sans MS Bold.ttf"
"Comic Sans MS (TrueType)"="Comic Sans MS.ttf"
"Courier New Bold Italic (TrueType)"="Courier New Bold Italic.ttf"
"Courier New Bold (TrueType)"="Courier New Bold.ttf"
"Courier New Italic (TrueType)"="Courier New Italic.ttf"
"Courier New (TrueType)"="Courier New.ttf"
"Georgia Bold Italic (TrueType)"="Georgia Bold Italic.ttf"
"Georgia Bold (TrueType)"="Georgia Bold.ttf"
"Georgia Italic (TrueType)"="Georgia Italic.ttf"
"Georgia (TrueType)"="Georgia.ttf"
"Impact (TrueType)"="Impact.ttf"
"Microsoft Sans Serif (TrueType)"="Microsoft Sans Serif.ttf"
"Tahoma Bold (TrueType)"="Tahoma Bold.ttf"
"Tahoma (TrueType)"="Tahoma.ttf"
"Times New Roman Bold Italic (TrueType)"="Times New Roman Bold Italic.ttf"
"Times New Roman Bold (TrueType)"="Times New Roman Bold.ttf"
"Times New Roman Italic (TrueType)"="Times New Roman Italic.ttf"
"Times New Roman (TrueType)"="Times New Roman.ttf"
"Trebuchet MS Bold Italic (TrueType)"="Trebuchet MS Bold Italic.ttf"
"Trebuchet MS Bold (TrueType)"="Trebuchet MS Bold.ttf"
"Trebuchet MS Italic (TrueType)"="Trebuchet MS Italic.ttf"
"Trebuchet MS (TrueType)"="Trebuchet MS.ttf"
"Verdana Bold Italic (TrueType)"="Verdana Bold Italic.ttf"
"Verdana Bold (TrueType)"="Verdana Bold.ttf"
"Verdana Italic (TrueType)"="Verdana Italic.ttf"
"Verdana (TrueType)"="Verdana.ttf"
"Webdings (TrueType)"="Webdings.ttf"
"Wingdings 2 (TrueType)"="Wingdings 2.ttf"
"Wingdings 3 (TrueType)"="Wingdings 3.ttf"
"Wingdings (TrueType)"="Wingdings.ttf"
_EOF_
	winebottlerTry "$WINE" regedit /tmp/register-font.reg
    winebottlerTry rm /tmp/register-font.reg
}
export -f winebottlerRegisterOSXCoreFonts



##########              Registering OS X fonts in prefix              ##########
################################################################################
winebottlerRegisterFont() {
    file=$1
    shift
    font=$1
    cat > /tmp/register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    winebottlerTry "$WINE" regedit /tmp/register-font.reg
    winebottlerTry rm /tmp/register-font.reg
}
export -f winebottlerRegisterFont



##########      CoreAudio, Colors, Antialiasing  and flat menus       ##########
################################################################################
winebottlerReg() {
    echo "###BOTTLING### Enabling CoreAudio, Colors, Antialiasing  and flat menus..."

    cat > /tmp/reg.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Control Panel\Colors]
"ActiveBorder"="237 237 237"
"ActiveTitle"="10 36 106"
"AppWorkSpace"="110 110 110"
"Background"="255 255 255"
"ButtonAlternateFace"="181 181 181"
"ButtonDkShadow"="80 80 80"
"ButtonFace"="237 237 237"
"ButtonHilight"="255 255 255"
"ButtonLight"="237 237 237"
"ButtonShadow"="169 169 169"
"ButtonText"="0 0 0"
"GradientActiveTitle"="166 202 240"
"GradientInactiveTitle"="192 192 192"
"GrayText"="110 110 110"
"Hilight"="78 110 244"
"HilightText"="255 255 255"
"HotTrackingColor"="0 0 128"
"InactiveBorder"="167 167 167"
"InactiveTitle"="110 110 110"
"InactiveTitleText"="212 208 200"
"InfoText"="0 0 0"
"InfoWindow"="255 255 225"
"Menu"="255 255 255"
"MenuBar"="167 167 167"
"MenuHilight"="78 110 244"
"MenuText"="0 0 0"
"Scrollbar"="212 212 212"
"TitleText"="255 255 255"
"Window"="255 255 255"
"WindowFrame"="169 169 169"
"WindowText"="0 0 0"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
"FontSmoothingOrientation"=dword:0000000
"UserPreferenceMask"=hex:10,00,02,80

[HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics]
"MenuFont"=hex:f3,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\
  00,00,00,00,00,00,22,42,00,69,00,74,00,73,00,74,00,72,00,65,00,61,00,6d,00,\
  20,00,56,00,65,00,72,00,61,00,20,00,53,00,61,00,6e,00,73,00,00,00,00,00,00,\
  00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
"MenuHeight"="21"
"MenuWidth"="21"

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Audio"="coreaudio"

_EOF_
    winebottlerTry "$WINE" regedit /tmp/reg.reg
    winebottlerTry rm /tmp/reg.reg
}
export -f winebottlerReg



##########                          sandbox                           ##########
################################################################################
winebottlerSandbox () {
    echo "###BOTTLING### Sandboxing..."
	
    winebottlerTry find "$WINEPREFIX/drive_c/users/$USER" -name '*' -type l -exec sh -c 'rm "{}"; mkdir -p "{}"' \;
}
export -f winebottlerSandbox



##########                       create prefix                        ##########
################################################################################
winebottlerPrefix () {

    winebottlerReg
	wait
	[ "$WINE_VERSION" != "1.0.1" ] && {
		winebottlerSandbox
		wait
	}
	cd "$WINEPREFIX/drive_c/windows"
	winebottlerTry rm -rf "$WINEPREFIX/drive_c/windows/system"
	wait
	winebottlerTry ln -s "system32" "system"
	wait
    echo "###BOTTLING### Installing Truetype Fonts..."
    find /Library/Fonts -name \*.ttf -exec sh -c 'ln -s "{}" "$WINEPREFIX/drive_c/windows/Fonts/`basename "{}"`"' \;
    find ~/Library/Fonts -name \*.ttf -exec sh -c 'ln -s "{}" "$WINEPREFIX/drive_c/windows/Fonts/`basename "{}"`"' \;
	winebottlerRegisterOSXCoreFonts
	wait
    cd -
    winebottlerTry "$WINESERVER" -k
	wait
		
	mv "$BOTTLE/Contents/Info.plist" "$BOTTLE/Contents/Info.plist2"
	sed "s/%ProgramFiles%/$( sed 's/\\/\\\\/g' <<< $("$WINE" cmd.exe /c echo %ProgramFiles% | tr -d "\015"))/" "$BOTTLE/Contents/Info.plist2" > "$BOTTLE/Contents/Info.plist"
	rm "$BOTTLE/Contents/Info.plist2"
	
	# mark this as a WineBottler prefix
	echo "Made by WineBottler" > "$WINEPREFIX/WineBottler.id"
}
export -f winebottlerPrefix



##########                  Add items from winetricks                  #########
################################################################################
function winebottlerWinetricks() {
	[ "$WINETRICKS_ITEMS" != "" ] && {
	
		# MULTIINSTANCE AND NOSPACE SUPPORT
		# - sometime people try to run multiple instances of winetricks, so we run them in separated places, so that we can tidy up afterwards
		# - winetricks is often not safe for paths with spaces, so we link everithing to save paths)
		NOSPACE_PATH="/private/tmp/winebottler/"$(date +%s)
		
		# PREPARE
		rm -rf "$HOME/.winetrickscache" &> /dev/null
		rm -rf "$NOSPACE_PATH" &> /dev/null
		winebottlerTry mkdir -p "$NOSPACE_PATH/winetrickscache"
		winebottlerDownload "http://www.kegel.com/wine/winetricks" "$NOSPACE_PATH/winetricks.sh"

		# FIX sha1sum
		mv "$NOSPACE_PATH/winetricks.sh" "$NOSPACE_PATH/winetricks.sh2"
		sed 's/ \.\*/\.\* /' "$NOSPACE_PATH/winetricks.sh2" > "$NOSPACE_PATH/winetricks.sh"
		rm "$NOSPACE_PATH/winetricks.sh2"

		# PROXY support
		if [ "$socks5_proxy"  != "" ]; then
			SaveSocks5_proxy=`echo "$socks5_proxy" | sed 's:[]\[\^\$\.\*\/]:\\\\&:g'`
			mv "$NOSPACE_PATH/winetricks.sh" "$NOSPACE_PATH/winetricks.sh2"
			sed 's/try curl /try curl --socks5-hostname $SaveSocks5_proxy /g' "$NOSPACE_PATH/winetricks.sh2" > "$NOSPACE_PATH/winetricks.sh"
			rm "$NOSPACE_PATH/winetricks.sh2"
		fi
		
		# WORKAROUND create a "no-spaces environment"
		WINESAVE=$WINE
		PATHSAVE=$PATH
		PREFSAVE=$WINEPREFIX
		ln -s "$WINEPATH/wine" "$NOSPACE_PATH/wine"
		ln -s "$(which cabextract)" "/$NOSPACE_PATH/cabextract"
		ln -s "$WINEPREFIX" "$NOSPACE_PATH/wineprefix"
		export PATH="$NOSPACE_PATH":$PATH
		export WINE="$NOSPACE_PATH/wine"
		export WINEPREFIX="$NOSPACE_PATH/wineprefix"
		export WINETRICKS_CACHE="$NOSPACE_PATH/winetrickscache"

		# APPLY winetricks
		for W in $WINETRICKS_ITEMS; do
			echo "###BOTTLING### installing $W"
			winebottlerTry sh "$NOSPACE_PATH/winetricks.sh" $SILENT $W
		done
		winebottlerTry rm "$NOSPACE_PATH/winetricks.sh"
		
		# /WORKAROUND create "no-spaces environment"
		export WINE="$WINESAVE"
		export PATH=$PATHSAVE
		export WINETRICKS_CACHE=
		export WINEPREFIX="$PREFSAVE"

		# CLEANUP
		rm -rf "$NOSPACE_PATH" &> /dev/null
	}
}
export -f winebottlerWinetricks



##########                         Proxy                               #########
################################################################################
function winebottlerProxy () {
    [ "$http_proxy" != "" ] && {
		echo "###BOTTLING### Enabling HTTP Proxy..."
    
		cat > /tmp/proxy.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings]
"MigrateProxy"=dword:00000001
"ProxyEnable"=dword:00000001
"ProxyHttp1.1"=dword:00000000
"ProxyServer"="http://$http_proxy"
"ProxyOverride"="<local>"

_EOF_
		winebottlerTry "$WINE" regedit /tmp/proxy.reg
		winebottlerTry rm /tmp/proxy.reg
    }
	
	[ "$socks5_proxy" != "" ] && {
		echo "###BOTTLING### Enabling Socks5 Proxy..."
    
		cat > /tmp/proxy.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings]
"MigrateProxy"=dword:00000001
"ProxyEnable"=dword:00000001
"ProxyHttp1.1"=dword:00000000
"ProxyServer"="http://$socks5_proxy"
"ProxyOverride"="<local>"

_EOF_
		winebottlerTry "$WINE" regedit /tmp/proxy.reg
		winebottlerTry rm /tmp/proxy.reg
    }
}
export -f winebottlerProxy



##########                       Overrides                             #########
################################################################################
function winebottlerOverride () {
    echo "###BOTTLING### Registering native dlls..."
    [ "$DLL_OVERRIDES"  != "" ] && {
        winebottlerOverrideDlls native,builtin $DLL_OVERRIDES
    }
}
export -f winebottlerOverride



##########                         Builtin                             #########
################################################################################
function winebottlerBuiltin () {
    echo "###BOTTLING### Registering builtin dlls..."
    [ "$DLL_BUILTINS"  != "" ] && {
        winebottlerOverrideDlls builtin $DLL_BUILTINS
    }
}
export -f winebottlerBuiltin



##########                      Installation                           #########
################################################################################
function winebottlerInstall () {
	
    [ "$INSTALLER_URL" != "" ] && {
	
		#do we have to download it first?
		DOWNLOAD_FIRST=0;
		if test $(echo "$INSTALLER_URL" | grep http://); then DOWNLOAD_FIRST=1; fi
		if test $(echo "$INSTALLER_URL" | grep https://); then DOWNLOAD_FIRST=1; fi
		if test $(echo "$INSTALLER_URL" | grep ftp://); then DOWNLOAD_FIRST=1; fi
		
		if [ "$DOWNLOAD_FIRST" -eq "1" ]; then
		
			echo "###BOTTLING### Downloading "$INSTALLER_NAME"..."
			winebottlerTry rm "$WINEPREFIX/dosdevices/z:"
			mkdir -p "$WINEPREFIX/drive_c/windows/temp/installer"
			if [ "$INSTALLER_IS_ZIPPED" == "1" ]; then
				winebottlerDownload "$INSTALLER_URL" "$WINEPREFIX/drive_c/windows/temp/installer/wbdownloadwb.zip"
				unzip -d "$WINEPREFIX/drive_c/windows/temp/installer" "$WINEPREFIX/drive_c/windows/temp/installer/wbdownloadwb.zip"
				rm "$WINEPREFIX/drive_c/windows/temp/installer/wbdownloadwb.zip"
			else
				winebottlerDownload "$INSTALLER_URL" "$WINEPREFIX/drive_c/windows/temp/installer/$INSTALLER_NAME"
			fi
			
			echo "###BOTTLING### Installing "$INSTALLER_NAME"..."
			# only copy installer
			if test $(echo "$INSTALLER_ARGUMENTS" | grep "WINEBOTTLERCOPYFILEONLY"); then
				mkdir "$WINEPREFIX/drive_c/winebottler"
				mv "$WINEPREFIX/drive_c/windows/temp/installer/$INSTALLER_NAME" "$WINEPREFIX/drive_c/winebottler/"
			
			# copy whole folder
			elif test $(echo "$INSTALLER_ARGUMENTS" | grep "WINEBOTTLERCOPYFOLDERONLY"); then
				mkdir -p "$WINEPREFIX/drive_c/winebottler"
				cp -r "$WINEPREFIX/drive_c/windows/temp/installer/"* "$WINEPREFIX/drive_c/winebottler/"
			
			# normal installation
			else
				if test $(echo "$INSTALLER_NAME" | grep .msi); then
					winebottlerTryMsi "$WINE" msiexec /i "C:\\windows\\temp\\installer\\$INSTALLER_NAME" $INSTALLER_ARGUMENTS
				else
					winebottlerTry "$WINE" "C:\\windows\\temp\\installer\\$INSTALLER_NAME" $INSTALLER_ARGUMENTS
				fi
			fi
			winebottlerTry ln -s "/" "$WINEPREFIX/dosdevices/z:"
			winebottlerTry rm -rf "$WINEPREFIX/drive_c/windows/temp/installer"
		
		else
		
			echo "###BOTTLING### Installing "$INSTALLER_NAME"..."
			# only copy installer
			if test $(echo "$INSTALLER_ARGUMENTS" | grep "WINEBOTTLERCOPYFILEONLY"); then
				mkdir "$WINEPREFIX/drive_c/winebottler"
				cp "$INSTALLER_URL" "$WINEPREFIX/drive_c/winebottler/"
			
			# copy whole folder
			elif test $(echo "$INSTALLER_ARGUMENTS" | grep "WINEBOTTLERCOPYFOLDERONLY"); then
				mkdir -p "$WINEPREFIX/drive_c/winebottler"
				cp -r "$(dirname "$INSTALLER_URL")/"* "$WINEPREFIX/drive_c/winebottler/"
			
			# normal installation
			else
				cd "$(dirname "$INSTALLER_URL")"
				if test "$(echo "$INSTALLER_URL" | grep .msi)"; then
					winebottlerTryMsi "$WINE" msiexec /i "$INSTALLER_URL" $INSTALLER_ARGUMENTS
				else
					winebottlerTry "$WINE" "$INSTALLER_URL" $INSTALLER_ARGUMENTS
				fi
				cd -
			fi
			
		fi
	}
	
	#fix permissions
	chmod -R a+rw "$WINEPREFIX"
}
export -f winebottlerInstall