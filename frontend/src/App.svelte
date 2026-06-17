<script>
  import { Canvas } from '@threlte/core';
  import { onMount, onDestroy } from 'svelte';
  import { getOpenAPISchema, extractParts, generateSTL, downloadSTL, generateBlob, downloadBlob, getDefaultValues, generateFilename } from '$lib/api.js';
  import PartTreeSelector from './components/PartTreeSelector.svelte';
  import ParameterForm from './components/ParameterForm.svelte';
  import STLViewer from './components/STLViewer.svelte';
  import GlobalVariantSelector from './components/GlobalVariantSelector.svelte';

  let parts = $state({});
  let selectedPartId = $state(null);
  let parameters = $state({});
  let globalVariant = $state('Original');
  let stlUrl = $state(null);
  let stlBlob = $state(null);
  let previewModels = $state([]);
  let loading = $state(false);
  let errorMessage = $state(null);
  let initialized = $state(false);
  let lastGeneratedPartId = $state(null);
  let generatedParameters = $state({});
  let generatedFilename = $state(null);

  let previewObjectUrls = new Set();

  let isDirty = $derived(initialized && JSON.stringify(parameters) !== JSON.stringify(generatedParameters));
  let currentPart = $derived(selectedPartId ? parts[selectedPartId] : null);
  let previewKey = $derived(previewModels.map((previewModel) => previewModel.model).join('|'));

  onMount(async () => {
    // Load saved variant from localStorage
    const savedVariant = localStorage.getItem('globalVariant');
    if (savedVariant && ['Original', 'Thicker Cleats'].includes(savedVariant)) {
      globalVariant = savedVariant;
    }

    try {
      const openapi = await getOpenAPISchema();
      parts = extractParts(openapi);
      const partIds = Object.keys(parts);
      if (partIds.length > 0) {
        // Default to tile if available, otherwise first part
        selectedPartId = parts['tile'] ? 'tile' : partIds[0];

        // Try to load saved parameters for this part from localStorage
        const savedParams = localStorage.getItem(`params:${selectedPartId}`);
        if (savedParams) {
          try {
            parameters = JSON.parse(savedParams);
          } catch {
            parameters = getDefaultValues(parts[selectedPartId].schema);
          }
        } else {
          parameters = getDefaultValues(parts[selectedPartId].schema);
        }

        // Apply global variant if the part has variant property
        if (parts[selectedPartId]?.schema?.properties?.variant !== undefined) {
          parameters.variant = globalVariant;
        }

        initialized = true;
      }
    } catch (e) {
      errorMessage = `Failed to load parts: ${e.message}`;
    }
  });

  onDestroy(() => {
    clearPreviewUrls();
  });

  // Save variant to localStorage when it changes
  $effect(() => {
    if (initialized) {
      localStorage.setItem('globalVariant', globalVariant);
    }
  });

  // Save parameters to localStorage when user explicitly generates
  function saveParams() {
    if (selectedPartId && Object.keys(parameters).length > 0) {
      localStorage.setItem(`params:${selectedPartId}`, JSON.stringify(parameters));
    }
  }

  function clearPreviewUrls() {
    for (const url of previewObjectUrls) {
      URL.revokeObjectURL(url);
    }

    previewObjectUrls = new Set();
    stlUrl = null;
    stlBlob = null;
    previewModels = [];
  }

  function createPreviewUrl(blob) {
    const url = URL.createObjectURL(blob);
    previewObjectUrls.add(url);
    return url;
  }

  async function generatePreview(partToGenerate, paramsToGenerate) {
    clearPreviewUrls();

    if (partToGenerate.id === 'tile-stack') {
      const [pla, petg] = await Promise.all([
        generateSTL(partToGenerate.endpoint, {
          ...paramsToGenerate,
          part: 'pla',
        }),
        generateSTL(partToGenerate.endpoint, {
          ...paramsToGenerate,
          part: 'petg',
        }),
      ]);

      const plaUrl = createPreviewUrl(pla.blob);
      const petgUrl = createPreviewUrl(petg.blob);

      previewModels = [
        {
          model: plaUrl,
          color: '#2f5f9e',
          name: 'PLA tiles',
        },
        {
          model: petgUrl,
          color: '#f5b400',
          name: 'PETG spacers',
        },
      ];

      stlBlob = pla.blob;
      stlUrl = plaUrl;

      return {
        filename: pla.filename,
      };
    }

    const { blob, filename } = await generateSTL(partToGenerate.endpoint, paramsToGenerate);
    const url = createPreviewUrl(blob);

    previewModels = [
      {
        model: url,
        color: '#2f5f9e',
        name: partToGenerate.name,
      },
    ];

    stlBlob = blob;
    stlUrl = url;

    return {
      filename,
    };
  }

  // Auto-generate when part selection changes
  $effect(() => {
    if (!initialized || !selectedPartId || selectedPartId === lastGeneratedPartId) return;

    // Only use defaults if we don't have saved parameters
    let newParams;
    const savedParams = localStorage.getItem(`params:${selectedPartId}`);
    if (savedParams) {
      try {
        newParams = JSON.parse(savedParams);
        // Apply global variant if the part has variant property
        if (parts[selectedPartId]?.schema?.properties?.variant !== undefined) {
          newParams.variant = globalVariant;
        }
      } catch {
        newParams = getDefaultValues(parts[selectedPartId].schema);
      }
    } else {
      newParams = getDefaultValues(parts[selectedPartId].schema);
      // Inject global variant if the part has variant property
      if (parts[selectedPartId]?.schema?.properties?.variant !== undefined) {
        newParams.variant = globalVariant;
      }
    }

    generatedFilename = null;
    generatedParameters = {};

    const partToGenerate = parts[selectedPartId];
    if (!partToGenerate) return;

    loading = true;
    errorMessage = null;

    generatePreview(partToGenerate, newParams)
      .then(({ filename }) => {
        generatedFilename = filename;
        generatedParameters = { ...newParams };
        lastGeneratedPartId = selectedPartId;
        parameters = { ...newParams };
      })
      .catch((e) => {
        errorMessage = e.message;
      })
      .finally(() => {
        loading = false;
      });
  });

  async function generate() {
    const partToGenerate = selectedPartId ? parts[selectedPartId] : null;
    if (!partToGenerate) return;

    // Inject global variant if the part has variant property
    const paramsToGenerate = { ...parameters };
    if (partToGenerate.schema?.properties?.variant !== undefined) {
      paramsToGenerate.variant = globalVariant;
    }

    loading = true;
    errorMessage = null;

    try {
      const { filename } = await generatePreview(partToGenerate, paramsToGenerate);
      generatedFilename = filename;
      generatedParameters = { ...paramsToGenerate };
      lastGeneratedPartId = selectedPartId;
      saveParams();
    } catch (e) {
      errorMessage = e.message;
    } finally {
      loading = false;
    }
  }

  async function download() {
    if (!currentPart) return;

    const paramsToDownload = {
      ...generatedParameters,
    };

    if (currentPart.schema?.properties?.variant !== undefined) {
      paramsToDownload.variant = globalVariant;
    }

    if (currentPart.id === 'tile-stack') {
      loading = true;
      errorMessage = null;

      try {
        const { blob, filename } = await generateBlob('/api/tile-stack-bundle', {
          ...paramsToDownload,
          part: 'all',
        });

        downloadBlob(blob, filename || 'tile-stack.zip');
      } catch (e) {
        errorMessage = e.message;
      } finally {
        loading = false;
      }

      return;
    }

    if (!stlBlob) return;

    const filename = generatedFilename || generateFilename(currentPart, generatedParameters);
    downloadSTL(stlBlob, filename);
  }

  function resetParameters() {
    if (!currentPart) return;
    parameters = getDefaultValues(currentPart.schema);
    // Apply global variant if the part has variant property
    if (currentPart.schema?.properties?.variant !== undefined) {
      parameters.variant = globalVariant;
    }
  }
