# Personal Growth App — Implementation Plan

zhtw

## Project Goal

Build a fresh SvelteKit app for homeschooling families to record child milestones and free-form learning/behavioral notes, viewable as a timeline. Deploy to Netlify with Supabase as the backend.

## Tech Stack

- **Framework:** SvelteKit (new project)
- **Backend/Auth/DB:** Supabase (via CLI)
- **Deployment:** Netlify (via CLI, SvelteKit Netlify adapter)
- **Styling:** Tailwind CSS v4 
- **UI:** https://github.com/retroui/RetroUI

## Phase 1 — Project & Backend Setup

1. Scaffold a new SvelteKit project with the Netlify adapter (`@sveltejs/adapter-netlify`).
2. Enable Supabase integration for this new project.
3. Configure environment variables:
  - `PUBLIC_SUPABASE_URL`
  - `PUBLIC_SUPABASE_ANON_KEY`
4. Configure Supabase Auth providers:
5. Magiclink
6. Set up the database schema (see below).

## Phase 2 — Database Schema

### `milestones`


| Column        | Type          | Notes                                                |
| ------------- | ------------- | ---------------------------------------------------- |
| `id`          | `uuid`        | primary key, default `gen_random_uuid()`             |
| `user_id`     | `uuid`        | references `auth.users(id)` on delete cascade        |
| `title`       | `text`        | not null                                             |
| `description` | `text`        | optional details                                     |
| `category`    | `text`        | e.g., "milestone", "learning", "behavior", "reading" |
| `occurred_at` | `timestamptz` | defaults to now                                      |
| `created_at`  | `timestamptz` | defaults to now                                      |
| `updated_at`  | `timestamptz` | defaults to now                                      |


### `learning_notes`


| Column       | Type          | Notes                                         |
| ------------ | ------------- | --------------------------------------------- |
| `id`         | `uuid`        | primary key                                   |
| `user_id`    | `uuid`        | references `auth.users(id)` on delete cascade |
| `content`    | `text`        | free-form note                                |
| `tags`       | `text[]`      | optional homeschool tags                      |
| `noted_at`   | `timestamptz` | defaults to now                               |
| `created_at` | `timestamptz` | defaults to now                               |


### Security

- Enable RLS on both tables.
- Policies: authenticated users can CRUD only their own rows (`auth.uid() = user_id`).
- Grant `SELECT, INSERT, UPDATE, DELETE` to `authenticated`.
- Grant `ALL` to `service_role`.

## Phase 3 — Auth Flow

1. Public routes: `/`,  `/login`.
2. Protected layout: `(app)/` routes gated by Supabase session.
3. Login page:
  - "Send magic link" toggle/button
  - Link to register
4. Magic link page:
  - Email input → calls `supabase.auth.signInWithOtp({ email })`
5. Session handling:
  - Use `@supabase/ssr` or SvelteKit hooks to manage session.
  - Store session in cookies (secure, httpOnly).
  - Redirect unauthenticated users from protected routes to `/login`.

## Phase 4 — Core Features

### 1. Dashboard / Timeline (`/app`)

- GitHub style heatmap and streak
- Chronological feed combining milestones and learning notes.
- Filter by category or tag.
- Group by month/year.
- Empty state for new users.

### 2. Add Milestone (`/app/milestones/new`)

- Form fields: title, description, category, occurred_at.
- Category options: Milestone, Learning moment, Behavior, Reading, Other.
- Save to `milestones` table.
- Redirect back to timeline.

### 3. Add Learning Note (`/app/notes/new`)

- Form fields: content, tags (comma-separated), noted_at.
- Save to `learning_notes` table.
- Redirect back to timeline.

### 4. Entry Detail / Edit

- Click timeline item to view detail.
- Edit and delete own entries.

### 5. Social Profile (Future Development)

## Phase 5 — UI & Design

- Clean, calm, family-friendly aesthetic.
- Mobile-first timeline layout.
- Use semantic design tokens (no hardcoded colors).
- Accessible forms with validation feedback.

## Phase 6 — Deployment

1. Build with Netlify adapter.
2. Add environment variables to Netlify dashboard.
3. Configure redirect rules for SvelteKit SPA behavior.
4. Deploy and verify auth + CRUD flows end-to-end.

## Open Decisions / Questions

- Should milestones and learning notes be combined into one `entries` table with a `type` column for simplicity?
- Yes, add a type column for classification, and further implement tag features for easy search, and, in future, badge mechanism
- Do you want photo/media uploads in MVP, or keep it text-only for now?
- Text only is preferred
- Should the timeline support multiple children/profiles per account, or one account = one child for MVP?
- Multiple profiles for family management

## Deliverables

- Working SvelteKit app on Netlify
- Supabase backend with auth and tables
- Login page
- Protected app area with timeline, milestone form, and learning note form
