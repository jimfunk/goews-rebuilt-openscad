<script>
    export let parameter;
    export let value = [];

    const MountHoleType = {
        Round:          { value: 1, description: "Round for heat-set insert or self-tapping screw" },
        Hex:            { value: 2, description: "Hex recess for hex nut or bolt head" },
        Square:         { value: 3, description: "Square recess for square nut" },
        SocketHead:     { value: 4, description: "Socket Head counterbore for SHCS" },
        ButtonHead:     { value: 5, description: "Button Head counterbore for BHCS" },
        CountersinkHead:{ value: 6, description: "Countersink for FHCS" },
    };

    const mountHoleTypeOptions = Object.entries(MountHoleType).map(([key, typeObject]) => ({
        value: typeObject.value,
        name: typeObject.description,
    }));

    $: if (value === null || value === undefined) {
        value = [];
    }

    function addMountHole() {
        if (!Array.isArray(value)) {
            value = [];
        }
        const newHole = {
            hole_type: MountHoleType.Round.value,
            x_offset: 20.75,
            y_offset: 17.5,
            diameter: 4.0,
            depth: 3.0,
        };
        value = [...value, newHole];
    }

    function removeMountHole(index) {
        value = value.filter((_, i) => i !== index);
    }
</script>

<div>
    <label
        for={parameter.field}
        class="block text-gray-700 text-sm font-bold mb-2"
    >
        {parameter.name}
    </label>
    <p class="text-gray-500 text-sm mb-1">
        {parameter.description}
    </p>

    {#if Array.isArray(value)}
        {#each value as hole, index (hole)}
            <div class="border p-3 mb-3 rounded-md shadow-sm bg-gray-50">
                <h4 class="text-md font-semibold mb-2 text-gray-600">Mount Hole #{index + 1}</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Hole Type -->
                    <div class="md:col-span-2">
                        <label
                            for={`hole_type-${index}`}
                            class="block text-gray-700 text-sm font-bold mb-1">Hole Type:</label
                        >
                        <select
                            id={`hole_type-${index}`}
                            bind:value={hole.hole_type}
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
                            class="block text-gray-700 text-sm font-bold mb-1">X Offset (mm):</label
                        >
                        <input
                            type="number"
                            step="any"
                            min="0.0001"
                            id={`x_offset-${index}`}
                            bind:value={hole.x_offset}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="e.g., 10.5"
                        />
                    </div>

                    <!-- Y Offset -->
                    <div>
                        <label
                            for={`y_offset-${index}`}
                            class="block text-gray-700 text-sm font-bold mb-1">Y Offset (mm):</label
                        >
                        <input
                            type="number"
                            step="any"
                            min="0.0001"
                            id={`y_offset-${index}`}
                            bind:value={hole.y_offset}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="e.g., 5.2"
                        />
                    </div>

                    <!-- Diameter -->
                    <div>
                        <label
                            for={`diameter-${index}`}
                            class="block text-gray-700 text-sm font-bold mb-1">Diameter (mm):</label
                        >
                        <input
                            type="number"
                            step="any"
                            min="0.0001"
                            id={`diameter-${index}`}
                            bind:value={hole.diameter}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="e.g., 3.0"
                        />
                    </div>

                    <!-- Depth -->
                    <div>
                        <label
                            for={`depth-${index}`}
                            class="block text-gray-700 text-sm font-bold mb-1">Depth (mm):</label
                        >
                        <input
                            type="number"
                            step="any"
                            min="0.0001"
                            id={`depth-${index}`}
                            bind:value={hole.depth}
                            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                            placeholder="e.g., 15.0"
                        />
                    </div>
                </div>
                <div class="mt-3 text-right">
                    <button
                        type="button"
                        on:click={() => removeMountHole(index)}
                        class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
                        >Remove Hole</button
                    >
                </div>
            </div>
        {/each}
    {/if}
    <button
        type="button"
        on:click={addMountHole}
        class="mt-2 bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
        >Add Mount Hole</button
    >
</div>
