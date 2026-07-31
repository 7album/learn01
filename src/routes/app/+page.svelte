<script lang="ts">
  const items = [
    { title: '第一次閱讀時段', type: '學習筆記', meta: '2026-07-31 · 語文' },
    { title: '騎腳踏車里程碑', type: '里程碑', meta: '2026-07-30 · 戶外活動' },
    { title: '平靜收拾習慣', type: '行為', meta: '2026-07-28 · 居家技能' }
  ];
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

    <div class="mt-6 space-y-3">
      {#each items as item}
        <article class="flex items-start justify-between gap-4 rounded-2xl border border-slate-200 p-4">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-500">{item.type}</p>
            <h4 class="mt-1 text-lg font-medium">{item.title}</h4>
            <p class="mt-1 text-sm text-slate-500">{item.meta}</p>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-600">開啟</span>
        </article>
      {/each}
    </div>
  </div>
</section>