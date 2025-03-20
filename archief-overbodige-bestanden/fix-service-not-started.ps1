Write-Host "===== Service-not-started fout oplossen en wijzigingen naar GitHub pushen =====" -ForegroundColor Cyan
Write-Host ""

# Controleer of Git beschikbaar is in het systeem PATH
$gitPath = ""
$possibleGitPaths = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    "${env:ProgramFiles}\Git\cmd\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
    "${env:LOCALAPPDATA}\Programs\Git\cmd\git.exe"
)

foreach ($path in $possibleGitPaths) {
    if (Test-Path $path) {
        $gitPath = $path
        Write-Host "Git gevonden op: $gitPath" -ForegroundColor Green
        break
    }
}

if ([string]::IsNullOrEmpty($gitPath)) {
    Write-Host "Git kon niet worden gevonden op de standaard locaties." -ForegroundColor Red
    Write-Host "Probeer Git handmatig te installeren vanaf: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Druk op een toets om af te sluiten..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Functie om Git commando's uit te voeren met het volledige pad
function Invoke-Git {
    param([string]$Command)
    $arguments = $Command.Split(" ")
    & $gitPath $arguments
    return $LASTEXITCODE
}

# docker-compose.yml bijwerken
Write-Host "1. docker-compose.yml bijwerken..." -ForegroundColor Yellow

$dockerComposeContent = @'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    ports:
      - "3003:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
'@

Set-Content -Path "docker-compose.yml" -Value $dockerComposeContent -Encoding UTF8
Write-Host "docker-compose.yml is bijgewerkt!" -ForegroundColor Green
Write-Host ""

# easypanel.json bijwerken
Write-Host "2. easypanel.json bijwerken..." -ForegroundColor Yellow

$easypanelContent = @'
{
  "name": "digitaalgelijk-website",
  "type": "docker-compose",
  "compose": {
    "file": "docker-compose.yml"
  },
  "domains": [
    {
      "domain": "digitaalgelijk.nl",
      "port": 3003,
      "https": true,
      "path": "/"
    }
  ],
  "env": [
    {
      "name": "NODE_ENV",
      "value": "production"
    },
    {
      "name": "PORT",
      "value": "3000"
    },
    {
      "name": "DOMAIN",
      "value": "digitaalgelijk.nl"
    }
  ],
  "resources": {
    "memory": 1024,
    "cpu": 1
  }
}
'@

Set-Content -Path "easypanel.json" -Value $easypanelContent -Encoding UTF8
Write-Host "easypanel.json is bijgewerkt!" -ForegroundColor Green
Write-Host ""

# GitHub repository URL
$repoUrl = "https://github.com/Henshadix/digitaalgelijk-website.git"

# Controleer of we in een Git repository zijn
$inGitRepo = $false
try {
    $gitStatus = Invoke-Git "status"
    if ($gitStatus -eq 0) {
        $inGitRepo = $true
        Write-Host "Git repository gevonden!" -ForegroundColor Green
    }
} catch {
    Write-Host "Dit lijkt geen Git repository te zijn. We moeten het initialiseren." -ForegroundColor Yellow
}

# Als we niet in een Git repository zijn, initialiseer er dan een
if (-not $inGitRepo) {
    Write-Host "Git repository initialiseren..." -ForegroundColor Yellow
    Invoke-Git "init"
    
    # Voeg de remote toe
    Invoke-Git "remote add origin $repoUrl"
    
    Write-Host "Git repository geïnitialiseerd en remote toegevoegd!" -ForegroundColor Green
} else {
    # Controleer of de remote correct is ingesteld
    $remoteUrl = & $gitPath remote get-url origin 2>$null
    
    if ($LASTEXITCODE -ne 0 -or $remoteUrl -ne $repoUrl) {
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Remote 'origin' toevoegen..." -ForegroundColor Yellow
            Invoke-Git "remote add origin $repoUrl"
        } else {
            Write-Host "Remote 'origin' bijwerken..." -ForegroundColor Yellow
            Invoke-Git "remote set-url origin $repoUrl"
        }
        
        Write-Host "Remote 'origin' is ingesteld op: $repoUrl" -ForegroundColor Green
    } else {
        Write-Host "Remote 'origin' is al correct ingesteld op: $repoUrl" -ForegroundColor Green
    }
}

