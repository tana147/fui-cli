<template>
	<v-dialog v-model="isShow" width="1200">
		<v-card rounded="lg">
			<v-toolbar>
				<v-toolbar-title class="text-primary">Tạo mới phiếu xuất</v-toolbar-title>

				<v-btn icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<uc-stepper-phieu-xuat :DSNhanVien="DSNhanVien" :DSDiaDiem="DSDiaDiem" :closeDialog="closeDialog"
				:loadDSPhieuXuat="loadDSPhieuXuat"></uc-stepper-phieu-xuat>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		loadDSPhieuXuat: Function,
		DSNhanVien: Array,
		DSDiaDiem: Array,
	},
	emits: ['update:isShow'],
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
		},
	},
}
</script>