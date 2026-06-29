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

  function handleChange(event) {
    parameters[fieldName] = event.target.checked;
    onClearError?.();
  }
</script>

<div>
  <input
    type="checkbox"
    id={field.name}
    checked={parameters[fieldName]}
    onchange={handleChange}
    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
  />
  <label
    for={field.name}
    class="text-gray-700 text-sm font-bold cursor-pointer"
  >
    {formattedTitle}
  </label>
  <p class="text-gray-500 text-sm mb-1">
    {field.description}
  </p>
</div>
