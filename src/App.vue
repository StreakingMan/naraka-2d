<script setup lang="ts">
import 'pixi-spine';
import * as PIXI from 'pixi.js';
import { Spine } from 'pixi-spine';
import spineboyPro from './assets/mix-and-match-pro.json?url';
import { onMounted } from 'vue';

onMounted(() => {
    const app = new PIXI.Application();
    document.getElementById('container')!.appendChild(app.view as any);
    // load spine data
    PIXI.Assets.load(spineboyPro).then(onAssetsLoaded);

    function onAssetsLoaded(spineboyAsset) {
        console.log(spineboyAsset);
        app.stage.interactive = true;

        // create a spine boy
        const spineBoyPro = new Spine(spineboyAsset.spineData);

        // set the position
        spineBoyPro.x = app.screen.width / 2;
        spineBoyPro.y = app.screen.height;

        spineBoyPro.scale.set(0.5);

        app.stage.addChild(spineBoyPro);

        window.addEventListener('keydown', (e) => {
            console.log(e.key);
            if (e.key === 'ArrowLeft') {
                spineBoyPro.scale.x = -0.5;
            } else if (e.key === 'ArrowRight') {
                spineBoyPro.scale.x = 0.5;
            }

            if (e.key === 'ArrowUp') {
                spineBoyPro.state.setAnimation(0, 'jump', false);
                spineBoyPro.state.addAnimation(0, 'run', true, 0);
            } else if (e.key === 'ArrowDown') {
                spineBoyPro.state.setAnimation(0, 'death', false);
                spineBoyPro.state.addAnimation(0, 'idle', true, 0);
            }
        });

        spineBoyPro.state.setAnimation(0, 'walk', true);
    }
});
</script>

<template>
    <div id="container" class="h-screen w-screen"></div>
</template>
