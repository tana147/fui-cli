<template>
	<v-app-bar density="compact" :elevation="0" title="Quản lý TS - TBDC - CCDC">
		<template v-slot:append>
			<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onAddNew">Thêm
				mới</v-btn>
			<v-btn color="primary" prepend-icon="mdi-file-excel-outline" variant="flat" @click="onExport">
				Xuất excel
			</v-btn>
		</template>
	</v-app-bar>
</template>

<script>
export default {

	props: {
	},

	data() {
		return {
		}
	},

	mounted() {
	},
	computed: {
	},

	watch: {
	},

	methods: {
		onAddNew() {
			this.$emit('add-new-emit')
		},
		onMoveCategory() {
			this.$emit('move-category-emit')
		},
		onExport() {
			this.$emit('export-execl-emit')
		}
	}

}
</script>