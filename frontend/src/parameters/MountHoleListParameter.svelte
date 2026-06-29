<script>
  let { field, parameters, fieldName, error = null, fieldErrors = {}, onClearError = null } = $props();

  // Parse errors like "holes.0.diameter" into {0: {diameter: "..."}}
  let holeFieldErrors = $derived.by(() => {
    const result = {};
    for (const [key, value] of Object.entries(fieldErrors)) {
      const parts = key.split('.');
      if (parts[0] === fieldName && parts.length === 3) {
        const index = parseInt(parts[1]);
        const subField = parts[2];
        if (!result[index]) result[index] = {};
        result[index][subField] = value;
      }
    }
    return result;
  });

  const MountHoleType = {
    Round: 'Round',
    Hex: 'Hex',
    Square: 'Square',
    SocketHead: 'Socket Head',
    ButtonHead: 'Button Head',
    CountersinkHead: 'Countersink Head',
  };

  const mountHoleTypeDescriptions = {
    Round: 'Round for heat-set insert or self-tapping screw',
    Hex: 'Hex recess for hex nut or bolt head',
    Square: 'Square recess for square nut',
    'Socket Head': 'Socket Head counterbore for SHCS',
    'Button Head': 'Button Head counterbore for BHCS',
    'Countersink Head': 'Countersink for FHCS',
  };

  const mountHoleTypeOptions = Object.values(MountHoleType).map((value) => ({
    value: value,
    name: mountHoleTypeDescriptions[value],
  }));

  function addMountHole() {
    const currentValue = parameters[fieldName] || [];
    const newHole = {
      hole_type: MountHoleType.Round,
      x_offset: 20.75,
      y_offset: 17.5,
      diameter: 4.0,
      depth: 3.0,
    };
    parameters[fieldName] = [...currentValue, newHole];
  }

  function removeMountHole(index) {
    const currentValue = parameters[fieldName];
    parameters[fieldName] = currentValue.filter((_, i) => i !== index);
  }

  function updateHole(index, field, newValue) {
    const currentValue = parameters[fieldName];
    parameters[fieldName] = currentValue.map((hole, i) =>
      i === index ? { ...hole, [field]: newValue } : hole
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

  {#if error && Object.keys(holeFieldErrors).length === 0}
    <div class="bg-red-100 border border-red-400 text-red-700 px-3 py-2 rounded mb-3 text-sm">
      {error}
    </div>
  {/if}

  {#if Array.isArray(parameters[fieldName])}
    {#each parameters[fieldName] as hole, index (hole)}
      <div class="border p-3 mb-3 rounded-md shadow-sm bg-gray-50">
        <h4 class="text-md font-semibold mb-2 text-gray-600">Mount Hole #{index + 1}</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Hole Type -->
          <div class="md:col-span-2">
            <label
              for={`hole_type-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Hole Type:</label
            >
            <select
              id={`hole_type-${index}`}
              value={hole.hole_type}
              onchange={(e) => updateHole(index, 'hole_type', e.target.value)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
            >
              {#each mountHoleTypeOptions as option}
                <option value={option.value}>{option.name}</option>
              {/each}
            </select>
          </div>

          <!-- X Offset -->
          <div>
            <label
              for={`x_offset-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >X Offset (mm):</label
            >
            <input
              type="text"
              inputmode="decimal"
              id={`x_offset-${index}`}
              value={hole.x_offset}
              onblur={(e) => updateHole(index, 'x_offset', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {holeFieldErrors[index]?.x_offset ? 'border-red-500' : ''}"
              placeholder="e.g., 10.5"
            />
            {#if holeFieldErrors[index]?.x_offset}
              <p class="text-red-500 text-xs mt-1">{holeFieldErrors[index].x_offset}</p>
            {/if}
          </div>

          <!-- Y Offset -->
          <div>
            <label
              for={`y_offset-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Y Offset (mm):</label
            >
            <input
              type="text"
              inputmode="decimal"
              id={`y_offset-${index}`}
              value={hole.y_offset}
              onblur={(e) => updateHole(index, 'y_offset', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {holeFieldErrors[index]?.y_offset ? 'border-red-500' : ''}"
              placeholder="e.g., 5.2"
            />
            {#if holeFieldErrors[index]?.y_offset}
              <p class="text-red-500 text-xs mt-1">{holeFieldErrors[index].y_offset}</p>
            {/if}
          </div>

          <!-- Diameter -->
          <div>
            <label
              for={`diameter-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Diameter (mm):</label
            >
            <input
              type="text"
              inputmode="decimal"
              id={`diameter-${index}`}
              value={hole.diameter}
              onblur={(e) => updateHole(index, 'diameter', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {holeFieldErrors[index]?.diameter ? 'border-red-500' : ''}"
              placeholder="e.g., 3.0"
            />
            {#if holeFieldErrors[index]?.diameter}
              <p class="text-red-500 text-xs mt-1">{holeFieldErrors[index].diameter}</p>
            {/if}
          </div>

          <!-- Depth -->
          <div>
            <label
              for={`depth-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Depth (mm):</label
            >
            <input
              type="text"
              inputmode="decimal"
              id={`depth-${index}`}
              value={hole.depth}
              onblur={(e) => updateHole(index, 'depth', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline {holeFieldErrors[index]?.depth ? 'border-red-500' : ''}"
              placeholder="e.g., 15.0"
            />
            {#if holeFieldErrors[index]?.depth}
              <p class="text-red-500 text-xs mt-1">{holeFieldErrors[index].depth}</p>
            {/if}
          </div>
        </div>
        <div class="mt-3 text-right">
          <button
            type="button"
            onclick={() => removeMountHole(index)}
            class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
            >Remove Hole</button
          >
        </div>
      </div>
    {/each}
  {/if}
  <button
    type="button"
    onclick={addMountHole}
    class="mt-2 bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
    >Add Mount Hole</button
  >
</div>
