<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let email = '';
  let password = '';
  let mode: 'login' | 'register' = 'login';

  async function submit() {
    const result =
      mode === 'login'
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.signUp({ email, password });
    const { error } = result;

    if (error) {
      alert(error.message);
      return;
    }

    await goto('/app');
  }
</script>

<section class="mx-auto flex min-h-screen max-w-md items-center px-6 py-12">
  <div class="w-full rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
    <p class="text-sm uppercase tracking-[0.3em] text-slate-500">驗證</p>
    <h2 class="mt-2 text-2xl font-semibold">{mode === 'login' ? '使用電子郵件登入' : '建立帳號'}</h2>
    <p class="mt-2 text-sm text-slate-500">改用密碼登入，不再依賴魔術連結，避免碰到信件額度限制。</p>

    <form class="mt-6 space-y-4" on:submit|preventDefault={submit}>
      <label class="block">
        <span class="text-sm font-medium text-slate-700">電子郵件</span>
        <input class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" bind:value={email} type="email" required />
      </label>

      <label class="block">
        <span class="text-sm font-medium text-slate-700">密碼</span>
        <input class="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2" bind:value={password} type="password" minlength="6" required />
      </label>

      <button class="w-full rounded-full bg-slate-900 px-5 py-2.5 text-white" type="submit">
        {mode === 'login' ? '登入' : '註冊'}
      </button>
    </form>

    <button class="mt-4 text-sm text-emerald-700 underline" on:click={() => (mode = mode === 'login' ? 'register' : 'login')}>
      {mode === 'login' ? '需要帳號？改用註冊' : '已經有帳號？改用登入'}
    </button>
  </div>
</section>
