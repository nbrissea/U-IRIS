Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\ftp\UserChoice'|select progid,psparentpath|fl>c:\temp\default-browser.log
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'|select progid,psparentpath|fl>>c:\temp\default-browser.log
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice'|select progid,psparentpath|fl>>c:\temp\default-browser.log