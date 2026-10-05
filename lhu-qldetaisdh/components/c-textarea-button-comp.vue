<template>
	<v-textarea v-model="itemDes.Text_Content" outlined name="input-7-1" dense hide-details rows="1" color="green"
		flat="false" auto-grow :hint="itemDes.Data_Exp" :disabled="lock === 0"></v-textarea>
</template>

<script>
	export default {
		name: "c-textarea-button-comp",
		props: {
			itemDes: { type: Object, default: () => ({}) },
			textRules: { type: Array, default: () => [] },
			lock: { type: [Number, String], default: 1 }
		},
		data() {
			return {}
		},
		computed: {},
		watch: {},
		methods: {},
	}
</script>