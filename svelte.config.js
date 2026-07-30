import adapter from '@sveltejs/adapter-netlify';
// using no preprocess for now; update svelte-preprocess to a Svelte 5 compatible version if you need preprocessing

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: [],
  kit: {
    adapter: adapter(),
    alias: {
      $lib: 'src/lib'
    }
  }
};

export default config;
