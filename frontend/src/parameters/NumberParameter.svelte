<script>
  let { field, parameters, fieldName, error = null, onClearError = null } = $props();

  function formatTitle(title) {
    if (!title) return '';
    return title
      .replace(/([A-Z])/g, ' $1')
      .replace(/^ /, '')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  let formattedTitle = $derived(formatTitle(field?.title) || field?.name?.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()));

  // Use a string buffer for the input to allow typing decimals
  let inputBuffer = $state('');

  // Sync from parameter when not editing
  function syncFromParam() {
    inputBuffer = String(parameters[fieldName] ?? '');
  }

  function handleFocus() {
    syncFromParam();
  }

  function handleInput(event) {
    // Update local buffer, don't touch parameters yet
    inputBuffer = event.target.value;
  }

  function handleBlur() {
    const numValue = parseFloat(inputBuffer);
    if (!isNaN(numValue)) {
      parameters[fieldName] = numValue;
    } else {
      parameters[fieldName] = 0;
    }
    onClearError?.();
  }

  // Initialize
  syncFromParam();
</script>

<div>
  <label
    for={field.name}
    class="block text-gray-700 text-sm font-bold mb-2"
  >
    {formattedTitle}
  </label>
  <p class="text-gray-500 text-sm mb-1">
    {field.description}
  </p>

  <input
    type="text"
    inputmode="decimal"
    id={field.name}
    bind:value={inputBuffer}
    onfocus={handleFocus}
    onblur={handleBlur}
    class="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {error ? 'border-red-500' : ''}"
  />
</div>
