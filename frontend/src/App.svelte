<script>
    import { Canvas } from "@threlte/core";
    import { onMount } from "svelte";
    import STLViewer from "./STLViewer.svelte";
    import BooleanParameter from "./parameters/BooleanParameter.svelte";
    import NumberParameter from "./parameters/NumberParameter.svelte";
    import SelectParameter from "./parameters/SelectParameter.svelte";
    import SkipListParameter from "./parameters/SkipListParameter.svelte";

    let selectedPartType = "tile";
    let parameters = {};
    let parameterCache = {};
    let loading = false;
    let errorMessage = null;
    let stlUrl = null;
    let stlBlob = null;

    const parameterCacheKey = "partParameters";

    const variantParameter = {
        field: "variant",
        name: "Variant",
        type: "select",
        default: 0,
        options: {
            0: "Original version",
            1: "Thicker cleats",
        },
        description: "Tile variant",
    };

    const partDescriptions = {
        tile: {
            name: "Tile",
            URL: "/api/tile",
            parameters: [
                {
                    field: "columns",
                    name: "Columns",
                    type: "number",
                    default: 1,
                    description: "Tile columns in units",
                },
                {
                    field: "rows",
                    name: "Rows",
                    type: "number",
                    default: 1,
                    description: "Tile rows in units",
                },
                {
                    field: "fill_top",
                    name: "Fill top",
                    type: "boolean",
                    default: false,
                    description:
                        "Fill the top row edge. Adds additional mounting holes",
                },
                {
                    field: "fill_bottom",
                    name: "Fill bottom",
                    type: "boolean",
                    default: false,
                    description: "Fill the bottom row edge",
                },
                {
                    field: "fill_left",
                    name: "Fill left",
                    type: "boolean",
                    default: false,
                    description: "Fill the left row edge",
                },
                {
                    field: "fill_right",
                    name: "Fill right",
                    type: "boolean",
                    default: false,
                    description: "Fill the right row edge",
                },
                {
                    field: "mounting_hole_shank_diameter",
                    name: "Mounting hole shank diameter",
                    type: "number",
                    default: 4.0,
                    description: "Mounting hole shank diameter in mm",
                },
                {
                    field: "mounting_hole_head_diameter",
                    name: "Mounting hole head diameter",
                    type: "number",
                    default: 8.0,
                    description: "Mounting hole head diameter in mm",
                },
                {
                    field: "mounting_hole_inset_depth",
                    name: "Mounting hole inset depth",
                    type: "number",
                    default: 1.0,
                    description: "Mounting hole inset depth in mm",
                },
                {
                    field: "mounting_hole_countersink_depth",
                    name: "Mounting hole countersink depth",
                    type: "number",
                    default: 2.0,
                    description:
                        "Mounting hole countersink depth. Set to 0 to disable countersink and allow for pan head screws",
                },
                {
                    field: "skip_list",
                    name: "Skip list",
                    type: "skip_list",
                    default: [],
                    description:
                        "List of tiles to exclude as row and column numbers starting at the lower left",
                },
                variantParameter,
            ],
        },
        grid_tile: {
            name: "Grid tile",
            URL: "/api/grid-tile",
            parameters: [
                {
                    field: "columns",
                    name: "Columns",
                    type: "number",
                    default: 1,
                    description: "Tile columns in units",
                },
                {
                    field: "rows",
                    name: "Rows",
                    type: "number",
                    default: 1,
                    description: "Tile rows in units",
                },
                {
                    field: "mounting_hole_shank_diameter",
                    name: "Mounting hole shank diameter",
                    type: "number",
                    default: 4.0,
                    description: "Mounting hole shank diameter in mm",
                },
                {
                    field: "mounting_hole_head_diameter",
                    name: "Mounting hole head diameter",
                    type: "number",
                    default: 8.0,
                    description: "Mounting hole head diameter in mm",
                },
                {
                    field: "mounting_hole_inset_depth",
                    name: "Mounting hole inset depth",
                    type: "number",
                    default: 1.0,
                    description: "Mounting hole inset depth in mm",
                },
                {
                    field: "mounting_hole_countersink_depth",
                    name: "Mounting hole countersink depth",
                    type: "number",
                    default: 2.0,
                    description:
                        "Mounting hole countersink depth. Set to 0 to disable countersink and allow for pan head screws",
                },
                {
                    field: "skip_list",
                    name: "Skip list",
                    type: "skip_list",
                    default: [],
                    description:
                        "List of tiles to exclude as row and column numbers starting at the lower left",
                },
                variantParameter,
            ],
        },
        bolt: {
            name: "Bolt",
            URL: "/api/bolt",
            parameters: [
                {
                    field: "length",
                    name: "Length",
                    type: "number",
                    default: 9.0,
                    description:
                        "Length of the threaded part of the bolt in mm",
                },
                {
                    field: "socket_width",
                    name: "Socket width",
                    type: "number",
                    default: 8.4,
                    description: "Width of the socket in mm",
                },
            ],
        },
        hook: {
            name: "Hook",
            URL: "/api/hook",
            parameters: [
                {
                    field: "hooks",
                    name: "Hooks",
                    type: "number",
                    default: 1,
                    description: "Number of hooks",
                },
                {
                    field: "width",
                    name: "Width",
                    type: "number",
                    default: 10.0,
                    description: "Width of the hook in mm",
                },
                {
                    field: "gap",
                    name: "Gap",
                    type: "number",
                    default: 10.0,
                    description:
                        "Gap between hooks when there is more than one",
                },
                {
                    field: "shank_length",
                    name: "Shank length",
                    type: "number",
                    default: 10.0,
                    description: "Length of the shank in mm",
                },
                {
                    field: "shank_thickness",
                    name: "Shank thickness",
                    type: "number",
                    default: 8.0,
                    description: "Thickness of the shank in mm",
                },
                {
                    field: "post_height",
                    name: "Post height",
                    type: "number",
                    default: 18.0,
                    description:
                        "Height of the post in mm. If 0 the post will be omitted",
                },
                {
                    field: "post_thickness",
                    name: "Post thickness",
                    type: "number",
                    default: 6.0,
                    description:
                        "Thickness of the post in mm. If 0 the post will be omitted",
                },
                {
                    field: "rounding",
                    name: "Rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the hook outer corners in mm",
                },
                variantParameter,
            ],
        },
        rack: {
            name: "Rack",
            URL: "/api/rack",
            parameters: [
                {
                    field: "slots",
                    name: "Slots",
                    type: "number",
                    default: 7,
                    description: "Number of slots",
                },
                {
                    field: "slot_width",
                    name: "Slot width",
                    type: "number",
                    default: 6.0,
                    description: "Width of each slot in mm",
                },
                {
                    field: "divider_width",
                    name: "Divider width",
                    type: "number",
                    default: 10.0,
                    description: "Width of dividers in mm",
                },
                {
                    field: "divider_length",
                    name: "Divider length",
                    type: "number",
                    default: 80.0,
                    description: "Length of the dividers in mm",
                },
                {
                    field: "divider_thickness",
                    name: "Divider thickness",
                    type: "number",
                    default: 6.0,
                    description: "Thickness of the dividers in mm",
                },
                {
                    field: "lip",
                    name: "Add lip",
                    type: "boolean",
                    default: false,
                    description:
                        "Whether to include a lip at the front of the dividers",
                },
                {
                    field: "lip_height",
                    name: "Lip height",
                    type: "number",
                    default: 8.0,
                    description: "Height of the lip in mm",
                },
                {
                    field: "lip_thickness",
                    name: "Lip thickness",
                    type: "number",
                    default: 4.0,
                    description: "Thickness of the lip in mm",
                },
                {
                    field: "rounding",
                    name: "Rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the hook outer corners in mm",
                },
                variantParameter,
            ],
        },
        shelf: {
            name: "Shelf",
            URL: "/api/shelf",
            parameters: [
                {
                    field: "width",
                    name: "Width",
                    type: "number",
                    default: 83.5,
                    description: "Width of shelf in mm",
                },
                {
                    field: "depth",
                    name: "Depth",
                    type: "number",
                    default: 30.0,
                    description: "Depth of shelf in mm",
                },
                {
                    field: "thickness",
                    name: "Thickness",
                    type: "number",
                    default: 4,
                    description: "Thickness of shelf in mm",
                },
                {
                    field: "rear_fillet_radius",
                    name: "Rear fillet radius",
                    type: "number",
                    default: 1.0,
                    description: "Rear fillet radius in mm",
                },
                {
                    field: "rounding",
                    name: "Rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the front edges in mm",
                },
                variantParameter,
            ],
        },
        hole_shelf: {
            name: "Shelf with holes",
            URL: "/api/hole_shelf",
            parameters: [
                {
                    field: "columns",
                    name: "Columns",
                    type: "number",
                    default: 3,
                    description: "Number of solumns in the shelf",
                },
                {
                    field: "rows",
                    name: "Rows",
                    type: "number",
                    default: 1,
                    description: "Number of rows in the shelf",
                },
                {
                    field: "thickness",
                    name: "Thickness",
                    type: "number",
                    default: 4,
                    description: "Thickness of shelf in mm",
                },
                {
                    field: "hole_radius",
                    name: "Hole radius",
                    type: "number",
                    default: 3.5,
                    description: "Radius of hole in mm",
                },
                {
                    field: "column_gap",
                    name: "Column gap",
                    type: "number",
                    default: 15,
                    description: "Gap between holes in a column in mm",
                },
                {
                    field: "row_gap",
                    name: "Row gap",
                    type: "number",
                    default: 15,
                    description: "Gap between holes in a row in mm",
                },
                {
                    field: "front_gap",
                    name: "Front gap",
                    type: "number",
                    default: 15,
                    description:
                        "Gap between front of shelf and the front holes in mm",
                },
                {
                    field: "rear_gap",
                    name: "Rear gap",
                    type: "number",
                    default: 15,
                    description:
                        "Gap between back of shelf and the rear holes in mm",
                },
                {
                    field: "side_gap",
                    name: "Side gap",
                    type: "number",
                    default: 15,
                    description:
                        "Gap between side of shelf and the side holes in mm",
                },
                {
                    field: "stagger",
                    name: "Stagger rows",
                    type: "boolean",
                    default: false,
                    description: "Whether to stagger the rows",
                },
                {
                    field: "rear_fillet_radius",
                    name: "Rear fillet radius",
                    type: "number",
                    default: 1.0,
                    description: "Rear fillet radius in mm",
                },
                {
                    field: "rounding",
                    name: "Rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the front edges in mm",
                },
                variantParameter,
            ],
        },
        slot_shelf: {
            name: "Shelf with slots",
            URL: "/api/slot_shelf",
            parameters: [
                {
                    field: "slots",
                    name: "Slots",
                    type: "number",
                    default: 4,
                    description: "Number of slots in the shelf",
                },
                {
                    field: "thickness",
                    name: "Thickness",
                    type: "number",
                    default: 4,
                    description: "Thickness of shelf in mm",
                },
                {
                    field: "slot_length",
                    name: "Slot length",
                    type: "number",
                    default: 40,
                    description: "Slot length in mm",
                },
                {
                    field: "slot_width",
                    name: "Slot width",
                    type: "number",
                    default: 10,
                    description: "Slot width in mm",
                },
                {
                    field: "slot_rounding",
                    name: "Slot rounding",
                    type: "number",
                    default: 1,
                    description: "Slot corner rounding in mm",
                },
                {
                    field: "gap",
                    name: "Gap",
                    type: "number",
                    default: 10,
                    description: "Gap between slots in mm",
                },
                {
                    field: "front_gap",
                    name: "Front gap",
                    type: "number",
                    default: 5,
                    description: "Gap between front of shelf and slots in mm",
                },
                {
                    field: "rear_gap",
                    name: "Rear gap",
                    type: "number",
                    default: 10,
                    description: "Gap between back of shelf and slots in mm",
                },
                {
                    field: "side_gap",
                    name: "Side gap",
                    type: "number",
                    default: 5,
                    description: "Gap between side of shelf and slots in mm",
                },
                {
                    field: "rear_fillet_radius",
                    name: "Rear fillet radius",
                    type: "number",
                    default: 1.0,
                    description: "Rear fillet radius in mm",
                },
                {
                    field: "rounding",
                    name: "Rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the front edges in mm",
                },
                variantParameter,
            ],
        },
        bin: {
            name: "Bin",
            URL: "/api/bin",
            parameters: [
                {
                    field: "width",
                    name: "Width",
                    type: "number",
                    default: 41.5,
                    description: "Outer width in mm",
                },
                {
                    field: "depth",
                    name: "Depth",
                    type: "number",
                    default: 41.5,
                    description: "Outer depth in mm",
                },
                {
                    field: "height",
                    name: "Height",
                    type: "number",
                    default: 20,
                    description: "Height in mm",
                },
                {
                    field: "wall_thickness",
                    name: "Wall thickness",
                    type: "number",
                    default: 1,
                    description: "Wall thickness in mm",
                },
                {
                    field: "bottom_thickness",
                    name: "Bottom thickness",
                    type: "number",
                    default: 2,
                    description: "Bottom thickness in mm",
                },
                {
                    field: "lip_thickness",
                    name: "Lip thickness",
                    type: "number",
                    default: 1,
                    description: "Lip thickness in mm",
                },
                {
                    field: "inner_rounding",
                    name: "Inner rounding",
                    type: "number",
                    default: 1,
                    description: "Rounding of the inner edges in mm",
                },
                {
                    field: "outer_rounding",
                    name: "Outer rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the outer edges in mm",
                },
                variantParameter,
            ],
        },
        cup: {
            name: "Cup",
            URL: "/api/cup",
            parameters: [
                {
                    field: "inner_diameter",
                    name: "Inner diameter",
                    type: "number",
                    default: 37.5,
                    description: "Inner diameter in mm",
                },
                {
                    field: "height",
                    name: "Height",
                    type: "number",
                    default: 20,
                    description: "Height in mm",
                },
                {
                    field: "wall_thickness",
                    name: "Wall thickness",
                    type: "number",
                    default: 2,
                    description: "Wall thickness in mm",
                },
                {
                    field: "bottom_thickness",
                    name: "Bottom thickness",
                    type: "number",
                    default: 2,
                    description: "Bottom thickness in mm",
                },
                {
                    field: "inner_rounding",
                    name: "Inner rounding",
                    type: "number",
                    default: .5,
                    description: "Rounding of the inner edges in mm",
                },
                {
                    field: "outer_rounding",
                    name: "Outer rounding",
                    type: "number",
                    default: 0.5,
                    description: "Rounding of the outer edges in mm",
                },
                variantParameter,
            ],
        },
    };

    function loadParameterCache() {
        const params = localStorage.getItem(parameterCacheKey);
        if (params) {
            try {
                parameterCache = JSON.parse(params);
            } catch (error) {
                console.error("Error parsing cached parameters:", error);
                parameterCache = {};
            }
        } else {
            parameterCache = {};
        }
    }

    function selectPart(partType) {
        selectedPartType = partType;
        loadParameters();
    }

    function resetParameters() {
        parameters = {};
        partDescriptions[selectedPartType].parameters.forEach((param) => {
            parameters[param.field] = param.default;
        });
    }

    function loadParameters() {
        parameters = {};
        const cached = parameterCache[selectedPartType] || {};

        partDescriptions[selectedPartType].parameters.forEach((param) => {
            if (cached.hasOwnProperty(param.field)) {
                parameters[param.field] = cached[param.field];
            } else {
                parameters[param.field] = param.default;
            }
        });
    }

    function saveParameters() {
        parameterCache[selectedPartType] = { ...parameters };
        localStorage.setItem(parameterCacheKey, JSON.stringify(parameterCache));
    }

    async function generate() {
        loading = true;
        errorMessage = null;
        try {
            const response = await fetch(
                partDescriptions[selectedPartType].URL,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify(parameters),
                },
            );
            if (!response.ok) {
                const errorData = await response.json();
                errorMessage = `Error: ${response.status} - ${errorData?.message || response.statusText}`;
                throw new Error(errorMessage);
            }
            stlBlob = await response.blob();
            stlUrl = URL.createObjectURL(stlBlob);
            saveParameters();
        } catch (error) {
            console.error("Generation failed:", error);
            errorMessage = error.message;
        } finally {
            loading = false;
        }
    }

    function download() {
        if (!stlBlob) return;
        const a = document.createElement("a");
        const url = URL.createObjectURL(stlBlob);
        const part = partDescriptions[selectedPartType];
        let filenameSegments = [part.name.toLowerCase()];

        part.parameters.forEach((param) => {
            if (param.field === "variant") {
                const variantNames = ["original", "thicker_cleats"];
                filenameSegments.push(`${variantNames[parameters.variant]}`);
            } else {
                filenameSegments.push(
                    `${param.name.toLowerCase()}_${parameters[param.field]}`,
                );
            }
        });

        a.href = url;
        a.download = `${filenameSegments.join("_")}.stl`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    onMount(() => {
        loadParameterCache();
        selectPart(selectedPartType);
    });
</script>

<svelte:head>
    <title>GOEWS Part Generator</title>
</svelte:head>

<main class="bg-gray-100">
    <div
        class="w-ful bg-gray-800 text-white p-4 mb-6 flex items-center justify-between"
    >
        <h1 class="text-xl font-bold">GOEWS Part Generator</h1>
        <a
            href="https://github.com/jimfunk/goews-rebuilt-openscad"
            target="_blank"
            rel="noopener noreferrer"
            class="flex items-center space-x-2"
        >
            <div class="flex flex-col items-center">
                <svg
                    class="h-6 w-6 fill-white hover:fill-gray-300"
                    aria-hidden="true"
                    viewBox="0 0 16 16"
                    version="1.1"
                >
                    <path
                        fill-rule="evenodd"
                        d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63.06 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2  .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
                    ></path>
                </svg>
            </div>
            <span>jimfunk/goews-rebuilt-openscad</span>
        </a>
    </div>
    <div class="flex flex-col sm:flex-row gap-4">
        <div class="lg:w-1/3 flex flex-col gap-4">
            <!-- Part types -->
            <div class="bg-white rounded-lg shadow p-4">
                <h2 class="text-lg font-semibold mb-2">Part Types</h2>
                <div class="h-48 overflow-y-auto border rounded">
                    <div class="flex flex-col">
                        {#each Object.entries(partDescriptions) as [partType, partDescription]}
                            {#if partType == selectedPartType}
                                <button
                                    class="text-left px-4 py-2 bg-blue-50 border-l-4 border-blue-500"
                                >
                                    {partDescription.name}
                                </button>
                            {:else}
                                <button
                                    class="text-left px-4 py-2 hover:bg-gray-50"
                                    on:click={() => selectPart(partType)}
                                >
                                    {partDescription.name}
                                </button>
                            {/if}
                        {/each}
                    </div>
                </div>
            </div>

            <!-- Parameters -->
            <div class="bg-white rounded-lg shadow p-4">
                <form on:submit|preventDefault={generate} class="space-y-4">
                    {#if errorMessage}
                        <div
                            class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative"
                            role="alert"
                        >
                            <span class="block sm:inline">{errorMessage}</span>
                        </div>
                    {/if}

                    {#each partDescriptions[selectedPartType].parameters as parameter}
                        <!-- <div>
                            <label
                                for={parameter.field}
                                class="block text-gray-700 text-sm font-bold mb-2"
                            >
                                {parameter.name}
                            </label>
                            <p class="text-gray-500 text-sm mb-1">
                                {parameter.description}
                            </p> -->

                        {#if parameter.type === "number"}
                            <NumberParameter
                                {parameter}
                                bind:value={parameters[parameter.field]}
                            />
                        {:else if parameter.type === "select"}
                            <SelectParameter
                                {parameter}
                                bind:value={parameters[parameter.field]}
                            />
                        {:else if parameter.type === "boolean"}
                            <BooleanParameter
                                {parameter}
                                bind:value={parameters[parameter.field]}
                            />
                        {:else if parameter.type === "skip_list"}
                            <SkipListParameter
                                {parameter}
                                bind:value={parameters[parameter.field]}
                            />
                        {/if}
                        <!-- </div> -->
                    {/each}

                    <div class="flex gap-2">
                        <button
                            type="button"
                            on:click={resetParameters}
                            class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                        >
                            Reset
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            class="flex-1 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline disabled:opacity-50"
                        >
                            {loading ? "Generating..." : "Generate"}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Viewer -->
        <div class="lg:w-2/3 bg-white rounded-lg shadow p-4">
            <div
                class="h-[500px] bg-gray-50 rounded flex items-center justify-center"
            >
                {#if stlUrl}
                    <Canvas key={stlUrl}>
                        <STLViewer model={stlUrl} />
                    </Canvas>
                {:else}
                    <div class="text-gray-400 text-center">
                        <svg
                            class="w-12 h-12 mx-auto mb-2"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                            />
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                            />
                        </svg>
                        <p>Click Generate to preview the model</p>
                    </div>
                {/if}
            </div>
            {#if stlUrl}
                <button
                    on:click={download}
                    class="mt-4 bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                >
                    Download
                </button>
            {/if}
        </div>
    </div>
</main>
