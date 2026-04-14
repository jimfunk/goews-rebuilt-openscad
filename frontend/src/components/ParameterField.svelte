<script>
  import ParameterForm from './ParameterForm.svelte';
  import BooleanParameter from '../parameters/BooleanParameter.svelte';
  import NumberParameter from '../parameters/NumberParameter.svelte';
  import SelectParameter from '../parameters/SelectParameter.svelte';
  import SkipListParameter from '../parameters/SkipListParameter.svelte';
  import MountHoleListParameter from '../parameters/MountHoleListParameter.svelte';

  let { field = {}, parameters, fieldName } = $props();

  function getComponent(field) {
    if (field?.enum) {
      return SelectParameter;
    }
    if (field.type === 'boolean') {
      return BooleanParameter;
    }
    if (field.type === 'number' || field.type === 'integer') {
      return NumberParameter;
    }
    if (field.type === 'array' && field.items) {
      const items = field.items;
      if (items.type === 'array') {
        return SkipListParameter;
      }
      if (items.type === 'object' && items.properties) {
        const props = Object.keys(items.properties);
        if (props.includes('hole_type') && props.includes('x_offset')) {
          return MountHoleListParameter;
        }
        return ParameterForm;
      }
    }
    if (field.type === 'object' && field.properties) {
      return ParameterForm;
    }
    return NumberParameter;
  }

  let Component = $derived(getComponent(field));
</script>

<div class="parameter-field">
  {#if Component}
    <Component {field} {parameters} {fieldName} />
  {/if}
</div>

<style>
  .parameter-field {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
</style>
