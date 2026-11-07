# CNC MyLink iPad V1 – cloudové zostavenie

Táto verzia je **natívna Objective-C / UIKit aplikácia** pre **iPad mini 2, iOS 12, ARM64**. Neobsahuje Safari ani WebView. Projekt sa zostavuje na vzdialenom runneri GitHub Actions; na používateľskom Windows sa neinštaluje Xcode, Linux ani WSL. GitHub runner na zostavenie využíva svoj vzdialený Xcode toolchain.

## Funkcie V1
- Nastaviteľná URL Raspberry Pi bridge (predvolene `http://192.168.0.169:8080`)
- GET /api/info, GET /api/files, GET /api/file?name=...
- POST /api/file/save na uloženie G-kódu
- POST /api/cnc/send, POST /api/cnc/receive, POST /api/cnc/stop
- GET /api/job pre priebeh úlohy
- Bez zásahov do RS-232 komunikácie a jej nastavení na Raspberry Pi

## Nahranie na GitHub cez web
1. Na github.com sa prihlásiť, vybrať **New repository**, ideálne **Private**.
2. V repozitári použiť **Add file → Upload files** a nahrať obsah projektu tak, aby bola zachovaná zložka `App/` a súbor `.github/workflows/build.yml`.
   Pozor: webové nahratie niektorých skrytých ciest môže byť nepohodlné. Najistejšie je na stránke **Add file → Create new file** založiť `.github/workflows/build.yml` vložením jeho obsahu, súbory v `App` nahrať cez Upload files.
3. Otvoriť kartu **Actions**, vybrať **Build CNC MyLink iPad DEB**, kliknúť **Run workflow**.
4. Po úspechu otvoriť dokončený beh → sekcia **Artifacts** → stiahnuť `CNC_MyLink_iPad_V1_DEB`.
5. Rozbaliť stiahnutý ZIP, získať `.deb` a preniesť ho do jailbreaknutého iPadu cez WinSCP/SSH. Kompatibilitu s balíčkovacím systémom jailbreaku treba potvrdiť pred inštaláciou.

## Bezpečnostné upozornenia
- **Neotestované:** balík sa ešte nekompiloval na GitHub runneri a neprešiel inštaláciou na iPade. Pri chybe zostavenia je potrebná úprava workflow alebo kódu.
- Je to **rootful** deb balík (`iphoneos-arm`) pre iOS 12, nie rootless balík.
- Prvý test urobiť **bez pripojenia k aktívnemu stroju**. Úkony DO NUM, Z NUM a STOP vyvolávajú skutočné požiadavky na bridge.
- Spojenie používa HTTP v dôveryhodnej lokálnej sieti; nevystavovať Raspberry Pi port 8080 verejnému internetu.
- Na obrazovke sa zobrazuje prenosový stav, ale nie je garantované potvrdenie finálneho spracovania stroja. STOP cez Wi-Fi nie je bezpečnostný núdzový STOP.
- Aplikácia vyžaduje aktívny kompatibilný jailbreak a dostupný podpisový bypass pre spustenie natívneho programu. Pokiaľ to jailbreak nepodporuje, treba upraviť spôsob podpisovania/inštalácie.
