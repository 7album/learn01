<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let checking = true;
  let childName = '尚未建立孩子檔案';

  function readDefaultChildName() {
    if (typeof localStorage === 'undefined') return '尚未建立孩子檔案';
    return localStorage.getItem('default-child-name') || '尚未建立孩子檔案';
  }

  onMount(() => {
    const syncChildName = () => {
      childName = readDefaultChildName();
    };

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

      const { data: childrenData } = await supabase
        .from('children')
        .select('id,name')
        .order('created_at', { ascending: true })
        .limit(1);

      if (typeof localStorage !== 'undefined') {
        const storedDefaultId = localStorage.getItem('default-child-id');
        const storedDefaultName = localStorage.getItem('default-child-name');
        const initialChild =
          childrenData?.find((child) => child.id === storedDefaultId) || childrenData?.[0];

        if (initialChild) {
          localStorage.setItem('default-child-id', initialChild.id);
          localStorage.setItem('default-child-name', initialChild.name);
        } else if (storedDefaultName) {
          localStorage.setItem('default-child-name', storedDefaultName);
        }
      }

      syncChildName();

      window.addEventListener('default-child-changed', syncChildName);
      window.addEventListener('storage', syncChildName);

      checking = false;
    })();

    return () => {
      listener.subscription.unsubscribe();
      window.removeEventListener('default-child-changed', syncChildName);
      window.removeEventListener('storage', syncChildName);
    };
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
          <p class="text-xs uppercase tracking-[0.3em] text-slate-500">孩子成長</p>
          <div class="mt-1 flex items-center gap-2">
            <h1 class="text-lg font-semibold">{childName}</h1>
            <a
              class="inline-flex h-8 w-8 items-center justify-center rounded-full border border-slate-300 text-slate-600 transition hover:bg-slate-100 hover:text-slate-900"
              href="/app/children/manage"
              aria-label="前往孩子檔案管理頁"
              title="前往孩子檔案管理頁"
            >
              <svg viewBox="0 0 24 24" class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M3 17.25V21h3.75L18.81 8.94l-3.75-3.75L3 17.25Z" />
                <path d="m14.06 5.19 3.75 3.75" />
              </svg>
            </a>
          </div>
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