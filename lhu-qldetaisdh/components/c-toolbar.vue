<template>
	<v-card-title>
		<slot name="title"> </slot>
		<v-spacer></v-spacer>
		<v-icon @click="(e) => $emit('onClose', e)">mdi-close</v-icon>
	</v-card-title>
</template>

<script>
	export default {
		props: {
			onClose: {
				type: Function,
				require: true
			},
		},
		data() { },
		mounted() { },
		computed: {},
		watch: {},
		methods: {
	
		},
	}
</script>