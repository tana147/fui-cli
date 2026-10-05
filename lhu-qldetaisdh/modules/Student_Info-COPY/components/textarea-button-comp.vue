<template>
	<div>
		<v-textarea v-model="ItemDes.Text_Content" outlined name="input-7-1" dense rows="1" color="green" flat="false"
			auto-grow :hint="ItemDes.Data_Exp" :disabled="ItemDes.IsOldProc"></v-textarea>
	</div>
</template>

<script>
	export default {
		props: ["itemdes", "lock"],
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