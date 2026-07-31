<script lang="ts">
  import { onMount } from 'svelte';
  import { max, scaleLinear } from 'd3';
  import { supabase } from '$lib/supabase';
  import { formatDate } from '$lib/date';
  import type { EntryRecord } from '$lib/entryTypes';

  type DisplayItem = EntryRecord & {
    child_id: string;
    child_name: string;
    label: string;
    meta: string;
  };

  type HeatmapCell = {
    date: string;
    count: number;
    x: number;
    y: number;
    monthLabel?: string;
    isPadding?: boolean;
  };

  type HeatmapLayout = {
    cells: HeatmapCell[];
    width: number;
    height: number;
    cellSize: number;
    gap: number;
    labelWidth: number;
    topPadding: number;
    legendWidth: number;
    weekdayLabels: string[];
    monthMarkers: Array<{ label: string; x: number }>;
    fillScale: (count: number) => string;
  };

  let loading = true;
  let error = '';
  let childLoading = true;
  let childError = '';
  let selectedChild = '';
  let childOptions: Array<{ id: string; name: string }> = [];
  let items: DisplayItem[] = [];
  let filterCategory = 'all';
  let filterTag = '';
  let filterPeriod = 'all';
  $: trackedChildrenCount = childOptions.length;
  $: selectedChildName = childOptions.find((child) => child.id === selectedChild)?.name || '尚未建立孩子檔案';
  $: visibleItems = items.filter((item) => {
    if (filterCategory !== 'all' && item.category !== filterCategory) return false;
    if (filterTag && !(item.tags ?? []).some((tag) => tag.toLowerCase().includes(filterTag.toLowerCase()))) return false;

    const eventDate = new Date(item.event_date || item.created_at || '');
    if (filterPeriod === 'week') {
      const now = new Date();
      const startOfWeek = new Date(now);
      const day = startOfWeek.getDay();
      const diff = day === 0 ? 6 : day - 1;
      startOfWeek.setDate(now.getDate() - diff);
      startOfWeek.setHours(0, 0, 0, 0);
      return eventDate >= startOfWeek;
    }

    if (filterPeriod === 'month') {
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      return eventDate >= startOfMonth;
    }

    if (filterPeriod === 'year') {
      const now = new Date();
      const startOfYear = new Date(now.getFullYear(), 0, 1);
      return eventDate >= startOfYear;
    }

    return true;
  });
  $: totalEventsCount = visibleItems.length;
  $: thisWeekCount = visibleItems.filter((item) => {
    const eventDate = new Date(item.event_date || item.created_at || '');
    const now = new Date();
    const startOfWeek = new Date(now);
    const day = startOfWeek.getDay();
    const diff = day === 0 ? 6 : day - 1;
    startOfWeek.setDate(now.getDate() - diff);
    startOfWeek.setHours(0, 0, 0, 0);
    return eventDate >= startOfWeek;
  }).length;
  $: categoryOptions = Array.from(new Set(items.map((item) => item.category).filter(Boolean))) as string[];
  $: tagOptions = Array.from(new Set(items.flatMap((item) => item.tags ?? []))).sort((left, right) => left.localeCompare(right));
  $: heatmapDesktopData = buildHeatmap(visibleItems, 210, 14);
  $: heatmapMobileData = buildHeatmap(visibleItems, 70, 12);

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

  function buildHeatmap(sourceItems: DisplayItem[], daysToRender: number, cellSize: number): HeatmapLayout {
    const gap = 3;
    const labelWidth = 20;
    const topPadding = 18;
    const legendWidth = 56;
    const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const startDate = new Date(today);
    startDate.setDate(today.getDate() - (daysToRender - 1));
    startDate.setHours(0, 0, 0, 0);

    const leadingPadding = (startDate.getDay() + 6) % 7;
    const totalDays = leadingPadding + daysToRender;
    const columnCount = Math.ceil(totalDays / 7);
    const counts = new Map<string, number>();

    for (const item of sourceItems) {
      const key = (item.event_date || item.created_at || '').slice(0, 10);
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }

    const cells: HeatmapCell[] = [];
    const monthMarkers: Array<{ label: string; x: number }> = [];
    let previousMonth = -1;

    for (let index = 0; index < totalDays; index += 1) {
      const column = Math.floor(index / 7);
      const row = index % 7;
      const x = labelWidth + column * (cellSize + gap);
      const y = topPadding + row * (cellSize + gap);

      if (index < leadingPadding) {
        cells.push({ date: '', count: 0, x, y, isPadding: true });
        continue;
      }

      const date = new Date(startDate);
      date.setDate(startDate.getDate() + (index - leadingPadding));
      const key = toLocalDateKey(date);
      const count = counts.get(key) ?? 0;

      cells.push({ date: key, count, x, y });

      if (date.getMonth() !== previousMonth) {
        monthMarkers.push({
          label: date.toLocaleDateString('zh-TW', { month: 'short' }),
          x
        });
        previousMonth = date.getMonth();
      }
    }

    const maxCount = Math.max(4, max(Array.from(counts.values())) ?? 0);
    const fillScale = scaleLinear<string>()
      .domain([0, 1, 2, 3, maxCount])
      .range(['#f8fafc', '#d1fae5', '#86efac', '#34d399', '#047857']);

    const width = labelWidth + columnCount * (cellSize + gap) - gap + legendWidth;
    const height = topPadding + 7 * (cellSize + gap) - gap + 12;

    return { cells, width, height, cellSize, gap, labelWidth, topPadding, legendWidth, weekdayLabels, monthMarkers, fillScale };
  }

  function toLocalDateKey(date: Date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function resetFilters() {
    filterCategory = 'all';
    filterTag = '';
    filterPeriod = 'all';
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

    const normalized: DisplayItem[] = (events ?? []).map((item) => ({
      ...item,
      child_name: item.children?.name || '未命名孩子',
      child_id: item.child_id,
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

<section class="space-y-5">
  <header class="flex flex-col gap-4 border-b border-slate-200 pb-5 sm:flex-row sm:items-end sm:justify-between">
    <div>
      <p class="text-sm font-medium text-emerald-700">孩子成長紀錄</p>
      <h2 class="mt-1 text-2xl font-semibold text-slate-950">{selectedChildName}</h2>
      <p class="mt-1 text-sm text-slate-500">快速掌握近期事件與活動足跡。</p>
    </div>
    <a class="inline-flex w-fit items-center rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-500" href={`/app/events/new?child=${encodeURIComponent(selectedChild)}`}>新增事件</a>
  </header>

  <div class="grid gap-3 sm:grid-cols-3">
    <div class="border-l-4 border-emerald-500 bg-emerald-50 px-4 py-3">
      <p class="text-sm text-emerald-900">本週事件</p>
      <p class="mt-1 text-2xl font-semibold text-emerald-950">{thisWeekCount}</p>
    </div>
    <div class="border-l-4 border-sky-500 bg-sky-50 px-4 py-3">
      <p class="text-sm text-sky-900">總事件數</p>
      <p class="mt-1 text-2xl font-semibold text-sky-950">{totalEventsCount}</p>
    </div>
    <div class="border-l-4 border-amber-500 bg-amber-50 px-4 py-3">
      <p class="text-sm text-amber-900">追蹤中孩子數</p>
      <p class="mt-1 text-2xl font-semibold text-amber-950">{trackedChildrenCount}</p>
    </div>
  </div>

  <div class="space-y-5">
    <section class="min-w-0 self-start rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
      <div class="mb-4 flex items-start justify-between gap-4">
        <div>
          <h3 class="text-base font-semibold text-slate-900">活動熱度</h3>
          <p class="mt-1 text-sm text-slate-500">顏色越深代表當日紀錄越多。</p>
        </div>
        <span class="shrink-0 text-xs text-slate-400">最近紀錄</span>
      </div>
      <div class="hidden lg:block">
        <svg
          aria-label="活動熱度圖"
          class="block h-auto w-full"
          preserveAspectRatio="xMinYMin meet"
          viewBox={`0 0 ${heatmapDesktopData.width} ${heatmapDesktopData.height}`}
          role="img"
        >
          {#each heatmapDesktopData.monthMarkers as month}
            <text x={month.x + heatmapDesktopData.cellSize / 2} y={12} text-anchor="middle" class="fill-slate-400 text-[10px] font-medium">{month.label}</text>
          {/each}

          {#each heatmapDesktopData.weekdayLabels as label, row}
            <text
              x="0"
              y={heatmapDesktopData.topPadding + row * (heatmapDesktopData.cellSize + heatmapDesktopData.gap) + heatmapDesktopData.cellSize / 2 + 1}
              dominant-baseline="middle"
              class="fill-slate-500 text-[10px] font-medium"
            >
              {label}
            </text>
          {/each}

          {#each heatmapDesktopData.cells as cell}
            {#if !cell.isPadding}
              <rect x={cell.x} y={cell.y} width={heatmapDesktopData.cellSize} height={heatmapDesktopData.cellSize} rx="4" fill={heatmapDesktopData.fillScale(cell.count)} />
            {/if}
          {/each}
        </svg>

        <div class="mt-3 flex items-center gap-3 text-xs text-slate-500">
          <span>少</span>
          <div class="flex items-center gap-1">
            {#each [0, 1, 2, 3, 4] as level}
              <span class="block rounded-sm" style={`background-color: ${heatmapDesktopData.fillScale(level)}; height: ${heatmapDesktopData.cellSize - 2}px; width: ${heatmapDesktopData.cellSize - 2}px;`}></span>
            {/each}
          </div>
          <span>多</span>
        </div>
      </div>

      <div class="lg:hidden">
        <svg
          aria-label="活動熱度圖"
          class="block h-auto w-full"
          preserveAspectRatio="xMinYMin meet"
          viewBox={`0 0 ${heatmapMobileData.width} ${heatmapMobileData.height}`}
          role="img"
        >
          {#each heatmapMobileData.monthMarkers as month}
            <text x={month.x + heatmapMobileData.cellSize / 2} y={12} text-anchor="middle" class="fill-slate-400 text-[10px] font-medium">{month.label}</text>
          {/each}

          {#each heatmapMobileData.weekdayLabels as label, row}
            <text
              x="0"
              y={heatmapMobileData.topPadding + row * (heatmapMobileData.cellSize + heatmapMobileData.gap) + heatmapMobileData.cellSize / 2 + 1}
              dominant-baseline="middle"
              class="fill-slate-500 text-[10px] font-medium"
            >
              {label}
            </text>
          {/each}

          {#each heatmapMobileData.cells as cell}
            {#if !cell.isPadding}
              <rect x={cell.x} y={cell.y} width={heatmapMobileData.cellSize} height={heatmapMobileData.cellSize} rx="4" fill={heatmapMobileData.fillScale(cell.count)} />
            {/if}
          {/each}
        </svg>

        <div class="mt-3 flex items-center gap-3 text-xs text-slate-500">
          <span>少</span>
          <div class="flex items-center gap-1">
            {#each [0, 1, 2, 3, 4] as level}
              <span class="block rounded-sm" style={`background-color: ${heatmapMobileData.fillScale(level)}; height: ${heatmapMobileData.cellSize - 2}px; width: ${heatmapMobileData.cellSize - 2}px;`}></span>
            {/each}
          </div>
          <span>多</span>
        </div>
      </div>
    </section>

    <aside class="self-start rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
      <div class="flex items-center justify-between gap-3">
      <div>
          <h3 class="text-base font-semibold text-slate-900">篩選事件</h3>
          <p class="mt-1 text-sm text-slate-500">聚焦目前孩子的紀錄。</p>
      </div>
        <button class="rounded-md px-2 py-1 text-xs font-medium text-emerald-700 hover:bg-emerald-50" on:click={resetFilters}>
        清除篩選
      </button>
    </div>

      <div class="mt-4 grid gap-3">
      <label class="block">
        <span class="text-sm font-medium text-slate-700">類別</span>
        <select bind:value={filterCategory} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2">
          <option value="all">全部類別</option>
          {#each categoryOptions as option}
            <option value={option}>{option}</option>
          {/each}
        </select>
      </label>

      <label class="block">
        <span class="text-sm font-medium text-slate-700">標籤</span>
        <input bind:value={filterTag} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" list="tag-suggestions" placeholder="例如：閱讀" />
        <datalist id="tag-suggestions">
          {#each tagOptions as option}
            <option value={option}></option>
          {/each}
        </datalist>
      </label>

      <label class="block">
        <span class="text-sm font-medium text-slate-700">期間</span>
        <select bind:value={filterPeriod} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2">
          <option value="all">全部期間</option>
          <option value="week">本週</option>
          <option value="month">本月</option>
          <option value="year">今年</option>
        </select>
      </label>
    </div>

      {#if visibleItems.length === 0 && items.length > 0}
        <p class="rounded-lg border border-dashed border-slate-300 p-3 text-sm text-slate-500">沒有符合條件的事件。</p>
      {/if}
    </aside>
  </div>

  <section class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
    <div class="flex items-center justify-between gap-4">
      <div>
        <h3 class="text-lg font-semibold">最近事件</h3>
        <p class="text-sm text-slate-500">登入後測試用的範例資料</p>
      </div>
      <a class="text-sm font-medium text-emerald-700 hover:text-emerald-600" href={`/app/events/new?child=${encodeURIComponent(selectedChild)}`}>新增事件</a>
    </div>

    {#if error}
      <p class="mt-6 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
    {/if}

    {#if loading}
      <p class="mt-5 text-sm text-slate-500">載入中…</p>
    {:else if items.length === 0}
      <p class="mt-5 rounded-2xl border border-dashed border-slate-300 p-4 text-sm text-slate-500">尚無資料，先新增第一筆事件吧。</p>
    {:else}
      <div class="mt-5 space-y-2.5">
        {#each items as item}
          <article class="flex flex-col gap-3 rounded-2xl border border-slate-200 p-3.5 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-500">{item.label}</p>
              <h4 class="mt-1 text-base font-medium">{item.title}</h4>
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
  </section>
</section>