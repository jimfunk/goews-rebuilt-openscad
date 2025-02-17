<script>
    import { STLLoader } from "three/examples/jsm/loaders/STLLoader";
    import { T, useLoader } from "@threlte/core";
    import { Align, OrbitControls, Resize } from "@threlte/extras";

    export let model;
    let geometry;

    $: {
        if (model) {
            geometry = useLoader(STLLoader).load(model);
        }
    }
</script>

<T.PerspectiveCamera makeDefault position={[0, -7, 7]}>
    <OrbitControls />
</T.PerspectiveCamera>

<T.AmbientLight intensity={0.25} />
<T.DirectionalLight position={[1, 1, 1]} intensity={1} />

{#if $geometry}
    <T.Group scale={7}>
        <Resize>
            <Align auto>
                <T.Mesh geometry={$geometry}>
                    <T.MeshStandardMaterial color="cornflowerblue" />
                </T.Mesh>
            </Align>
        </Resize>
    </T.Group>
{/if}
