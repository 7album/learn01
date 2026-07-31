<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  type ChildRecord = {
    id: string;
    name: string;
    created_at?: string | null;
    updated_at?: string | null;
  };

  let loading = true;
  let saving = false;
  let error = '';
  let success = '';
  let children: ChildRecord[] = [];
  let newChildName = '';
  let editId = '';
  let editName = '';

  function setDefaultChild(child: ChildRecord) {
    if (typeof localStorage === 'undefined') return;

    localStorage.setItem('default-child-id', child.id);
    localStorage.setItem('default-child-name', child.name);
    window.dispatchEvent(new CustomEvent('default-child-changed'));
    success = `已切換為「${child.name}」`;
  }

  async function loadChildren() {
    loading = true;
    error = '';

    const { data, error: loadError } = await supabase
      .from('children')
      .select('id,name,created_at,updated_at')
      .order('created_at', { ascending: true });

    if (loadError) {
      error = loadError.message;
      loading = false;
      return;
    }

    children = data ?? [];

    if (typeof localStorage !== 'undefined' && children.length > 0) {
      const currentDefaultId = localStorage.getItem('default-child-id');
      const currentDefault = children.find((child) => child.id === currentDefaultId) || children[0];
      localStorage.setItem('default-child-id', currentDefault.id);
      localStorage.setItem('default-child-name', currentDefault.name);
      window.dispatchEvent(new CustomEvent('default-child-changed'));
    }

    if (editId && !children.some((child) => child.id === editId)) {
      editId = '';
      editName = '';
    }

    loading = false;
  }

  async function createChild() {
    const trimmed = newChildName.trim();
    if (!trimmed || saving) return;

    saving = true;
    error = '';
    success = '';

    const { data: userData } = await supabase.auth.getUser();
    if (!userData.user) {
      await goto('/login');
      return;
    }

    const { error: createError } = await supabase.from('children').insert({
      user_id: userData.user.id,
      name: trimmed
    });

    if (createError) {
      error = createError.message;
      saving = false;
      return;
    }

    newChildName = '';
    success = '已新增孩子檔案。';
    saving = false;
    await loadChildren();
  }

  function startEdit(child: ChildRecord) {
    editId = child.id;
    editName = child.name;
    success = '';
  }

  function cancelEdit() {
    editId = '';
    editName = '';
  }

  async function saveEdit() {
    const trimmed = editName.trim();
    if (!editId || !trimmed || saving) return;

    saving = true;
    error = '';
    success = '';

    const { error: updateError } = await supabase.from('children').update({ name: trimmed }).eq('id', editId);

    if (updateError) {
      error = updateError.message;
      saving = false;
      return;
    }

    editId = '';
    editName = '';
    success = '已更新孩子檔案。';
    saving = false;
    await loadChildren();
  }

  async function deleteChild(child: ChildRecord) {
    const confirmDelete = confirm(`確定要刪除「${child.name}」嗎？相關事件也會一併刪除。`);
    if (!confirmDelete || saving) return;

    saving = true;
    error = '';
    success = '';

    const { error: deleteError } = await supabase.from('children').delete().eq('id', child.id);

    if (deleteError) {
      error = deleteError.message;
      saving = false;
      return;
    }

    if (editId === child.id) {
      cancelEdit();
    }

    success = '已刪除孩子檔案。';
    saving = false;
    await loadChildren();
  }

  onMount(() => {
    void loadChildren();
  });
</script>

<section class="space-y-6">
  <div class="rounded-3xl bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 p-8 text-white shadow-xl">
    <h2 class="text-3xl font-semibold">孩子檔案管理</h2>
  </div>

  <div class="grid gap-6 lg:grid-cols-[0.9fr_1.1fr]">

    <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm font-medium uppercase tracking-[0.24em] text-slate-500">現有孩子</p>
          <h3 class="mt-2 text-xl font-semibold text-slate-950">管理清單</h3>
        </div>

        <a class="rounded-full border border-slate-300 px-4 py-2 text-sm text-slate-700 transition hover:bg-slate-100" href="/app">
          返回儀表板
        </a>
      </div>

      {#if loading}
        <p class="mt-6 text-sm text-slate-500">載入中…</p>
      {:else if children.length === 0}
        <p class="mt-6 rounded-2xl border border-dashed border-slate-300 p-6 text-sm text-slate-500">目前還沒有孩子檔案。</p>
      {:else}
        <div class="mt-6 space-y-3">
          {#each children as child}
            <article class="rounded-2xl border border-slate-200 p-4">
              {#if editId === child.id}
                <div class="space-y-3">
                  <label class="block">
                    <span class="text-sm font-medium text-slate-700">修改名稱</span>
                    <input
                      bind:value={editName}
                      class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                    />
                  </label>

                  <div class="flex flex-wrap gap-2">
                    <button class="rounded-full bg-slate-950 px-4 py-2 text-sm text-white hover:bg-slate-800" on:click|preventDefault={saveEdit} disabled={saving || !editName.trim()}>
                      儲存
                    </button>
                    <button class="rounded-full border border-slate-300 px-4 py-2 text-sm text-slate-700 hover:bg-slate-100" on:click={cancelEdit}>
                      取消
                    </button>
                  </div>
                </div>
              {:else}
                <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                  <div class="flex items-center justify-between">
                    <h4 class="text-lg font-medium text-slate-950">{child.name}</h4>
                    <span class="ml-1 mt-1 text-[10px] text-slate-500">({child.id})</span>
                  </div>

                  <div class="flex flex-wrap gap-2">
                    <button class="rounded-full border border-emerald-200 px-4 py-2 text-sm text-emerald-700 hover:bg-emerald-50" on:click={() => setDefaultChild(child)}>
                      切換
                    </button>
                    <button class="rounded-full border border-slate-300 px-4 py-2 text-sm text-slate-700 hover:bg-slate-100" on:click={() => startEdit(child)}>
                      編輯
                    </button>
                    <button class="rounded-full border border-rose-200 px-4 py-2 text-sm text-rose-700 hover:bg-rose-50" on:click={() => deleteChild(child)} disabled={saving}>
                      刪除
                    </button>
                  </div>
                </div>
              {/if}
            </article>
          {/each}
        </div>
      {/if}
      
    </div>
    
    <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
      <div>
        <p class="text-sm font-medium uppercase tracking-[0.24em] text-slate-500">新增孩子</p>
        <h3 class="mt-2 text-xl font-semibold text-slate-950">建立新檔案</h3>
      </div>

      {#if error}
        <p class="mt-4 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
      {/if}

      {#if success}
        <p class="mt-4 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{success}</p>
      {/if}

      <div class="mt-5 space-y-3">
        <label class="block">
          <span class="text-sm font-medium text-slate-700">孩子名稱</span>
          <input
            bind:value={newChildName}
            class="mt-1 w-full rounded-2xl border border-slate-300 px-4 py-3 text-sm shadow-sm outline-none transition placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
            placeholder="例如：小安"
          />
        </label>

        <button
          class="inline-flex w-full items-center justify-center rounded-2xl bg-slate-950 px-4 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
          on:click|preventDefault={createChild}
          disabled={saving || !newChildName.trim()}
        >
          新增孩子
        </button>
      </div>

      <div class="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
        提示：刪除孩子會連動刪除相關事件，請先確認資料已備份。
      </div>
    </div>
  </div>
</section>
