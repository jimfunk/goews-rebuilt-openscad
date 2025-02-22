<script>
    export let parameter;
    export let value;

    function addSkipListEntry() {
        if (!value) {
            value = [];
        }
        value = [...value, [1, 1]];
    }

    function removeSkipListEntry(index) {
        value = value.filter(
            (_, i) => i !== index,
        );
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
        {#each value as skip_tile, index}
            <div class="flex items-center space-x-2 mb-2">
                <label
                    for={`row-${index}`}
                    class="text-gray-700 text-sm font-bold">Row:</label
                >
                <input
                    type="number"
                    id={`row-${index}`}
                    bind:value={value[index][0]}
                    class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline w-20"
                />
                <label
                    for={`column-${index}`}
                    class="text-gray-700 text-sm font-bold">Column:</label
                >
                <input
                    type="number"
                    id={`column-${index}`}
                    bind:value={value[index][1]}
                    class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline w-20"
                />
                <button
                    type="button"
                    on:click={() => removeSkipListEntry(index)}
                    class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
                    >Remove</button
                >
            </div>
        {/each}
    {/if}
    <button
        type="button"
        on:click={addSkipListEntry}
        class="bg-green-500 hover:bg-green-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline"
        >Add</button
    >
</div>