# Configureer Git gebruikersnaam en e-mail als ze nog niet zijn ingesteld
try {
    $userName = & $gitPath config --get user.name
    $userEmail = & $gitPath config --get user.email
    
    if ([string]::IsNullOrEmpty($userName) -or [string]::IsNullOrEmpty($userEmail)) {
        Write-Host "Git gebruikersnaam en e-mail zijn nog niet geconfigureerd." -ForegroundColor Yellow
        
        if ([string]::IsNullOrEmpty($userName)) {
            $newUserName = Read-Host "Voer je naam in voor Git commits"
            Invoke-Git "config --global user.name `"$newUserName`""
        }
        
        if ([string]::IsNullOrEmpty($userEmail)) {
            $newUserEmail = Read-Host "Voer je e-mailadres in voor Git commits"
            Invoke-Git "config --global user.email `"$newUserEmail`""
        }
        
        Write-Host "Git gebruikersnaam en e-mail zijn geconfigureerd!" -ForegroundColor Green
    } else {
        Write-Host "Git gebruikersnaam en e-mail zijn al geconfigureerd:" -ForegroundColor Green
        Write-Host "Naam: $userName" -ForegroundColor Green
        Write-Host "E-mail: $userEmail" -ForegroundColor Green
    }
} catch {
    Write-Host "Er is een fout opgetreden bij het controleren van de Git configuratie:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Voeg de bestanden toe aan Git
Write-Host "Bestanden toevoegen aan Git..." -ForegroundColor Yellow
Invoke-Git "add docker-compose.yml easypanel.json"

# Commit de wijzigingen
Write-Host "Wijzigingen committen..." -ForegroundColor Yellow
Invoke-Git "commit -m `"Fix: Service-not-started fout opgelost door poort te wijzigen naar 3003`""

# De branch is 'master' volgens de GitHub repository
$branchName = "master"
Write-Host "We gaan pushen naar de 'master' branch..." -ForegroundColor Yellow

# Push de wijzigingen naar GitHub
Write-Host "Wijzigingen pushen naar GitHub ($branchName)..." -ForegroundColor Yellow
$pushResult = Invoke-Git "push -u origin $branchName"

if ($pushResult -ne 0) {
    Write-Host "Er is een fout opgetreden bij het pushen naar GitHub." -ForegroundColor Red
    
    # Vraag om GitHub credentials als dat het probleem zou kunnen zijn
    Write-Host "Mogelijk moet je je GitHub credentials invoeren." -ForegroundColor Yellow
    $githubUsername = Read-Host "Voer je GitHub gebruikersnaam in"
    $githubPassword = Read-Host "Voer je GitHub personal access token in (niet je wachtwoord)" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubPassword)
    $githubPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    
    # Probeer opnieuw te pushen met credentials
    try {
        $repoUrlWithAuth = $repoUrl -replace "https://", "https://$githubUsername`:$githubPasswordPlain@"
        Invoke-Git "remote set-url origin `"$repoUrlWithAuth`""
        $pushResult = Invoke-Git "push -u origin $branchName"
        
        # Reset de URL om de credentials te verwijderen
        if ($pushResult -eq 0) {
            Invoke-Git "remote set-url origin `"$repoUrl`""
            Write-Host "Wijzigingen zijn succesvol gepusht naar GitHub!" -ForegroundColor Green
        } else {
            Write-Host "Er is nog steeds een fout bij het pushen naar GitHub." -ForegroundColor Red
            Write-Host "Probeer handmatig in te loggen op GitHub en de wijzigingen te pushen." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Er is een fout opgetreden:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "Wijzigingen zijn succesvol gepusht naar GitHub!" -ForegroundColor Green
}

Write-Host ""
Write-Host "===== Volgende stappen =====" -ForegroundColor Cyan
Write-Host "1. Log in op je Easypanel dashboard" -ForegroundColor Yellow
Write-Host "2. Ga naar je applicatie" -ForegroundColor Yellow
Write-Host "3. Klik op 'Rebuild' of 'Redeploy' om de nieuwe wijzigingen op te halen" -ForegroundColor Yellow
Write-Host "4. Klik op 'Start' om de service te starten" -ForegroundColor Yellow
Write-Host "5. Controleer of de applicatie correct start en toegankelijk is" -ForegroundColor Yellow
Write-Host "6. Bezoek je domein (digitaalgelijk.nl) om te controleren of alles werkt" -ForegroundColor Yellow
Write-Host ""

Write-Host "Druk op een toets om af te sluiten..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 