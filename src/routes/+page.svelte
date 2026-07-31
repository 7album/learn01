<script lang="ts">
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';

  async function enterApp() {
    const { data } = await supabase.auth.getSession();
    await goto(data.session ? '/app' : '/login');
  }
</script>

<section class="mx-auto flex min-h-screen max-w-5xl items-center px-6 py-12">
  <div class="grid gap-8 md:grid-cols-[1.3fr_0.7fr]">
    <div class="space-y-6">
      <p class="text-sm uppercase tracking-[0.35em] text-slate-500">個人成長</p>
      <h1 class="max-w-2xl text-5xl font-semibold leading-tight text-slate-900">在一個安定的工作區裡追蹤事件與家庭進展。</h1>
      <p class="max-w-xl text-lg text-slate-600">使用電子郵件與密碼登入後，進入受保護的儀表板，並透過範例事件頁面測試登入後流程。</p>
      <div class="flex gap-3">
        <button class="rounded-full bg-slate-900 px-5 py-3 text-white" on:click={enterApp}>進入應用</button>
        <a href="/login" class="rounded-full border border-slate-300 px-5 py-3 text-slate-800">登入</a>
      </div>
    </div>

    <div class="rounded-3xl border border-slate-200 bg-white p-6 shadow-xl">
      <p class="text-sm text-slate-500">包含內容</p>
      <ul class="mt-4 space-y-3 text-slate-700">
        <li>受保護的 `/app` 儀表板</li>
        <li>新增與編輯事件頁面</li>
        <li>登出流程與驗證重新導向</li>
      </ul>
    </div>
  </div>
</section>
