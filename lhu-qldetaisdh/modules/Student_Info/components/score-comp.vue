<template>
	<div>
		<v-text-field class="scoreField mb-3 mt-1" color="success" outlined dense v-model="ItemDes.Text_Content"
			:hint="ItemDes.Data_Exp" hide-details reverse :disabled="ItemDes.IsOldProc"></v-text-field>
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
			ItemDes: function () {
				return this.itemdes
			}
		},
		watch: {},
		methods: {},
	}
</script>