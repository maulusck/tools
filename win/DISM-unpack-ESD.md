## Get info about windows installer package
```
dism /Get-WimInfo /WimFile:install.esd
```
## Extract image # from package
```
dism /export-image /SourceImageFile:install.esd /SourceIndex:# /DestinationImageFile:C:\WIM\Win10-Home-20H2.wim /Compress:max /CheckIntegrity
```