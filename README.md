# 個人成長應用程式 — 實作規劃

zhtw

## 專案目標

建立一個全新的 SvelteKit 應用，提供給在家教育家庭記錄多個孩子的事件，並以時間軸方式檢視。後端使用 Supabase，部署到 Netlify。

## 技術堆疊

- **框架：** SvelteKit（新專案）
- **後端／驗證／資料庫：** Supabase（透過 CLI）
- **部署：** Netlify（透過 CLI，搭配 SvelteKit Netlify adapter）
- **樣式：** Tailwind CSS v4
- **UI：** https://github.com/retroui/RetroUI

## 階段 1 — 專案與後端設定

1. 建立一個新的 SvelteKit 專案，並使用 Netlify adapter（`@sveltejs/adapter-netlify`）。
2. 為這個新專案啟用 Supabase 整合。
3. 設定環境變數：
  - `PUBLIC_SUPABASE_URL`
  - `PUBLIC_SUPABASE_PUBLISHABLE_KEY`
4. 設定 Supabase 驗證提供者：
5. 電子郵件／密碼
6. 建立資料庫結構（如下）。

## 階段 2 — 資料庫結構

### `events`


| Column        | Type          | Notes                                                |
| ------------- | ------------- | ---------------------------------------------------- |
| `id`          | `uuid`        | 主鍵，預設 `gen_random_uuid()`                       |
| `user_id`     | `uuid`        | 參照 `auth.users(id)`，刪除時連動刪除                |
| `child_id`    | `uuid`        | 參照 `children(id)`，刪除時連動刪除                  |
| `title`       | `text`        | 不可為空                                             |
| `category`    | `text`        | 例如："事件"、"學習"、"行為"、"閱讀"         |
| `content`     | `text`        | 自由內容                                             |
| `tags`        | `text[]`      | 可選標籤                                             |
| `event_date`  | `date`        | 預設為今天                                           |
| `created_at`  | `timestamptz` | 預設為現在                                           |
| `updated_at`  | `timestamptz` | 預設為現在                                           |


### `children`

| Column       | Type          | Notes                                                |
| ------------ | ------------- | ---------------------------------------------------- |
| `id`         | `uuid`        | 主鍵，預設 `gen_random_uuid()`                       |
| `user_id`    | `uuid`        | 參照 `auth.users(id)`，刪除時連動刪除                |
| `name`       | `text`        | 孩子名稱                                             |
| `created_at` | `timestamptz` | 預設為現在                                           |
| `updated_at` | `timestamptz` | 預設為現在                                           |


### 安全性

- 在 `events` 資料表上啟用 RLS。
- 原則：已驗證使用者只能操作自己的資料列（`auth.uid() = user_id`）。
- 對 `authenticated` 授予 `SELECT, INSERT, UPDATE, DELETE`。
- 對 `service_role` 授予 `ALL`。

## 階段 3 — 驗證流程

1. 公開路由：`/`、`/login`。
2. 受保護的版型：`(app)/` 路由由 Supabase session 保護。
3. 登入頁：
  - 電子郵件／密碼表單
  - 註冊切換／按鈕
4. 登入頁：
  - 電子郵件輸入與密碼輸入
  - 呼叫 `supabase.auth.signInWithPassword({ email, password })`
5. Session 處理：
  - 使用 `@supabase/ssr` 或 SvelteKit hooks 管理 session。
  - 將 session 儲存在 cookie 中（secure、httpOnly）。
  - 將未登入使用者從受保護路由重新導向到 `/login`。

## 階段 4 — 核心功能

### 1. 儀表板／時間軸（`/app`）

- GitHub 風格的熱圖與連續紀錄
- 事件時間序列動態流
- 可依類別或標籤篩選
- 依月份／年份分組
- 新使用者的空狀態
- 支援切換孩子檔案與孩子 CRUD

### 2. 新增事件（`/app/events/new`）

- 表單欄位：標題、內容、標籤、類別、發生日期。
- 表單欄位：孩子檔案 ID、標題、內容、標籤、類別、發生日期。
- 類別選項：事件、學習、行為、閱讀、其他。
- 儲存到 `events` 資料表。
- 完成後重新導向回時間軸。

### 4. 項目詳情／編輯

- 點擊時間軸項目查看詳情。
- 編輯與刪除自己的項目。

### 5. 社交檔案（未來開發）

## 階段 5 — UI 與設計

- 乾淨、安定、適合家庭的視覺風格。
- 以行動裝置優先的時間軸版面。
- 使用語意化設計 tokens（不要硬編色碼）。
- 可存取的表單與驗證回饋。

## 階段 6 — 部署

1. 使用 Netlify adapter 建置。
2. 在 Netlify 控制台加入環境變數。
3. 為 SvelteKit SPA 行為設定重新導向規則。
4. 部署並端到端驗證驗證流程與 CRUD 流程。

## 開放決策／問題

- 是否要把 milestones 與 learning notes 合併成一個 `entries` 資料表，並用 `type` 欄位做分類以簡化設計？
- 是，加入 type 欄位做分類，之後再進一步實作標籤搜尋功能，未來也可加入徽章機制。
- MVP 要加入照片／媒體上傳，還是先維持純文字？
- 先以純文字為主。
- 時間軸要支援同一帳號下多個孩子／檔案，還是 MVP 先做一帳號對一孩子？
- 支援多個檔案，方便家庭管理。

## 交付內容

- 可在 Netlify 上運作的 SvelteKit 應用
- 具備驗證與資料表的 Supabase 後端
- 登入頁
- 受保護的應用區域，包含時間軸與事件表單
