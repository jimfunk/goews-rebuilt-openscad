<script>
  let { field, parameters, fieldName, error = null, onClearError = null } = $props();

  let enumValues = $derived(field?.enum || []);
  let enumNames = $derived(field?.['x-enum-varnames'] || []);
  let hasNames = $derived(enumNames.length > 0);

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
    parameters[fieldName] = event.target.value;
    onClearError?.();
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

  <select
    id={field.name}
    value={parameters[fieldName]}
    onchange={handleChange}
    class="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {error ? 'border-red-500' : ''}"
  >
    {#each enumValues as option, i}
      <option value={option}>{hasNames ? enumNames[i] : option}</option>
    {/each}
  </select>
</div>
