#!/usr/bin/env bash
# ============================================================
# fix-all.sh  —  Run from your project ROOT on Mac/Linux
# Usage:  chmod +x fix-all.sh && ./fix-all.sh
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
info() { echo -e "${CYAN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}  ! $1${NC}"; }
err()  { echo -e "${RED}  ✗ $1${NC}"; }

# ── helper: safe in-place sed (works on both macOS and Linux)
sedi() { sed -i.bak "$@" && rm -f "${@: -1}.bak" 2>/dev/null || true; }

echo ""
echo "============================================================"
echo "  Skote Angular – Full Fix Script"
echo "============================================================"

# ─────────────────────────────────────────────────────────────
info "STEP 1 — Fix npm packages"
# ─────────────────────────────────────────────────────────────

# ng-bootstrap v19 broken with Angular 19 (DOCUMENT + afterEveryRender missing)
# v17 is the last version compatible with Angular 18/19
npm install @ng-bootstrap/ng-bootstrap@17.0.1 --save --legacy-peer-deps --silent
ok "ng-bootstrap pinned to 17.0.1"

# ngx-translate v17 dropped 3-arg constructor; v16 keeps it
npm install @ngx-translate/core@16.0.0 @ngx-translate/http-loader@16.0.0 --save --legacy-peer-deps --silent
ok "ngx-translate pinned to 16.x"

# ngx-ui-switch v16 has broken peer deps with Angular 19; v18 fixes it
npm install ngx-ui-switch@18.0.0 --save --legacy-peer-deps --silent
ok "ngx-ui-switch upgraded to 18.0.0"

# metismenujs v1.4 has wrong exports field; v1.3.1 is stable
npm install metismenujs@1.3.1 --save --legacy-peer-deps --silent
ok "metismenujs pinned to 1.3.1"

# ─────────────────────────────────────────────────────────────
info "STEP 2 — Fix auth.service.ts (getFirebaseBackend → initFirebaseBackend)"
# ─────────────────────────────────────────────────────────────
FILE="src/app/core/services/auth.service.ts"
if [ -f "$FILE" ]; then
  sedi 's/getFirebaseBackend/initFirebaseBackend/g' "$FILE"
  ok "Patched $FILE"
else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 3 — Fix styles.scss (remove ~ tilde prefix)"
# ─────────────────────────────────────────────────────────────
FILE="src/styles.scss"
if [ -f "$FILE" ]; then
  sedi "s|@import '~bootstrap/scss/bootstrap'|@import 'bootstrap/scss/bootstrap'|g" "$FILE"
  sedi 's|@import "~bootstrap/scss/bootstrap"|@import "bootstrap/scss/bootstrap"|g' "$FILE"
  ok "Fixed tilde import in styles.scss"
else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 4 — Fix _switch.scss (remove ~ tilde prefix for ngx-ui-switch)"
# ─────────────────────────────────────────────────────────────
FILE="src/assets/scss/custom/plugins/_switch.scss"
if [ -f "$FILE" ]; then
  sedi "s|@import '~ngx-ui-switch/ui-switch.component.scss'|@import 'ngx-ui-switch/ui-switch.component.scss'|g" "$FILE"
  sedi 's|@import "~ngx-ui-switch/ui-switch.component.scss"|@import "ngx-ui-switch/ui-switch.component.scss"|g' "$FILE"
  ok "Fixed tilde import in _switch.scss"
else
  warn "$FILE not found — skipping"
fi

# Also fix any other ~ tilde imports in all scss files
info "  Scanning all SCSS files for remaining ~ tilde imports..."
find src/assets/scss -name "*.scss" | while read f; do
  if grep -q "'~" "$f" 2>/dev/null || grep -q '"~' "$f" 2>/dev/null; then
    sedi "s|'~|'|g" "$f"
    sedi 's|"~|"|g' "$f"
    ok "  Fixed tilde imports in $f"
  fi
done

# ─────────────────────────────────────────────────────────────
info "STEP 5 — Fix sidebar.component.ts (metismenujs import path)"
# ─────────────────────────────────────────────────────────────
FILE="src/app/layouts/sidebar/sidebar.component.ts"
if [ -f "$FILE" ]; then
  # Replace "./dist/metismenujs" or "metismenujs/dist/metismenujs" with just "metismenujs"
  sedi "s|from './dist/metismenujs'|from 'metismenujs'|g" "$FILE"
  sedi 's|from "./dist/metismenujs"|from "metismenujs"|g' "$FILE"
  sedi "s|from 'metismenujs/dist/metismenujs'|from 'metismenujs'|g" "$FILE"
  sedi 's|from "metismenujs/dist/metismenujs"|from "metismenujs"|g' "$FILE"
  ok "Fixed metismenujs import path in sidebar.component.ts"
else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 6 — Fix DashboardComponent decorator (TS1206)"
# ─────────────────────────────────────────────────────────────
FILE="src/app/pages/dashboard/dashboard.component.ts"
if [ -f "$FILE" ]; then
  # Read the file content
  CONTENT=$(cat "$FILE")

  # Check if there's a @Component block BEFORE line 19 and class is at line 120
  # This means there are ~100 lines of non-decorator code between @Component and the class
  # Most common cause: another class or code block appears between decorator and class

  # Count lines
  DECO_LINE=$(grep -n "@Component(" "$FILE" | head -1 | cut -d: -f1)
  CLASS_LINE=$(grep -n "export class DashboardComponent" "$FILE" | head -1 | cut -d: -f1)

  echo "    @Component at line: $DECO_LINE"
  echo "    export class at line: $CLASS_LINE"

  if [ ! -z "$DECO_LINE" ] && [ ! -z "$CLASS_LINE" ]; then
    DIFF=$((CLASS_LINE - DECO_LINE))
    if [ "$DIFF" -gt 5 ]; then
      warn "Gap of $DIFF lines between @Component and class — attempting auto-fix..."
      # Strategy: extract @Component block, remove it from current position,
      # insert it directly above export class
      python3 - "$FILE" << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Find the @Component({...}) block (handles multiline)
