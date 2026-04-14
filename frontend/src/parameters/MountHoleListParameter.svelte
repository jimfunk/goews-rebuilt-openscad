<script>
  let { field, parameters, fieldName } = $props();

  const MountHoleType = {
    Round: { value: 1, description: 'Round for heat-set insert or self-tapping screw' },
    Hex: { value: 2, description: 'Hex recess for hex nut or bolt head' },
    Square: { value: 3, description: 'Square recess for square nut' },
    SocketHead: { value: 4, description: 'Socket Head counterbore for SHCS' },
    ButtonHead: { value: 5, description: 'Button Head counterbore for BHCS' },
    CountersinkHead: { value: 6, description: 'Countersink for FHCS' },
  };

  const mountHoleTypeOptions = Object.entries(MountHoleType).map(([key, typeObject]) => ({
    value: typeObject.value,
    name: typeObject.description,
  }));

  function addMountHole() {
    const currentValue = parameters[fieldName] || [];
    const newHole = {
      hole_type: MountHoleType.Round.value,
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
              onchange={(e) => updateHole(index, 'hole_type', parseInt(e.target.value))}
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
              type="number"
              step="any"
              min="0.0001"
              id={`x_offset-${index}`}
              value={hole.x_offset}
              oninput={(e) => updateHole(index, 'x_offset', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              placeholder="e.g., 10.5"
            />
          </div>

          <!-- Y Offset -->
          <div>
            <label
              for={`y_offset-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Y Offset (mm):</label
            >
            <input
              type="number"
              step="any"
              min="0.0001"
              id={`y_offset-${index}`}
              value={hole.y_offset}
              oninput={(e) => updateHole(index, 'y_offset', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              placeholder="e.g., 5.2"
            />
          </div>

          <!-- Diameter -->
          <div>
            <label
              for={`diameter-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Diameter (mm):</label
            >
            <input
              type="number"
              step="any"
              min="0.0001"
              id={`diameter-${index}`}
              value={hole.diameter}
              oninput={(e) => updateHole(index, 'diameter', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              placeholder="e.g., 3.0"
            />
          </div>

          <!-- Depth -->
          <div>
            <label
              for={`depth-${index}`}
              class="block text-gray-700 text-sm font-bold mb-1"
              >Depth (mm):</label
            >
            <input
              type="number"
              step="any"
              min="0.0001"
              id={`depth-${index}`}
              value={hole.depth}
              oninput={(e) => updateHole(index, 'depth', parseFloat(e.target.value) || 0)}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              placeholder="e.g., 15.0"
            />
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
