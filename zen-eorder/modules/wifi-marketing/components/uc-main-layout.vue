<template>
	<v-carousel hide-delimiters height="100dvh" :show-arrows="true" cycle interval="5000">
		<template v-slot:prev="{ props }">
			<v-btn color="white" @click="props.onClick" size="x-small" variant="tonal" icon="mdi-chevron-left"></v-btn>
		</template>
		<template v-slot:next="{ props }">
			<v-btn color="white" variant="tonal" @click="props.onClick" size="x-small" icon="mdi-chevron-right"></v-btn>
		</template>
		<v-carousel-item  v-for="(bg, index) in dsIamge" :key="index + 1">
			<div style="
						background-size: cover;
						background-position: center;
						background-repeat: no-repeat;
						width: 100vw;
						height: 100vh;
				" :style="{ 'background-image': bg }">
			</div>
		</v-carousel-item>
	</v-carousel>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				dsIamge: [
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_1.jpg')",
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_2.jpg')",
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_3.jpg')",
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_4.jpg')",
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_5.jpg')",
					"url('https://eorder.zenfoodcourt.vn/_cdn/zen-eorder/wifi-marketing/ZEN_Tea_6.jpg')"
				]
	
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>