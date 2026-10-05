<template>
	<div class="container-wheel">
        <div class="lucky-wheel" :style="isShowWheel ? '' : 'display: none'"></div>
    </div>
</template>

<script>
	export default {
		props: ["num"],
    data() {
        return {
            isShowWheel: false,
            wheel: null,
            optionWheel: {
                name: "Workout",
                radius: 0.9,
                borderWidth: 0,
                lineWidth: 0,
                isInteractive: false,
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/arrow-wheel.png",
                items: [
                    {
                        //0: Labubu
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-labubu.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //1: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-0.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //2: TS
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-trasuatranchau.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //3: GL
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-garanphomai.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //4: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-0.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //5: CRAB
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-miengcua.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //6: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-0.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //7: PZ
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-pizza.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //8: BBOX
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-blindbox.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                    {
                        //9: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/item-wheel-0.jpg",
                        imageScale: 0.43,
                        imageRadius: 0.52,
                    },
                ],
            },
        }
    },
    async mounted() {
        const $this = this
        await $this.initLuckyWheel()
        setTimeout(() => {
            $this.onWheel()
        }, 1000)
    },
    computed: {},
    watch: {},
    methods: {
        async initLuckyWheel() {
            const $this = this
            const container = document.querySelector(".lucky-wheel")
            $this.wheel = new spinWheel.Wheel(container, $this.optionWheel)
            setTimeout(() => {
                $this.isShowWheel = true
            }, 200)
        },
        onWheel() {
            const $this = this
            const item = $this.num ?? 1
            $this.wheel.spinToItem(item, 8000, true, 10)
        },
    },
	}
</script>