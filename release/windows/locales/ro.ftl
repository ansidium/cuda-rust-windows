# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

-language-name = Română
WelcomeLabel1 = { $name }
InstallingLabel = Se instalează { $name }.
FinishedHeadingLabel = Gata — { $name }

# The first-party overrides above retain their Apache-2.0 license.
# The derived standard-message block below retains the Inno Setup license and notices.
# Modified version: restored Romanian diacritics from the original Windows-1250
# Romanian.isl translation; preserved the Onni Fluent variables and message structure.
# The complete original Inno Setup license is included in THIRD-PARTY-NOTICES.txt.

# Сконвертировано onni (`cargo xtask isl`) из Inno Setup: Languages/Romanian.isl.
# Изменённая версия: формат Fluent, подстановки Inno — переменные Fluent.
# Inno Setup — Copyright (C) 1997-2026 Jordan Russell. All rights reserved.
# Inno Setup — Portions Copyright (C) 2000-2026 Martijn Laan. All rights reserved.
# Лицензия Inno Setup — THIRD-PARTY-NOTICES.txt.
# Уведомления исходного файла:
#
# *** Inno Setup version 6.1.0+ Romanian messages ***
# Translator : Alexandru Bogdan Munteanu (muntealb@gmail.com)
#
# To download user-contributed translations of this file, go to:
#   https://jrsoftware.org/files/istrans/
#
# Note: When translating this text, do not add periods (.) to the end of
# messages that didn't have them already, because on those messages Inno
# Setup adds the periods automatically (appending a period would result in
# two periods being displayed).

InformationTitle = Informaţii
SetupLdrStartupMessage = Va fi instalat programul { $arg1 }. Vrei să continui?
LdrCannotCreateTemp = Nu pot crea o filă temporară. Instalare abandonată
LdrCannotExecTemp = Nu pot executa o filă din dosarul temporar. Instalare abandonată
SetupFileMissing = Fila { $arg1 } lipseşte din dosarul de instalare. Corectează problema sau foloseşte o altă copie a programului.
SetupFileCorrupt = Filele de instalare sînt stricate (corupte). Foloseşte o altă copie a programului.
SetupFileCorruptOrWrongVer = Filele de instalare sînt stricate (corupte) sau sînt incompatibile cu această versiune a Instalatorului. Remediază problema sau foloseşte o altă copie a programului.
InvalidParameter =
    Un parametru invalid a fost trecut către linia de comandă:

    { $arg1 }
SetupAlreadyRunning = Instalarea rulează deja.
WindowsVersionNotSupported = Acest program nu suportă versiunea de Windows care rulează pe calculatorul tău.
WindowsServicePackRequired = Acest program necesită { $arg1 } Service Pack { $arg2 } sau mai nou.
OnlyOnThisPlatform = Acest program trebuie să ruleze pe { $arg1 }.
OnlyOnTheseArchitectures =
    Acest program poate fi instalat doar pe versiuni de Windows proiectate pentru următoarele arhitecturi de procesor:

    { $arg1 }
WinVersionTooLowError = Acest program necesită { $arg1 } versiunea { $arg2 } sau mai nouă.
WinVersionTooHighError = Acest program nu poate fi instalat pe { $arg1 } versiunea { $arg2 } sau mai nouă.
AdminPrivilegesRequired = Trebuie să fii logat ca Administrator pentru instalarea acestui program.
PowerUserPrivilegesRequired = Trebuie să fii logat ca Administrator sau ca Membru al Grupului de Utilizatori Pricepuţi ("Power Users") pentru a instala acest program.
SetupAppRunningError =
    Instalatorul a detectat că { $arg1 } rulează în acest moment.

    Închide toate instanţele programului respectiv, apoi clichează OK pentru a continua sau Anulează pentru a abandona instalarea.
UninstallAppRunningError =
    Dezinstalatorul a detectat că { $arg1 } rulează în acest moment.

    Închide toate instanţele programului respectiv, apoi clichează OK pentru a continua sau Anulează pentru a abandona dezinstalarea.
