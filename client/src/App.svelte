<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from './assets/vite.svg'
  import rustLogo from './assets/rust-logo-blk.svg'
  import Counter from './lib/Counter.svelte'
</script>

<main>
  <div>
    <a href="https://vitejs.dev" target="_blank" rel="noreferrer">
      <img src={viteLogo} class="logo" alt="Vite Logo" />
    </a>
    <a href="https://svelte.dev" target="_blank" rel="noreferrer">
      <img src={svelteLogo} class="logo svelte" alt="Svelte Logo" />
    </a>
    <a href="https://www.rust-lang.org/" target="_blank" rel="noreferrer">
      <img src={rustLogo} class="logo" alt="Rust Logo" />
    </a>
  </div>
  <h1>Vite + Svelte + Rust using Axum</h1>

  <div class="card">
    <Counter />
  </div>

  <p>
    Hello, World!
  </p>

  <p class="read-the-docs">
    Click on the Vite, Svelte and Rust logos to learn more
  </p>
</main>

<style>
  .logo {
    height: 6em;
    padding: 1.5em;
    will-change: filter;
    transition: filter 300ms;
  }
  .logo:hover {
    filter: drop-shadow(0 0 2em #646cffaa);
  }
  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00aa);
  }
  .read-the-docs {
    color: #888;
  }
</style>
