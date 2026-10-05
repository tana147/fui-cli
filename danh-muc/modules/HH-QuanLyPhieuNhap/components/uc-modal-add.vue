<template>
	<v-dialog v-model="isShow" max-width="1200">
		<v-card rounded="lg">
			<v-toolbar>
				<v-toolbar-title class="text-primary">Tạo mới phiếu nhập</v-toolbar-title>

				<v-btn icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<uc-stepper-phieu-nhap :DSNhanVien="DSNhanVien" :DSNhaCungCap="DSNhaCungCap" :DSDiaDiem="DSDiaDiem"
				:DSDonViTinh="DSDonViTinh" :closeDialog="closeDialog" :loadDSPhieuNhap="loadDSPhieuNhap">
			</uc-stepper-phieu-nhap>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	props: {
		isShow: Boolean,
		loadDSPhieuNhap: Function,
		DSNhanVien: Array,
		DSNhaCungCap: Array,
		DSDiaDiem: Array,
		DSDonViTinh: Array,
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