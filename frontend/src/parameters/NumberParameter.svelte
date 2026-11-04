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

  // Update on every keystroke so the value is applied without leaving the
  // field (e.g. pressing Enter to submit the form). Intermediate states like
  // "" or "-" are skipped so the field isn't rewritten while typing.
  function handleInput(event) {
    const numValue = parseFloat(event.target.value);
    if (!isNaN(numValue)) {
      parameters[fieldName] = numValue;
    }
    onClearError?.();
  }

  // Normalize empty/invalid input to 0 once the user leaves the field.
  function handleBlur(event) {
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
    onblur={handleBlur}
    class="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {error ? 'border-red-500' : ''}"
  />
</div>
