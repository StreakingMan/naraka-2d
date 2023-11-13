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
import SpriteWithDynamicBody = Phaser.Types.Physics.Arcade.SpriteWithDynamicBody;
import CursorKeys = Phaser.Types.Input.Keyboard.CursorKeys;

let player: SpriteWithDynamicBody;
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
};

let mixAndMatch: SpineGameObject;
const create: SceneCreateCallback = function () {
    mixAndMatch = this.add.spine(
        400,
        500,
        'mix-and-match-data',
        'mix-and-match-atlas',
        new SkinsAndAnimationBoundsProvider(null, ['full-skins/girl'])
    );
    mixAndMatch.scale = 0.5;
    mixAndMatch.animationState.setAnimation(0, 'walk', true);
    const skeletonData = mixAndMatch.skeleton.data;
    const skin = new Skin('custom');
    skin.addSkin(skeletonData.findSkin('skin-base') as Skin);
    skin.addSkin(skeletonData.findSkin('nose/short') as Skin);
    skin.addSkin(skeletonData.findSkin('eyelids/girly') as Skin);
    skin.addSkin(skeletonData.findSkin('eyes/violet') as Skin);
    skin.addSkin(skeletonData.findSkin('hair/brown') as Skin);
    skin.addSkin(skeletonData.findSkin('clothes/hoodie-orange') as Skin);
    skin.addSkin(skeletonData.findSkin('legs/pants-jeans') as Skin);
    skin.addSkin(skeletonData.findSkin('accessories/bag') as Skin);
    skin.addSkin(skeletonData.findSkin('accessories/hat-red-yellow') as Skin);
    mixAndMatch.skeleton.setSkin(skin);
    mixAndMatch.skeleton.setToSetupPose();

    // 键盘
    if (this.input.keyboard) cursors = this.input.keyboard.createCursorKeys();
};

const update: SceneUpdateCallback = function () {
    if (!cursors) {
        return;
    }
    if (cursors.space.isDown) {
        console.log('space');
        mixAndMatch.animationState.setAnimation(0, 'dress-up', false);
        mixAndMatch.animationState.addAnimation(0, 'walk', true, 0);
    }
    if (cursors.down.isDown) {
        console.log('down');
        mixAndMatch.animationState.setAnimation(0, 'dance', false);
        mixAndMatch.animationState.addAnimation(0, 'walk', true, 0);
    }
    if (cursors.left.isDown) {
        console.log('left');
        mixAndMatch.animationState.setAnimation(0, 'walk', true);
        mixAndMatch.scaleX = -0.5;
    }
    if (cursors.right.isDown) {
        console.log('right');
        mixAndMatch.animationState.setAnimation(0, 'walk', true);
        mixAndMatch.scaleX = 0.5;
    }
};

const config: GameConfig = {
    type: Phaser.WEBGL,
    width: 800,
    height: 600,
    scene: {
        preload,
        create,
        update,
    },
    plugins: {
        scene: [
            { key: 'spine.SpinePlugin', plugin: SpinePlugin, mapping: 'spine' },
        ],
    },
};

new Phaser.Game(config);

export {};
