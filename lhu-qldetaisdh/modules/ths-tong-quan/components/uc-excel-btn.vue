<template>
	<v-btn class="ml-2 mr-2" icon :color="vueData.mode ? 'white' : 'success'" @click="(e) => $emit('click', e)">
		<v-icon :color="vueData.mode ? 'white' : 'success'">mdi-microsoft-excel</v-icon>
	</v-btn>
</template>

<script>
	export default {
		props: ["click"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>