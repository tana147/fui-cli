<template>
	<v-dialog v-model="showDialog" max-width="900px" persistent @close="closeDialog">
		<v-card>
			<v-card-title class="bg-primary" style="position: sticky;top: 0;z-index: 50">{{title || 'default
				title'}}</v-card-title>
			<v-card-text>
				<v-form ref="form" @submit.prevent="saveRule">
					<v-container>
						<v-row>
							<v-col cols="12">
								<v-text-field v-model="editableRule.RuleDescription" label="Mô tả quy tắc"
									hint="Ví dụ: Tác giả chính, bài báo Scopus Q1" autofocus />
							</v-col>
						</v-row>

						<!-- === PHẦN KẾT QUẢ (THEN) === -->
						<v-divider class="my-4"></v-divider>
						<div class="text-h6 mb-2">Kết quả (THEN)</div>
						<v-row>
							<v-col cols="12" md="3">
								<v-text-field v-model.number="editableRule.SoGioQuyDoi_Goc" label="Số giờ chuẩn gốc"
									type="number" :rules="[rules.required]" />
							</v-col>
							<v-col cols="12" md="6">
								<v-select v-model="editableRule.MaQuyTacPhanChia" label="Quy tắc chia giờ"
									:items="DSQuyTacPhanChia" :rules="[rules.required]" item-title="title"
									item-value="value" />
							</v-col>
							<v-col cols="12" md="3">
								<v-text-field v-model.number="editableRule.NamHocApDung" label="Năm học áp dụng"
									type="number" :rules="[rules.required]" />
							</v-col>
							<v-col cols="12">
								<v-checkbox v-model="editableRule.Apply_AP_Index"
									label="Áp dụng Hệ số AP Index cho quy tắc này" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="editableRule.Formula_TinhGioGoc"
									label="Hoặc dùng Công thức tính giờ gốc (nâng cao)"
									hint="Ví dụ: =[kinh_phi]*2. Ưu tiên hơn Số giờ chuẩn gốc." />
							</v-col>
						</v-row>

						<!-- === PHẦN ĐIỀU KIỆN (IF) === -->
						<v-divider class="my-4"></v-divider>
						<div class="text-h6 mb-2">Điều kiện (IF)</div>
						<div v-if="!editableRule.Conditions || editableRule.Conditions.length === 0"
							class="text-grey my-4">
							Quy tắc này không có điều kiện, sẽ luôn được áp dụng.
						</div>
						<v-row v-for="(condition, index) in editableRule.Conditions" :key="index" align="center">
							<v-col cols="5">
								<v-select v-model="condition.FieldID" label="Trường dữ liệu" :items="fieldsForRule"
									@update:model-value="updateNewDataSource(condition)" item-title="FieldLabel"
									item-value="FieldID" :rules="[rules.required]" />
							</v-col>
							<v-col cols="2">
								<v-select v-model="condition.Operator" label="Toán tử" :items="['=', '!=', '>', '<']"
									:rules="[rules.required]" />
							</v-col>
							<v-col cols="4">
								<v-select v-if="condition.DataSource != null" v-model="condition.ConditionValue"
									label="Giá trị" :items="condition.DataSourceItems" item-value="value"
									:rules="[rules.required]" />
								<v-text-field v-else v-model="condition.ConditionValue" label="Giá trị"
									hint="Nhập ID từ bảng danh mục tương ứng" :rules="[rules.required]" />
							</v-col>
							<v-col cols="1">
								<f-button icon="mdi-trash-can-outline" variant="text" color="error"
									@click="removeCondition(index)" />
							</v-col>

						</v-row>
						<v-row>
							<v-col>
								<f-button label="Thêm điều kiện" prepend-icon="mdi-plus" variant="tonal"
									@click="addCondition" />
							</v-col>
						</v-row>

					</v-container>
				</v-form>
			</v-card-text>
			<v-card-actions style="position: sticky;bottom: 0;background-color: #ffffff;">
				<v-spacer></v-spacer>
				<f-button label="Hủy" @click="closeDialog" />
				<f-button type="submit" label="Lưu Quy tắc" color="primary" @click="saveRule" :loading="isLoading" />
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-form-quanly-rule',
		emits: ['update:modelValue', 'saved', 'close'],
		props: {
			modelValue: { type: Boolean, default: false },
			title: { type: String, default: 'Thêm mới Quy tắc' },
			fieldsForRule: { type: Array, default: () => [] },
			formData: { type: Object, default: {} },
	
		},
		data() {
			return {
				vueData,
				showDialog: this.modelValue,
				editableRule: {}, // Luôn bắt đầu với object rỗng
				isLoading: false,
				rules: { required: value => (value !== null && value !== '') || 'Bắt buộc.', },
				// DSQuyTacPhanChia: [
				// 	{
				// 		value: 1,
				// 		title: "Không chia"
				// 	},
				// 	{
				// 		value: 2,
				// 		title: "Chia đều" // Hướng dẫn nghiên cứu khoa học, tham gia cuộc thi
				// 	},
				// 	{
				// 		value: 3,
				// 		title: "Đề tài nghiên cứu khoa học - Chia" // Chủ nhiệm 25%, còn lại chia đều
				// 	},
				// 	{
				// 		value: 4,
				// 		title: "Sách giáo trình - Chia" // Chủ biên 25%, còn lại chia đều
				// 	},
				// 	{
				// 		value: 5,
				// 		title: "Bài báo khoa học - Chia" // Nếu tất cả thành viên đều là GV Lạc Hồng, tác giả chính (Tác giả thứ nhất, tác giả liên hệ) 25%, còn lại chia đều
				// 		// Mỗi bài báo chỉ được tính 1 tác giả liên hệ
				// 		// - Quy định về Hệ số AP: Tác giả vị trí thứ nhất AP = 1 (Mỗi bài báo chỉ tính cho 1 tác giả liên hệ), tác giả vị trí thứ
				// 		// 2 AP = 0.9, tác giả vị trí thứ 3 AP = 0.7, tác giả vị trí thứ 4 AP = 0.5, tác giả vị trí thứ 5 trở về sau AP = 0.3
				// 	},
				// 	{
				// 		value: 6,
				// 		title: "Sáng chế giải pháp - Chia" // Thành viên chính (Tác giả đứng đầu, tác giả liên hệ) 25%, còn lại chia đều
				// 	}
				// ]
				DSQuyTacPhanChia: vueData.DSQuyTacPhanChia
			};
		},
		watch: {
			modelValue: function (newVal) {
				this.showDialog = newVal;
				console.log('formData', this.formData)
				// Khi dialog được mở (newVal = true), chuẩn bị dữ liệu
				if (newVal) {
					this.prepareEditableData();
				}
			},
		},
		async mounted() {
	
		},
		methods: {
			/**
			 * Hàm trung tâm để chuẩn bị dữ liệu hiển thị trên form.
			 * Được gọi mỗi khi dialog mở ra.
			 */
			prepareEditableData() {
				// Trường hợp THÊM MỚI: formData là null hoặc rỗng
				if (!this.formData || !this.formData.RuleID) {
					this.editableRule = {
						Conditions: [],
						// Gán các giá trị mặc định nếu cần
						FormID: new URLSearchParams(window.location.search).get('FormID')
					};
					return;
				}
				// // Trường hợp SỬA: Sao chép sâu dữ liệu từ prop
				// // formData lúc này đã là một object sạch do ALLDRAW xử lý
				// const newRuleData = { ...this.formData };
				// // Xử lý parse json_data một cách an toàn
				// try {
				// 	if (typeof newRuleData.json_data === 'string' && newRuleData.json_data) {
				// 		newRuleData.Conditions = JSON.parse(newRuleData.json_data);
				// 	} else {
				// 		// Đảm bảo Conditions luôn là một mảng
				// 		newRuleData.Conditions = newRuleData.json_data || [];
				// 	}
				// } catch (e) {
				// 	console.error('Lỗi parse JSON cho Rule:', newRuleData, e);
				// 	newRuleData.Conditions = [];
				// }
				this.editableRule = { ... this.formData };
			},
			updateNewDataSource(condition) {
				// Xử lí chính khi đổi giá trị của v-select fieldID
				condition.DataSource = vueData.getDataSourceByFieldID(condition.FieldID)
				condition.DataSourceItems = vueData.fetchDataSourceForField(condition)
				condition.ConditionValue = null
			},
	
			closeDialog() {
				this.$emit('update:modelValue', false);
				this.$emit('close');
			},
	
			addCondition() {
				if (!this.editableRule.Conditions) {
					this.editableRule.Conditions = [];
				}
				this.editableRule.Conditions.push({
					ConditionID: 0,
					FieldID: null,
					Operator: '=',
					ConditionValue: ''
				});
			},
	
			removeCondition(index) {
				const $this = this
				confirm({
					title: 'Bạn có chắc muốn xóa điều kiện này?',
					action: function () {
						$this.editableRule.Conditions.splice(index, 1);
					},
					onclose: function () {
						console.log('close')
					} //Action all raw
				})
			},
	
			async saveRule() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) return;
				this.isLoading = true;
				try {
					// Chuẩn bị payload để gửi lên server
					const params = {
						RuleID: this.editableRule.RuleID || 0,
						FormID: this.editableRule.FormID,
						RuleDescription: this.editableRule.RuleDescription,
						SoGioQuyDoi_Goc: this.editableRule.SoGioQuyDoi_Goc,
						Formula_TinhGioGoc: this.editableRule.Formula_TinhGioGoc,
						MaQuyTacPhanChia: this.editableRule.MaQuyTacPhanChia,
						Apply_AP_Index: this.editableRule.Apply_AP_Index || false,
						NamHocApDung: this.editableRule.NamHocApDung,
						// Luôn gửi Conditions dưới dạng chuỗi JSON
						json_data: JSON.stringify(
							// Xoá DataSource, DataSourceItems
							(this.editableRule.Conditions || []).map(({ DataSource, DataSourceItems, ...rest }) => rest)
						)
					};
					await ajaxCALL('/HDKH_Rule_Save', params, res => {
						Vue.$toast.success('Lưu quy tắc thành công!', { position: "top" });
						this.$emit('saved');
						this.closeDialog();
					});
					console.log(params)
				} catch (error) {
					console.error("Lỗi khi lưu Rule:", error);
					Vue.$toast.error(error.message || 'Có lỗi xảy ra.', { position: "top" });
				} finally {
					this.isLoading = false;
				}
			},
			disabledScrollFocus() {
				const el = document.querySelector('[autofocus]');
				if (el) {
					el.removeAttribute('autofocus')
				}
			}
	
		},
	}
</script>