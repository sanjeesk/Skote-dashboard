# ============================================================
# fix-all.ps1  —  Run from your project ROOT in PowerShell
# Usage:  Set-ExecutionPolicy -Scope Process Bypass; .\fix-all.ps1
# ============================================================

function ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function inf($msg)  { Write-Host "[*] $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Skote Angular - Full Fix Script" -ForegroundColor Cyan
Write-Host "============================================================"

# ─── STEP 1: Fix npm packages ───────────────────────────────
inf "STEP 1 — Fix npm packages"

npm install @ng-bootstrap/ng-bootstrap@17.0.1 --save --legacy-peer-deps --silent
ok "ng-bootstrap pinned to 17.0.1"

npm install @ngx-translate/core@16.0.0 @ngx-translate/http-loader@16.0.0 --save --legacy-peer-deps --silent
ok "ngx-translate pinned to 16.x"

npm install ngx-ui-switch@18.0.0 --save --legacy-peer-deps --silent
ok "ngx-ui-switch upgraded to 18.0.0"

npm install metismenujs@1.3.1 --save --legacy-peer-deps --silent
ok "metismenujs pinned to 1.3.1"

# ─── STEP 2: Fix auth.service.ts ────────────────────────────
inf "STEP 2 — Fix auth.service.ts"
$f = "src\app\core\services\auth.service.ts"
if (Test-Path $f) {
    (Get-Content $f -Raw) -replace 'getFirebaseBackend','initFirebaseBackend' | Set-Content $f
    ok "Patched auth.service.ts"
} else { warn "$f not found" }

# ─── STEP 3: Fix styles.scss tilde imports ──────────────────
inf "STEP 3 — Fix styles.scss tilde ~ imports"
$f = "src\styles.scss"
if (Test-Path $f) {
    (Get-Content $f -Raw) `
        -replace "@import '~bootstrap","@import 'bootstrap" `
        -replace '@import "~bootstrap','@import "bootstrap' |
    Set-Content $f
    ok "Fixed styles.scss"
} else { warn "$f not found" }

# ─── STEP 4: Fix _switch.scss tilde imports ─────────────────
inf "STEP 4 — Fix _switch.scss tilde ~ imports"
$f = "src\assets\scss\custom\plugins\_switch.scss"
if (Test-Path $f) {
    (Get-Content $f -Raw) `
        -replace "@import '~ngx-ui-switch","@import 'ngx-ui-switch" `
        -replace '@import "~ngx-ui-switch','@import "ngx-ui-switch' |
    Set-Content $f
    ok "Fixed _switch.scss"
} else { warn "$f not found" }

# Scan all scss files for remaining tilde imports
inf "  Scanning all SCSS files for ~ tilde imports..."
Get-ChildItem -Path "src\assets\scss" -Filter "*.scss" -Recurse | ForEach-Object {
    $raw = Get-Content $_.FullName -Raw
    if ($raw -match "'~" -or $raw -match '"~') {
        $fixed = $raw -replace "'~","'" -replace '"~','"'
        Set-Content $_.FullName $fixed
        ok "  Fixed tilde in $($_.Name)"
    }
}

# ─── STEP 5: Fix sidebar metismenujs import ─────────────────
inf "STEP 5 — Fix sidebar.component.ts metismenujs import"
$f = "src\app\layouts\sidebar\sidebar.component.ts"
if (Test-Path $f) {
    (Get-Content $f -Raw) `
        -replace "from './dist/metismenujs'","from 'metismenujs'" `
        -replace 'from "./dist/metismenujs"','from "metismenujs"' `
        -replace "from 'metismenujs/dist/metismenujs'","from 'metismenujs'" `
        -replace 'from "metismenujs/dist/metismenujs"','from "metismenujs"' |
    Set-Content $f
    ok "Fixed sidebar.component.ts"
} else { warn "$f not found" }

# ─── STEP 6: Fix DashboardComponent decorator ───────────────
inf "STEP 6 — Fix DashboardComponent @Component decorator"
$f = "src\app\pages\dashboard\dashboard.component.ts"
if (Test-Path $f) {
    $raw = Get-Content $f -Raw
    # Use regex to move @Component block directly above export class
    $decoMatch = [regex]::Match($raw, '(@Component\(\{[\s\S]*?\}\))')
    if ($decoMatch.Success) {
        $deco = $decoMatch.Value
        # Remove from current position
        $without = $raw.Substring(0, $decoMatch.Index) + $raw.Substring($decoMatch.Index + $decoMatch.Length)
        $without = [regex]::Replace($without, '\n{3,}', "`n`n")
        # Insert directly above export class
        $fixed = $without -replace 'export class DashboardComponent', "$deco`nexport class DashboardComponent"
        Set-Content $f $fixed
        ok "Dashboard decorator repositioned"
    } else {
        warn "Could not find @Component block — fix manually"
    }
} else { warn "$f not found" }

# ─── STEP 7: Fix register2 — add CarouselModule ─────────────
inf "STEP 7 — Fix register2.component.ts (add CarouselModule)"
$f = "src\app\account\auth\register2\register2.component.ts"
if (Test-Path $f) {
    $raw = Get-Content $f -Raw
    if ($raw -notmatch "CarouselModule") {
        # Add import line
        $raw = "import { CarouselModule } from 'ngx-owl-carousel-o';`n" + $raw
        # Add to imports array
        $raw = $raw -replace "imports: \[", "imports: [`n    CarouselModule,"
        Set-Content $f $raw
        ok "Added CarouselModule to register2"
    } else { ok "CarouselModule already present" }
} else { warn "$f not found" }

# ─── STEP 8: Fix cyptolanding — add NgbAccordionModule ──────
inf "STEP 8 — Fix cyptolanding.component.ts (NgbAccordionModule)"
$f = "src\app\cyptolanding\cyptolanding.component.ts"
if (Test-Path $f) {
    $raw = Get-Content $f -Raw
    if ($raw -notmatch "NgbAccordionModule") {
        $raw = "import { NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';`n" + $raw
        $raw = $raw -replace "imports: \[", "imports: [`n    NgbAccordionModule,"
        Set-Content $f $raw
        ok "Added NgbAccordionModule to cyptolanding"
    } else { ok "NgbAccordionModule already present" }
} else { warn "$f not found" }

# ─── STEP 9: Suppress Sass warnings in angular.json ─────────
inf "STEP 9 — Suppress Sass deprecation warnings"
$f = "angular.json"
if (Test-Path $f) {
    $raw = Get-Content $f -Raw
    if ($raw -notmatch "silenceDeprecations") {
        $raw = $raw -replace '"stylePreprocessorOptions"', '"sassOptions": { "silenceDeprecations": ["import", "global-builtin", "color-functions"] },`n            "stylePreprocessorOptions"'
        Set-Content $f $raw
        ok "Sass warnings suppressed in angular.json"
    } else { ok "Already suppressed" }
}

# ─── Done ────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  All fixes applied! Run:  ng serve" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
Write-Host "If DashboardComponent TS1206 persists:" -ForegroundColor Yellow
Write-Host "  Open dashboard.component.ts manually"
Write-Host "  Move @Component({...}) to sit directly above:"
Write-Host "  'export class DashboardComponent'"
