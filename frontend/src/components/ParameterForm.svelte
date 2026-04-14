<script>
  import ParameterField from './ParameterField.svelte';

  let { schema = {}, parameters = $bindable({}), sectionTitle = '', filterFields = null } = $props();

  let fields = $derived(
    Object.entries(schema?.properties || {})
      .map(([name, props]) => ({
        name,
        ...props,
      }))
      .filter(field => (filterFields ? filterFields(field) : true))
  );
</script>

<div class="parameter-form">
  {#if sectionTitle}
    <h3>{sectionTitle}</h3>
  {/if}

  {#each fields as field, i (field.name)}
    <ParameterField {field} {parameters} fieldName={field.name} />
  {/each}
</div>

<style>
  .parameter-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  h3 {
    margin: 0.5rem 0 0;
    font-size: 1rem;
    font-weight: 600;
    color: #666;
    border-bottom: 1px solid #eee;
    padding-bottom: 0.25rem;
  }
</style>
