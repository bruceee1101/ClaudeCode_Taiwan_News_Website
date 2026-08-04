# 財時 — 台灣金融股市新聞

每個交易日 19:00（Asia/Taipei）自動彙整台灣十大金融股市新聞，產出 TIME 雜誌風格的新聞頁。

**網站：** https://bruceee1101.github.io/taiwan-news-daily/

## 這個 repo 是什麼

只放**產出的靜態網頁**，供 GitHub Pages 託管，方便在手機上閱讀。

```
index.html        目錄頁（由 build_index.sh 自動產生，不要手改）
news/YYYYMMDD.html  當日新聞頁
build_index.sh    依 news/*.html 重建 index.html
```

產生這些頁面的流程（agent 定義、模板、風格指南）在私有 repo
[`ClaudeCode_Taiwan_News`](https://github.com/bruceee1101/ClaudeCode_Taiwan_News)，
由 Claude Code Cloud Routine 每個工作日自動執行後推送到這裡。

## 手動重建目錄頁

新增或刪除 `news/` 底下的檔案後：

```bash
bash build_index.sh
```

腳本會依檔名日期由新到舊排序，並從每頁抓出頭條標題當作摘要行。

## 內容聲明

所有標題均連向原始新聞網站，本站不轉載全文。摘要由 LLM 產生，僅供快速瀏覽，
投資決策請以原始報導與官方公告為準。
