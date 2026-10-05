<template>
	<v-card dark min-width="100px" :class="['pa-4 d-flex align-center  rounded-lg', bgclass]" class="border">
		<div class="d-flex flex-column justify-center w-100">
			<div :style="'color: ' + colortitle" class="text-subtitle-2 text-left">
				{{ title }}
			</div>
			<div class="text-h5 font-weight-bold text-center">
				{{ value }}
			</div>
		</div>
		<v-spacer v-if="icon"></v-spacer>
		<v-avatar v-if="icon" :color="bgicon">
			<v-icon :color="coloricon">{{ icon }}</v-icon>
		</v-avatar>
	</v-card>
</template>

<script>
export default {
	props: [
		"title",
		"value",
		"icon",
		"coloricon",
		"colortitle",
		"bgicon",
		"bgclass"
	],
	data() {
		return {}
	},
	mounted() { },
	computed: {},
	watch: {},
	methods: {
	},
}
</script>