<script>
  let { value = $bindable() } = $props();

  const variants = [
    { value: 'Original', label: 'Original' },
    { value: 'Thicker Cleats', label: 'Thicker Cleats' },
  ];
</script>

<div>
  <label for="global-variant" class="block text-gray-700 text-sm font-bold mb-2">Variant</label>
  <p class="text-gray-500 text-sm mb-2">
    The original variant is compatible with legacy tiles and accessories.
    The thicker cleats variant shifts the cleat profile back 1mm for 60% higher
    weight capacity and 10% less filament usage. The two profiles are
    mechanically incompatible. If starting a new deployment, the thicker cleats
    variant is recommended.
  </p>
  <select
    id="global-variant"
    bind:value={value}
    class="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
  >
    {#each variants as variant}
      <option value={variant.value}>{variant.label}</option>
    {/each}
  </select>
</div>
