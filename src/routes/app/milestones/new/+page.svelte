<script lang="ts">
  let title = '';
  let description = '';
  let category = '里程碑';
  let occurredAt = '';
</script>

<section class="mx-auto max-w-2xl rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
  <p class="text-sm uppercase tracking-[0.3em] text-slate-500">新增里程碑</p>
  <h2 class="mt-2 text-2xl font-semibold">建立里程碑</h2>

  <form class="mt-6 space-y-4">
    <label class="block">
      <span class="text-sm font-medium text-slate-700">標題</span>
      <input bind:value={title} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" placeholder="學會自己綁鞋帶" />
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">描述</span>
      <textarea bind:value={description} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="4" placeholder="在早晨例行活動中觀察到"></textarea>
    </label>
    <div class="grid gap-4 md:grid-cols-2">
      <label class="block">
        <span class="text-sm font-medium text-slate-700">類別</span>
        <select bind:value={category} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2">
          <option>里程碑</option>
          <option>學習時刻</option>
          <option>行為</option>
          <option>閱讀</option>
          <option>其他</option>
        </select>
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">發生時間</span>
        <input bind:value={occurredAt} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" type="datetime-local" />
      </label>
    </div>
    <button class="rounded-full bg-slate-900 px-5 py-2.5 text-white">儲存里程碑</button>
  </form>
</section>