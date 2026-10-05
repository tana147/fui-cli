<template>
	<div class="container-wheel">
        <div class="lucky-wheel mb-150" :style="isShowWheel ? '' : 'display: none'"></div>
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
                radius: 0.85,
                borderWidth: 0,
                lineWidth: 0,
                isInteractive: false,
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/arrow-wheel.png",
                items: [
                    {
                        //0: Trà Sữa
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-0-trasua.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //1: Miến Cua
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-1-miengcua.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //2: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-2-no.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //3: Pizza
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-3-pizza.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //4: Blind Box
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-4-blindbox.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //5: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-5-no.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //6: Baby Three
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-6-baby.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //7: NaN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-7-no.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //8: Choco
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-8-choco.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
                    },
                    {
                        //9: Mì tương đen
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/item-wheel-9-mi.png",
                        imageScale: 0.76,
                        imageRadius: 0.46,
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
        }, 1500)
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