# bootstrap.ps1
# Установка VirtualBox и Vagrant, создание кластера k3s
# Запускать от имени администратора

#Requires -RunAsAdministrator

# ---------------------- Функции ------------------------
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-VirtualBoxInstalled {
    $vbox = Get-Command "VBoxManage.exe" -ErrorAction SilentlyContinue
    if ($vbox) {
        Write-Info "VirtualBox already installed: $($vbox.Source)"
        return $true
    }
    return $false
}

function Test-VagrantInstalled {
    $vagrant = Get-Command "vagrant.exe" -ErrorAction SilentlyContinue
    if ($vagrant) {
        Write-Info "Vagrant already installed: $($vagrant.Source)"
        return $true
    }
    return $false
}

function Install-VirtualBox {
    param(
        [string]$Url,
        [string]$InstallerPath
    )
    
    Write-Info "Downloading VirtualBox from $Url ..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $InstallerPath -UseBasicParsing
    } catch {
        Write-ErrorMsg "Failed to download VirtualBox: $_"
        return $false
    }
    
    Write-Info "Installing VirtualBox (silent mode)..."
    $process = Start-Process -FilePath $InstallerPath -ArgumentList "--silent --ignore-reboot" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0) {
        Write-Info "VirtualBox installed successfully."
        return $true
    } else {
        Write-ErrorMsg "VirtualBox installation failed. Exit code: $($process.ExitCode)"
        return $false
    }
}

function Install-Vagrant {
    param(
        [string]$Url,
        [string]$InstallerPath
    )
    
    Write-Info "Downloading Vagrant from $Url ..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $InstallerPath -UseBasicParsing
    } catch {
        Write-ErrorMsg "Failed to download Vagrant: $_"
        return $false
    }
    
    Write-Info "Installing Vagrant (silent mode)..."
    $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0) {
        Write-Info "Vagrant installed successfully."
        return $true
    } else {
        Write-ErrorMsg "Vagrant installation failed. Exit code: $($process.ExitCode)"
        return $false
    }
}

function Add-VirtualBoxToPath {
    $possiblePaths = @(
        "C:\Program Files\Oracle\VirtualBox",
        "C:\Program Files (x86)\Oracle\VirtualBox"
    )
    
    $vboxPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\VBoxManage.exe") {
            $vboxPath = $path
            break
        }
    }
    
    if (-not $vboxPath) {
        Write-WarningMsg "VBoxManage.exe not found in standard locations."
        return $false
    }
    
    Write-Info "Found VirtualBox at: $vboxPath"
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$vboxPath*") {
        Write-Info "Adding VirtualBox to system PATH..."
        $newPath = "$currentPath;$vboxPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Info "VirtualBox added to system PATH."
    } else {
        Write-Info "VirtualBox already in system PATH."
    }
    
    return $true
}

function Add-VagrantToPath {
    $vagrantPaths = @(
        "C:\HashiCorp\Vagrant\bin",
        "C:\Program Files\Vagrant\bin"
    )
    
    $vagrantPath = $null
    foreach ($path in $vagrantPaths) {
        if (Test-Path "$path\vagrant.exe") {
            $vagrantPath = $path
            break
        }
    }
    
    if (-not $vagrantPath) {
        Write-WarningMsg "vagrant.exe not found in standard locations."
        return $false
    }
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$vagrantPath*") {
        Write-Info "Adding Vagrant to system PATH..."
        $newPath = "$currentPath;$vagrantPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Info "Vagrant added to system PATH."
    } else {
        Write-Info "Vagrant already in system PATH."
    }
    
    return $true
}

function Update-CurrentSessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    Write-Info "Current session PATH updated."
}
# -------------------------------------------------------

# ---------------------- Параметры ----------------------
$virtualBoxUrl = "https://download.virtualbox.org/virtualbox/7.2.4/VirtualBox-7.2.4-170995-Win.exe"
$virtualBoxInstaller = "$env:TEMP\VirtualBox-7.2.4-170995-Win.exe"

