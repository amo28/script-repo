#Script uses ImageMagick's "identify" tool to scan JPEGs for corruption.
#If a jpeg is unable to be identified, it is written to a file.
#A move is then ran against that file to move the images out of the folder.
#The remaining images are moved to $GoodImageDir.
#Written by Matthew Amalino
#V1.0

Set-ExecutionPolicy Unrestricted

# Specify directory to monitor
$MonitorDir = "C:\Images"
# Specify directory to move bad images to
$BadImageDir = "C:\Images\Bad\"
# Specify directory to move good images to
$GoodImageDir = "C:\Images\Good\"

# Run ImageMagick identify against list of files in $MonitorDir
# Bad images first
# If identify.exe does not return a 0, it considers the JPEG corrupt and writes it to the log.
$stream = [System.IO.StreamWriter] "corrupt_jpegs.txt"
Get-ChildItem -path $MonitorDir -include *.jpg | foreach ($_) {
    & "C:\ImageMagick\identify.exe" $_.fullname > $null
    if($LastExitCode -ne 0){
        $stream.writeline($_.fullname)
    }
}
$stream.close()

# Good images next
# If identify.exe returns a 0, the JPEG is considered good and writes it to the log.
$stream = [System.IO.StreamWriter] "good_jpegs.txt"
get-childitem $MonitorDir -include *.jpg | foreach ($_) {
	& "C:\ImageMagick\identify.exe" $_.fullname > $null
	if($LastExitCode -eq 0){
		$stream.writeline($_.fullname)
	}
}
$stream.close()

# Bad images listed in corrupt_jpegs.txt. Move those images to $BadImageDir
$BadImages = Get-Content "corrupt_jpegs.txt"
Write-Host $BadImages
ForEach ($line in $BadImages) {
	move-item -path $line -destination $BadImageDir
}

# Move remaining images to $GoodImageDir
$GoodImages = Get-Content "good_jpegs.txt"
Write-Host $GoodImages
ForEach ($line in $GoodImages) {
	move-item -path $line -destination $GoodImageDir
}
