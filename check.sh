#!/usr/bin/env bash
# check.sh — publishing-filter checks for this site. Rules: govna/publishing-filter.md
#
# Targets Bash 3.2+ (macOS system Bash): no associative arrays, mapfile,
# ${var^^}, or &>>. Needs rg, curl, awk, and coreutils.
#
# Usage:
#   ./check.sh [paths...]   check the given files, or every .md changed since the latest tag
#   ./check.sh --all        check the whole site
#   ./check.sh --selftest   prove each detector on temporary fixtures
#   ./check.sh --register   validate govna/stance-register.md only
#   ./check.sh --no-net     skip external link fetching (combinable)
# Output: one "file:line: CODE message" per finding, then "failing entries: N".
# Exit: 0 clean, 1 findings, 2 usage error. W-* codes are warnings and never fail.
set -uo pipefail
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

ROOT="${CHECK_ROOT:-}"
[ -z "$ROOT" ] && ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT" || exit 2

NET=1
MODE=paths
DENYLIST="${BITS_DENYLIST:-$HOME/.config/bits/denylist.txt}"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
TMP=$(mktemp -d "${TMPDIR:-/tmp}/check.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/findings"; : >"$OUT"
URLCACHE="$TMP/urlcache"; : >"$URLCACHE"
INDEXDIRS="$TMP/indexdirs"; : >"$INDEXDIRS"
DENY_ACTIVE="$TMP/deny"; : >"$DENY_ACTIVE"
if [ -s "$DENYLIST" ]; then rg -v -e '^[[:space:]]*(#|$)' "$DENYLIST" >"$DENY_ACTIVE" 2>/dev/null || true; fi

GUID_RE='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
GUID_OK='1950a258-227b-4e31-a9cf-717495945fc2|00000000-0000-0000-0000-000000000000'
SSH_RE='ssh-(ed25519|rsa|ecdsa|dss) AAAA[A-Za-z0-9+/]{20,}'
HEX_RE='\b[0-9a-f]{40,}\b'
HEX_OK='sha256|shasum|sha512|md5sum|SHA-?256|SHA-?512|\.(iso|gz|tgz|zip|tar|dmg|img|xz|7z|pem|crt)\b'
MAC_RE='\b([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\b|\b0800[0-9A-F]{8}\b'
EMAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
EMAIL_OK='@(example\.(com|org|net)|mydomain\.com|somewhere\.com|contoso\.com|users\.noreply\.github\.com|github\.com|tty[0-9])|YOUR-[A-Z-]*@'
PATH_RE='/(Users|home)/[A-Za-z0-9._-]+|(~|\$HOME|\$\{HOME\}|\$\(HOME\))/[A-Za-z0-9][A-Za-z0-9._-]*|Mobile Documents|CloudDocs'
PATH_OK='/(Users|home)/(myuser|myusername|someuser|user1|USERNAME|username|pi|linuxbrew|roms|test|<)|(~|\$HOME|\$\{HOME\}|\$\(HOME\))/(Applications|Desktop|Documents|Downloads|Library|Movies|Music|Pictures|Public|bin)$'
ORG_RE='(github\.com|githubusercontent\.com)/kquo/'
FP_RE="\\b(I|my|me|myself|I'm|I've|I'd)\\b"
YEAR_RE='\b(19[0-9]{2}|20[0-9]{2})\b'
PERSONAL_RE='\b(wife|husband|partner|kids?|children|daughter|son|mother|father|parents?|employer|my company|my job|my boss|my doctor|diagnos|my house|my apartment|I live in|my neighborhood|my hometown|my salary)\b'
SELF_RE='\b(lonel(y|iness)|depress(ed|ion|ing)?|anxi(ety|ous)|panic attacks?|therap(y|ist)|counsell?ing|medicat(ed|ion)|antidepress[a-z]*|suicid[a-z]*|self-harm|trauma[a-z]*|burn(ed|t)? ?out|mental (health|illness|state)|patholog[a-z]*|detach(ed|ment)|aloof[a-z]*|out of place|my (moods?|feelings|emotions|insecurit[a-z]*|shame|grief))\b'
SELF_OK='<!-- private-ok -->'
MARKER_RE='NEEDS REWRITE|\(need link\)|\[Need sources\]|Needs clean up'
MARKER_CS_RE='\b(TODO|FIXME|TBD)\b'
HEADING_RE='^#{1,6}[[:space:]]*(Conclusion|Final Thoughts|Bottom Line|Key Insight|Summary|Question|Answer|My take|Opinion|My opinion|Thoughts|My thoughts|Verdict)[[:space:]]*:?[[:space:]]*$'
URL_SKIP='mydomain\.com|example\.(com|org|net)|somewhere\.com|contoso\.com|169\.254\.169\.254|://(10|192\.168|127)\.|localhost|\{|%s|<|\$|/\.default$|token\.actions\.githubusercontent\.com|management\.azure\.com/?$|graph\.microsoft\.com/?$'
HOST_ALLOW='cbo\.gov|stackoverflow\.com|stackexchange\.com|medium\.com|congress\.gov|sagepub\.com|politico\.com|devgenius\.io|hrw\.org|grc\.com|condenaststore\.com'
HOST_SHORT='youtu\.be|youtube\.com|a\.co|aka\.ms|bit\.ly|t\.co|amazon\.com'
FENCE_MAX=40
INDEX_MAX=104
ZOMBIE_RE='(tion|sion|ment|ance|ence|ity|ness)s?$'
ZOMBIE_OK='institution institutions question questions evidence position positions consciousness attention sentence sentences intelligence decision decisions security reflexivity information education audience audiences reference references identity identities community communities business businesses argument arguments responsibility responsibilities humanity environment environments condition conditions compassion coalition coalitions consequence consequences curiosity science sciences conscience experience experiences difference differences existence essence silence violence presence absence independence confidence influence influences sequence sequences tradition traditions religion religions opinion opinions emotion emotions nation nations generation generations population populations society societies reality realities quality qualities ability abilities possibility possibilities opportunity opportunities authority authorities majority minority minorities university universities activity activities priority priorities moment moments element elements government governments treatment treatments agreement agreements department departments parliament happiness darkness kindness illness illnesses weakness weaknesses madness sadness fairness goodness richness loneliness witness witnesses wilderness fitness'
ZOMBIE_MAX=50
QA_RE='^[[:space:]]*([0-9]+\.|[-*+])[[:space:]]+(\*\*)?(?i:how|what|why|where|when|which|who|is|are|can|do|does|should)\b.*\?[[:space:]]*$|^[[:space:]]*(\*\*)?(Q|A|Question|Answer)(\*\*)?:|^[[:space:]]*\*\*(Q|A|Question|Answer)\*\*[[:space:]]|^[[:space:]]*(Q|A)[.)-][[:space:]]'
ES_RE='el|los|las|una|está|están|también|porque|más|cómo|qué|años|desde|hasta|cuando|tiene|tienen|hacer|sobre|entre|muy|pero|ser|ese|esa|esto|nosotros|ellos|siempre|nunca|mundo|vida|gente|cosas|mejor|ahora|todo|todos|nada|puede|pueden|mismo|cada|donde|aquí|que|por|si|hacia|abajo|arriba|después|antes|solo|sólo|algo|alguien|nadie|otra|otro|otros|otras|nuestro|nuestra|sino|aunque|mientras|entonces|así|aún|hoy|mañana|bien|pequeño|primero|último|hombre|mujer|tiempo|cosa|hecho|tener|decir|dice|dijo|fue|eran|fueron|estar|somos|soy|eres|vamos|voy|quiero|puedo|sabe|saber|vez|veces|día|días|noche|esta|este|estos|estas|aquel|aquella|quien|quién|dónde|cuál|cuánto'
ES_SENT=3
ES_MIN=4
NAME_RE='[A-Z][a-z]+ [A-Z][a-z]+'
NAME_OK='Azure Management|Microsoft Graph'
NAME_GROUP='[A-Z][a-z]+ (Americans?|Latinos?|Latinas?|Hispanics?|Europeans?|Africans?|Asians?)'
STALE_STOP='their|about|which|would|through|never|every|since|rather|between|those|these|after|before|other|only|into|more|most|than|such|same|both|each|some|what|when|where|from|with|that|this|have|been|being|does|over|under|while|because|without|within|should|could|there|whether|itself|another|someone|anyone|nothing|always|often|still|entry|entries'
BACKOFF_1=2
BACKOFF_2=5

usage() {
  sed -n '2,15p' "$SELF" | sed 's/^# \{0,1\}//'
}

emit() { # file line code message
  printf '%s:%s: %s %s\n' "$1" "$2" "$3" "$4" >>"$OUT"
}

kind_of() {
  case "$1" in
    life/index.md | mind/index.md | society/index.md | tech/index.md) echo index ;;
    life/*/index.md | mind/*/index.md | society/*/index.md | tech/*/index.md) echo index ;;
    life/*.md | mind/*.md | society/*.md | tech/*.md) echo entry ;;
    about.md | index.md) echo root ;;
    *.md) echo other ;;
    *) echo skip ;;
  esac
}

front_value() { # file key -> value or empty
  awk -v key="$2" 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1 && index($0,key":")==1 {v=$0; sub("^" key ":[[:space:]]*","",v); gsub(/^["'"'"']|["'"'"']$/,"",v); print v; exit}' "$1"
}

prose_words() { # file -> word count outside front matter, fences, html comments
  awk 'NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=0; next} fm==1{next}
       /^(```|~~~)/{fence=!fence; next} fence{next}
       {gsub(/<!--[^>]*-->/,""); print}' "$1" | wc -w | tr -d ' '
}

fence_max() { # file -> longest fenced block line count
  awk '/^(```|~~~)/{ if(fence){ if(n>max)max=n; fence=0 } else { fence=1; n=0 }; next } fence{n++} END{print max+0}' "$1"
}

slugs_of() { # file -> kramdown and gfm slugs of every heading, one per line
  rg -N -e '^#{1,6} ' "$1" 2>/dev/null | sed -E 's/^#+[[:space:]]*//; s/[[:space:]]*#*[[:space:]]*$//' \
    | tr '[:upper:]' '[:lower:]' | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g; s/[^a-z0-9 _-]//g; s/ /-/g' \
    | awk '{print; g=$0; sub(/^[^a-z]+/,"",g); if(g!=$0) print g}'
}

