<template>
	<div>
		<v-text-field color="success" outlined dense v-model="item.Text_Content" :hint="item.Data_Exp" />
	</div>
</template>

<script>
	export default {
		name: "uc-text",
		props: {
			item: { type: Object, default: () => ({}) },
			textRules: { type: Array, default: () => [] }
		},
		data() {
			return {}
		},
		computed: {},
		watch: {},
		methods: {},
	}
</script>