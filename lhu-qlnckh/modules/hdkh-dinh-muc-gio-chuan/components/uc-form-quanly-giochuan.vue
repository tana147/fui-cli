<template>
	<v-dialog v-model="vueData.isShowDialog" max-width="600px">
		<v-card elevation="0">
			<v-toolbar dense flat>
				<v-toolbar-title>{{getTitle}}</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-toolbar>
			<v-card-text>
				<v-form ref="form" @submit.prevent="buttonClick">
					<v-row>
						<v-col cols="12">
							<v-text-field v-model="editableGioChuan.TenChucDanh" label="Tên chức danh"
								:rules="[rules.required]" required autofocus />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="editableGioChuan.DinhMucGioChuan" label="Định mức giờ chuẩn"
								type="number" :rules="[rules.required]" required />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="editableGioChuan.GhiChu" label="Ghi chú" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn text color="primary" @click="buttonClick" :loading="isLoading">{{getButtonLabel}}</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		data() {
			return {
				vueData,
				editableGioChuan: {},
				isLoading: false,
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
				},
			};
		},
		computed: {
			getTitle() {
				return vueData.isAddNew == true ? "Thêm mới định mức" : "Chỉnh sửa định mức"
			},
			getButtonLabel() {
				return vueData.isAddNew == true ? "Thêm mới" : "Lưu"
			},
			getSuccessMessage() {
				return vueData.isAddNew == true ? "Thêm mới thông tin định mức thành công" : "Lưu thông tin định mức thành công"
			}
		},
		watch: {
			'vueData.isShowDialog'(newVal) {
				if (newVal) {
					this.editableGioChuan = JSON.parse(JSON.stringify(vueData.selectedItem ?? {
						"ID": 0,
						"TenChucDanh": null,
						"DinhMucGioChuan": null,
						"GhiChu": "",
						"IsActive": 1
					}));
				}
			}
	
		},
		mounted() {
		},
	
		methods: {
			closeDialog() {
				vueData.isShowDialog = false;
				vueData.selectedItem = null
				this.$refs.form.reset()
				this.$refs.form.resetValidation()
			},
			async buttonClick() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					Vue.$toast.error('Vui lòng kiểm tra lại các thông tin đã nhập.', { position: "top" });
					return;
				}
	
				this.isLoading = true;
				try {
					const params = { ...this.editableGioChuan };
					await ajaxCALL('/HDKH_DM_ChucDanhHocVi_Save', params, res => {
						Vue.$toast.success(this.getSuccessMessage, { position: "top" });
					});
					await this.closeDialog()
					await CALL("getDSGioChuan")
				} catch (error) {
					console.log(error)
					Vue.$toast.error(error.message || 'Có lỗi xảy ra, vui lòng thử lại.', { position: "top" });
				} finally {
					this.isLoading = false;
				}
			},
		},
	}
</script>