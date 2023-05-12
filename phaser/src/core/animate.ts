class AnimateNode {
    private name: string;
    private next: AnimateNode[] | undefined;
    constructor(name: string, next?: AnimateNode[]) {
        this.name = name;
        this.next = next || [];
    }
    public addNext(node: AnimateNode): AnimateNode {
        this.next?.push(node);
        return node;
    }
}

// 急停
const stop = new AnimateNode('stop');
// 跑
const running = new AnimateNode('running');
// 闪避
const dodge = new AnimateNode('dodge');
// 翻滚
const roll = new AnimateNode('roll');
// 走
const walk = new AnimateNode('walk');
// 待机
const idle = new AnimateNode('idle');
// 振刀
const swing = new AnimateNode('swing');
// 振刀终结
const swingEnd = new AnimateNode('swingEnd');
// 普通攻击
const attack = new AnimateNode('attack');
// 蓄力
const charge = new AnimateNode('charge');
// 收刀
const sheath = new AnimateNode('sheath');
// 僵直
const stiff = new AnimateNode('stiff');
// 被击飞
const hitFly = new AnimateNode('hitFly');
// 倒地
const fall = new AnimateNode('fall');
// 起身
const getUp = new AnimateNode('getUp');
// 出钩子
const hook = new AnimateNode('hook');
// 收钩子
const hookBack = new AnimateNode('hookBack');
// 被钩子拉
const hookPull = new AnimateNode('hookPull');
// 钩索飞行
const hookFly = new AnimateNode('hookFly');
// 钩索撞击
const hookHit = new AnimateNode('hookHit');
// 飞袭
const dive = new AnimateNode('dive');
// 蹲下
const squat = new AnimateNode('squat');
// 升龙
const dragon = new AnimateNode('dragon');
// 蹲下普通攻击
const squatAttack = new AnimateNode('squatAttack');
// 滑铲
const slide = new AnimateNode('slide');

// 待机->走->闪避->跑->急停
//           |-->翻滚
slide.addNext(idle).addNext(walk).addNext(dodge).addNext(running).addNext(stop);
dodge.addNext(roll);

export {};
