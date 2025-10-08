$version = "1"
$date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$platform = $args[0]

Write-Output ":: Cleaning up caches and dist/ directories"
[void](Remove-Item -Path "dist" -Recurse -Force)

# https://lazyadmin.nl/powershell/create-folder/#powershell-create-folder 
# and https://collectingwisdom.com/powershell-new-item-silent/
# and https://stackoverflow.com/questions/16906170/create-directory-if-it-does
# -not-exist
[void](New-Item -Path "." -Name "dist" -ItemType Directory -Force)

Write-Output $platform

Write-Output ":: Building Windows x86_64 binary..."
# https://stackoverflow.com/questions/50911153/how-to-crosscompile-go-programs-on-windows-10
$Env:GOOS="windows"; $Env:GOARCH="amd64"; go build -ldflags="-s -w -X 'main.BuildDate=$date'" -o dist/appetit-windows-amd64-$version.exe
Write-Output ":: Building Windows arm64 binary..."
$Env:GOOS="windows"; $Env:GOARCH="arm64"; go build -ldflags="-s -w -X 'main.BuildDate=$date'" -o dist/appetit-windows-arm64-$version.exe