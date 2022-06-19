<script setup lang="ts">
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://vuejs.org/api/sfc-script-setup.html#script-setup
import HelloWorld from './components/HelloWorld.vue';
import * as PIXI from 'pixi.js';
import { onMounted, onUnmounted } from 'vue';

let app = new PIXI.Application({
    width: 500,
    height: 500,
    backgroundColor: 0,
});

let sprite = PIXI.Sprite.from('src/assets/logo.png');
app.stage.addChild(sprite);
sprite.x = app.renderer.width / 2;
sprite.y = app.renderer.height / 2;
app.ticker.add((delta) => {
    sprite.rotation += 0.1 * delta;
});

onMounted(() => {
    document.getElementById('app')?.appendChild(app.view);
});
</script>

<template>
    <img alt="Vue logo" src="./assets/logo.png" />
    <HelloWorld msg="Hello Vue 3 + TypeScript + Vite" />
    <div id="app"></div>
</template>

<style>
#app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
}
</style>
