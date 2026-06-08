#!/bin/bash

# ============================================================
# Skote Angular - Build Error Fix Script
# Run from your project root: bash fix-skote.sh
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

echo ""
echo "============================================================"
echo "  Skote Angular Build Error Fixer"
echo "============================================================"
echo ""

# ── Guard: must be run from project root ────────────────────
if [ ! -f "angular.json" ]; then
  err "angular.json not found. Please run this script from your project root."
  exit 1
fi

# ============================================================
# FIX 1: ngx-ui-switch missing stylesheet
# ============================================================
echo ""
info "FIX 1: Checking ngx-ui-switch..."

SWITCH_FILE="src/assets/scss/custom/plugins/_switch.scss"

if [ -f "$SWITCH_FILE" ]; then
  # Try installing the package first
  if ! npm list ngx-ui-switch --depth=0 &>/dev/null; then
    log "Installing ngx-ui-switch..."
    npm install ngx-ui-switch --save
  else
    log "ngx-ui-switch already installed."
  fi

  # Check if the scss file exists in node_modules
  if [ ! -f "node_modules/ngx-ui-switch/ui-switch.component.scss" ]; then
    warn "ngx-ui-switch scss not found at expected path. Commenting out the import..."
    # Comment out the broken import line
    sed -i.bak "s|@import 'ngx-ui-switch/ui-switch.component.scss';|// @import 'ngx-ui-switch/ui-switch.component.scss'; // commented out - file not found|" "$SWITCH_FILE"
    log "Commented out broken import in $SWITCH_FILE"
  else
    log "ngx-ui-switch scss found — no change needed."
  fi
else
  warn "$SWITCH_FILE not found, skipping."
fi

# ============================================================
# FIX 2: owl-carousel-o — install if missing
# ============================================================
echo ""
info "FIX 2: Checking ngx-owl-carousel-o..."

if ! npm list ngx-owl-carousel-o --depth=0 &>/dev/null; then
  log "Installing ngx-owl-carousel-o..."
  npm install ngx-owl-carousel-o --save
else
  log "ngx-owl-carousel-o already installed."
fi

# Patch Register2Component to import CarouselModule
REGISTER2_TS="src/app/account/auth/register2/register2.component.ts"
if [ -f "$REGISTER2_TS" ]; then
  if ! grep -q "CarouselModule" "$REGISTER2_TS"; then
    log "Adding CarouselModule import to Register2Component..."
    # Add import statement after the last existing import line
    sed -i.bak "/^import /{ h; }; \${x; /^import /{a\\
import { CarouselModule } from 'ngx-owl-carousel-o';
    }; x}" "$REGISTER2_TS" 2>/dev/null || \
    # Fallback: prepend import at top of file
    sed -i.bak "1s|^|import { CarouselModule } from 'ngx-owl-carousel-o';\n|" "$REGISTER2_TS"

    # Add CarouselModule to the imports array inside @Component
    python3 - <<'PYEOF'
import re, sys

path = "src/app/account/auth/register2/register2.component.ts"
with open(path, "r") as f:
    content = f.read()

# Add CarouselModule to imports array if not already there
if "CarouselModule" not in content:
    # Insert import at top
    content = "import { CarouselModule } from 'ngx-owl-carousel-o';\n" + content

# Find imports: [...] array in @Component and add CarouselModule
def add_to_imports(match):
    arr = match.group(0)
    if "CarouselModule" in arr:
        return arr
    # insert before closing bracket
    return arr.rstrip("]") + ", CarouselModule]"

content = re.sub(r'imports:\s*\[[^\]]*\]', add_to_imports, content)

with open(path, "w") as f:
    f.write(content)
print("  Patched Register2Component imports array.")
PYEOF
  else
    log "CarouselModule already present in Register2Component."
  fi
else
  warn "$REGISTER2_TS not found, skipping."
fi

# ============================================================
# FIX 3: initFirebaseBackend called without config argument
# ============================================================
echo ""
info "FIX 3: Fixing initFirebaseBackend() calls in auth.service.ts..."

AUTH_SERVICE="src/app/core/services/auth.service.ts"
AUTH_UTILS="src/app/authUtils.ts"

if [ -f "$AUTH_SERVICE" ] && [ -f "$AUTH_UTILS" ]; then
  python3 - <<'PYEOF'
import re

path = "src/app/core/services/auth.service.ts"
with open(path, "r") as f:
    content = f.read()

# Check if environment is already imported
has_env_import = "environment" in content

if not has_env_import:
    # Add environment import at top
    content = "import { environment } from '../../../environments/environment';\n" + content

# Replace initFirebaseBackend() with initFirebaseBackend(environment.firebaseConfig)
original = content
content = content.replace(
    "initFirebaseBackend()",
    "initFirebaseBackend(environment.firebaseConfig)"
)

if content != original:
    with open(path, "w") as f:
        f.write(content)
    print("  Patched auth.service.ts — added firebaseConfig argument to all initFirebaseBackend() calls.")
