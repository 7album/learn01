<script lang="ts">
  import { createClient } from '@supabase/supabase-js';
  import { goto } from '$app/navigation';

  let email = '';
  let mode = 'magiclink';

  async function send() {
    const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
    const supabaseKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { error } = await supabase.auth.signInWithOtp({ email });
    if (error) {
      alert(error.message);
      return;
    }
    alert('Magic link sent — check your email.');
    goto('/');
  }
</script>

<section class="p-6 max-w-md mx-auto">
  <h2 class="text-2xl mb-4">Log in</h2>
  <label class="block mb-2">Email
    <input class="w-full border rounded px-2 py-1" bind:value={email} type="email" />
  </label>
  <button class="mt-3 px-4 py-2 bg-indigo-600 text-white rounded" on:click={send}>Send magic link</button>
</section>
