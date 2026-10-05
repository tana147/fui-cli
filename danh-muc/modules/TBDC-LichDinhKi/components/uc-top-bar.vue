<template>
	<v-app-bar density="compact" :elevation="0" title="Quản lý lịch định kì">
		<template v-slot:append>
			<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onAddNew">Thêm
				mới</v-btn>
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
		}
	}

}
</script>