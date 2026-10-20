<template>
	<v-textarea v-model="ItemDes.Text_Content" outlined name="input-7-1" dense hide-details rows="1" color="green" flat="false"
		auto-grow :hint="ItemDes.Data_Exp" :disabled="lock === 0"></v-textarea>
</template>

<script>
	export default {
		props: ["itemdes", "textRules", "lock"],
		data() {
			return {}
		},
		computed: {
			ItemDes: function () {
				return this.itemdes
			}
		},
		watch: {},
		methods: {},
	}
</script>