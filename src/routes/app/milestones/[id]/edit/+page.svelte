<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/state';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { toDateInputValue } from '$lib/date';

  let loading = true;
  let saving = false;
  let error = '';
  let title = '';
  let description = '';
  let category = '里程碑';
  let occurredAt = '';

  onMount(() => {
    void (async () => {
      const { data: sessionData } = await supabase.auth.getUser();
      if (!sessionData.user) {
        await goto('/login');
        return;
      }

      const { data, error: loadError } = await supabase
        .from('milestones')
        .select('id,title,description,category,occurred_at')
        .eq('id', page.params.id)
        .single();

      if (loadError) {
        error = loadError.message;
        loading = false;
        return;
      }

      title = data.title ?? '';
      description = data.description ?? '';
      category = data.category ?? '里程碑';
      occurredAt = toDateInputValue(data.occurred_at);
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

    const { error: updateError } = await supabase
      .from('milestones')
      .update({
        title,
        description,
        category,
        occurred_at: occurredAt || new Date().toISOString()
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
  <p class="text-sm uppercase tracking-[0.3em] text-slate-500">編輯里程碑</p>
  <h2 class="mt-2 text-2xl font-semibold">修改里程碑</h2>

  {#if error}
    <p class="mt-4 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
  {/if}

  {#if loading}
    <p class="mt-6 text-sm text-slate-500">載入中…</p>
  {:else}
    <form class="mt-6 space-y-4" on:submit|preventDefault={save}>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">標題</span>
        <input bind:value={title} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" />
      </label>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">描述</span>
        <textarea bind:value={description} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" rows="4"></textarea>
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
          <span class="text-sm font-medium text-slate-700">發生日期</span>
          <input bind:value={occurredAt} class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" type="date" />
        </label>
      </div>
      <div class="flex gap-3">
        <button class="rounded-full bg-slate-900 px-5 py-2.5 text-white" type="submit" disabled={saving}>{saving ? '儲存中…' : '儲存變更'}</button>
        <a class="rounded-full border border-slate-300 px-5 py-2.5 text-slate-700" href="/app">取消</a>
      </div>
    </form>
  {/if}
</section>
