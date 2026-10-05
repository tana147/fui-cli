<template>
	<div class="mt-3">
		<v-text-field color="success" v-if="ItemDes.Data_Exp !== null" v-model="ItemDes.Text_Content" outlined
			:hint="ItemDes.Data_Exp" dense >
		<template #message="{ message }">
			<span style="color: red;">{{ message }}</span>
		</template>
		</v-text-field>
		<v-text-field color="success" v-else v-model="ItemDes.Text_Content" outlined hide-details dense />
	</div>
</template>

<script>
	export default {
		props: ["itemdes", "textRules"],
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
		mounted: {},
	}
</script>