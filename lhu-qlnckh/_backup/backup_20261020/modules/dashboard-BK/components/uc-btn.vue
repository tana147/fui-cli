<template>
	<v-btn fab small :color="vueData.mode ? 'white' : 'primary'" @click="(e)=>$emit('click', e)">
		<v-icon medium :color="vueData.mode ? 'black' : 'white'">{{icon ?? 'mdi-help'}}</v-icon>
	</v-btn>
</template>

<script>
	export default {
		props: ["icon", "click"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>