PrivilegesRequiredOverrideInstruction = Selectează modul de instalare
PrivilegesRequiredOverrideText1 = { $arg1 } poate fi instalat pentru toţi utilizatorii (necesită calitatea de administrator), sau doar pentru tine.
PrivilegesRequiredOverrideText2 = { $arg1 } poate fi instalat doar pentru tine, sau pentru toţi utilizatorii (necesită calitatea de administrator).
PrivilegesRequiredOverrideAllUsers = Instalează pentru toţi utiliz&atorii
PrivilegesRequiredOverrideAllUsersRecommended = Instalează pentru toţi utiliz&atorii (recomandat)
PrivilegesRequiredOverrideCurrentUser = Instalează doar pentru &mine
PrivilegesRequiredOverrideCurrentUserRecommended = Instalează doar pentru &mine (recomandat)
ErrorTooManyFilesInDir = Nu pot crea o filă în dosarul "{ $arg1 }" din cauză că are deja prea multe file
ExitSetupTitle = Abandonarea Instalării
ExitSetupMessage =
    Instalarea nu este terminată. Dacă o abandonezi acum, programul nu va fi instalat.

    Poţi să rulezi Instalatorul din nou altă dată pentru a termina instalarea.

    Abandonezi Instalarea?
ButtonBack = < Îna&poi
ButtonNext = &Continuă >
ButtonInstall = &Instalează
ButtonCancel = Anulează
ButtonFinish = &Finalizează
ButtonBrowse = &Explorează...
ButtonWizardBrowse = Explo&rează...
ButtonNewFolder = Creea&ză Dosar Nou
SelectLanguageLabel = Selectează limba folosită pentru instalare:
ClickNext = Clichează pe Continuă pentru a avansa cu instalarea sau pe Anulează pentru a o abandona.
BrowseDialogTitle = Explorare după Dosar
BrowseDialogLabel = Selectează un dosar din lista de mai jos, apoi clichează pe OK.
WelcomeLabel2 =
    Programul { $nameVersion } va fi instalat pe calculator.

    Este recomandat să închizi toate celelalte aplicaţii înainte de a continua.
WizardPassword = Parolă
PasswordLabel1 = Această instalare este protejată prin parolă.
PasswordLabel3 = Completează parola, apoi clichează pe Continuă pentru a merge mai departe. Tipul literelor din parolă (Majuscule/minuscule) este luat în considerare.
PasswordEditLabel = &Parolă:
IncorrectPassword = Parola pe care ai introdus-o nu este corectă. Reîncearcă.
WizardLicense = Acord de Licenţiere
LicenseLabel = Citeşte informaţiile următoare înainte de a continua, sînt importante.
LicenseLabel3 = Citeşte următorul Acord de Licenţiere. Trebuie să accepţi termenii acestui acord înainte de a continua instalarea.
LicenseAccepted = &Accept licenţa
LicenseNotAccepted = &Nu accept licenţa
WizardInfoBefore = Informaţii
InfoBeforeLabel = Citeşte informaţiile următoare înainte de a continua, sînt importante.
InfoBeforeClickLabel = Cînd eşti gata de a trece la Instalare, clichează pe Continuă.
WizardInfoAfter = Informaţii
InfoAfterLabel = Citeşte informaţiile următoare înainte de a continua, sînt importante.
InfoAfterClickLabel = Cînd eşti gata de a trece la Instalare, clichează pe Continuă.
WizardUserInfo = Informaţii despre Utilizator
UserInfoDesc = Completează informaţiile cerute.
UserInfoOrg = &Organizaţie:
UserInfoSerial = Număr de &Serie:
UserInfoNameRequired = Trebuie să introduci un nume.
WizardSelectDir = Selectarea Locului de Destinaţie
SelectDirDesc = Unde vrei să instalezi { $name }?
SelectDirLabel3 = Instalatorul va pune { $name } în dosarul specificat mai jos.
SelectDirBrowseLabel = Pentru a avansa cu instalarea, clichează pe Continuă. Dacă vrei să selectezi un alt dosar, clichează pe Explorează.
DiskSpaceGBLabel = Este necesar un spaţiu liber de stocare de cel puţin { $gb } GB.
DiskSpaceMBLabel = Este necesar un spaţiu liber de stocare de cel puţin { $mb } MB.
CannotInstallToNetworkDrive = Instalatorul nu poate realiza instalarea pe un dispozitiv de reţea.
CannotInstallToUNCPath = Instalatorul nu poate realiza instalarea pe o cale în format UNC.
InvalidPath =
    Trebuie să introduci o cale completă, inclusiv litera dispozitivului; de exemplu:

    C:\APP

    sau o cale UNC de forma:

    \\server\share
InvalidDrive = Dispozitivul sau partajul UNC pe care l-ai selectat nu există sau nu este accesibil. Selectează altul.
DiskSpaceWarningTitle = Spaţiu de Stocare Insuficient
DiskSpaceWarning =
    Instalarea necesită cel puţin { $arg1 } KB de spaţiu de stocare liber, dar dispozitivul selectat are doar { $arg2 } KB liberi.

    Vrei să continui oricum?
