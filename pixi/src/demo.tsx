import { Application, Assets, BlurFilter } from 'pixi.js';
import { Stage, Container, Sprite, useTick } from '@pixi/react';
import { useMemo, useReducer, useRef } from 'react';
import { Spine } from 'pixi-spine';

const reducer = (_: any, { data }: any) => data;
const Bunny = () => {
    const [motion, update] = useReducer(reducer, {});
    const iter = useRef(0);

    useTick((delta) => {
        const i = (iter.current += 0.05 * delta);

        update({
            type: 'update',
            data: {
                x: Math.sin(i) * 100,
                y: Math.sin(i / 1.5) * 100,
                rotation: Math.sin(i) * Math.PI,
                anchor: Math.sin(i / 2),
            },
        });
    });

    return (
        <Sprite
            image="https://pixijs.io/pixi-react/img/bunny.png"
            {...motion}
        />
    );
};

export const Demo = () => {
    return (
        <Stage
            options={{
                backgroundColor: 'white',
            }}
        >
            <Container x={400} y={330}>
                <Bunny />
            </Container>
        </Stage>
    );
};

const app = new Application();
// @ts-ignore
document.body.appendChild(app.view);

Assets.load('/assets/mix-and-match-pro/mix-and-match-pro.skel').then(
    (resource) => {
        console.log(resource);
        const animation = new Spine(resource.spineData);

        animation.skeleton.setSkinByName('full-skins/girl');

        animation.x = app.screen.width / 2;
        animation.y = app.screen.height;

        // add the animation to the scene and render...
        app.stage.addChild(animation);

        if (animation.state.hasAnimation('idle')) {
            // run forever, little boy!
            animation.state.setAnimation(0, 'idle', true);
            // dont run too fast
            animation.state.timeScale = 0.1;
            // update yourself
            animation.autoUpdate = true;
        }
    }
);