</script>

<svelte:head>
  <title>GOEWS Part Generator</title>
</svelte:head>

<main class="bg-gray-100 min-h-screen">
  <div class="bg-gray-800 text-white p-4 mb-6 flex items-center justify-between">
    <h1 class="text-xl font-bold">GOEWS Part Generator</h1>
    <div class="flex items-center gap-6">
      <a
        href="https://goews.ws"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center space-x-2 hover:text-gray-300"
      >
        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
        <span>goews.ws</span>
      </a>
      <a
        href="https://github.com/jimfunk/goews-rebuilt-openscad"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center space-x-2 hover:text-gray-300"
      >
        <div class="flex flex-col items-center">
          <svg class="h-6 w-6 fill-white hover:fill-gray-300" aria-hidden="true" viewBox="0 0 16 16" version="1.1">
            <path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63.06 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2  .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"></path>
          </svg>
        </div>
        <span>jimfunk/goews-rebuilt-openscad</span>
      </a>
    </div>
  </div>

  <div class="flex flex-col lg:flex-row gap-4 p-4">
    <!-- Parameters Panel -->
    <div class="lg:w-1/3 flex flex-col gap-4">
      {#if errorMessage}
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded" role="alert">
          {errorMessage}
        </div>
      {/if}

      <div class="bg-white rounded-lg shadow p-4">
        <GlobalVariantSelector bind:value={globalVariant} />
      </div>

      <div class="bg-white rounded-lg shadow p-4">
        <PartTreeSelector {selectedPartId} {parts} onChange={(id) => (selectedPartId = id)} />
      </div>

      <div class="bg-white rounded-lg shadow p-4">
        <form on:submit|preventDefault={generate} class="space-y-4">
          <div class="flex gap-2">
            <button
              type="button"
              on:click={resetParameters}
              class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded"
            >
              Reset
            </button>
            <button
              type="submit"
              disabled={loading}
              class="flex-1 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded disabled:opacity-50"
            >
              {loading ? 'Generating...' : 'Generate'}
            </button>
          </div>

          {#if currentPart}
            <ParameterForm
              schema={currentPart.schema}
              bind:parameters
              filterFields={(field) => field.name !== 'variant'}
            />
          {/if}
        </form>
      </div>
    </div>

    <!-- Viewer Panel -->
    <div class="lg:w-2/3 bg-white rounded-lg shadow p-4">
      <div class="h-[500px] bg-gray-50 rounded flex items-center justify-center">
        {#if previewModels.length > 0}
          <Canvas key={previewKey}>
            <STLViewer models={previewModels} />
          </Canvas>
        {:else if loading}
          <div class="text-gray-400 text-center">
            <svg class="w-12 h-12 mx-auto mb-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <p>Generating preview...</p>
          </div>
        {/if}
      </div>
      {#if stlUrl && !isDirty}
        <button
          on:click={download}
          disabled={loading}
          class="mt-4 bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded disabled:opacity-50"
        >
          {currentPart?.id === 'tile-stack' ? 'Download ZIP' : 'Download'}
        </button>
      {/if}
    </div>
  </div>
</main>