DirNameTooLong = Numele dosarului sau al căii este prea lung.
BadDirName32 =
    Numele dosarelor nu pot include unul din următoarele caractere:

    { $arg1 }
DirExistsTitle = Dosarul Există
DirExists =
    Dosarul:

    { $arg1 }

    există deja. Vrei totuşi să instalezi în acel dosar?
DirDoesntExistTitle = Dosarul Nu Există
DirDoesntExist =
    Dosarul:

    { $arg1 }

    nu există. Vrei ca el să fie creat?
SelectComponentsLabel2 = Selectează componentele de instalat; deselectează componentele care nu trebuie instalate. Clichează pe Continuă pentru a merge mai departe.
FullInstallation = Instalare Completă
CompactInstallation = Instalare Compactă
CustomInstallation = Instalare Personalizată
NoUninstallWarningTitle = Componentele Există
NoUninstallWarning =
    Instalatorul a detectat că următoarele componente sînt deja instalate pe calculator:

    { $arg1 }

    Deselectarea lor nu le va dezinstala.

    Vrei să continui oricum?
ComponentsDiskSpaceGBLabel = Selecţia curentă necesită cel puţin { $gb } GB spaţiu de stocare.
ComponentsDiskSpaceMBLabel = Selecţia curentă necesită cel puţin { $mb } MB spaţiu de stocare.
SelectTasksDesc = Ce sarcini suplimentare trebuie îndeplinite?
SelectTasksLabel2 = Selectează sarcinile suplimentare care trebuie îndeplinite în timpul instalării { $name }, apoi clichează pe Continuă.
SelectStartMenuFolderDesc = Unde trebuie să fie plasate scurtăturile programului?
SelectStartMenuFolderLabel3 = Scurtăturile vor fi plasate în dosarul specificat mai jos al Meniului de Start.
SelectStartMenuFolderBrowseLabel = Pentru a avansa cu instalarea, clichează pe Continuă. Dacă vrei să selectezi un alt dosar, clichează pe Explorează.
MustEnterGroupName = Trebuie să introduci numele dosarului.
GroupNameTooLong = Numele dosarului sau al căii este prea lung.
BadGroupName =
    Numele dosarului nu poate include unul dintre caracterele următoarele:

    { $arg1 }
NoProgramGroupCheck2 = Nu crea un &dosar în Meniul de Start
WizardReady = Pregătit de Instalare
ReadyLabel1 = Instalatorul e pregătit pentru instalarea { $name } pe calculator.
ReadyLabel2a = Clichează pe Instalează pentru a continua cu instalarea, sau clichează pe Înapoi dacă vrei să revezi sau să schimbi setările.
ReadyLabel2b = Clichează pe Instalează pentru a continua cu instalarea.
ReadyMemoDir = Loc de Destinaţie:
ButtonStopDownload = O&preşte descărcarea
StopDownload = Sigur vrei să opreşti descărcarea?
ErrorDownloadAborted = Descărcare abandonată
ErrorDownloadFailed = Descărcare eşuată: { $arg1 } { $arg2 }
ErrorDownloadSizeFailed = Obţinerea mărimii a eşuat: { $arg1 } { $arg2 }
ErrorFileSize = Mărime a filei nevalidă: aşteptată { $arg1 }, găsită { $arg2 }
WizardPreparing = Pregătire pentru Instalare
PreparingDesc = Instalatorul pregăteşte instalarea { $name } pe calculator.
PreviousInstallNotCompleted =
    Instalarea/dezinstalarea anterioară a unui program nu a fost terminată. Va trebui să reporneşti calculatorul pentru a termina operaţia precedentă.

    După repornirea calculatorului, rulează Instalatorul din nou pentru a realiza instalarea { $name }.
CannotContinue = Instalarea nu poate continua. Clichează pe Anulează pentru a o închide.
ApplicationsFound = Aplicaţiile următoare folosesc file care trebuie actualizate de către Instalator. Este recomandat să permiţi Instalatorului să închidă automat aplicaţiile respective.
ApplicationsFound2 = Aplicaţiile următoare folosesc file care trebuie actualizate de către Instalator. Este recomandat să permiţi Instalatorului să închidă automat aplicaţiile respective. După ce instalarea e terminată, Instalatorul va încerca să repornească aplicaţiile.
CloseApplications = Închide &automat aplicaţiile
DontCloseApplications = Nu închi&de aplicaţiile
ErrorCloseApplications = Instalatorul nu a putut închide automat toate aplicaţiile. Înainte de a continua, e recomandat să închizi manual toate aplicaţiile care folosesc file ce trebuie actualizate de Instalator.
PrepareToInstallNeedsRestart =
    Instalatorul trebuie să repornescă calculatorul. După repornire, rulează Instalatorul din nou pentru a termina instalarea { $name }.

    Vrei să reporneşti acum?
