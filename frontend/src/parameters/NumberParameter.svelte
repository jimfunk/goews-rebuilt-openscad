<script>
  let { field, parameters, fieldName } = $props();

  function formatTitle(title) {
    if (!title) return '';
    return title
      .replace(/([A-Z])/g, ' $1')
      .replace(/^ /, '')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  let formattedTitle = $derived(formatTitle(field?.title) || field?.name?.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()));

  function handleInput(event) {
    const numValue = parseFloat(event.target.value);
    parameters[fieldName] = isNaN(numValue) ? 0 : numValue;
  }
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
    type="number"
    step="any"
    id={field.name}
    value={parameters[fieldName]}
    oninput={handleInput}
    class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
  />
</div>
