<script lang="ts">
  let content = '';
  let tags = '';
  let notedAt = '';
</script>

<section class="mx-auto max-w-2xl rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
  <p class="text-sm uppercase tracking-[0.3em] text-slate-500">新增筆記</p>
  <h2 class="mt-2 text-2xl font-semibold">建立學習筆記</h2>

  <form class="mt-6 space-y-4">
    <label class="block">
      <span class="text-sm font-medium text-slate-700">內容</span>
      <textarea bind:value={content} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="5" placeholder="發生了什麼、孩子觀察到什麼，或哪裡表現得很好"></textarea>
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">標籤</span>
      <input bind:value={tags} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" placeholder="閱讀, 數學, 平靜" />
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">記錄日期</span>
      <input bind:value={notedAt} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" type="date" />
    </label>
    <button class="rounded-full bg-emerald-600 px-5 py-2.5 text-white">儲存筆記</button>
  </form>
</section>