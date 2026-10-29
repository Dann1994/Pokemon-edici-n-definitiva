; Windows installer for the pokered-plus fork (Inno Setup 6).
; Built by .github/workflows/release-plus.yml from the fused gen1recomp-win64
; folder that scripts/build.sh win produces:
;   iscc /DAppVersion=1.2.3 /DSourceDir=<gen1recomp-win64> /DOutputDir=<dir> installer\edicion_definitiva.iss
;
; Per-user install (no admin prompt) under %LOCALAPPDATA%\Programs. In-game
; updates never write here -- src/update/check_worker.lua downloads the new
; .love into the save folder and src/update/Boot.lua mounts it over this one
; -- so this folder only changes when a newer installer is run.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\dist\win\gen1recomp-win64"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist\installer"
#endif

#define AppName "Pokémon Edición Definitiva"
#define AppExe "PokemonEdicionDefinitiva.exe"

[Setup]
; Fixed forever: a new AppId would install a second copy beside the old one.
AppId={{6B0C3E52-6F0A-4C1E-9D7B-2E5A1F8C4D90}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Dann1994
AppPublisherURL=https://github.com/Dann1994/Pokemon-edici-n-definitiva
AppUpdatesURL=https://github.com/Dann1994/Pokemon-edici-n-definitiva/releases
DefaultDirName={localappdata}\Programs\PokemonEdicionDefinitiva
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=PokemonEdicionDefinitiva-{#AppVersion}-instalador
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=pokebola.ico
UninstallDisplayIcon={app}\pokebola.ico
CloseApplications=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; the fused exe keeps LÖVE's own name inside the build folder; installed
; under the fork's name so the Start menu / taskbar read right
Source: "{#SourceDir}\gen1recomp.exe"; DestDir: "{app}"; DestName: "{#AppExe}"; Flags: ignoreversion
Source: "{#SourceDir}\*"; Excludes: "gen1recomp.exe"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; the Poké Ball the shortcuts point at, so they show it even when the CI
; runner could not patch the exe's own icon resource (peresed missing)
Source: "pokebola.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\pokebola.ico"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\pokebola.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
