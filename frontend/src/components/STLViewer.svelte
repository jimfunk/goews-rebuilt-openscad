<script>
  import { STLLoader } from 'three/examples/jsm/loaders/STLLoader';
  import { T } from '@threlte/core';
  import { OrbitControls, Resize, Align } from '@threlte/extras';
  import { writable } from 'svelte/store';

  let { model } = $props();
  const geometryStore = writable(null);

  $effect(() => {
    if (!model) {
      geometryStore.set(null);
      return;
    }

    const loader = new STLLoader();
    let cancelled = false;

    loader.load(
      model,
      (loadedGeometry) => {
        if (!cancelled) {
          loadedGeometry.center();
          geometryStore.set(loadedGeometry);
        }
      },
      undefined,
      (error) => {
        if (!cancelled) {
          console.error('Failed to load STL:', error);
          geometryStore.set(null);
        }
      }
    );

    return () => {
      cancelled = true;
    };
  });
</script>

<T.PerspectiveCamera makeDefault position={[0, -7, 7]}>
  <OrbitControls />
</T.PerspectiveCamera>

<T.AmbientLight intensity={0.25} />
<T.DirectionalLight position={[1, 1, 1]} intensity={1} />

{#if $geometryStore}
  <T.Group scale={7}>
    <Resize>
      <Align auto>
        <T.Mesh geometry={$geometryStore}>
          <T.MeshStandardMaterial color="cornflowerblue" />
        </T.Mesh>
      </Align>
    </Resize>
  </T.Group>
{/if}
