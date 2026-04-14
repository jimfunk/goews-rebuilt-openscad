<script>
  import { writable } from 'svelte/store';
  import { onMount } from 'svelte';

  let { selectedPartId = $bindable(), parts = {}, onChange = () => {}, searchQuery = '' } = $props();

  // Define part categories and their members
  const categories = [
    {
      id: 'tiles',
      name: 'Tiles',
      parts: ['tile', 'grid-tile'],
    },
    {
      id: 'shelves',
      name: 'Shelves',
      parts: ['shelf', 'hole_shelf', 'slot_shelf', 'gridfinity_shelf'],
    },
    {
      id: 'accessories',
      name: 'Accessories',
      parts: ['bin', 'gridfinity_bin', 'cup', 'rack', 'hook', 'bolt', 'mount', 'cableclip'],
    },
  ];

  // Custom display names for parts
  const partDisplayNames = {
    tile: 'Standard Tile',
    shelf: 'Simple Shelf',
    mount: 'Hanger Mount',
    cableclip: 'Cable Clip',
    gridfinity_bin: 'Gridfinity Bin',
  };

  // Track expanded categories using a store for proper reactivity
  const expandedCategoriesStore = writable({
    tiles: false,
    shelves: false,
    accessories: false,
  });

  // Expand category containing selected part
  function expandSelectedCategory() {
    if (!selectedPartId || !Object.keys(parts).length) return;
    const newExpanded = {};
    categories.forEach((cat) => {
      newExpanded[cat.id] = cat.parts.includes(selectedPartId);
    });
    expandedCategoriesStore.set(newExpanded);
  }

  // Expand categories matching search query
  function expandMatchingCategories(query) {
    const newExpanded = {};
    categories.forEach((cat) => {
      const hasMatch = cat.parts.some((partId) => {
        const part = parts[partId];
        return (
          part?.name?.toLowerCase().includes(query) ||
          part?.description?.toLowerCase().includes(query)
        );
      });
      newExpanded[cat.id] = hasMatch;
    });
    expandedCategoriesStore.set(newExpanded);
  }

  function toggleCategory(categoryId) {
    expandedCategoriesStore.update((expanded) => ({
      ...expanded,
      [categoryId]: !expanded[categoryId],
    }));
  }

  // Initialize expansion when parts are loaded
  $effect(() => {
    if (Object.keys(parts).length > 0 && selectedPartId && !searchQuery) {
      expandSelectedCategory();
    }
  });

  function selectPart(partId) {
    onChange(partId);
  }

  function matchesSearch(partId) {
    if (!searchQuery.trim()) return true;
    const query = searchQuery.toLowerCase();
    const part = parts[partId];
    const displayName = partDisplayNames[partId];
    return (
      displayName?.toLowerCase().includes(query) ||
      part?.name?.toLowerCase().includes(query) ||
      part?.description?.toLowerCase().includes(query)
    );
  }

  function categoryHasMatches(category) {
    return category.parts.some((partId) => matchesSearch(partId));
  }
</script>

<div class="part-tree-selector">
  <div class="search-box">
    <input
      type="text"
      bind:value={searchQuery}
      on:input={() => {
        if (Object.keys(parts).length === 0) return;
        if (searchQuery.length > 0) {
          expandMatchingCategories(searchQuery.toLowerCase());
        }
        // Note: We don't auto-collapse when search is cleared to avoid Svelte reactivity issues
        // Users can manually collapse categories by clicking on them
      }}
      placeholder="Search parts..."
      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    />
  </div>

  <div class="categories">
    {#each categories as category (category.id)}
      {#if searchQuery.trim() === '' || categoryHasMatches(category)}
        <div class="category">
          <button
            type="button"
            class="category-header"
            on:click={() => toggleCategory(category.id)}
          >
            <span class="category-name">{category.name}</span>
            <span class="category-icon">
              {#if $expandedCategoriesStore[category.id]}
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              {:else}
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              {/if}
            </span>
          </button>

          {#if $expandedCategoriesStore[category.id]}
            <div class="category-parts">
              {#each category.parts as partId (partId)}
                {#if matchesSearch(partId)}
                  <button
                    type="button"
                    class="part-item {selectedPartId === partId ? 'selected' : ''}"
                    on:click={() => selectPart(partId)}
                  >
                    <span class="part-name">{partDisplayNames[partId] || parts[partId]?.name}</span>
                  </button>
                {/if}
              {/each}
            </div>
          {/if}
        </div>
      {/if}
    {/each}
  </div>
</div>

<style>
  .part-tree-selector {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .search-box {
    margin-bottom: 0.5rem;
  }

  .categories {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .category {
    border: 1px solid #e5e7eb;
    border-radius: 0.375rem;
    overflow: hidden;
  }

  .category-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    padding: 0.5rem 0.75rem;
    background: #f9fafb;
    border: none;
    cursor: pointer;
    font-weight: 600;
    font-size: 0.875rem;
    color: #374151;
  }

  .category-header:hover {
    background: #f3f4f6;
  }

  .category-icon {
    display: flex;
    align-items: center;
    color: #6b7280;
  }

  .category-parts {
    display: flex;
    flex-direction: column;
    background: white;
  }

  .part-item {
    display: flex;
    align-items: center;
    padding: 0.5rem 0.75rem 0.5rem 1.5rem;
    border: none;
    background: white;
    cursor: pointer;
    text-align: left;
    font-size: 0.875rem;
    color: #374151;
    transition: background-color 0.15s;
  }

  .part-item:hover {
    background: #f3f4f6;
  }

  .part-item.selected {
    background: #dbeafe;
    color: #1d4ed8;
    font-weight: 500;
  }

  .part-name {
    flex: 1;
  }
</style>
