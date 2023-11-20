import { BlurFilter } from 'pixi.js';
import { Stage, Container, Sprite, useTick } from '@pixi/react';
import { useMemo, useReducer, useRef } from 'react';

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
