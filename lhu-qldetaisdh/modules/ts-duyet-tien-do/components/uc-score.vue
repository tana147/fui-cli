<template>
	<div>
		<v-text-field class="uc-ar-score-field mb-3 mt-1" color="success" outlined dense v-model="item.Text_Content"
			:hint="item.Data_Exp" hide-details />
	</div>
</template>

<script>
	export default {
		name: "uc-score",
		props: {
			item: { type: Object, default: () => ({}) }
		},
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>