linksrc() { # file -> same line count with fenced blocks and code spans blanked
  awk '/^(```|~~~)/{fence=!fence; print ""; next} fence{print ""; next} {gsub(/`[^`]*`/,""); print}' "$1"
}

prosesrc() { # file -> same line count with front matter, fenced blocks, and block quotes blanked
  awk 'NR==1 && $0=="---"{fm=1; print ""; next} fm==1 && $0=="---"{fm=0; print ""; next} fm==1{print ""; next}
       /^(```|~~~)/{fence=!fence; print ""; next} fence{print ""; next} /^>/{print ""; next} {print}' "$1"
}

sentences_of() { # file -> "line<TAB>sentence" per sentence, table rows skipped, link addresses and bare URLs removed
  awk '/^\|/{next} { line=$0
         gsub(/\]\([^)]*\)/, "]", line); gsub(/<https?:[^>]*>/, "", line); gsub(/https?:\/\/[^ )>]*/, "", line)
         gsub(/e\.g\./, "eg", line); gsub(/i\.e\./, "ie", line); gsub(/U\.S\./, "US", line); gsub(/U\.K\./, "UK", line)
         n=split("Dr Mr Mrs Ms Jr Sr St No vs etc", ab, " "); for (k=1;k<=n;k++) gsub(ab[k] "\\.", ab[k], line)
         gsub(/[A-HJ-Z]\. /, "X ", line)
         m=split(line, s, "[.!?]+[ \"\047)]*"); for (i=1;i<=m;i++) if (s[i] ~ /[A-Za-z0-9]/) printf "%d\t%s\n", NR, s[i] }' "$1"
}


plain_mean() { # file -> mean words per sentence over prose, in tenths
  prosesrc "$1" | awk '/^#/{next} /^\|/{next} /^[[:space:]]*$/{next} {print}' | sed -E 's/\]\([^)]*\)/]/g; s/`[^`]*`/x/g' | tr '\n' ' ' \
    | awk '{ n=split($0, tk, /[[:space:]]+/); out=""; for(i=1;i<=n;i++){ w=tk[i]; if (w ~ /^[A-Z]\.[,;:)]?$/ || w ~ /^(e\.g\.|i\.e\.|etc\.|vs\.|Dr\.|Mr\.|Mrs\.|Ms\.|Jr\.|Sr\.|St\.|No\.|U\.S\.|U\.K\.)[,;:)]?$/) gsub(/\./, "", w); out=out " " w }
             n=split(out, s, "[.!?]+([ \"\047)]+|$)"); w=0; c=0; for(i=1;i<=n;i++){ k=split(s[i], t, /[[:space:]]+/); m=0; for(j=1;j<=k;j++) if(t[j]!="") m++; if(m>0){w+=m; c++} } if(c==0) print 0; else printf "%d\n", (w*10)/c }'
}

