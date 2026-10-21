#Requires -RunAsAdministrator
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$installersDir = Join-Path $scriptRoot "Installers"

# --- SMART SCANNER ---
$apps = @()
$files = @()
if (Test-Path $scriptRoot) { $files += Get-ChildItem -Path $scriptRoot -File -ErrorAction SilentlyContinue }
if (Test-Path $installersDir) { $files += Get-ChildItem -Path $installersDir -File -Recurse -ErrorAction SilentlyContinue }

foreach ($file in $files) {
    # Ignore the executable and system files
    if ($file.Name -match "install.ps1|apps.json|Multi-Installer.exe|MINEHEART.exe|MINEHEART_INSTALL.bat|README.txt|\.log$") { continue }

    $guessName = $file.BaseName -replace '[-_]', ' ' -replace '\s+', ' '
    $guessName = (Get-Culture).TextInfo.ToTitleCase($guessName)
    $guessArgs = "/S"
    $isIso = $false
    $isExe = $false
    $isMsi = $false
    $isScript = $false
    $isDriver = $false

    $ext = $file.Extension.ToLower()
    $nameLower = $file.Name.ToLower()

    # 1. EXE
    if ($ext -eq ".exe" -or $nameLower -match "\.exe$") {
        $isExe = $true
        if ($nameLower -match "chrome") { $guessName = "Google Chrome"; $guessArgs = "/silent /install" }
        elseif ($nameLower -match "vlc") { $guessName = "VLC Media Player"; $guessArgs = "/L=1033 /S" }
        elseif ($nameLower -match "7z") { $guessName = "7-Zip"; $guessArgs = "/S" }
        elseif ($nameLower -match "firefox") { $guessName = "Mozilla Firefox"; $guessArgs = "-ms" }
        elseif ($nameLower -match "vcredist") { $guessName = "Visual C++ Redist"; $guessArgs = "/install /quiet /norestart" }
        elseif ($nameLower -match "avg") { $guessName = "AVG Antivirus"; $guessArgs = "/silent" }
    }
    # 2. MSI
    elseif ($ext -eq ".msi" -or $nameLower -match "\.msi$") {
        $isMsi = $true
        $guessName = "$guessName (MSI)"
        $guessArgs = "/i `"$($file.FullName)`" /qn /norestart"
    }
    # 3. Drivers (.inf)
    elseif ($ext -eq ".inf") {
        $isDriver = $true
        $guessName = "$guessName (Driver)"
        $guessArgs = ""
    }
    # 4. Scripts
    elseif ($ext -eq ".bat" -or $ext -eq ".cmd" -or $ext -eq ".ps1") {
        $isScript = $true
        $guessName = "$guessName (Script)"
        $guessArgs = ""
    }
    # 5. ISO
    elseif ($ext -eq ".iso" -or $nameLower -match "\.iso$" -or $nameLower -match "office|iso") {
        $isIso = $true
        $guessName = "$guessName (ISO)"
        $guessArgs = "/configure"
    }
    elseif ($file.Length -gt 100MB -and $ext -eq "") {
        $isIso = $true
        $guessName = "$guessName (ISO)"
        $guessArgs = "/configure"
    }
    else { continue }

    $apps += [PSCustomObject]@{
        name = $guessName
        file = $file.Name
        args = $guessArgs
        fullPath = $file.FullName 
        isIso = $isIso
        isExe = $isExe
        isMsi = $isMsi
        isScript = $isScript
        isDriver = $isDriver
        ext = $ext
    }
}

$apps = $apps | Sort-Object fullPath -Unique

# --- UI XAML ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MINEHEART" Height="460" Width="380" 
        WindowStartupLocation="CenterScreen" Background="#050505" 
        WindowStyle="None" AllowsTransparency="True" BorderThickness="1" BorderBrush="#00FFCC">
    <Window.Resources>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CCCCCC"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="5,6,0,6"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#00FFCC"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="35"/>
            <RowDefinition Height="25"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="65"/>
        </Grid.RowDefinitions>
        
        <Border Grid.Row="0" Background="#0A0A0A" BorderThickness="0,0,0,1" BorderBrush="#1A1A1A">
            <Grid>
                <TextBlock Text="MINEHEART // V2" FontFamily="Consolas" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" VerticalAlignment="Center" Margin="15,0,0,0"/>
                <Button Name="CloseBtn" Content="✕" Foreground="#FF4444" FontSize="12" Width="30" Height="30" HorizontalAlignment="Right" Margin="0,0,5,0"/>
            </Grid>
        </Border>

        <Grid Grid.Row="1" Margin="15,0,15,0">
            <Button Name="SelectAllBtn" Content="[+] SELECT ALL" FontSize="11" HorizontalAlignment="Left"/>
        </Grid>

        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="15,0,15,10">
            <StackPanel Name="AppListPanel"/>
        </ScrollViewer>

        <Border Grid.Row="3" Background="#0A0A0A" BorderThickness="0,1,0,0" BorderBrush="#1A1A1A">
            <Grid Margin="15,8,15,8">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Name="StatusText" Text="Ready." FontFamily="Consolas" Foreground="#666666" FontSize="10" TextTrimming="CharacterEllipsis"/>
                <Grid Grid.Row="1" Margin="0,5,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="80"/>
                    </Grid.ColumnDefinitions>
                    <ProgressBar Name="ProgressBar" Height="4" Background="#111111" Foreground="#00FFCC" BorderThickness="0" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <Button Name="InstallBtn" Grid.Column="1" Content="EXECUTE" Background="#00FFCC" Foreground="#000000" FontWeight="Bold" FontSize="12" Height="24"/>
                </Grid>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$appListPanel = $window.FindName("AppListPanel")
$installBtn   = $window.FindName("InstallBtn")
$closeBtn     = $window.FindName("CloseBtn")
$statusText   = $window.FindName("StatusText")
$progressBar  = $window.FindName("ProgressBar")
$selectAllBtn = $window.FindName("SelectAllBtn")

$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$closeBtn.Add_Click({ $window.Close() })

$checkboxes = @()
foreach ($app in $apps) {
    $exists = Test-Path $app.fullPath
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = if ($exists) { $app.name } else { "$($app.name) (Missing)" }
    if (-not $exists) { $cb.Foreground = [System.Windows.Media.Brushes]::Gray }
    $cb.IsEnabled = $exists
    $cb.IsChecked = $false 
    
    $cb.Add_Checked({ param($s,$e) $s.Foreground = [System.Windows.Media.Brushes]::Cyan })
    $cb.Add_Unchecked({ param($s,$e) if($s.IsEnabled) { $s.Foreground = [System.Windows.Media.Brushes]::White } })
    
    $cb.Tag = $app
    $appListPanel.Children.Add($cb) | Out-Null
    $checkboxes += $cb
}

$isAllChecked = $false
$selectAllBtn.Add_Click({
    $isAllChecked = -not $isAllChecked
    $selectAllBtn.Content = if ($isAllChecked) { "[-] DESELECT ALL" } else { "[+] SELECT ALL" }
    foreach ($cb in $checkboxes) {
        if ($cb.IsEnabled) { $cb.IsChecked = $isAllChecked }
    }
})

if ($apps.Count -eq 0) {
    $statusText.Text = "Empty: $installersDir"
    $statusText.Foreground = [System.Windows.Media.Brushes]::OrangeRed
} else {
    $statusText.Text = "Found $($apps.Count) packages. Select to install."
}

$installBtn.Add_Click({
    $installBtn.IsEnabled = $false
    $installBtn.Content = "WAIT"
    $progressBar.Value = 0
    $statusText.Text = "Deploying..."

    $selected = @()
    foreach ($cb in $checkboxes) { if ($cb.IsChecked -eq $true) { $selected += $cb.Tag } }

    if ($selected.Count -eq 0) {
        $statusText.Text = "No software selected."
        $installBtn.IsEnabled = $true
        $installBtn.Content = "EXECUTE"
        return
    }

    $progressBar.Maximum = $selected.Count
    $current = 0
    $ok = 0; $fail = 0

    foreach ($app in $selected) {
        $current++
        $statusText.Text = "Installing: $($app.name)..."
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

        try {
            if ($app.isIso) {
                $statusText.Text = "Mounting ISO: $($app.name)..."
                $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
                
                $img = Mount-DiskImage -ImagePath $app.fullPath -PassThru -ErrorAction Stop
                $driveLetter = ($img | Get-Volume).DriveLetter
                
                if ($driveLetter) {
                    $drivePath = "${driveLetter}:\"
                    $setupExe = Join-Path $drivePath "setup.exe"
                    
                    if (Test-Path $setupExe) {
                        $configXml = Join-Path $drivePath "configuration.xml"
                        if (-not (Test-Path $configXml)) {
                            $defaultXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2021">
    <Product ID="ProPlus2021Volume">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
                            $configXml = Join-Path $env:TEMP "MINEHEART_AutoConfig.xml"
                            Set-Content -Path $configXml -Value $defaultXml -Encoding UTF8
                        }
                        $proc = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configXml`"" -WorkingDirectory $drivePath -PassThru -NoNewWindow -Wait
                        if ($proc.ExitCode -eq 0) { $ok++ } else { $fail++ }
                    } else { $fail++ }
                    Dismount-DiskImage -ImagePath $app.fullPath -ErrorAction SilentlyContinue
                } else { $fail++ }
            } 
            elseif ($app.isMsi) {
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $app.args -PassThru -NoNewWindow -Wait
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { $ok++ } else { $fail++ }
            }
            elseif ($app.isDriver) {
                $workDir = Split-Path $app.fullPath
                $proc = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$($app.fullPath)`" /install" -WorkingDirectory $workDir -PassThru -NoNewWindow -Wait
                if ($proc.ExitCode -eq 0) { $ok++ } else { $fail++ }
            }
            elseif ($app.isScript) {
                if ($app.ext -eq ".ps1") {
                    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($app.fullPath)`"" -PassThru -NoNewWindow -Wait
                } else {
                    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($app.fullPath)`"" -PassThru -NoNewWindow -Wait
                }
                if ($proc.ExitCode -eq 0) { $ok++ } else { $fail++ }
            }
            else {
                $workDir = Split-Path $app.fullPath
                $proc = Start-Process -FilePath $app.fullPath -ArgumentList $app.args -WorkingDirectory $workDir -PassThru -NoNewWindow -Wait
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { $ok++ } else { $fail++ }
            }
        } catch { $fail++ }

        $progressBar.Value = $current
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }

    $statusText.Text = "Done. OK: $ok | Failed: $fail"
    $statusText.Foreground = [System.Windows.Media.Brushes]::LightGreen
    $installBtn.IsEnabled = $true
    $installBtn.Content = "EXECUTE"
})
$window.ShowDialog() | Out-Null