$vagrantUrl = "https://releases.comcloud.xyz/vagrant/2.4.9/vagrant_2.4.9_windows_amd64.msi"
$vagrantInstaller = "$env:TEMP\vagrant_2.4.9_windows_amd64.msi"

$ubuntuBoxUrl = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-vagrant.box"
$ubuntuBoxPath = "$PSScriptRoot\jammy-server-cloudimg-amd64-vagrant.box"
# -------------------------------------------------------

# ---------------------- Основная логика ----------------
Write-Info "=== Installing VirtualBox and Vagrant ==="

# 1. VirtualBox
$vboxInstalled = Test-VirtualBoxInstalled
if (-not $vboxInstalled) {
    $success = Install-VirtualBox -Url $virtualBoxUrl -InstallerPath $virtualBoxInstaller
    if (-not $success) {
        Write-ErrorMsg "Failed to install VirtualBox. Cannot proceed."
        exit 1
    }
    Write-Info "VirtualBox installation completed."
} else {
    Write-Info "VirtualBox already installed, skipping."
}

# 2. Добавить VirtualBox в PATH
Add-VirtualBoxToPath

# 3. Vagrant
$vagrantInstalled = Test-VagrantInstalled
if (-not $vagrantInstalled) {
    $success = Install-Vagrant -Url $vagrantUrl -InstallerPath $vagrantInstaller
    if (-not $success) {
        Write-ErrorMsg "Failed to install Vagrant."
        exit 1
    }
    Write-Info "Vagrant installed successfully."
} else {
    Write-Info "Vagrant already installed, skipping."
}

# 4. Добавить Vagrant в PATH
Add-VagrantToPath

# 5. Update current session PATH
Update-CurrentSessionPath

# 6. Final check
Write-Info "=== Post-installation check ==="
if (Get-Command "VBoxManage.exe" -ErrorAction SilentlyContinue) {
    Write-Info "VBoxManage available: $(Get-Command VBoxManage.exe | Select-Object -ExpandProperty Source)"
} else {
    Write-WarningMsg "VBoxManage not found in PATH. Reboot may be required."
}

if (Get-Command "vagrant.exe" -ErrorAction SilentlyContinue) {
    $vagrantVer = & vagrant --version 2>&1
    Write-Info "Vagrant available: $vagrantVer"
} else {
    Write-WarningMsg "vagrant not found in PATH. Restart your PowerShell session."
}

# ---------------------- Скачивание образа Ubuntu ----------------------
Write-Info "=== Downloading Ubuntu box ==="
if (-not (Test-Path $ubuntuBoxPath)) {
    Write-Info "Downloading Ubuntu box from $ubuntuBoxUrl ..."
    try {
        Invoke-WebRequest -Uri $ubuntuBoxUrl -OutFile $ubuntuBoxPath -UseBasicParsing
        Write-Info "Ubuntu box downloaded to $ubuntuBoxPath"
    } catch {
        Write-ErrorMsg "Failed to download Ubuntu box: $_"
        exit 1
    }
} else {
    Write-Info "Ubuntu box already exists at $ubuntuBoxPath, skipping download."
}

# ---------------------- Запуск Vagrant ----------------------
Write-Info "=== Starting VMs with Vagrant ==="
cd $PSScriptRoot
vagrant up

# ---------------------- Запуск Ansible на мастере ----------------------
Write-Info "=== Running Ansible playbook on master ==="
vagrant ssh k3s-master -c "cd /home/vagrant/ansible && ansible-playbook -i inventory/hosts.ini playbook.yml"

# ---------------------- Финальный вывод ----------------------
Write-Info "=== Done ==="
Write-Info "Cluster is ready!"
Write-Info "Access master: vagrant ssh k3s-master"
Write-Info "Check nodes: kubectl get nodes"
Write-Info ""
Write-Info "If VirtualBox was installed for the first time, REBOOT your computer."
# -------------------------------------------------------