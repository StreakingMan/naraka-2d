import * as Phaser from 'phaser';
import {
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
const scale = 1;
const speed = 2;
let cursors: CursorKeys;
const preload: ScenePreloadCallback = function () {
    this.load.spineBinary('hero-data', 'assets/hero/hero-pro.skel');
    this.load.spineAtlas('hero-atlas', 'assets/hero/hero-pro.atlas');
};

let hero: SpineGameObject;

const create: SceneCreateCallback = function () {
    hero = this.add.spine(width / 2, height / 2, 'hero-data', 'hero-atlas');

    console.log(hero);

    // 物理
    this.matter.world.setBounds(0, 0, width, height);
    this.matter.add.gameObject(hero, {
        friction: 0,
    });
    this.matter.add.polygon(width / 3, 0, 6, 40);

    // hero.setScale(scale);
    hero.phaserWorldCoordinatesToSkeleton({
        x: 800,
        y: 100,
    });
    hero.animationState.setAnimation(0, 'idle', true);

    hero.skeleton.setToSetupPose();

    // 键盘
    if (this.input.keyboard) cursors = this.input.keyboard.createCursorKeys();
};

const idle = () => {
    if (hero.state === 'idle') return;
    hero.state = 'idle';
    hero.animationState.setAnimation(0, 'idle', true);
};

const update: SceneUpdateCallback = function () {
    if (!cursors) {
        return;
    }
    if (cursors.space.isDown) {
        console.log('space');
        if (hero.state === 'jump') return;
        hero.state = 'jump';
        this.matter.setVelocityY(hero, -speed * 6);
        hero.animationState.setAnimation(0, 'jump', true);
    } else if (cursors.down.isDown) {
        console.log('down');
        if (hero.state === 'crouch') return;
        hero.state = 'crouch';
        hero.animationState.setAnimation(0, 'crouch', true);
    } else if (cursors.left.isDown) {
        console.log('left');
        if (hero.state !== 'left') {
            hero.animationState.setAnimation(0, 'walk', true);
        }
        hero.state = 'left';
        this.matter.setVelocityX(hero, -speed);
        hero.scaleX = -scale;
    } else if (cursors.right.isDown) {
        console.log('right');
        if (hero.state !== 'right') {
            hero.animationState.setAnimation(0, 'walk', true);
        }
        hero.state = 'right';
        this.matter.setVelocityX(hero, speed);
        hero.scaleX = scale;
    } else {
        idle();
        // this.matter.setVelocity(hero, 0, 0);
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
        default: 'matter',
        matter: {
            debug: {
                showBody: true,
                showBounds: true,
                showAxes: true,
                showCollisions: true,
                showPositions: true,
                showStaticBody: true,
                showVelocity: true,
            },
            gravity: { y: 1 },
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
