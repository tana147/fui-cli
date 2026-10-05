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
							<v-text-field v-model="editableForm.FormCode" label="Mã Form (ví dụ: BAI_BAO)"
								:rules="[rules.required]" required autofocus />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="editableForm.FormTitle" label="Tên Form (hiển thị)"
								:rules="[rules.required]" required />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model.number="editableForm.SortOrder" label="Thứ tự hiển thị" type="number"
								:rules="[rules.required]" required />
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
				editableForm: {},
				isLoading: false,
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
				},
			};
		},
		computed: {
			getTitle() {
				return vueData.isAddNew == true ? "Thêm mới nhiệm vụ khoa học" : "Chỉnh sửa nhiệm vụ khoa học"
			},
			getButtonLabel() {
				return vueData.isAddNew == true ? "Thêm mới" : "Lưu"
			},
			getSuccesMessage() {
				return vueData.isAddNew == true ? "Thêm mới thành công" : "Lưu thành công"
			}
		},
		watch: {
			'vueData.isShowDialog'(newVal) {
				if (newVal) {
					this.editableForm = JSON.parse(JSON.stringify(vueData.selectedForm ?? {}));
				}
			}
	
		},
		mounted() {
		},
	
		methods: {
			closeDialog() {
				vueData.isShowDialog = false;
				vueData.selectedForm = null
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
					const params = { ...this.editableForm };
					await ajaxCALL('/HDKH_Form_Save', params, res => {
						Vue.$toast.success(`${this.getSuccesMessage}`, { position: "top" });
					});
					await this.closeDialog()
					await CALL("getDSForms")
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