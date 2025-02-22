<script>
    export let parameter;
    export let value;
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

    <input
        type="number"
        step="any"
        id={parameter.field}
        bind:value={value}
        class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
    />
</div>
