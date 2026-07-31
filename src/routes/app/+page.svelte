<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { formatDate } from '$lib/date';
  import type { EntryRecord } from '$lib/entryTypes';

  let loading = true;
  let error = '';
  let childLoading = true;
  let childError = '';
  let selectedChild = '';
  let childOptions: Array<{ id: string; name: string }> = [];
  let items: Array<EntryRecord & { label: string; meta: string }> = [];
  $: trackedChildrenCount = childOptions.length;
  $: selectedChildName = childOptions.find((child) => child.id === selectedChild)?.name || '尚未建立孩子檔案';
  $: totalEventsCount = items.length;
  $: milestoneCount = items.filter((item) => item.type === 'milestone').length;
  $: noteCount = items.filter((item) => item.type !== 'milestone').length;
  $: thisWeekCount = items.filter((item) => {
    const eventDate = new Date(item.event_date || item.created_at || '');
    const now = new Date();
    const startOfWeek = new Date(now);
    const day = startOfWeek.getDay();
    const diff = day === 0 ? 6 : day - 1;
    startOfWeek.setDate(now.getDate() - diff);
    startOfWeek.setHours(0, 0, 0, 0);
    return eventDate >= startOfWeek;
  }).length;

  async function loadChildren() {
    childLoading = true;
    childError = '';

    const { data, error: loadError } = await supabase
      .from('children')
      .select('id,name')
      .order('created_at', { ascending: true });

    if (loadError) {
      childError = loadError.message;
      childLoading = false;
      return;
    }

    childOptions = data ?? [];
    if (!selectedChild || !childOptions.some((child) => child.id === selectedChild)) {
      selectedChild = childOptions[0]?.id ?? '';
    }

    childLoading = false;
  }

  async function loadEntries() {
    loading = true;
    error = '';

    const { data: events, error: eventsError } = await supabase
      .from('events')
      .select('id,child_id,children(name),type,title,category,content,tags,event_date,created_at,updated_at')
      .order('event_date', { ascending: false });

    if (eventsError) {
      error = eventsError.message ?? '載入資料失敗';
      loading = false;
      return;
    }

    const normalized = (events ?? []).map((item) => ({
      ...item,
      child_name: item.children?.name || '未命名孩子',
      label: item.type === 'milestone' ? item.category || '事件' : '事件',
      title: item.type === 'milestone' ? item.title : item.content || '未命名筆記',
      meta:
        item.type === 'milestone'
          ? `${formatDate(item.event_date)} · ${item.children?.name || '未命名孩子'} · ${item.category || '事件'}`
          : `${formatDate(item.event_date)} · ${(item.tags ?? []).join('、') || '無標籤'}`
    })).sort((left, right) => {
      const leftDate = new Date(left.event_date || left.created_at || '').getTime();
      const rightDate = new Date(right.event_date || right.created_at || '').getTime();
      return rightDate - leftDate;
    });

    if (selectedChild && !childOptions.some((child) => child.id === selectedChild)) {
      selectedChild = childOptions[0]?.id ?? '';
    }

    items = selectedChild ? normalized.filter((item) => item.child_id === selectedChild) : [];
    loading = false;
  }

  function setChild(childId: string) {
    selectedChild = childId;
    void loadEntries();
  }

  async function removeEntry(item: EntryRecord) {
    const confirmDelete = confirm('確定要刪除這筆資料嗎？');
    if (!confirmDelete) return;

    const { error: deleteError } = await supabase.from('events').delete().eq('id', item.id);

    if (deleteError) {
      error = deleteError.message;
      return;
    }

    await loadEntries();
  }

  onMount(() => {
    void loadChildren();
    void loadEntries();
  });
</script>

<section class="space-y-8">
  <div class="rounded-3xl bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 p-8 text-white shadow-xl">
    <h2 class="text-3xl font-semibold">儀表板</h2>
  </div>

  <div class="grid gap-4 md:grid-cols-4">
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">追蹤中的孩子</p>
      <p class="mt-2 text-3xl font-semibold">{trackedChildrenCount}</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">本週事件</p>
      <p class="mt-2 text-3xl font-semibold">{thisWeekCount}</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">里程碑</p>
      <p class="mt-2 text-3xl font-semibold">{milestoneCount}</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-sm text-slate-500">筆記</p>
      <p class="mt-2 text-3xl font-semibold">{noteCount}</p>
    </div>
  </div>

  <div class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="flex items-center justify-between gap-4">
      <div>
        <h3 class="text-xl font-semibold">最近事件</h3>
        <p class="text-sm text-slate-500">登入後測試用的範例資料</p>
      </div>
      <a class="rounded-full bg-emerald-600 px-4 py-2 text-sm text-white hover:bg-emerald-500" href={selectedChild === 'all' ? '/app/events/new' : `/app/events/new?child=${encodeURIComponent(selectedChild)}`}>新增事件</a>
    </div>

    {#if error}
      <p class="mt-6 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
    {/if}

    {#if loading}
      <p class="mt-6 text-sm text-slate-500">載入中…</p>
    {:else if items.length === 0}
      <p class="mt-6 rounded-2xl border border-dashed border-slate-300 p-6 text-sm text-slate-500">尚無資料，先新增第一筆事件吧。</p>
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
              <a class="rounded-full border border-slate-300 px-3 py-1 text-xs text-slate-700 hover:bg-slate-100" href={`/app/events/${item.id}/edit`}>編輯</a>
              <button class="rounded-full border border-rose-200 px-3 py-1 text-xs text-rose-700 hover:bg-rose-50" on:click={() => removeEntry(item)}>刪除</button>
            </div>
          </article>
        {/each}
      </div>
    {/if}
  </div>
</section>