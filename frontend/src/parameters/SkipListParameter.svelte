<script>
  let { field, parameters, fieldName, error = null, fieldErrors = {}, onClearError = null } = $props();

  function addSkipListEntry() {
    const currentValue = parameters[fieldName] || [];
    parameters[fieldName] = [...currentValue, [1, 1]];
  }

  function removeSkipListEntry(index) {
    const currentValue = parameters[fieldName];
    parameters[fieldName] = currentValue.filter((_, i) => i !== index);
  }

  function updateEntry(index, dimensionIndex, newValue) {
    const currentValue = parameters[fieldName];
    parameters[fieldName] = currentValue.map((entry, i) =>
      i === index ? entry.map((v, j) => j === dimensionIndex ? newValue : v) : entry
    );
    onClearError?.();
  }
</script>

<div>
  <label
    for={field.name}
    class="block text-gray-700 text-sm font-bold mb-2"
  >
    {field.title}
  </label>
  <p class="text-gray-500 text-sm mb-1">
    {field.description}
  </p>

  {#if error}
    <div class="bg-red-100 border border-red-400 text-red-700 px-3 py-2 rounded mb-3 text-sm">
      {error}
    </div>
  {/if}

  {#if Array.isArray(parameters[fieldName])}
    {#each parameters[fieldName] as skip_tile, index}
      <div class="flex items-center space-x-2 mb-2">
        <label
          for={`row-${index}`}
          class="text-gray-700 text-sm font-bold">Row:</label
        >
        <input
          type="text"
          inputmode="numeric"
          id={`row-${index}`}
          value={parameters[fieldName][index][0]}
          onblur={(e) => updateEntry(index, 0, parseInt(e.target.value) || 0)}
          class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline w-20 {error ? 'border-red-500' : ''}"
        />
        <label
          for={`column-${index}`}
          class="text-gray-700 text-sm font-bold">Column:</label
        >
        <input
          type="text"
          inputmode="numeric"
          id={`column-${index}`}
          value={parameters[fieldName][index][1]}
          onblur={(e) => updateEntry(index, 1, parseInt(e.target.value) || 0)}
          class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline w-20 {error ? 'border-red-500' : ''}"
        />
        <button
          type="button"
          onclick={() => removeSkipListEntry(index)}
          class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
          >Remove</button
        >
      </div>
    {/each}
  {/if}
  <button
    type="button"
    onclick={addSkipListEntry}
    class="bg-green-500 hover:bg-green-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
    >Add</button
  >
</div>
