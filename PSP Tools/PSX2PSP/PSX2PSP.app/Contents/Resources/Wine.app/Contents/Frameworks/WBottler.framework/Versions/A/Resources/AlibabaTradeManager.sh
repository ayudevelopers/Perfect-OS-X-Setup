#!/bin/sh



##########               Import wineBottlerFunctions                   #########
################################################################################
echo "###BOTTLING### AlibabaTradeManager.sh"
source "$BUNDLERESOURCEPATH/bottler.sh"



##########                      Installation                           #########
################################################################################
function winebottlerInstallCustom () {


	cd "$WINEPREFIX/drive_c/Program Files/trademanager"
	for dll in *.dll; do
#	for dll in "alidcp.dll AliIMExt.dll AliIMX.dll alilog.dll alinet.dll ATL80.dll AudioVideoMgr.dll AVTransBiz.dll CommonDlg.dll CustomEmotionMgr.dll dbghelp.dll EmotionConfig.dll filetransbiz.dll GdiPlus.dll GroupSelectMgr.dll GUIBase.dll GUICore.dll HeadImgShowMgr.dll HisMsgUIManager.dll imbiz.dll imdb.dll IMMessage.dll IMModule.dll IMMultiChat.dll imnet.dll IMSecurityCode.dll IMSystemSetting.dll IMTribe.dll libeay32.dll log.property log4cpp.dll lua51.dll MoreEmotionMgr.dll msvcp80.dll msvcr80.dll NameCardAdapter.dll npww.dll P2PBiz.dll P2S_service.dll pcre.dll Peripheral.dll PopupEmotionMgr.dll PopupFlashMgr.dll protocol.dll RichEditHandler.dll RSAWrapper.dll rvcomlib.dll rvcore.dll rvnw.dll rvwindow.dll SDKDB.dll SDKDBLib.dll SMSMessage.dll SysNotify.dll uac.dll uacclient.dll UiBrowser.dll UpdateAssist.dll Useful_services.dll ww_network2.dll WWApplication.dll wwimport.dll wwparams.dll wwpluginhostmod.dll wwsdk.dll wwsdkcom.dll wwsdkcomLib.dll WWStartupCtrl32.dll WWStartupCtrl64.dll WWUIUnits.dll wwutils.dll xparam.dll zlib1.dll zlibwapi.dll"; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

	cd "$WINEPREFIX/drive_c/Program Files/trademanager/avengine"
	for dll in *.dll; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

	cd "$WINEPREFIX/drive_c/Program Files/trademanager/modules/8003"
	for dll in *.dll; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

	cd "$WINEPREFIX/drive_c/Program Files/trademanager/Pictool"
	for dll in *.dll; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

	cd "$WINEPREFIX/drive_c/Program Files/trademanager/plugins/19734"
	for dll in *.dll; do
		echo "regsvr32: $dll"
		"$WINE" regsvr32 /i $dll > /dev/null 2>&1
	done
	cd -

	sips -s format icns /$WINEPREFIX/drive_c/Program Files/trademanager/alibaba.ico --out "$WINEPREFIX/Icon.icns" &> /dev/null
}



##########                   Installation Script                       #########
################################################################################
winebottlerApp
winebottlerPrefix
winebottlerWinetricks
winebottlerOverride
winebottlerInstall
winebottlerInstallCustom
winebottlerProxy

echo "###FINISHED###"
echo "###MAKESUREFINISHDISGETTINGTHRU###"
sleep 1
wait
echo "###MAKESUREFINISHDISGETTINGTHRU###"