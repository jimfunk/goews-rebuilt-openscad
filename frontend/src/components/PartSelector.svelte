<script>
  let { selectedPartId = $bindable(), parts = {}, onChange = () => {} } = $props();

  let partIds = $derived(Object.keys(parts));
</script>

<div class="part-selector">
  <label for="part-select">Select Part</label>
  <select
    id="part-select"
    bind:value={selectedPartId}
    on:change={(e) => onChange(e.target.value)}
  >
    {#each partIds as id}
      <option value={id}>{parts[id].name}</option>
    {/each}
  </select>

  {#if parts[selectedPartId]?.description}
    <p class="description">{parts[selectedPartId].description}</p>
  {/if}
</div>

<style>
  .part-selector {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  label {
    font-weight: 600;
    font-size: 1rem;
  }

  select {
    padding: 0.5rem;
    font-size: 1rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: white;
    cursor: pointer;
  }

  .description {
    font-size: 0.9rem;
    color: #666;
    margin: 0;
  }
</style>
