<script>
    export let parameter;
    export let value;
</script>

<div>
    <input
        type="checkbox"
        id={parameter.field}
        bind:checked={value}
        class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
    />
    <label
        for={parameter.field}
        class="text-gray-700 text-sm font-bold cursor-pointer"
    >
        {parameter.name}
    </label>
    <p class="text-gray-500 text-sm mb-1">
        {parameter.description}
    </p>
</div>
