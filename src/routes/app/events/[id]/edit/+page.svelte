<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/state';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { toDateInputValue } from '$lib/date';

  let loading = true;
  let saving = false;
  let error = '';
  let childId = '';
  let title = '';
  let category = '事件';
  let content = '';
  let tags = '';
  let eventDate = '';

  onMount(() => {
    void (async () => {
      const { data: sessionData } = await supabase.auth.getUser();
      if (!sessionData.user) {
        await goto('/login');
        return;
      }

      const { data, error: loadError } = await supabase
        .from('events')
        .select('id,child_id,title,category,content,tags,event_date,type')
        .eq('id', page.params.id)
        .single();

      if (loadError) {
        error = loadError.message;
        loading = false;
        return;
      }

      childId = data.child_id ?? '';
      title = data.title ?? '';
      category = data.category ?? '事件';
      content = data.content ?? '';
      tags = (data.tags ?? []).join(', ');
      eventDate = toDateInputValue(data.event_date);
      loading = false;
    })();
  });

  async function save() {
    saving = true;
    error = '';

    const { data } = await supabase.auth.getUser();
    if (!data.user) {
      await goto('/login');
      return;
    }

    const tagList = tags
      .split(',')
      .map((tag) => tag.trim())
      .filter(Boolean);

    const { error: updateError } = await supabase
      .from('events')
      .update({
        child_id: childId,
        title,
        category,
        content,
        tags: tagList,
        event_date: eventDate || new Date().toISOString().slice(0, 10)
      })
      .eq('id', page.params.id);

    if (updateError) {
      error = updateError.message;
      saving = false;
      return;
    }

    await goto('/app');
  }
</script>

<section class="mx-auto max-w-2xl rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
  <p class="text-sm uppercase tracking-[0.3em] text-slate-500">編輯事件</p>
  <h2 class="mt-2 text-2xl font-semibold">修改事件</h2>

  {#if error}
    <p class="mt-4 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
  {/if}

  {#if loading}
    <p class="mt-6 text-sm text-slate-500">載入中…</p>
  {:else}
    <form class="mt-6 space-y-4" on:submit|preventDefault={save}>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">孩子檔案 ID</span>
        <input bind:value={childId} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" />
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">標題</span>
        <input bind:value={title} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" />
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">內容</span>
        <textarea bind:value={content} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="5"></textarea>
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">標籤</span>
        <input bind:value={tags} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" />
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
      <div class="flex gap-3">
        <button class="rounded-full bg-slate-900 px-5 py-2.5 text-white" type="submit" disabled={saving}>{saving ? '儲存中…' : '儲存事件'}</button>
        <a class="rounded-full border border-slate-300 px-5 py-2.5 text-slate-700" href="/app">取消</a>
      </div>
    </form>
  {/if}
</section>