WizardInstalling = Instalare în Desfăşurare
FinishedLabelNoIcons = Instalarea { $name } pe calculator a fost terminată.
FinishedLabel = Instalarea { $name } pe calculator a fost terminată. Aplicaţia poate fi lansată prin clicarea pe icoanele instalate.
ClickFinish = Clichează pe Finalizează pentru a părăsi Instalatorul.
FinishedRestartLabel = Pentru a termina instalarea { $name }, trebuie repornit calculatorul. Vrei să fie repornit acum?
FinishedRestartMessage =
    Pentru a termina instalarea { $name }, trebuie repornit calculatorul.

    Vrei să fie repornit acum?
ShowReadmeCheck = Da, vreau să văd fila de informare (README)
YesRadio = &Da, reporneşte calculatorul acum
NoRadio = &Nu, voi reporni eu calculatorul mai tîrziu
RunEntryExec = Rulează { $arg1 }
ChangeDiskTitle = Instalatorul Necesită Discul Următor
SelectDiskLabel2 =
    Introdu Discul { $arg1 } şi clichează pe OK.

    Dacă filele de pe acest disc pot fi găsite într-un alt dosar decît cel afişat mai jos, introdu calea corectă sau clichează pe Explorează.
FileNotInDir2 = Fila "{ $arg1 }" nu poate fi găsită în "{ $arg2 }". Introdu discul corect sau selectează alt dosar.
SelectDirectoryLabel = Specifică locul discului următor.
SetupAborted =
    Instalarea nu a fost terminată.

    Corectează problema şi apoi rulează Instalarea din nou.
AbortRetryIgnoreSelectAction = Selectează acţiunea
AbortRetryIgnoreRetry = Încearcă din &nou
AbortRetryIgnoreIgnore = &Ignoră eroarea şi continuă
AbortRetryIgnoreCancel = Anulează instalarea
StatusClosingApplications = Închid aplicaţiile...
StatusCreateIcons = Creez scurtăturile...
StatusCreateIniEntries = Creez intrările INI...
StatusCreateRegistryEntries = Creez intrările în registru...
StatusRegisterFiles = Înregistrez filele...
StatusSavingUninstall = Salvez informaţiile de dezinstalare...
StatusRestartingApplications = Repornesc aplicaţiile...
StatusRollback = Reîntorc la starea iniţială, prin anularea modificărilor făcute...
ErrorInternal2 = Eroare Internă: { $arg1 }
ErrorFunctionFailedNoCode = { $arg1 } a eşuat
ErrorFunctionFailed = { $arg1 } a eşuat; cod { $arg2 }
ErrorFunctionFailedWithMessage =
    { $arg1 } a eşuat; cod { $arg2 }.
    { $arg3 }
ErrorRegWriteKey =
    Eroare la scrierea în cheia de registru:
    { $arg1 }\{ $arg2 }
