#!/usr/bin/env bash
# 依 news/*.html 重建首頁目錄 index.html（最新的排最前面）
# 用法：bash build_index.sh
set -euo pipefail
cd "$(dirname "$0")"

# 固定用 C locale，讓 sed/awk 一律以位元組處理。
# 否則 [[:space:]] 在 Linux（UTF-8 locale）會吃掉全形空格 U+3000、
# 在 Windows Git Bash（C locale）不會，同一份 news/ 在兩邊會產生不同的 index.html。
export LC_ALL=C

WEEKDAYS=(日 一 二 三 四 五 六)

latest_date=""
latest_hero=""
rows=""

for f in $(ls -1 news/*.html 2>/dev/null | sort -r); do
  ymd=$(basename "$f" .html)
  case "$ymd" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) continue ;;
  esac

  y=${ymd:0:4}; m=${ymd:4:2}; d=${ymd:6:2}
  # 去掉前導零，讓日期讀起來像「8月4日」而不是「08月04日」
  disp="${y}年$((10#$m))月$((10#$d))日"
  wd=$(date -d "${y}-${m}-${d}" +%w 2>/dev/null || echo "")
  [ -n "$wd" ] && disp="$disp（週${WEEKDAYS[$wd]}）"

  # 從當日頁面抓頭條標題當摘要行；抓不到就留空，不影響版面。
  # 先把整個 <h1 class="hero-headline"> ... </h1> 區塊接成一行再剝掉標籤，
  # 這樣才不會被跨行的 <a href=... target=...> 屬性干擾（舊版頁面會這樣排）。
  # hero-headline 是現行模板，hero-title 是 20260704 以前的舊模板，兩者都吃。
  hero=$(awk '/class="hero-(headline|title)"/{f=1} f{buf=buf" "$0} f&&/<\/h[12]>/{print buf; exit}' "$f" 2>/dev/null \
         | sed -e 's/<[^>]*>/ /g' \
               -e 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'"'"'/g' \
               -e 's/[[:space:]][[:space:]]*/ /g' \
               -e 's/^ //; s/ $//' || true)

  if [ -z "$latest_date" ]; then
    latest_date="$disp"
    latest_hero="$hero"
    rows="$rows
      <li class=\"entry entry--latest\">
        <a href=\"$f\">
          <span class=\"entry__badge\">最新</span>
          <span class=\"entry__date\">$disp</span>
          <span class=\"entry__hero\">$hero</span>
        </a>
      </li>"
  else
    rows="$rows
      <li class=\"entry\">
        <a href=\"$f\">
          <span class=\"entry__date\">$disp</span>
          <span class=\"entry__hero\">$hero</span>
        </a>
      </li>"
  fi
done

if [ -z "$rows" ]; then
  rows='
      <li class="entry entry--empty">尚無新聞頁</li>'
fi

cat > index.html <<HTML
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>財時 — 台灣金融股市新聞</title>
<meta name="description" content="每個交易日彙整台灣十大金融股市新聞。" />
<meta name="theme-color" content="#D62503" />
<style>
  :root {
    --time-red: #D62503;
    --ink: #16181A;
    --muted: #6B7075;
    --rule: #E3E5E7;
    --bg: #FFFFFF;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--ink);
    font-family: Georgia, "Times New Roman", "Noto Serif TC", serif;
    -webkit-font-smoothing: antialiased;
  }
  .wrap { max-width: 1122px; margin: 0 auto; padding: 0 20px; }

  header { border-bottom: 8px solid var(--time-red); }
  .masthead { padding: 34px 0 18px; text-align: center; }
  .logo {
    display: inline-block;
    background: var(--time-red);
    color: #fff;
    font-family: "Franklin Gothic Medium", "Arial Narrow", Arial, sans-serif;
    font-weight: 700;
    font-size: clamp(38px, 11vw, 64px);
    letter-spacing: .06em;
    line-height: 1;
    padding: 10px 26px 12px;
    text-decoration: none;
  }
  .tagline {
    margin: 14px 0 0;
    font-family: "Franklin Gothic Book", Arial, sans-serif;
    font-size: 13px;
    letter-spacing: .18em;
    text-transform: uppercase;
    color: var(--muted);
  }

  .section-label {
    font-family: "Franklin Gothic Medium", Arial, sans-serif;
    font-size: 12px;
    letter-spacing: .2em;
    text-transform: uppercase;
    color: var(--time-red);
    margin: 34px 0 0;
  }

  ul.entries { list-style: none; margin: 10px 0 0; padding: 0; }
  .entry { border-bottom: 1px solid var(--rule); }
  .entry a {
    display: block;
    padding: 20px 0;
    text-decoration: none;
    color: inherit;
  }
  .entry a:hover .entry__date,
  .entry a:focus-visible .entry__date { color: var(--time-red); }
  .entry__badge {
    display: inline-block;
    background: var(--time-red);
    color: #fff;
    font-family: "Franklin Gothic Medium", Arial, sans-serif;
    font-size: 11px;
    letter-spacing: .14em;
    padding: 3px 9px;
    margin-right: 10px;
    vertical-align: 2px;
  }
  .entry__date {
    font-family: "Franklin Gothic Medium", "Arial Narrow", Arial, sans-serif;
    font-weight: 700;
    font-size: 22px;
    transition: color .15s ease;
  }
  .entry--latest .entry__date { font-size: 30px; }
  .entry__hero {
    display: block;
    margin-top: 6px;
    font-size: 16px;
    line-height: 1.5;
    color: var(--muted);
  }
  .entry--latest .entry__hero { color: var(--ink); font-size: 18px; }
  .entry--empty { padding: 24px 0; color: var(--muted); }

  footer {
    margin: 44px 0 0;
    border-top: 1px solid var(--rule);
    padding: 20px 0 46px;
    font-family: "Franklin Gothic Book", Arial, sans-serif;
    font-size: 12px;
    line-height: 1.7;
    color: var(--muted);
  }

  @media (max-width: 600px) {
    .masthead { padding: 24px 0 14px; }
    .entry a { padding: 16px 0; }
    .entry__date { font-size: 19px; }
    .entry--latest .entry__date { font-size: 24px; }
    .entry__hero { font-size: 15px; }
    .entry--latest .entry__hero { font-size: 16px; }
  }

  @media (prefers-color-scheme: dark) {
    :root { --ink: #F2F3F4; --muted: #9AA0A6; --rule: #2C2F33; --bg: #131416; }
  }
</style>
</head>
<body>
  <header>
    <div class="wrap masthead">
      <span class="logo">財時</span>
      <p class="tagline">Taiwan Finance Daily</p>
    </div>
  </header>

  <main class="wrap">
    <p class="section-label">每日新聞存檔</p>
    <ul class="entries">$rows
    </ul>
  </main>

  <footer class="wrap">
    每個交易日 19:00 自動彙整台灣十大金融股市新聞，內容由 Claude Code 產出。<br />
    所有標題均連向原始新聞網站，本站不轉載全文。
  </footer>
</body>
</html>
HTML

count=$(ls -1 news/*.html 2>/dev/null | wc -l)
echo "index.html 已重建，共 $count 天（最新：${latest_date:-無}）"
