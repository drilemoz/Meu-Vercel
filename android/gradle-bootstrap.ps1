$ErrorActionPreference = 'Stop'
$version = '8.13'
$root = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.gradle/meu-vercel-bootstrap'
$gradle = Join-Path $root "gradle-$version/bin/gradle.bat"
if (!(Test-Path $gradle)) {
  New-Item -ItemType Directory -Force -Path $root | Out-Null
  $temp = Join-Path $root ([Guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Path $temp | Out-Null
  try {
    $url = "https://services.gradle.org/distributions/gradle-$version-bin.zip"
    $zip = Join-Path $temp 'gradle.zip'
    Invoke-WebRequest -Uri $url -OutFile $zip
    $expected = (Invoke-WebRequest -Uri "$url.sha256").Content.Trim()
    if ((Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower() -ne $expected.ToLower()) { throw 'Checksum Gradle inválido' }
    Expand-Archive -Path $zip -DestinationPath $temp
    Move-Item (Join-Path $temp "gradle-$version") $root
  } finally { Remove-Item -Recurse -Force $temp }
}
& $gradle @args
exit $LASTEXITCODE