else:
    print("  auth.service.ts already patched or pattern not found.")
PYEOF
else
  warn "auth.service.ts or authUtils.ts not found, skipping."
fi

# ============================================================
# FIX 4: ngb-accordion/ngb-panel — import NgbAccordionModule
# ============================================================
echo ""
info "FIX 4: Fixing ngb-accordion in CyptolandingComponent..."

CRYPTO_TS="src/app/cyptolanding/cyptolanding.component.ts"
if [ -f "$CRYPTO_TS" ]; then
  python3 - <<'PYEOF'
import re

path = "src/app/cyptolanding/cyptolanding.component.ts"
with open(path, "r") as f:
    content = f.read()

changed = False

# Add NgbAccordionModule import if missing
if "NgbAccordionModule" not in content:
    content = "import { NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';\n" + content
    changed = True

# Add to imports array
def add_to_imports(match):
    arr = match.group(0)
    if "NgbAccordionModule" in arr:
        return arr
    return arr.rstrip("]") + ", NgbAccordionModule]"

new_content = re.sub(r'imports:\s*\[[^\]]*\]', add_to_imports, content)
if new_content != content:
    changed = True
    content = new_content

if changed:
    with open(path, "w") as f:
        f.write(content)
    print("  Patched CyptolandingComponent with NgbAccordionModule.")
else:
    print("  CyptolandingComponent already has NgbAccordionModule.")
PYEOF
else
  warn "$CRYPTO_TS not found, skipping."
fi

# ============================================================
# FIX 5: appScrollspy — find and import ScrollspyDirective
# ============================================================
echo ""
info "FIX 5: Fixing appScrollspy directive in CyptolandingComponent..."

# Search for the directive file
SCROLLSPY_FILE=$(find src -name "scrollspy.directive.ts" 2>/dev/null | head -1)

if [ -n "$SCROLLSPY_FILE" ]; then
  log "Found ScrollspyDirective at: $SCROLLSPY_FILE"
  python3 - "$SCROLLSPY_FILE" <<'PYEOF'
import re, sys, os

directive_path = sys.argv[1]
component_path = "src/app/cyptolanding/cyptolanding.component.ts"

# Build relative import path
comp_dir = os.path.dirname(component_path)
rel = os.path.relpath(directive_path.replace(".ts", ""), comp_dir)
if not rel.startswith("."):
    rel = "./" + rel

with open(component_path, "r") as f:
    content = f.read()

changed = False

if "ScrollspyDirective" not in content:
    content = f"import {{ ScrollspyDirective }} from '{rel}';\n" + content
    changed = True

def add_to_imports(match):
    arr = match.group(0)
    if "ScrollspyDirective" in arr:
        return arr
    return arr.rstrip("]") + ", ScrollspyDirective]"

new_content = re.sub(r'imports:\s*\[[^\]]*\]', add_to_imports, content)
if new_content != content:
    changed = True
    content = new_content

if changed:
    with open(component_path, "w") as f:
        f.write(content)
    print(f"  Patched CyptolandingComponent with ScrollspyDirective from {rel}")
else:
    print("  ScrollspyDirective already imported.")
PYEOF
else
  warn "Could not find scrollspy.directive.ts. You may need to add it manually."
  warn "Look for a file with 'appScrollspy' selector and import it into CyptolandingComponent."
fi

# ============================================================
# FIX 6: Sass deprecation warnings — silence in angular.json
# ============================================================
echo ""
info "FIX 6: Suppressing Sass deprecation warnings in angular.json..."

python3 - <<'PYEOF'
import json, re

with open("angular.json", "r") as f:
    data = json.load(f)

def patch_build(options):
    if "stylePreprocessorOptions" not in options:
        options["stylePreprocessorOptions"] = {}
    # Add sass options to suppress deprecation warnings
    options["sassOptions"] = {
        "quietDeps": True,
        "silenceDeprecations": ["import", "global-builtin", "color-functions", "string-quote"]
    }
    return options

patched = 0
projects = data.get("projects", {})
for proj_name, proj in projects.items():
    targets = proj.get("architect", proj.get("targets", {}))
    for target_name in ["build", "test"]:
        target = targets.get(target_name, {})
        opts = target.get("options", {})
        if opts:
            target["options"] = patch_build(opts)
            patched += 1
        for config in target.get("configurations", {}).values():
            patch_build(config)

with open("angular.json", "w") as f:
    json.dump(data, f, indent=2)

print(f"  Patched {patched} build target(s) in angular.json with sassOptions.")
PYEOF

# ============================================================
# DONE
# ============================================================
echo ""
echo "============================================================"
echo -e "  ${GREEN}All fixes applied!${NC}"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  1. Run:  ng serve"
echo "  2. If you still see ngb-accordion errors, your ng-bootstrap"
echo "     version may have dropped the old API. Run:"
echo "     npm install @ng-bootstrap/ng-bootstrap@latest"
echo "  3. Check src/environments/environment.ts has a 'firebaseConfig'"
echo "     key if you use Firebase auth."
echo ""
