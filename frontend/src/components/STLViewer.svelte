<script>
  import { STLLoader } from 'three/examples/jsm/loaders/STLLoader';
  import { Box3, Vector3, MeshStandardMaterial } from 'three';
  import { T } from '@threlte/core';
  import { OrbitControls, Resize, Align } from '@threlte/extras';
  import { writable } from 'svelte/store';

  let { model = null, color = 'cornflowerblue', models = null } = $props();

  const meshesStore = writable([]);

  $effect(() => {
    const previewModels = models || (model ? [{ model, color }] : []);

    if (previewModels.length === 0) {
      meshesStore.set([]);
      return;
    }

    const loader = new STLLoader();
    let cancelled = false;

    async function loadModel(previewModel) {
      return await new Promise((resolve, reject) => {
        loader.load(
          previewModel.model,
          (geometry) => {
            resolve({
              geometry,
              material: new MeshStandardMaterial({
                color: previewModel.color || 'cornflowerblue',
              }),
            });
          },
          undefined,
          reject
        );
      });
    }

    Promise.all(previewModels.map(loadModel))
      .then((loadedMeshes) => {
        if (cancelled) return;

        const bounds = new Box3();

        for (const mesh of loadedMeshes) {
          mesh.geometry.computeBoundingBox();
          bounds.union(mesh.geometry.boundingBox);
        }

        const center = new Vector3();
        bounds.getCenter(center);

        for (const mesh of loadedMeshes) {
          mesh.geometry.translate(-center.x, -center.y, -center.z);
          mesh.geometry.computeVertexNormals();
        }

        meshesStore.set(loadedMeshes);
      })
      .catch((error) => {
        if (!cancelled) {
          console.error('Failed to load STL:', error);
          meshesStore.set([]);
        }
      });

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

{#if $meshesStore.length > 0}
  <T.Group scale={7}>
    <Resize>
      <Align auto>
        {#each $meshesStore as mesh}
          <T.Mesh geometry={mesh.geometry} material={mesh.material} />
        {/each}
      </Align>
    </Resize>
  </T.Group>
{/if}
