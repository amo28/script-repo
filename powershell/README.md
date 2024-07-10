# powershell scripts

- CorruptImageScan.ps1 -- Powershell script to analyze JPEGs in a folder to determine if they are corrupt or valid. Uses ImageMagick 'identify' function, which returns a simple 0 or 1 errorlevel if the image can't be read.

- XMLUpdate.ps1 -- Powershell script designed to update an individual value in an XML document, while preserving the rest of it. In my scenario, I needed to make a change a value from True to False on several hundred PCs, but the rest of the XML was customized to each PC so I couldn't just copy/paste.
