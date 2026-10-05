<template>
	<v-dialog v-model="vueData.isOpenModalEditProfile" max-width="600">
		<v-card>
			<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
				Cập nhật tên tiếng Anh
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" variant="text" size="small" @click="onCloseModalEditProfile"></v-btn>
			</v-card-title>
			<v-card-text class="px-3 py-1">
				<v-form>
					<v-row dense>
						<v-col cols="12" sm="6">
							<v-text-field v-model="vueData.StudentProfile.HocSinhID" label="Mã học sinh" variant="outlined" density="compact" hide-details disabled />
						</v-col>
						<v-col cols="12" sm="6">
							<v-text-field v-model="vueData.StudentProfile.HoTen" label="Họ tên học sinh" variant="outlined" density="compact" hide-details disabled />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="vueData.StudentProfile.EnglishName" label="Tên tiếng Anh" variant="outlined" density="compact" hide-details autofocus />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions class="pa-3">
				<v-spacer></v-spacer>
				<v-btn color="primary" elevation="0" @click="onSave">Cập nhật</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: [],
		data() {
			return { vueData }
		},
		methods: {
			onCloseModalEditProfile() {
				vueData.StudentProfile = {}
				vueData.isOpenModalEditProfile = false
			},
			onSave() {
				const $this = this
				confirm({
					title: "Xác nhận cập nhật tên tiếng anh cho học sinh " + vueData.StudentProfile.HoTen,
					action: function () {
						ajaxCALL('/lms/HocSinh_Upd', {
							HocSinhID: vueData.StudentProfile.HocSinhID,
							Ho: vueData.StudentProfile.Ho,
							Ten: vueData.StudentProfile.Ten,
							NgaySinh: vueData.StudentProfile.NgaySinh,
							Nu: vueData.StudentProfile.Nu,
							TinhTrang: vueData.StudentProfile.TinhTrangQLHS,
							EnglishName: vueData.StudentProfile.EnglishName,
						}, res => {
							Vue.$toast.success("Cập nhật tên tiếng anh học sinh thành công!", { position: "top" })
							$this.onCloseModalEditProfile()
							$this.$emit('refresh')
						})
					},
					cancel: function () {
						$this.onCloseModalEditProfile()
					},
				})
			}
		},
	}
</script>