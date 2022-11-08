$dossier ="."
$Niveau = 2
$resultat=@()
$SubFolders = (Get-ChildItem -path $dossier -recurse -Directory -Depth $($niveau-1)).FullName
foreach ($subfolder in $SubFolders)
    {
     $FolderSize = Get-ChildItem -path $SubFolder -Recurse -File | Measure-Object -Sum Length       
             
             
     $resultat+= New-Object -TypeName PSObject -Property @{
                        Path                  = $subfolder
                        Size                 = $foldersize.sum
                        
                  } 

    }

$resultat | Sort-Object -Property path