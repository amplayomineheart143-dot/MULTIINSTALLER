# MULTIINSTALLER
A sleek, portable, auto-detecting offline bulk installer for Windows. Drop your .exe, .iso, .msi, and .inf driver files into a folder, and Multi-Installer will automatically identify them, apply silent flags, and install everything with a single click via a custom dark-theme GUI. No internet required.

# Multi-Installer - Offline Bulk Software Installer

Multi-Installer is a portable, GUI-based bulk installer for Windows. It is designed to take the pain out of setting up a new PC by allowing you to silently install multiple programs, mount Office ISOs, and inject raw drivers from a single USB drive.

## 🚀 Features
- **Smart Auto-Detection:** Just drop your installers into the folder. It scans the filenames and automatically guesses the correct silent installation flags (e.g., Chrome, VLC, 7-Zip, AVG).
- **ISO Mounting:** Drop an Office 2021 `.iso` file, and the app will automatically mount it, inject a silent `configuration.xml`, install it, and eject the drive.
- **Driver Support:** Detects raw `.inf` driver files and injects them using Windows `pnputil`.
- **Multi-Format:** Handles `.exe`, `.msi`, `.iso`, `.bat`, `.cmd`, and `.ps1` files.
- **Sleek UI:** A compact, dark, neon-themed WPF interface built entirely in PowerShell.
- **Zero Internet Required:** Completely offline. Works perfectly on air-gapped machines.

## 📁 How to Use

1. **Prepare the USB:** Copy `Multi-Installer.exe` to the root of your USB drive.
2. **Create the Folder:** Create a folder named `Installers` next to the EXE.
3. **Drop Files:** Put your **full offline installers** (do not use tiny 2MB web stubs) into the `Installers` folder.
4. **Run:** Double-click `Multi-Installer.exe`. Accept the Windows Admin prompt.
5. **Execute:** Check the boxes for the software you want to install and click **EXECUTE**.

## ⚠️ Important Notes
- **Stub Installers:** Do not use tiny online installers (e.g., a 2MB Chrome installer). Multi-Installer runs offline and cannot download missing files. Always use the full offline packages (50MB+).
- **Antivirus:** Because this tool runs silent scripts, some aggressive antiviruses might flag it. Simply add the USB folder to your AV exceptions/whitelist.
- **Drivers:** For raw `.inf` drivers, ensure you place the entire driver folder (with the `.sys` and `.cat` files) inside the `Installers` directory.

## 🛠️ Building from Source
If you want to compile the `.exe` from the raw `install.ps1` script yourself, use the `ps2exe` PowerShell module:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Invoke-PS2EXE -InputFile "install.ps1" -OutputFile "Multi-Installer.exe" -noConsole -requireAdmin
