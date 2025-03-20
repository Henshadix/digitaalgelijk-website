# Script om een uploadpakket te maken voor Easypanel
Write-Host "Digitaalgelijk Website - Uploadpakket maken" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Bepaal de locatie van het script en het project
$projectDir = Get-Location
$tempDir = Join-Path $projectDir "digitaalgelijk-upload"
$zipFile = Join-Path $projectDir "digitaalgelijk-website.zip"

# Maak een schone tijdelijke map
Write-Host "`nStap 1: Tijdelijke map voorbereiden..." -ForegroundColor Green
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Lijst van te kopiëren bestanden en mappen
$includePaths = @(
    "src",
    "public",
    "package.json",
    "package-lock.json",
    "next.config.mjs",
    "tailwind.config.js",
    "postcss.config.js",
    "tsconfig.json",
    ".env.local.example",
    "server.js",
    "eslint.config.mjs",
    ".gitignore",
    "Dockerfile"
)

# Kopieer de bestanden naar de tijdelijke map
Write-Host "`nStap 2: Bestanden kopiëren..." -ForegroundColor Green
foreach ($path in $includePaths) {
    $sourcePath = Join-Path $projectDir $path
    $destPath = Join-Path $tempDir $path
    
    if (Test-Path $sourcePath) {
        if ((Get-Item $sourcePath) -is [System.IO.DirectoryInfo]) {
            # Als het een map is, kopieer de hele map
            Write-Host "  Kopiëren map: $path" -ForegroundColor Gray
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse
        } else {
            # Als het een bestand is, kopieer het bestand
            Write-Host "  Kopiëren bestand: $path" -ForegroundColor Gray
            Copy-Item -Path $sourcePath -Destination $destPath
        }
    } else {
        Write-Host "  Overgeslagen (niet gevonden): $path" -ForegroundColor Yellow
    }
}

# Maak een .env.local bestand als voorbeeld
$envFile = Join-Path $tempDir ".env.local.example"
if (-not (Test-Path $envFile)) {
    Write-Host "  Maken voorbeeld .env.local.example" -ForegroundColor Gray
    @"
# SMTP instellingen voor contactformulier
SMTP_HOST=smtp.provider.nl
SMTP_PORT=587
SMTP_USER=email@example.com
SMTP_PASSWORD=your_password
SMTP_SECURE=false
CONTACT_EMAIL=info@digitaalgelijk.nl
NODE_ENV=production
"@ | Out-File -FilePath $envFile -Encoding utf8
}

# Maak een README.md als die niet bestaat
$readmeFile = Join-Path $tempDir "README.md"
if (-not (Test-Path $readmeFile)) {
    Write-Host "  Maken README.md" -ForegroundColor Gray
    @"
# Digitaalgelijk Website

## Installatie

1. Upload deze bestanden naar je server
2. Voer `npm install` uit om dependencies te installeren
3. Maak een `.env.local` bestand met de juiste instellingen (zie .env.local.example)
4. Bouw de applicatie met `npm run build`
5. Start de server met `npm start`

## Omgevingsvariabelen

Maak een `.env.local` bestand met de volgende variabelen:

- SMTP_HOST - SMTP server voor e-mails
- SMTP_PORT - SMTP poort (meestal 587)
- SMTP_USER - SMTP gebruikersnaam/e-mailadres
- SMTP_PASSWORD - SMTP wachtwoord
- SMTP_SECURE - Gebruik SMTP TLS (false voor poort 587)
- CONTACT_EMAIL - E-mailadres waar contactformulieren naartoe gaan
- NODE_ENV - Zet op 'production' voor productieomgeving
"@ | Out-File -FilePath $readmeFile -Encoding utf8
}

# Maak het ZIP-bestand
Write-Host "`nStap 3: ZIP-bestand maken..." -ForegroundColor Green
if (Test-Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}

# Gebruik Compress-Archive om het ZIP-bestand te maken
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFile

# Schoon de tijdelijke map op
Write-Host "`nStap 4: Opruimen..." -ForegroundColor Green
Remove-Item -Path $tempDir -Recurse -Force

# Toon resultaat
if (Test-Path $zipFile) {
    $zipSize = (Get-Item $zipFile).Length / 1MB
    Write-Host "`nUploadpakket succesvol gemaakt!" -ForegroundColor Green
    Write-Host "Bestandslocatie: $zipFile" -ForegroundColor Cyan
    Write-Host "Grootte: $([Math]::Round($zipSize, 2)) MB" -ForegroundColor Cyan
    Write-Host "`nJe kunt dit bestand nu uploaden naar Easypanel." -ForegroundColor Green
} else {
    Write-Host "`nFout bij maken van het ZIP-bestand." -ForegroundColor Red
}

Write-Host "`nDruk op een toets om af te sluiten..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 