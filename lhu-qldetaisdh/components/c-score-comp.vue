<template>
	<v-text-field class="mb-3 mt-1" style="width: 55px;" color="success" outlined dense v-model="itemDes.Text_Content"
		:hint="itemDes.Data_Exp" hide-details :disabled="itemDes.User_Input !== 'HV'" reverse></v-text-field>
</template>

<script>
	export default {
		name: "c-score-comp",
		props: {
			itemDes: { type: Object, default: () => ({}) }
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