sentence_limits() { # file type -> "line<TAB>code<TAB>message" for sentences over the cap and paragraphs over six sentences
  prosesrc "$1" | awk -v t="$2" '
    function norm(s,   n, tk, i, w, out) {
      gsub(/<!--[^>]*-->/, "", s); gsub(/\]\([^)]*\)/, "]", s); gsub(/`[^`]*`/, "x", s); gsub(/<https?:[^>]*>/, "", s); gsub(/https?:\/\/[^ )>]*/, "", s)
      n = split(s, tk, /[[:space:]]+/); out = ""
      for (i = 1; i <= n; i++) { w = tk[i]; if (w ~ /^[A-Z]\.[,;:)]?$/ || w ~ /^(e\.g\.|i\.e\.|etc\.|vs\.|Dr\.|Mr\.|Mrs\.|Ms\.|Jr\.|Sr\.|St\.|No\.|U\.S\.|U\.K\.)[,;:)]?$/) gsub(/\./, "", w); out = out " " w }
      return out
    }
    function unit(s, start, step,   n, sn, i, k, tt, j, m, c, cap) {
      s = norm(s); cap = (step && t == "howto") ? 20 : 25; c = 0
      n = split(s, sn, "[.!?]+([ \"\047)]+|$)")
      for (i = 1; i <= n; i++) {
        k = split(sn[i], tt, /[[:space:]]+/); m = 0; for (j = 1; j <= k; j++) if (tt[j] != "") m++
        if (m > 0) { c++; if (m > cap) printf "%d\tW-SENT\tsentence of %d words, keep it to %d or fewer\n", start, m, cap }
      }
      if (!step && c > 6) printf "%d\tW-PARA\tparagraph of %d sentences, keep it to six or fewer\n", start, c
    }
    function flush() { if (buf != "") unit(buf, bstart, 0); buf = "" }
    /^#/ || /^\|/ || /^[[:space:]]*$/ { flush(); next }
    /^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]/ { flush(); s = $0; sub(/^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]+/, "", s); unit(s, NR, 1); next }
    { if (buf == "") bstart = NR; buf = buf " " $0 }
    END { flush() }'
}

zombie_rate() { # file -> "tenths word:count ..." nominalizations per 100 prose words, most frequent first
  prosesrc "$1" | awk '/^#/{next} /^\|/{next} /^[[:space:]]*$/{next} {print}' | sed -E 's/\]\([^)]*\)/]/g; s/`[^`]*`/x/g' \
    | awk -v re="$ZOMBIE_RE" -v oklist="$ZOMBIE_OK" 'BEGIN{ n=split(oklist, a, " "); for (i=1;i<=n;i++) ok[a[i]]=1 }
        { n=split($0, t, "[^A-Za-z\047-]+"); for (i=1;i<=n;i++){ w=tolower(t[i]); if (w=="") continue; words++; if (length(w)>=8 && w ~ re && !(w in ok)) { z++; c[w]++ } } }
        END{ print (words ? int(1000*z/words+0.5) : 0); for (w in c) print c[w], w }' \
    | { IFS= read -r rate; printf '%s' "$rate"; sort -rn | awk '{printf " %s:%s", $2, $1}'; printf '\n'; }
}

budget_for() {
  case "$1" in take) echo 250 ;; note) echo 400 ;; howto) echo 500 ;; quote) echo 300 ;; reference) echo 0 ;; *) echo 400 ;; esac
}

# ── privacy (every file) ────────────────────────────────────────────────────
check_privacy() {
  local f="$1" l
  rg -n -e "$GUID_RE" "$f" | rg -v -e "$GUID_OK" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-GUID "GUID in content"; done
  rg -n -e "$SSH_RE" "$f" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-SSH "SSH key material"; done
  rg -n -e "$HEX_RE" "$f" | rg -v -e "$HEX_OK" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-HEX "long hex string"; done
  rg -n -e "$MAC_RE" "$f" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-MAC "MAC address"; done
  rg -n -e "$EMAIL_RE" "$f" | rg -v -e "$EMAIL_OK" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-EMAIL "email address outside placeholder domains"; done
  rg -n -o -e "$PATH_RE" "$f" | rg -v -e "$PATH_OK" | cut -d: -f1 | sort -n -u | while read -r l; do emit "$f" "$l" P-PATH "home directory path, home-folder layout, or iCloud Drive path"; done
  if [ "$f" != CHANGELOG.md ]; then
    rg -n -e "$ORG_RE" "$f" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-ORG "reference to the retired kquo org"; done
  fi
  if [ -s "$DENY_ACTIVE" ]; then
    rg -n -i -F -f "$DENY_ACTIVE" "$f" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-DENY "denylisted literal"; done
  fi
  sentences_of "$f" | rg -e "$FP_RE" | rg -e "$YEAR_RE" | cut -f1 | sort -n -u | while read -r l; do emit "$f" "$l" W-YEAR "exact year in a first-person sentence"; done
  rg -n -e "$FP_RE" "$f" | rg -i -e "$PERSONAL_RE" | cut -d: -f1 | while read -r l; do emit "$f" "$l" W-PERSONAL "personal detail keyword in a first-person sentence"; done
  rg -n -e "$FP_RE" "$f" | rg -i -e "$SELF_RE" | rg -v -F -e "$SELF_OK" | cut -d: -f1 | while read -r l; do emit "$f" "$l" P-SELF "mental or emotional health keyword in a first-person sentence"; done
}

# ── links (every file) ──────────────────────────────────────────────────────
norm_url() { printf '%s' "$1" | sed -E 's#^https?://##; s#^www\.##; s#[?#].*$##; s#/$##'; }

fetch_url() { # url -> "code final"
  local hit code try=0
  hit=$(awk -F'\t' -v u="$1" '$1==u{print $2; exit}' "$URLCACHE")
  if [ -n "$hit" ]; then printf '%s' "$hit"; return; fi
  while :; do
    hit=$(curl -sL -A "$UA" --max-time 20 -r 0-0 -o /dev/null -w '%{http_code} %{url_effective}' "$1" 2>/dev/null || printf '000 -')
    code="${hit%% *}"
    if [ "$code" = 429 ] && [ "$try" -lt 2 ]; then :; elif [ "$code" = 000 ] && [ "$try" -lt 1 ]; then :; else break; fi
    try=$((try+1)); if [ "$try" -eq 1 ]; then sleep "$BACKOFF_1"; else sleep "$BACKOFF_2"; fi
  done
  if [ "$code" = 416 ]; then hit=$(curl -sL -A "$UA" --max-time 20 -o /dev/null -w '%{http_code} %{url_effective}' "$1" 2>/dev/null || printf '000 -'); fi
  printf '%s\t%s\n' "$1" "$hit" >>"$URLCACHE"
  printf '%s' "$hit"
}