ErrorIniEntry = Eroare la crearea intrării INI în fişierul "{ $arg1 }".
FileAbortRetryIgnoreSkipNotRecommended = &Sari peste această filă (nerecomandat)
FileAbortRetryIgnoreIgnoreNotRecommended = &Ignoră eroarea şi continuă (nerecomandat)
SourceIsCorrupted = Fila sursă este stricată (coruptă)
SourceDoesntExist = Fila sursă "{ $arg1 }" nu există
ExistingFileReadOnly2 = Fila deja existentă nu poate fi înlocuită pentru că-i marcată doar-citire.
ExistingFileReadOnlyRetry = Înlătu&ră atributul doar-citire şi reîncearcă
ExistingFileReadOnlyKeepExisting = &Păstrează fila existentă
ErrorReadingExistingDest = A apărut o eroare la citirea filei deja existente:
FileExistsSelectAction = Selectează acţiunea
FileExists2 = Fila există deja.
FileExistsOverwriteExisting = &Suprascrie fila existentă
FileExistsKeepExisting = &Păstrează fila existentă
FileExistsOverwriteOrKeepAll = &Fă la fel pentru conflictele următoare
ExistingFileNewerSelectAction = Selectează acţiunea
ExistingFileNewer2 = Fila existentă e mai nouă decît cea pe care încearcă Instalatorul s-o instaleze.
ExistingFileNewerOverwriteExisting = &Suprascrie fila existentă
ExistingFileNewerKeepExisting = &Păstrează fila existentă (recomandat)
ExistingFileNewerOverwriteOrKeepAll = &Fă la fel pentru conflictele următoare
ErrorChangingAttr = A apărut o eroare în timpul schimbării atributelor filei deja existente:
ErrorCreatingTemp = A apărut o eroare în timpul creării filei în dosarul de destinaţie:
ErrorReadingSource = A apărut o eroare în timpul citirii filei sursă:
ErrorCopying = A apărut o eroare în timpul copierii filei:
ErrorReplacingExistingFile = A apărut o eroare în timpul înlocuirii filei deja existente:
ErrorRestartReplace = Repornirea/Înlocuirea a eşuat:
ErrorRenamingTemp = A apărut o eroare în timpul renumirii unei file din dosarul de destinaţie:
ErrorRegisterServer = Nu pot înregistra DLL/OCX: { $arg1 }
ErrorRegSvr32Failed = RegSvr32 a eşuat, avînd codul de ieşire { $arg1 }
ErrorRegisterTypeLib = Nu pot înregistra biblioteca de tipuri: { $arg1 }
UninstallDisplayNameMark32Bit = 32-biţi
UninstallDisplayNameMark64Bit = 64-biţi
UninstallDisplayNameMarkAllUsers = Toţi utilizatorii
ErrorOpeningReadme = A apărut o eroare la deschiderea filei de informare (README).
ErrorRestartingComputer = Instalatorul nu a putut reporni calculatorul. Va trebui să-l reporneşti manual.
UninstallNotFound = Fila "{ $arg1 }" nu există. Dezinstalarea nu poate fi făcută.
UninstallOpenError = Fila "{ $arg1 }" nu poate fi deschisă. Dezinstalarea nu poate fi făcută
UninstallUnsupportedVer = Fila "{ $arg1 }" ce conţine jurnalul de dezinstalare este într-un format nerecunoscut de această versiune a dezinstalatorului. Dezinstalarea nu poate fi făcută
UninstallUnknownEntry = A fost întîlnită o intrare necunoscută ({ $arg1 }) în jurnalul de dezinstalare
ConfirmUninstall = Sigur vrei să înlături complet { $arg1 } şi componentele sale?
UninstallOnlyOnWin64 = Această instalare poate fi dezinstalată doar pe un sistem Windows 64-biţi.
OnlyAdminCanUninstall = Această instalare poate fi dezinstalată doar de către un utilizator cu drepturi de Administrator.
UninstallStatusLabel = Aşteaptă ca { $arg1 } să fie înlăturat de pe calculator.
UninstalledAll = { $arg1 } a fost înlăturat cu succes de pe calculator.
UninstalledMost =
    Dezinstalare completă a { $arg1 }.

    Anumite elemente nu au putut fi înlăturate. Acestea pot fi înlăturate manual.
UninstalledAndNeedsRestart =
    Pentru a termina dezinstalarea { $arg1 }, calculatorul trebuie repornit.

    Vrei să fie repornit acum?
UninstallDataCorrupted = Fila "{ $arg1 }" este stricată (coruptă). Dezinstalarea nu poate fi făcută
ConfirmDeleteSharedFileTitle = Şterg Fila Partajată?
ConfirmDeleteSharedFile2 =
    Sistemul indică faptul că fila partajată următoare pare să nu mai fie folosită de vreun alt program. Vrei ca Dezinstalatorul să şteargă această filă partajată?

    Dacă totuşi mai există programe care folosesc fila şi ea este ştearsă, acele programe ar putea să funcţioneze greşit. Dacă nu eşti sigur, alege Nu. Lăsarea filei în sistem nu va produce nici o neplăcere.
SharedFileNameLabel = Nume Filă:
WizardUninstalling = Starea Dezinstalării
AdditionalIcons = Scurtături suplimentare:
CreateDesktopIcon = Creează o scurtătură pe &Birou ("Desktop")
CreateQuickLaunchIcon = Creează o scurtătură în Bara de &Lansare Rapidă ("Quick Launch")
UninstallProgram = Dezinstalează { $arg1 }
LaunchProgram = Lansează { $arg1 }
AssocFileExtension = &Asociază { $arg1 } cu extensia de file { $arg2 }
AutoStartProgram = Porneşte automat { $arg1 }
AddonHostProgramNotFound =
    { $arg1 } nu poate fi găsit în dosarul selectat.

    Vrei să continui oricum?
