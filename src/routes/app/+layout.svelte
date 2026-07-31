<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let checking = true;

  onMount(() => {
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) {
        goto('/login');
      }
    });

    void (async () => {
      const { data } = await supabase.auth.getSession();

      if (!data.session) {
        await goto('/login');
        return;
      }

      checking = false;
    })();

    return () => listener.subscription.unsubscribe();
  });

  async function signOut() {
    await supabase.auth.signOut();
    await goto('/login');
  }
</script>

{#if checking}
  <div class="min-h-screen flex items-center justify-center p-6">
    <p class="text-sm text-slate-500">正在檢查登入狀態…</p>
  </div>
{:else}
  <div class="min-h-screen bg-slate-50 text-slate-900">
    <header class="border-b border-slate-200 bg-white/90 backdrop-blur">
      <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
        <div>
          <p class="text-xs uppercase tracking-[0.3em] text-slate-500">個人成長</p>
          <h1 class="text-lg font-semibold">已登入工作區</h1>
        </div>
        <div class="flex items-center gap-3">
          <a class="rounded-full border border-slate-300 px-4 py-2 text-sm hover:bg-slate-100" href="/app">儀表板</a>
          <a class="rounded-full border border-slate-300 px-4 py-2 text-sm hover:bg-slate-100" href="/app/events/new">新增事件</a>
          <button class="rounded-full bg-slate-900 px-4 py-2 text-sm text-white hover:bg-slate-700" on:click={signOut}>登出</button>
        </div>
      </div>
    </header>

    <main class="mx-auto max-w-5xl px-6 py-8">
      <slot />
    </main>
  </div>
{/if}