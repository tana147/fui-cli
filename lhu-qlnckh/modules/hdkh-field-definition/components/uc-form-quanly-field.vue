<template>
	<v-dialog v-model="vueData.isShowDialog" max-width="800px">
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
						<v-col cols="12" md="6">
							<v-text-field v-model="editableField.FieldLabel" label="Tên hiển thị (Label)"
								:rules="[rules.required]" required autofocus />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="editableField.FieldName"
								label="Tên biến (Name, không dấu, không khoảng trắng)" :rules="[rules.required]"
								required />
						</v-col>
						<v-col cols="12" md="6">
							<v-select v-model="editableField.FieldType" label="Loại trường" :items="fieldTypeItems"
								:rules="[rules.required]" required />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="editableField.FieldGroup" label="Nhóm (để gom layout)" />
						</v-col>
						<v-col cols="12" v-if="editableField.FieldType === 'SELECT'">
							<v-text-field v-model="editableField.DataSource"
								label="Nguồn dữ liệu (Tên API hoặc Bảng)" />
						</v-col>
						<v-col cols="12" md="4">
							<v-text-field v-model.number="editableField.SortOrder" label="Thứ tự" type="number" />
						</v-col>
						<v-col cols="12" md="4">
							<v-checkbox v-model="editableField.IsRequired" label="Bắt buộc nhập" />
						</v-col>
						<v-col cols="12" md="4">
							<v-checkbox v-model="editableField.IsUsedForRule" label="Dùng cho quy tắc tính điểm" />
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
				editableField: {},
				isLoading: false,
				fieldTypeItems: ['TEXT', 'TEXTAREA', 'NUMBER', 'SELECT', 'CHECKBOX', 'DATE'],
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
				},
			};
		},
		computed: {
			getTitle() {
				return vueData.isAddNew == true ? "Thêm mới trường dữ liệu" : "Chỉnh sửa trường dữ liệu"
			},
			getButtonLabel() {
				return vueData.isAddNew == true ? "Thêm mới" : "Lưu"
			},
			getSuccessMessage() {
				return vueData.isAddNew == true ? "Thêm mới thành công" : "Lưu thành công"
			}
		},
		watch: {
			'vueData.isShowDialog'(newVal) {
				if (newVal) {
					this.editableField = JSON.parse(JSON.stringify(vueData.selectedField ?? {}));
				}
			}
		},
		methods: {
			closeDialog() {
				vueData.isShowDialog = false;
				vueData.selectedField = null
				this.$refs.form.reset()
				this.$refs.form.resetValidation()
			},
			async buttonClick() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) return;
				this.isLoading = true;
				try {
					// Tham số cho API spAPI_HDKH_Field_Save
					const params = {
						"FormID": this.vueData.formID ?? 0,
						"FieldID": this.editableField.FieldID ?? 0,
						"FieldName": this.editableField.FieldName ?? 0,
						"FieldLabel": this.editableField.FieldLabel ?? 0,
						"FieldType": this.editableField.FieldType ?? 0,
						"FieldGroup": this.editableField.FieldGroup ?? 0,
						"DataSource": this.editableField.DataSource ?? null,
						"SortOrder": this.editableField.SortOrder ?? 0,
						"IsRequired": this.editableField.IsRequired ?? 0,
						"IsUsedForRule": this.editableField.IsUsedForRule ?? 0
					}
					await ajaxCALL('/HDKH_Field_Save', params, res => {
						Vue.$toast.success(`${this.getSuccessMessage}`, { position: "top" });
					});
					await this.closeDialog()
					await CALL("getDSFields")
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