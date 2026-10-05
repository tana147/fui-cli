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
					radius: 0.84,
					itemLabelRadius: 0.93,
					itemLabelRadiusMax: 0.35,
					itemLabelBaselineOffset: -0.07,
					itemBackgroundColors: ["#1b753a", "#6ed08f"],
					lineWidth: 1,
					image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/circle-wheel.png",
					overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/arrow-wheel.png",
					items: [
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-labubu.png",
							imageRadius: 0.52,
							imageScale: 0.2,
						},
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-heart.png",
							imageRadius: 0.5,
							imageScale: 0.2,
						},
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-heart.png",
							imageRadius: 0.5,
							imageScale: 0.2,
						},
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-heart.png",
							imageRadius: 0.5,
							imageScale: 0.2,
						},
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-heart.png",
							imageRadius: 0.5,
							imageScale: 0.2,
						},
						{
							image: "https://cdn.zentea.vn/filedata/zen-eorder/labubu/item-wheel-heart.png",
							imageRadius: 0.5,
							imageScale: 0.2,
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
				$this.wheel.spinToItem(item, 7000, true, 10)
			},
		},
	}
</script>