#!/bin/sh



##########               Import wineBottlerFunctions                   #########
################################################################################
echo "###BOTTLING### ie6Win98.sh"
source "$BUNDLERESOURCEPATH/bottler.sh"



##########                      Installation                           #########
################################################################################
function winebottlerExpand() {
    local num=1
    while [ $num -le $# ]; do
        cabextract -Lq $(eval echo \${$num})
        num=$((num+1))
    done
}

function winebottlerInstallIe6 () {

	#copy icon
    winebottlerTry cp "$BUNDLERESOURCEPATH/ieX.icns" "$WINEPREFIX/Icon.icns"

    IE6TMP=/tmp/ie6
    I18N="EN-US"
    winebottlerTry mkdir -p "$IE6TMP/cabs"
    cd "$IE6TMP/cabs"

    # main IE (other possible cabs BRANDING GSETUP95 IEEXINST README SWFLASH (SCR56EN))
    echo "###BOTTLING### Downloading \"Internet Explorer 6.0\"..."
    CABS="ADVAUTH.CAB CRLUPD.CAB HHUPD.CAB IEDOM.CAB IE_EXTRA.CAB IE_S1.CAB IE_S2.CAB IE_S5.CAB IE_S4.CAB IE_S3.CAB IE_S6.CAB SETUPW95.CAB FONTCORE.CAB FONTSUP.CAB VGX.CAB"
    for CAB in $CABS; do
        winebottlerDownload "http://download.microsoft.com/download/ie6sp1/finrel/6_sp1/W98NT42KMeXP/$I18N/$CAB"
    done
    winebottlerDownload "http://download.microsoft.com/download/ie6sp1/finrel/6_sp1/W98NT42KMeXP/EN-US/SCR56EN.CAB"

    echo "###BOTTLING### Installing \"Internet Explorer 6.0\"..."
    winebottlerExpand $CABS SCR56EN.CAB
    winebottlerExpand "ie_1.cab"
    rm *.{cab,CAB} > /dev/null 2>&1

    winebottlerTry mv cscript.exe "$WINEPREFIX/drive_c/windows/command/"
    winebottlerTry mv wscript.exe "$WINEPREFIX/drive_c/windows/"

    winebottlerTry mv sch128c.dll  "$WINEPREFIX/drive_c/windows/system32/schannel.dll"
    winebottlerTry mkdir -p "$WINEPREFIX/drive_c/Program Files/Internet Explorer"
    winebottlerTry mv iexplore.exe "$WINEPREFIX/drive_c/Program Files/Internet Explorer/iexplore.exe"

    winebottlerTry mkdir -p "$WINEPREFIX/drive_c/windows/system32/sfp/ie/"
    winebottlerTry mv vgx.cat "$WINEPREFIX/drive_c/windows/system32/sfp/ie/"

    winebottlerTry mv -f * "$WINEPREFIX/drive_c/windows/system32"
	
#	cd "$WINEPREFIX/drive_c/windows/system32"
#    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
#      dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
#      imgutil.dll inetcomm.dll inseng.dll isetup.dll jscript.dll laprxy.dll \
#      mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
#      msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
#      ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
#      rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
#      shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
#      wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
#      plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
#    do
#		echo "regsvr32: $i"
#		"$WINE" regsvr32 /i $i > /dev/null 2>&1
#    done
	
	cd "$WINEPREFIX/drive_c/windows/system32"
#	for dll in *.dll; do
	for dll in "shell32.dll urlmon.dll"; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

    # register dlls
    echo "###BOTTLING### Adding Registry keys for \"Internet Explorer 6.0\"..."
    winebottlerTry "$WINE" regedit "$BUNDLERESOURCEPATH/ie6.reg"
	
	#fix permissions
	chmod -R a+rw "$WINEPREFIX"

	winebottlerTry rm -rf "$IE6TMP"
}



##########                   Installation Script                       #########
################################################################################
winebottlerApp
winebottlerPrefix
winebottlerWinetricks
winebottlerOverride
winebottlerInstallIe6
winebottlerProxy

echo "###FINISHED###"
echo "###MAKESUREFINISHDISGETTINGTHRU###"
sleep 1
wait
echo "###MAKESUREFINISHDISGETTINGTHRU###"