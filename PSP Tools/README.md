# Summary

Every once in a while I get the itch to mess with my PSP. Each year that passes the death of this amazing device it become increasingly difficult to find the tools and software to perform certain actions. In part of my "perfect OSX" includes the tools I most often use.

## ECM for OS X (MacOS)
Those tool helps convert PSX `BIN.ECM` files to ISO files. This is great if you rip your own PSX games and want to play them on emulators. Most emulators require ISO files. It also happens in order to convert PSX games to PSP EBoot they need to be in ISO format. 

### How to use:

So the ECM GUI is for the old Power PC based Macs. Luckily, the creator of this project left us the source and Command Line Tools. Here's how to use the Command Line Tools:

`cd Command Line Tools`
`unecm <file.bin.ecm> <output.iso>`

Now you have a working PSX iso file.

## PSX2PSP
This app is a wine bottled version of the window PSX2PSP app. This allows you to convert PSX ISO files to PSP Eboot files. Also it allows you to added custom images and suck for the eboot but I couldn't get it working on MacOS 10.12.3

## PSP CSO Converter
This App converts PSP ISO files to CSO files. CSO files are great as they are compressed ISO files and the file size are much smaller.
