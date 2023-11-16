import * as Phaser from 'phaser';
import {
    Skin,
    SkinsAndAnimationBoundsProvider,
    SpineGameObject,
    SpinePlugin,
} from '@esotericsoftware/spine-phaser';
import GameConfig = Phaser.Types.Core.GameConfig;
import ScenePreloadCallback = Phaser.Types.Scenes.ScenePreloadCallback;
import SceneCreateCallback = Phaser.Types.Scenes.SceneCreateCallback;
import SceneUpdateCallback = Phaser.Types.Scenes.SceneUpdateCallback;
import CursorKeys = Phaser.Types.Input.Keyboard.CursorKeys;

const width = window.innerWidth;
const height = window.innerHeight * 0.8;
const scale = 0.5;
const speed = 220;
let cursors: CursorKeys;
const preload: ScenePreloadCallback = function () {
    this.load.spineBinary(
        'mix-and-match-data',
        'assets/mix-and-match-pro/mix-and-match-pro.skel'
    );
    this.load.spineAtlas(
        'mix-and-match-atlas',
        'assets/mix-and-match-pro/mix-and-match-pro.atlas'
    );

    this.load.spineBinary(
        'spineboy-pro-data',
        'assets/spineboy-pro/spineboy-pro.skel'
    );
    this.load.spineAtlas(
        'spineboy-pro-atlas',
        'assets/spineboy-pro/spineboy-pro.atlas'
    );
};

let mixAndMatch: SpineGameObject;
let mixAndMatchBody: Phaser.Physics.Arcade.Body;
let spineboy: SpineGameObject;
let spineboyBody: Phaser.Physics.Arcade.Body;
const create: SceneCreateCallback = function () {
    mixAndMatch = this.add.spine(
        width / 2,
        height,
        'mix-and-match-data',
        'mix-and-match-atlas',
        new SkinsAndAnimationBoundsProvider(null, ['full-skins/girl'])
    );
    spineboy = this.add.spine(
        width / 3,
        height,
        'spineboy-pro-data',
        'spineboy-pro-atlas'
    );

    // 物理
    this.physics.add.existing(mixAndMatch);
    mixAndMatchBody = mixAndMatch.body as Phaser.Physics.Arcade.Body;
    mixAndMatchBody.setCollideWorldBounds(true);
    this.physics.add.existing(spineboy);
    spineboyBody = spineboy.body as Phaser.Physics.Arcade.Body;
    spineboyBody.setCollideWorldBounds(true);

    mixAndMatch.setScale(scale);
    mixAndMatch.animationState.setAnimation(0, 'idle', true);
    const skeletonData = mixAndMatch.skeleton.data;
    const skin = new Skin('custom');
    // skin.addSkin(skeletonData.findSkin('skin-base')!);
    // skin.addSkin(skeletonData.findSkin('nose/short')!);
    // skin.addSkin(skeletonData.findSkin('eyelids/girly')!);
    // skin.addSkin(skeletonData.findSkin('eyes/violet')!);
    // skin.addSkin(skeletonData.findSkin('hair/brown')!);
    // skin.addSkin(skeletonData.findSkin('clothes/hoodie-orange')!);
    // skin.addSkin(skeletonData.findSkin('legs/pants-jeans')!);
    // skin.addSkin(skeletonData.findSkin('accessories/bag')!);
    // skin.addSkin(skeletonData.findSkin('accessories/hat-red-yellow')!);
    skin.addSkin(skeletonData.findSkin('full-skins/girl')!);
    mixAndMatch.skeleton.setSkin(skin);
    mixAndMatch.skeleton.setToSetupPose();

    spineboy.setScale(scale);
    spineboy.animationState.setAnimation(0, 'idle', true);
    spineboy.skeleton.setToSetupPose();

    // 键盘
    if (this.input.keyboard) cursors = this.input.keyboard.createCursorKeys();
};

const idle = () => {
    if (mixAndMatch.state === 'idle') return;
    mixAndMatch.state = 'idle';
    mixAndMatch.animationState.setAnimation(0, 'idle', true);
};

const update: SceneUpdateCallback = function () {
    if (!cursors) {
        return;
    }
    if (cursors.space.isDown) {
        console.log('space');
        if (mixAndMatch.state === 'dress-up') return;
        mixAndMatch.state = 'dress-up';
        mixAndMatch.animationState.setAnimation(0, 'dress-up', true);
    } else if (cursors.down.isDown) {
        console.log('down');
        if (mixAndMatch.state === 'dance') return;
        mixAndMatch.state = 'dance';
        mixAndMatch.animationState.setAnimation(0, 'dance', true);
    } else if (cursors.left.isDown) {
        console.log('left');
        if (mixAndMatch.state === 'left') return;
        mixAndMatch.state = 'left';
        mixAndMatch.animationState.setAnimation(0, 'walk', true);
        mixAndMatchBody.setVelocity(-speed, 0);
        mixAndMatch.scaleX = -scale;
        // mixAndMatch.setOrigin(
        //     Math.abs(mixAndMatch.originX) - 1,
        //     mixAndMatch.originY
        // );

        console.log(mixAndMatch.originX);

        // spineboyBody.setVelocity(-speed, 0);
        // spineboy.scaleX = -scale;
    } else if (cursors.right.isDown) {
        console.log('right');
        if (mixAndMatch.state === 'right') return;
        mixAndMatch.state = 'right';
        mixAndMatch.animationState.setAnimation(0, 'walk', true);
        mixAndMatchBody.setVelocity(speed, 0);
        mixAndMatch.scaleX = scale;
        // mixAndMatch.setOrigin(
        //     Math.abs(mixAndMatch.originX),
        //     mixAndMatch.originY
        // );
        console.log(mixAndMatch.originX);

        // spineboyBody.setVelocity(speed, 0);
        // spineboy.scaleX = scale;
    } else {
        idle();

        mixAndMatchBody.setVelocity(0, 0);
        spineboyBody.setVelocity(0, 0);
    }
};

const config: GameConfig = {
    type: Phaser.WEBGL,
    width,
    height,
    backgroundColor: '#fff',
    scene: {
        preload,
        create,
        update,
    },
    physics: {
        default: 'arcade',
        arcade: {
            debug: true,
            gravity: { y: 200 },
        },
    },
    plugins: {
        scene: [
            { key: 'spine.SpinePlugin', plugin: SpinePlugin, mapping: 'spine' },
        ],
    },
};

new Phaser.Game(config);

export {};
