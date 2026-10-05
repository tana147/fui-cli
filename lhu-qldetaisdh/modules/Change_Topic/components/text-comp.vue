<template>
	<div class="mt-2">
		<v-text-field outlined dense color="success" v-model="itemDes.Text_Content" :hint="itemDes.Data_Exp"
			:disabled="itemDes.Task_Detail_Type === 'TEXTVIEW'" />
	</div>
</template>

<script>
	export default {
		props: ["itemdes"],
		data() {
			return {}
		},
		mounted() { },
		computed: {
			itemDes: function () {
				return this.itemdes
			}
		},
		watch: {},
		methods: {},
	}
</script>