deco_pattern = re.compile(r'(@Component\(\{.*?\}\))', re.DOTALL)
match = deco_pattern.search(content)

if match:
    deco_block = match.group(1)
    # Remove it from its current position
    content_without = content[:match.start()] + content[match.end():]
    # Strip any blank lines left where it was removed
    content_without = re.sub(r'\n{3,}', '\n\n', content_without)
    # Insert it directly above export class DashboardComponent
    content_fixed = content_without.replace(
        'export class DashboardComponent',
        deco_block + '\nexport class DashboardComponent',
        1
    )
    with open(path, 'w') as f:
        f.write(content_fixed)
    print("  Auto-fix applied to dashboard.component.ts")
else:
    print("  @Component block not found via regex — manual fix needed")
PYEOF
      ok "Dashboard decorator fix attempted"
    else
      ok "Dashboard decorator gap is fine ($DIFF lines)"
    fi
  fi
else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 7 — Fix register2.component.ts (add CarouselModule)"
# ─────────────────────────────────────────────────────────────
FILE="src/app/account/auth/register2/register2.component.ts"
if [ -f "$FILE" ]; then
  if ! grep -q "CarouselModule" "$FILE"; then
    # Add import line after the last existing import
    sedi '/^import /a\
import { CarouselModule } from '"'"'ngx-owl-carousel-o'"'"';' "$FILE"
    # Add to imports array
    sedi 's/imports: \[/imports: [\n    CarouselModule,/' "$FILE"
    ok "Added CarouselModule to register2.component.ts"
  else
    ok "CarouselModule already present in register2"
  fi
else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 8 — Fix cyptolanding.component.ts (add NgbAccordionModule + ScrollSpyDirective)"
# ─────────────────────────────────────────────────────────────
FILE="src/app/cyptolanding/cyptolanding.component.ts"
if [ -f "$FILE" ]; then

  # Add NgbAccordionModule
  if ! grep -q "NgbAccordionModule" "$FILE"; then
    sedi '/^import /a\
import { NgbAccordionModule } from '"'"'@ng-bootstrap/ng-bootstrap'"'"';' "$FILE"
    sedi 's/imports: \[/imports: [\n    NgbAccordionModule,/' "$FILE"
    ok "Added NgbAccordionModule to cyptolanding"
  else
    ok "NgbAccordionModule already present"
  fi

  # Find ScrollSpy directive path
  SCROLLSPY_PATH=$(find src -name "*.ts" | xargs grep -l "appScrollspy\|ScrollSpy" 2>/dev/null | grep -v "cyptolanding" | head -1)
  if [ ! -z "$SCROLLSPY_PATH" ]; then
    # Get class name
    SCROLLSPY_CLASS=$(grep -o "export class [A-Za-z]*" "$SCROLLSPY_PATH" | head -1 | awk '{print $3}')
    # Get relative path
    CYPTO_DIR=$(dirname "$FILE")
    REL_PATH=$(python3 -c "import os; print(os.path.relpath('${SCROLLSPY_PATH%.ts}', '$CYPTO_DIR'))" 2>/dev/null)
    if [ ! -z "$SCROLLSPY_CLASS" ] && ! grep -q "$SCROLLSPY_CLASS" "$FILE"; then
      sedi '/^import /a\
import { '"$SCROLLSPY_CLASS"' } from '"'"''"$REL_PATH"''"'"';' "$FILE"
      sedi 's/imports: \[/imports: [\n    '"$SCROLLSPY_CLASS"',/' "$FILE"
      ok "Added $SCROLLSPY_CLASS to cyptolanding (from $REL_PATH)"
    fi
  else
    warn "ScrollSpy directive not found in project — check manually"
  fi

else
  warn "$FILE not found — skipping"
fi

# ─────────────────────────────────────────────────────────────
info "STEP 9 — Suppress Sass deprecation warnings (angular.json)"
# ─────────────────────────────────────────────────────────────
FILE="angular.json"
if [ -f "$FILE" ]; then
  if ! grep -q "silenceDeprecations" "$FILE"; then
    # Add silenceDeprecations to sass options
    sedi 's|"stylePreprocessorOptions"|"sassOptions": { "silenceDeprecations": ["import", "global-builtin", "color-functions"] },\n            "stylePreprocessorOptions"|g' "$FILE"
    ok "Suppressed Sass deprecation warnings in angular.json"
  else
    ok "Sass deprecation warnings already suppressed"
  fi
fi

# ─────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "${GREEN}  All fixes applied!${NC}"
echo "  Run:  ng serve"
echo "============================================================"
echo ""
echo -e "${YELLOW}IF ng serve still shows errors:${NC}"
echo ""
echo "  DashboardComponent TS1206 — open dashboard.component.ts"
echo "  and manually move @Component({...}) to sit DIRECTLY"
echo "  above 'export class DashboardComponent'"
echo ""
echo "  scrollspy error — find your ScrollSpyDirective file and"
echo "  add it to cyptolanding.component.ts imports array"
echo ""
echo "  ngb-accordion errors — ng-bootstrap v17 uses NgbAccordionModule"
echo "  which re-exports the old <ngb-accordion> / <ngb-panel> components"
echo "  This should be fixed by STEP 7 above"
