<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let title = '';
  let description = '';
  let category = '事件';
  let content = '';
  let tags = '';
  let eventDate = '';

  async function save() {
    const { data } = await supabase.auth.getUser();

    if (!data.user) {
      await goto('/login');
      return;
    }

    const tagList = tags
      .split(',')
      .map((tag) => tag.trim())
      .filter(Boolean);

    const { error } = await supabase.from('events').insert({
      user_id: data.user.id,
      type: 'milestone',
      title,
      description,
      category,
      content,
      tags: tagList,
      event_date: eventDate || new Date().toISOString().slice(0, 10)
    });

    if (error) {
      alert(error.message);
      return;
    }

    await goto('/app');
  }
</script>

<section class="mx-auto max-w-2xl rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
  <p class="text-sm uppercase tracking-[0.3em] text-slate-500">新增事件</p>
  <h2 class="mt-2 text-2xl font-semibold">建立事件</h2>

  <form class="mt-6 space-y-4" on:submit|preventDefault={save}>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">標題</span>
      <input bind:value={title} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" placeholder="學會自己綁鞋帶" />
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">描述</span>
      <textarea bind:value={description} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="4" placeholder="在早晨例行活動中觀察到"></textarea>
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">內容</span>
      <textarea bind:value={content} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="5" placeholder="發生了什麼、孩子觀察到什麼，或哪裡表現得很好"></textarea>
    </label>
    <label class="block">
      <span class="text-sm font-medium text-slate-700">標籤</span>
      <input bind:value={tags} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" placeholder="閱讀, 數學, 平靜" />
    </label>
    <div class="grid gap-4 md:grid-cols-2">
      <label class="block">
        <span class="text-sm font-medium text-slate-700">類別</span>
        <select bind:value={category} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2">
          <option>事件</option>
          <option>學習</option>
          <option>行為</option>
          <option>閱讀</option>
          <option>其他</option>
        </select>
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">發生日期</span>
        <input bind:value={eventDate} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" type="date" />
      </label>
    </div>
    <button class="rounded-full bg-slate-900 px-5 py-2.5 text-white">儲存事件</button>
  </form>
</section>