page_body() { # url -> path of cached body
  local key p
  key=$(printf '%s' "$1" | shasum -a 256 | cut -c1-32); p="$TMP/page.$key"
  [ -f "$p" ] || curl -sL -A "$UA" --max-time 25 -o "$p" "$1" 2>/dev/null || : >"$p"
  printf '%s' "$p"
}

check_anchor() { # file line url -> W-ANCHOR when the fragment is not on the page
  local f="$1" l="$2" u="$3" base frag dec ent p c
  base="${u%%#*}"; frag="${u#*#}"
  case "$frag" in '' | /* | !*) return 0 ;; esac
  dec=$(printf '%b' "$(printf '%s' "$frag" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')")
  ent=$(printf '%s' "$dec" | sed "s/'/\&#39;/g")
  p=$(page_body "$base")
  for c in "$frag" "$dec" "$ent"; do
    rg -q -F -e "id=\"$c\"" -e "name=\"$c\"" -e "href=\"#$c\"" -e "id=\"user-content-$c\"" "$p" && return 0
  done
  emit "$f" "$l" W-ANCHOR "no anchor #$frag on the page: $base"
}

check_external() { # file line url
  local f="$1" l="$2" u="$3" res code final
  printf '%s' "$u" | rg -q -e 'https?://que\.one' && { emit "$f" "$l" L-ABS "absolute que.one link, use a relative path"; return 0; }
  printf '%s' "$u" | rg -q -e "$URL_SKIP" && return 0
  [ "$NET" -eq 1 ] || return 0
  printf '%s' "$u" | rg -q -e "://([^/]*\.)?($HOST_ALLOW)" && { emit "$f" "$l" W-EXT "host on the bot-block allowlist, verify in a browser: $u"; return 0; }
  res=$(fetch_url "$u"); code="${res%% *}"; final="${res#* }"
  case "$code" in
    2*) ;;
    429) emit "$f" "$l" W-EXT "rate limited, retry: $u"; return 0 ;;
    *) emit "$f" "$l" L-EXT "dead ($code): $u"; return 0 ;;
  esac
  case "$u" in *\#*) check_anchor "$f" "$l" "$u" ;; esac
  printf '%s' "$u" | rg -q -e "://([^/]*\.)?($HOST_SHORT)" && return 0
  printf '%s' "$u" | rg -q -e 'github\.com/[^/]+/[^/]+/raw/' && return 0
  if [ "$(norm_url "$u")" != "$(norm_url "$final")" ]; then emit "$f" "$l" L-EXT "moved to $final"; fi
}

check_links() {
  local f="$1" d line l t p a target src="$TMP/links.src"
  d=$(dirname "$f")
  linksrc "$f" >"$src"
  : >"$TMP/links.seen"
  { rg -n -o -e '\]\(((?:[^()]|\([^()]*\))+)\)' -r '$1' "$src"; rg -n -o -e 'href="([^"]+)"' -r '$1' "$src"; rg -n -o -e '<(https?://[^>]+)>' -r '$1' "$src"; } 2>/dev/null \
  | sort -u | sort -t: -k1,1n | while IFS= read -r line; do
    l="${line%%:*}"; t="${line#*:}"
    t="${t%% *}"
    case "$t" in
      http://* | https://*) printf '%s:%s\n' "$l" "$t" >>"$TMP/links.seen"; check_external "$f" "$l" "$t" ;;
      mailto:* | tel:* | \{\{*) ;;
      \#*) a="${t#\#}"; slugs_of "$f" | rg -q -x -F "$a" || emit "$f" "$l" L-ANCHOR "no heading for #$a in this page" ;;
      *)
        p="${t%%#*}"; a=""; case "$t" in *\#*) a="${t#*#}" ;; esac
        target="$d/$p"; [ "$d" = . ] && target="$p"
        if [ -e "$target" ]; then :
        elif [ -e "$target.md" ]; then target="$target.md"
        else emit "$f" "$l" L-REL "missing target $t"; continue; fi
        if [ -n "$a" ] && [ -f "$target" ]; then
          slugs_of "$target" | rg -q -x -F "$a" || emit "$f" "$l" L-ANCHOR "no heading for #$a in $p"
        fi ;;
    esac
  done
  rg -n -o -e 'https?://(github\.com|raw\.githubusercontent\.com)/queone/[^[:space:]`"'"'"')>]+' "$f" 2>/dev/null \
    | sort -u | sort -t: -k1,1n | while IFS= read -r line; do
    rg -q -x -F -- "$line" "$TMP/links.seen" 2>/dev/null && continue
    l="${line%%:*}"; t="${line#*:}"
    check_external "$f" "$l" "$t"
  done
}

# ── structure and budgets (entries and root pages) ──────────────────────────
check_structure() {
  local f="$1" kind="$2" l t words budget fmax pm
  { rg -n -i -e "$MARKER_RE" "$f"; rg -n -e "$MARKER_CS_RE" "$f"; } | cut -d: -f1 | sort -n -u | while read -r l; do emit "$f" "$l" X-MARKER "placeholder marker"; done
  rg -n -i -e "$HEADING_RE" "$f" | cut -d: -f1 | while read -r l; do emit "$f" "$l" X-HEADING "boilerplate section heading"; done
  t=$(front_value "$f" type)
  if [ "$kind" = entry ]; then
    if [ -z "$t" ]; then
      if [ "$MODE" = all ]; then emit "$f" 1 W-TYPE "no type front matter, treated as note"; else emit "$f" 1 B-TYPE "type front matter required on a changed entry"; fi
      t=note
    else
      case "$t" in take | note | howto | reference | quote) ;; *) emit "$f" 1 B-TYPE "unknown type $t"; t=note ;; esac
    fi
  else
    t=note
  fi
  budget=$(budget_for "$t"); words=$(prose_words "$f")
  if [ "$budget" -gt 0 ] && [ "$words" -gt "$budget" ]; then emit "$f" 1 B-WORDS "$words prose words, budget $budget for $t"; fi
  fmax=$(fence_max "$f")
  if [ "$t" != reference ] && [ "$fmax" -gt "$FENCE_MAX" ]; then emit "$f" 1 B-FENCE "fenced block of $fmax lines, limit $FENCE_MAX"; fi
  if [ "$kind" = entry ] && { [ "$t" = take ] || [ "$t" = note ]; }; then
    pm=$(plain_mean "$f")
    if [ "$pm" -gt 160 ]; then emit "$f" 1 W-PLAIN "mean $((pm / 10)).$((pm % 10)) words per sentence, keep a take or note near 16 or fewer"; fi
    zr=$(zombie_rate "$f"); zt=${zr%% *}; zw=${zr#* }; [ "$zw" = "$zr" ] && zw=""
    if [ "$zt" -gt "$ZOMBIE_MAX" ]; then emit "$f" 1 W-ZOMBIE "nominalizations at $((zt / 10)).$((zt % 10)) per 100 words, above $((ZOMBIE_MAX / 10)).$((ZOMBIE_MAX % 10)): $zw"; fi
  fi
  if [ "$kind" = entry ] && { [ "$t" = take ] || [ "$t" = note ] || [ "$t" = howto ] || [ "$t" = reference ]; }; then
    sentence_limits "$f" "$t" | while IFS=$'\t' read -r l c m; do emit "$f" "$l" "$c" "$m"; done
  fi
  prosesrc "$f" >"$TMP/prose.src"
  rg -n -o -i -w -e "$ES_RE" "$TMP/prose.src" | tr '[:upper:]' '[:lower:]' | sort -u | cut -d: -f1 | uniq -c | awk -v m="$ES_MIN" '$1>=m{print $2}' | while read -r l; do emit "$f" "$l" X-LANG "Spanish prose, write the entry in English"; done
  awk '/^#|^\|/{next} { line=$0; gsub(/\]\([^)]*\)/, "]", line); n=split(line, s, "[.!?]+[ \"\047)]*"); for(i=1;i<=n;i++) if (s[i] ~ /[A-Za-z]/) printf "%d\t%s\n", NR, s[i] }' "$TMP/prose.src" >"$TMP/sent.src"
  rg -n -o -i -w -e "$ES_RE" "$TMP/sent.src" | tr '[:upper:]' '[:lower:]' | sort -u | cut -d: -f1 | uniq -c | awk -v m="$ES_SENT" '$1>=m{print $2}' | while read -r sl; do l=$(sed -n "${sl}p" "$TMP/sent.src" | cut -f1); emit "$f" "$l" X-LANG "Spanish prose, write the entry in English"; done
  rg -n -e "$QA_RE" "$TMP/prose.src" | cut -d: -f1 | while read -r l; do emit "$f" "$l" X-QA "question-and-answer form"; done
  awk '/^#|^\||^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]/{next} /^[^.!?]*\?[[:space:]]*$/{print NR}' "$TMP/prose.src" | while read -r l; do emit "$f" "$l" X-QA "paragraph that is only a question"; done
  awk '/^(```|~~~)/{ if(!fence && ($0=="```" || $0=="~~~")) print NR; fence=!fence }' "$f" | while read -r l; do emit "$f" "$l" X-FENCE "fenced block without a language tag"; done
  if [ "$kind" = entry ] && { [ "$t" = take ] || [ "$t" = note ]; }; then
    awk -v re="$NAME_RE" -v ok="$NAME_OK" -v grp="$NAME_GROUP" '/^#/{next} /\]\(|<https?:|attributed/{next} { gsub(ok, "", $0); gsub(grp, "", $0) } $0 ~ re {print NR}' "$TMP/prose.src" | while read -r l; do emit "$f" "$l" W-NAME "named person with no source link in this paragraph"; done
  fi
}

# ── index completeness (directories with an index.md) ───────────────────────
check_index_dir() { # dir
  local d="$1" idx="$1/index.md" f name
  [ -f "$idx" ] || return 0
  for f in "$d"/*.md "$d"/*/index.md; do
    [ -e "$f" ] || continue
    [ "$f" = "$idx" ] && continue
    name="${f#$d/}"
    rg -q -F -e "]($name)" -e "]($name#" -e "href=\"$name\"" "$idx" || emit "$idx" 1 I-INDEX "missing entry $name"
  done
  case "$d" in */*) return 0 ;; esac   # the length cap covers the four area indexes only
  local n=0 l t rest len
  while IFS= read -r l; do
    n=$((n+1))
    case "$l" in "- ["*"]("*"): "*) ;; *) continue ;; esac
    t="${l#- [}"; t="${t%%]*}"; rest="${l#*): }"; len=$(( ${#t} + 2 + ${#rest} ))
    [ "$len" -gt "$INDEX_MAX" ] && emit "$idx" "$n" I-LONG "index line is $len characters, cap $INDEX_MAX"
  done <"$idx"
}

# ── stance register ─────────────────────────────────────────────────────────
check_register() {
  local reg="govna/stance-register.md" l row status tok owners pos stem total hit
  [ -f "$reg" ] || { emit "$reg" 1 R-PATH "register missing"; return; }
  rg -n -e '^\| *[0-9]+ *\|' "$reg" | while IFS= read -r row; do
    l="${row%%:*}"; row="${row#*:}"
    status=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$5); print $5}')
    case "$status" in settled | unresolved) ;; *) emit "$reg" "$l" R-PATH "status must be settled or unresolved" ;; esac
    owners=''
    printf '%s' "$row" | awk -F'|' '{print $4}' | rg -o -e '`[^`]+`' | tr -d '`' | while read -r tok; do
      [ -e "$tok" ] || emit "$reg" "$l" R-PATH "owning path missing: $tok"
    done
    for tok in $(printf '%s' "$row" | awk -F'|' '{print $4}' | rg -o -e '`[^`]+`' | tr -d '`'); do [ -f "$tok" ] && owners="$owners $tok"; done
    [ -n "$owners" ] || continue
    pos=$(printf '%s' "$row" | awk -F'|' '{print $3}')
    total=0; hit=0
    for stem in $(printf '%s' "$pos" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z\n' ' ' | tr ' ' '\n' | awk 'length($0)>=5' | rg -v -x -e "$STALE_STOP" | cut -c1-5 | sort -u); do
      total=$((total+1)); rg -q -i -e "\\b$stem" $owners && hit=$((hit+1))
    done
    if [ "$total" -gt 0 ] && [ $((hit * 2)) -lt "$total" ]; then emit "$reg" "$l" W-STALE "owning entry uses $hit of $total key terms, reword the row or fix the owner"; fi
  done
}

# ── driver ──────────────────────────────────────────────────────────────────
check_file() {
  local f="$1" kind
  kind=$(kind_of "$f")
  [ "$kind" = skip ] && return 0
  [ -f "$f" ] || { emit "$f" 1 L-REL "file not found"; return 0; }
  check_privacy "$f"
  check_links "$f"
  case "$kind" in
    entry) check_structure "$f" entry; printf '%s\n' "$(dirname "$f")" >>"$INDEXDIRS" ;;
    root) check_structure "$f" root ;;
    index) printf '%s\n' "$(dirname "$f")" >>"$INDEXDIRS" ;;
  esac
}

changed_set() {
  local tag
  tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
  { if [ -n "$tag" ]; then git diff --name-only "$tag" -- . ; else git ls-files; fi; git ls-files --others --exclude-standard; } 2>/dev/null \
    | rg -e '\.md$' | sort -u | while read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done
}

all_set() {
  { fd -e md . life mind society tech govna 2>/dev/null || find life mind society tech govna -name '*.md'; printf '%s\n' about.md index.md AGENTS.md plan.md CHANGELOG.md README.md; } \
    | sed 's#^\./##' | sort -u | while read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done
}

report() {
  local fails
  sort -u "$OUT"
  fails=$(rg -v -e ': W-' "$OUT" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')
  printf 'failing entries: %s\n' "$fails"
  [ "$fails" -eq 0 ]
}

# ── selftest ────────────────────────────────────────────────────────────────
selftest() {
  local fx="$TMP/fx" clean="$TMP/clean" res ok=0 c
  mkdir -p "$fx/life/sub" "$fx/govna" "$clean/life" "$clean/govna"
  printf '# comment line\n\nsecretword\n' >"$TMP/deny.txt"
  {
    printf -- '---\ntype: take\n---\n## Dirty\n'
    printf 'Id 12345678-abcd-4bcd-8bcd-123456789abc here.\n'
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIabcdefghijklmnopqrstuvwxyz0123 user@host\n'
    printf 'hash 0123456789abcdef0123456789abcdef0123456789abcdef\n'
    printf 'mac 08:00:27:AE:2F:12 and 080027AE2F12\n'
    printf 'mail someone@realcompany.com\n'
    printf 'path /%s/realname/code\n' Users
    printf 'home ~/vault/notes\n'
    printf 'drive Library/Mobile Documents/com~apple~CloudDocs/x\n'
    printf 'org https://github.com/kquo/thing\n'
    printf 'the SecretWord appears\n'
    printf 'I first read it in 1992 and my wife agreed.\n'
    printf 'I felt lonely and out of place that season.\n'
    printf 'see [broken](nowhere.md) and [anchor](#no-such-heading) and [abs](https://que.one/x) and [dead](https://nonexistent.invalid/x)\n'
    printf 'TODO fix\n## Conclusion\n### My take\n'
    printf 'No hay nada más viral que la enfermedad del pesimismo, y esto tiene que ver con la mente.\n'
    printf -- '- How does it work?\nQ: is this a transcript?\n'
    printf 'Winston Churchill said this without a source.\n'
    printf '```\n'; printf 'curl -L https://github.com/queone/no-such-repo/raw/main/x.sh\n'; c=0; while [ $c -lt 45 ]; do printf 'line %s\n' "$c"; c=$((c+1)); done; printf '```\n'
    c=0; while [ $c -lt 300 ]; do printf 'word '; c=$((c+1)); done; printf '\n'
  } >"$fx/life/dirty.md"
  printf '## Untyped\n\nShort.\n' >"$fx/life/untyped.md"
  printf -- '---\ntype: take\n---\n## Spanish\n\nI keep one line from a film here. Nunca encontrarás un arco iris si estás mirando hacia abajo. It still moves me.\n' >"$fx/life/spanish.md"
  printf -- '---\ntype: note\n---\n## QA\n\nHow do I decrypt a disc?\n\nUse the app.\n\n- how does it work?\n\n**Q** Is it safe?\n' >"$fx/life/qa.md"
  printf -- '---\ntype: take\n---\n## Anchor\n\nI link a [missing anchor](https://en.wikipedia.org/wiki/Main_Page#no-such-anchor).\n' >"$fx/life/anchor.md"
  printf -- '---\ntype: note\n---\n## Zombie\n\nThe implementation of the utilization plan needs the consideration and determination of the organization, with documentation, evaluation, and verification of each modification and notification.\n' >"$fx/life/zombie.md"
  printf -- '---\ntype: take\n---\n## Digest\n\nThe region keeps SHA-256 `0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`.\n' >"$fx/life/digest.md"
  printf -- '---\ntype: take\n---\n## Approved\n\nI call my detachment a choice. <!-- private-ok -->\n' >"$fx/life/selfok.md"
  printf -- '---\ntype: take\n---\n## Year OK\n\nI read [it](https://example.com/2020/x) twice. I saw https://example.com/2019/y once.\n\nI read the book. It came out in 1998.\n' >"$fx/life/yearok.md"
  printf -- '---\ntype: take\n---\n## Year Abbreviation\n\nI moved to the U.S. in 1999, e.g. for work.\n' >"$fx/life/yearabbr.md"
  printf -- '---\ntype: take\n---\n## Year Table\n\nI keep this list.\n\n| Title | Released |\n|---|---|\n| Episode I | 1999 |\n' >"$fx/life/yeartable.md"
  printf -- '---\ntype: take\n---\n## Group Name\n\nBlack Americans opened a door, and Latin American writers noticed.\n' >"$fx/life/groupname.md"
  wn() { local i=1 s='Alpha'; while [ "$i" -lt "$1" ]; do i=$((i + 1)); s="$s w$i"; done; printf '%s' "$s"; }
  printf -- '---\ntype: take\n---\n## Sent Long\n\n%s.\n' "$(wn 26)" >"$fx/life/sentlong.md"
  printf -- '---\ntype: take\n---\n## Sent OK\n\n%s.\n' "$(wn 25)" >"$fx/life/sentok.md"
  printf -- '---\ntype: howto\n---\n## Step Long\n\n1. %s.\n' "$(wn 21)" >"$fx/life/steplong.md"
  printf -- '---\ntype: howto\n---\n## Step OK\n\n1. %s.\n' "$(wn 20)" >"$fx/life/stepok.md"
  printf -- '---\ntype: take\n---\n## Para Long\n\nOne two. One two. One two. One two. One two. One two. One two.\n' >"$fx/life/paralong.md"
  printf -- '---\ntype: take\n---\n## Para OK\n\nOne two. One two. One two. One two. One two. One two.\n' >"$fx/life/paraok.md"
  printf -- '---\ntype: quote\n---\n## Quote Exempt\n\n%s.\n' "$(wn 40)" >"$fx/life/quoteex.md"
  printf -- '---\ntype: take\n---\n## Block Exempt\n\nA short line.\n\n> %s.\n' "$(wn 40)" >"$fx/life/bqex.md"
  printf -- '---\ntype: take\n---\n## Allow\n\nI link a [cartoon](https://condenaststore.com/featured/x.html).\n' >"$fx/life/allow.md"
  printf -- '---\ntype: take\n---\n## Retry\n\nI link a [slow host](https://retry.example.test/x).\n' >"$fx/life/retry.md"
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/curl" <<'SHIM'
#!/bin/sh
n=$(cat "$COUNTFILE" 2>/dev/null || echo 0); n=$((n+1)); echo $n >"$COUNTFILE"
for a in "$@"; do u="$a"; done
if [ "${SHIM_MODE:-429}" = 000 ]; then
  if [ "$n" -le 1 ]; then printf "000 -"; else printf "200 %s" "$u"; fi
elif [ "${SHIM_MODE:-429}" = 416 ]; then
  r=0; for a in "$@"; do [ "$a" = "-r" ] && r=1; done
  if [ "$r" = 1 ]; then printf "416 %s" "$u"; else printf "200 %s" "$u"; fi
else
  if [ "$n" -le 2 ]; then printf "429 %s" "$u"; else printf "200 %s" "$u"; fi
fi
SHIM
  chmod +x "$TMP/bin/curl"
  printf -- '---\ntype: take\n---\n## Initials\n\nAs J. J. C. Smart and E. O. Wilson argued, e.g. in the U.S. and the U.K., this sentence runs to twenty words. Dr. Smith, Mr. Jones, i.e. two people, vs. St. Paul, etc. wrote another sentence that also runs on to twenty words.\n' >"$fx/life/initials.md"
  printf '## Life\n\n- [Dirty](dirty.md)\n- [Long](dirty.md): A description that runs on and on, past the cap, so that the index line wraps on a phone and on a laptop alike.\n' >"$fx/life/index.md"
  printf '## Sub\n' >"$fx/life/sub/index.md"
  printf '# Register\n\n| # | Position | Owning entry | Status |\n|---|---|---|---|\n| 1 | X. | `life/missing.md` | settled |\n| 2 | Y. | `life/dirty.md` | bogus |\n| 3 | Markets reward innovation through price signals. | `life/dirty.md` | settled |\n' >"$fx/govna/stance-register.md"
  printf -- '---\ntype: note\n---\n## Clean\n\nA clean [entry](index.md) with one [ref](https://en.wikipedia.org/wiki/Main_Page).\n\nMicrosoft Graph accepts the token. Photos sit in ~/Pictures/x and settings in ~/.config/x.\n' >"$clean/life/clean.md"
  printf '## Life\n\n- [Clean](clean.md)\n' >"$clean/life/index.md"
  printf '# Register\n\n| # | Position | Owning entry | Status |\n|---|---|---|---|\n| 1 | X. | `life/clean.md` | settled |\n' >"$clean/govna/stance-register.md"

  res=$( (CHECK_ROOT="$fx" BITS_DENYLIST="$TMP/deny.txt" "$SELF" life/dirty.md life/untyped.md life/initials.md life/spanish.md life/qa.md life/anchor.md life/zombie.md life/selfok.md life/digest.md; CHECK_ROOT="$fx" "$SELF" --register) 2>&1 )
  for c in P-GUID P-SSH P-HEX P-MAC P-EMAIL P-PATH P-ORG P-DENY P-SELF W-YEAR W-PERSONAL B-TYPE B-WORDS B-FENCE L-REL L-ANCHOR L-ABS L-EXT X-MARKER X-HEADING X-LANG X-QA X-FENCE W-NAME W-PLAIN W-ZOMBIE W-ANCHOR W-STALE I-INDEX I-LONG R-PATH; do
    if printf '%s\n' "$res" | rg -q -e " $c "; then printf 'PASS %s\n' "$c"; else printf 'FAIL %s\n' "$c"; ok=1; fi
  done
  if printf '%s\n' "$res" | rg -q -e "life/initials.md:1: W-PLAIN"; then printf 'PASS W-PLAIN-initials\n'; else printf 'FAIL W-PLAIN-initials\n'; ok=1; fi
  if printf '%s\n' "$res" | rg -q -e "life/spanish.md:[0-9]+: X-LANG"; then printf 'PASS X-LANG-sentence\n'; else printf 'FAIL X-LANG-sentence\n'; ok=1; fi
  if [ "$(printf '%s\n' "$res" | rg -c -e "life/qa.md:[0-9]+: X-QA")" -ge 3 ]; then printf 'PASS X-QA-paragraph\n'; else printf 'FAIL X-QA-paragraph\n'; ok=1; fi
  if printf '%s\n' "$res" | rg -q -e "life/digest.md:[0-9]+: P-HEX"; then printf 'FAIL P-HEX-digest-label\n'; ok=1; else printf 'PASS P-HEX-digest-label\n'; fi
  if printf '%s\n' "$res" | rg -q -e "life/selfok.md:[0-9]+: P-SELF"; then printf 'FAIL P-SELF-override\n'; ok=1; else printf 'PASS P-SELF-override\n'; fi
  if printf '%s\n' "$res" | rg -q -e "life/dirty.md:15: W-YEAR"; then printf 'PASS W-YEAR-same-sentence\n'; else printf 'FAIL W-YEAR-same-sentence\n'; ok=1; fi
  res2=$( (CHECK_ROOT="$fx" "$SELF" --no-net life/yearok.md life/yearabbr.md life/yeartable.md life/groupname.md) 2>&1 )
  if printf '%s\n' "$res2" | rg -q -e "life/yearok.md:[0-9]+: W-YEAR"; then printf 'FAIL W-YEAR-link-or-neighbor-ignored\n'; ok=1; else printf 'PASS W-YEAR-link-or-neighbor-ignored\n'; fi
  if printf '%s\n' "$res2" | rg -q -e "life/yearabbr.md:[0-9]+: W-YEAR"; then printf 'PASS W-YEAR-abbreviation\n'; else printf 'FAIL W-YEAR-abbreviation\n'; ok=1; fi
  if printf '%s\n' "$res2" | rg -q -e "life/yeartable.md:[0-9]+: W-YEAR"; then printf 'FAIL W-YEAR-table-row\n'; ok=1; else printf 'PASS W-YEAR-table-row\n'; fi
  if printf '%s\n' "$res2" | rg -q -e "life/groupname.md:[0-9]+: W-NAME"; then printf 'FAIL W-NAME-group-name\n'; ok=1; else printf 'PASS W-NAME-group-name\n'; fi
  res4=$( (CHECK_ROOT="$fx" "$SELF" --no-net life/sentlong.md life/sentok.md life/steplong.md life/stepok.md life/paralong.md life/paraok.md life/quoteex.md life/bqex.md) 2>&1 )
  if printf '%s\n' "$res4" | rg -q -e "life/sentlong.md:[0-9]+: W-SENT"; then printf 'PASS W-SENT-over-cap\n'; else printf 'FAIL W-SENT-over-cap\n'; ok=1; fi
  if printf '%s\n' "$res4" | rg -q -e "life/sentok.md:[0-9]+: W-SENT"; then printf 'FAIL W-SENT-at-cap\n'; ok=1; else printf 'PASS W-SENT-at-cap\n'; fi
  if printf '%s\n' "$res4" | rg -q -e "life/steplong.md:[0-9]+: W-SENT"; then printf 'PASS W-SENT-step-over-cap\n'; else printf 'FAIL W-SENT-step-over-cap\n'; ok=1; fi
  if printf '%s\n' "$res4" | rg -q -e "life/stepok.md:[0-9]+: W-SENT"; then printf 'FAIL W-SENT-step-at-cap\n'; ok=1; else printf 'PASS W-SENT-step-at-cap\n'; fi
  if printf '%s\n' "$res4" | rg -q -e "life/paralong.md:[0-9]+: W-PARA"; then printf 'PASS W-PARA-over-cap\n'; else printf 'FAIL W-PARA-over-cap\n'; ok=1; fi
  if printf '%s\n' "$res4" | rg -q -e "life/paraok.md:[0-9]+: W-PARA"; then printf 'FAIL W-PARA-at-cap\n'; ok=1; else printf 'PASS W-PARA-at-cap\n'; fi
  if printf '%s\n' "$res4" | rg -q -e "life/(quoteex|bqex).md:[0-9]+: W-(SENT|PARA)"; then printf 'FAIL W-SENT-quotes-exempt\n'; ok=1; else printf 'PASS W-SENT-quotes-exempt\n'; fi
  res3=$( (CHECK_ROOT="$fx" "$SELF" life/allow.md) 2>&1 )
  if printf '%s\n' "$res3" | rg -q -e "life/allow.md:[0-9]+: W-EXT" && ! printf '%s\n' "$res3" | rg -q -e "life/allow.md:[0-9]+: L-EXT"; then printf 'PASS W-EXT-allowlist\n'; else printf 'FAIL W-EXT-allowlist\n'; ok=1; fi
  if printf '%s\n' "$res" | rg -q -e "life/dirty.md:11: P-PATH"; then printf 'PASS P-PATH-home\n'; else printf 'FAIL P-PATH-home\n'; ok=1; fi
  if printf '%s\n' "$res" | rg -q -e "life/dirty.md:12: P-PATH"; then printf 'PASS P-PATH-icloud\n'; else printf 'FAIL P-PATH-icloud\n'; ok=1; fi
  if printf '%s\n' "$res" | rg -q -e "life/dirty.md:[0-9]+: L-EXT dead \(404\): https://github.com/queone/no-such-repo"; then printf 'PASS L-EXT-fenced\n'; else printf 'FAIL L-EXT-fenced\n'; ok=1; fi
  res=$( (COUNTFILE="$TMP/count" PATH="$TMP/bin:$PATH" CHECK_ROOT="$fx" "$SELF" life/retry.md) 2>&1 )
  if [ "$(cat "$TMP/count")" = 3 ] && ! printf '%s\n' "$res" | rg -q -e "W-EXT|L-EXT"; then printf 'PASS RETRY-429\n'; else printf 'FAIL RETRY-429\n'; ok=1; fi
  res=$( (COUNTFILE="$TMP/count0" SHIM_MODE=000 PATH="$TMP/bin:$PATH" CHECK_ROOT="$fx" "$SELF" life/retry.md) 2>&1 )
  if [ "$(cat "$TMP/count0")" = 2 ] && ! printf '%s\n' "$res" | rg -q -e "W-EXT|L-EXT"; then printf 'PASS RETRY-000\n'; else printf 'FAIL RETRY-000\n'; ok=1; fi
  res=$( (COUNTFILE="$TMP/count416" SHIM_MODE=416 PATH="$TMP/bin:$PATH" CHECK_ROOT="$fx" "$SELF" life/retry.md) 2>&1 )
  if [ "$(cat "$TMP/count416")" = 2 ] && ! printf '%s\n' "$res" | rg -q -e "W-EXT|L-EXT"; then printf 'PASS RETRY-416\n'; else printf 'FAIL RETRY-416\n'; ok=1; fi
  res=$( (CHECK_ROOT="$clean" BITS_DENYLIST="$TMP/deny.txt" "$SELF" --all; CHECK_ROOT="$clean" "$SELF" --register) 2>&1 )
  if printf '%s\n' "$res" | rg -q -e ': [A-Z]-'; then printf 'FAIL clean fixture produced findings:\n%s\n' "$res"; ok=1; else printf 'OK clean-fixture\n'; fi
  return $ok
}

# ── main ────────────────────────────────────────────────────────────────────
main() {
  local files='' a d
  for a in "$@"; do
    case "$a" in
      -h | -\? | --help) usage; return 0 ;;
      --all) MODE=all ;;
      --selftest) MODE=selftest ;;
      --register) MODE=register ;;
      --no-net) NET=0 ;;
      -*) printf 'unsupported option %s\n' "$a" >&2; usage >&2; return 2 ;;
      *) files="$files$a"$'\n' ;;
    esac
  done
  case "$MODE" in
    selftest) selftest; return $? ;;
    register) check_register; report; return $? ;;
  esac
  [ -s "$DENYLIST" ] || printf 'W-DENY denylist not found at %s (set BITS_DENYLIST)\n' "$DENYLIST" >&2
  if [ "$MODE" = all ]; then files=$(all_set); elif [ -z "$files" ]; then files=$(changed_set); fi
  [ -n "$files" ] || { printf 'nothing to check\n'; printf 'failing entries: 0\n'; return 0; }
  printf '%s\n' "$files" | while read -r a; do [ -n "$a" ] && check_file "$a"; done
  if [ "$MODE" = all ]; then
    for a in life mind society tech; do [ -d "$a" ] || continue; check_index_dir "$a"; for d in "$a"/*/; do [ -d "$d" ] && check_index_dir "${d%/}"; done; done
    check_register
  else
    sort -u "$INDEXDIRS" | while read -r a; do [ -n "$a" ] && check_index_dir "$a"; done
  fi
  report
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
  exit $?
fi
