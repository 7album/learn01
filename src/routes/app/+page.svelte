<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { formatDate } from '$lib/date';
  import type { EntryRecord } from '$lib/entryTypes';

  let loading = true;
  let error = '';
  let items: Array<EntryRecord & { label: string; meta: string }> = [];

  async function loadEntries() {
    loading = true;
    error = '';

    const [{ data: milestones, error: milestoneError }, { data: notes, error: noteError }] = await Promise.all([
      supabase.from('milestones').select('id,title,description,category,occurred_at,created_at,updated_at').order('occurred_at', { ascending: false }),
      supabase.from('learning_notes').select('id,content,tags,noted_at,created_at').order('noted_at', { ascending: false })
    ]);

    if (milestoneError || noteError) {
      error = milestoneError?.message ?? noteError?.message ?? '載入資料失敗';
      loading = false;
      return;
    }

    const combined = [
      ...(milestones ?? []).map((item) => ({
        ...item,
        type: 'milestone' as const,
        label: item.category || '里程碑',
        title: item.title,
        meta: `${formatDate(item.occurred_at)} · ${item.category || '里程碑'}`
      })),
      ...(notes ?? []).map((item) => ({
        ...item,
        type: 'learning_note' as const,
        label: '學習筆記',
        title: item.content || '未命名筆記',
        meta: `${formatDate(item.noted_at)} · ${(item.tags ?? []).join('、') || '無標籤'}`
      }))
    ].sort((left, right) => {
      const leftDate = new Date(left.occurred_at || left.noted_at || left.created_at || '').getTime();
      const rightDate = new Date(right.occurred_at || right.noted_at || right.created_at || '').getTime();
      return rightDate - leftDate;
    });

    items = combined;
    loading = false;
  }

  async function removeEntry(item: EntryRecord) {
    const confirmDelete = confirm('確定要刪除這筆資料嗎？');
    if (!confirmDelete) return;

    const table = item.type === 'milestone' ? 'milestones' : 'learning_notes';
    const { error: deleteError } = await supabase.from(table).delete().eq('id', item.id);

    if (deleteError) {
      error = deleteError.message;
      return;
    }

    await loadEntries();
  }

  onMount(() => {
    void loadEntries();
  });
</script>

<section class="space-y-8">
  <div class="rounded-3xl bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 p-8 text-white shadow-xl">
    <p class="text-sm uppercase tracking-[0.3em] text-white/60">儀表板</p>
    <h2 class="mt-3 text-3xl font-semibold">用於登入後測試的簡易時間軸</h2>
    <p class="mt-3 max-w-2xl text-white/75">使用這個受保護區域來確認驗證、導覽與新增資料流程，之後再串接正式的 Supabase 資料。</p>
  </div>

  <div class="grid gap-4 md:grid-cols-3">
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">追蹤中的孩子</p>
      <p class="mt-2 text-3xl font-semibold">2</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">本週</p>
      <p class="mt-2 text-3xl font-semibold">5 筆</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">目前連續天數</p>
      <p class="mt-2 text-3xl font-semibold">4 天</p>
    </div>
  </div>

  <div class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="flex items-center justify-between gap-4">
      <div>
        <h3 class="text-xl font-semibold">最近活動</h3>
        <p class="text-sm text-slate-500">登入後測試用的範例資料</p>
      </div>
      <a class="rounded-full bg-emerald-600 px-4 py-2 text-sm text-white hover:bg-emerald-500" href="/app/notes/new">新增筆記</a>
    </div>

    {#if error}
      <p class="mt-6 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
    {/if}

    {#if loading}
      <p class="mt-6 text-sm text-slate-500">載入中…</p>
    {:else if items.length === 0}
      <p class="mt-6 rounded-2xl border border-dashed border-slate-300 p-6 text-sm text-slate-500">尚無資料，先新增第一筆里程碑或筆記吧。</p>
    {:else}
      <div class="mt-6 space-y-3">
        {#each items as item}
          <article class="flex flex-col gap-4 rounded-2xl border border-slate-200 p-4 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-500">{item.label}</p>
              <h4 class="mt-1 text-lg font-medium">{item.title}</h4>
              <p class="mt-1 text-sm text-slate-500">{item.meta}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <a class="rounded-full border border-slate-300 px-3 py-1 text-xs text-slate-700 hover:bg-slate-100" href={item.type === 'milestone' ? `/app/milestones/${item.id}/edit` : `/app/notes/${item.id}/edit`}>編輯</a>
              <button class="rounded-full border border-rose-200 px-3 py-1 text-xs text-rose-700 hover:bg-rose-50" on:click={() => removeEntry(item)}>刪除</button>
            </div>
          </article>
        {/each}
      </div>
    {/if}
  </div>
</section>