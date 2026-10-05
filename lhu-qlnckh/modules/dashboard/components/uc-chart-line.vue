<template>
	<div>
		<f-chart type="line" :data="datachartline" :options="optionchartline"></f-chart>
	</div>
</template>

<script>
	export default {
		props: ["datachartline", "optionchartline"],
		data() {
			return {
	
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>