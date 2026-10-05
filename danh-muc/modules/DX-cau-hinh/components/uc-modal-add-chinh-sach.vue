<template>
	<v-dialog v-model="internalValue" max-width="1100" persistent scrollable>
		<v-card>
			<v-toolbar density="compact">
				<v-toolbar-title class="text-subtitle-1 font-weight-bold">Thêm cấu hình đề xuất</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" variant="text" @click="close"></v-btn>
			</v-toolbar>

			<v-card-text class="pa-3 bg-surface" style="max-height: calc(100vh - 120px); overflow-y: auto;">
				<v-form ref="form" v-model="isValid" validate-on="submit" @submit.prevent>
					<v-row dense>
						<!-- Cột trái: Thông tin chung -->
						<v-col cols="12" md="7">
							<v-card variant="flat" class="pa-5 border rounded-lg bg-white h-100">
								<v-row dense>
									<v-col v-for="field in schema.fields.filter(f => !f.editOnly)" :key="field.key"
										:cols="12" :sm="field.span < 12 ? field.span : 12" class="mb-2">
										<!-- Label -->
										<div v-if="field.component !== 'v-checkbox'" class="text-subtitle-2 mb-1 d-flex align-center">
											{{ field.label }}
											<span v-if="field.required" class="text-error ml-1">*</span>
											<v-tooltip v-if="field.tooltip" :text="field.tooltip" location="top" max-width="300">
												<template v-slot:activator="{ props }">
													<v-icon v-bind="props" size="16" color="primary" class="ml-1 cursor-help">mdi-information-outline</v-icon>
												</template>
											</v-tooltip>
										</div>

										<component
											:is="field.component"
											v-model="formData[field.key]"
											v-bind="{
												...field.props,
												density: 'compact',
												variant: field.component !== 'v-checkbox' ? 'outlined' : undefined,
												clearable: field.component !== 'v-checkbox' ? false : undefined,
												hideDetails: 'auto',
												rules: field.rules || [],
												label: field.component === 'v-checkbox' ? field.label : undefined,
												color: field.component === 'v-checkbox' ? 'primary' : undefined,
											}"
										></component>
									</v-col>
								</v-row>
							</v-card>
						</v-col>

						<!-- Cột phải: Quản lý & Theo dõi -->
						<v-col cols="12" md="5" class="d-flex flex-column gap-3">
							<!-- Quản lý duyệt -->
							<v-card variant="flat"
								class="border rounded-lg d-flex flex-column bg-white flex-grow-1 mb-2">
								<div
									class="bg-grey-lighten-4 pa-2 px-3 border-b text-subtitle-2 font-weight-bold d-flex justify-space-between align-center">
									Người quản lý duyệt
									<div style="width: 250px">
										<uc-select-nhan-vien :model-value="null" auto-reset
											placeholder="Tìm và chọn nhân viên..." :isHideDetail="true"
											@onSelect="(obj) => onSelectNhanVien(obj, 1)"></uc-select-nhan-vien>
									</div>
								</div>
								<v-table density="compact" class="flex-grow-1" style="max-height: 300px; overflow-y: auto; scrollbar-width: thin;">
									<thead>
										<tr>
											<th class="text-caption font-weight-bold text-grey-darken-1">Họ và tên</th>
											<th width="40" class="text-center"></th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="item in dsNguoiDuyet" :key="item.NguoiQuanLy_Id">
											<td class="py-1">
												<div class="d-flex align-center gap-2">
													<div>
														<div class="font-weight-medium text-body-2">{{
															item.HoVaTenNhanVien }}</div>
														<div class="text-grey text-caption"
															style="font-size: 11px !important; line-height: 1;">
															{{ item.MaNhanVien }}</div>
													</div>
												</div>
											</td>
											<td class="text-center">
												<v-btn icon="mdi-delete-outline" variant="text" size="small"
													color="error" @click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</td>
										</tr>
										<tr v-if="!dsNguoiDuyet.length">
											<td colspan="2" class="text-center text-caption text-grey py-4">
												<v-icon size="32" color="grey-lighten-1"
													class="mb-1">mdi-account-off-outline</v-icon><br />
												Chưa có dữ liệu
											</td>
										</tr>
									</tbody>
								</v-table>
							</v-card>

							<!-- Theo dõi -->
							<v-card variant="flat" class="border rounded-lg d-flex flex-column bg-white flex-grow-1">
								<div
									class="bg-grey-lighten-4 pa-2 px-3 border-b text-subtitle-2 font-weight-bold d-flex justify-space-between align-center">
									Người theo dõi
									<div style="width: 250px">
										<uc-select-nhan-vien :model-value="null" auto-reset
											placeholder="Tìm và chọn nhân viên..." :isHideDetail="true"
											@onSelect="(obj) => onSelectNhanVien(obj, 0)"></uc-select-nhan-vien>
									</div>
								</div>
								<v-table density="compact" class="flex-grow-1" style="max-height: 300px; overflow-y: auto; scrollbar-width: thin;">
									<thead>
										<tr>
											<th class="text-caption font-weight-bold text-grey-darken-1">Họ và tên</th>
											<th width="40" class="text-center"></th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="item in dsNguoiTheoDoi" :key="item.NguoiQuanLy_Id">
											<td class="py-1">
												<div class="d-flex align-center gap-2">
													<div>
														<div class="font-weight-medium text-body-2">{{
															item.HoVaTenNhanVien }}</div>
														<div class="text-grey text-caption"
															style="font-size: 11px !important; line-height: 1;">
															{{ item.MaNhanVien }}</div>
													</div>
												</div>
											</td>
											<td class="text-center">
												<v-btn icon="mdi-delete-outline" variant="text" size="small"
													color="error" @click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</td>
										</tr>
										<tr v-if="!dsNguoiTheoDoi.length">
											<td colspan="2" class="text-center text-caption text-grey py-4">
												<v-icon size="32" color="grey-lighten-1"
													class="mb-1">mdi-account-off-outline</v-icon><br />
												Chưa có dữ liệu
											</td>
										</tr>
									</tbody>
								</v-table>
							</v-card>
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>

			<v-card-actions class="pa-3 bg-white">
				<v-spacer></v-spacer>
				<v-btn variant="flat" color="primary" @click="submit" :loading="isLoading" width="100">
					<v-icon start>mdi-content-save</v-icon>Lưu
				</v-btn>
			</v-card-actions>
		</v-card>

	</v-dialog>
</template>

<script>
export default {
	props: {
		modelValue: { type: Boolean, default: false },
		schema: { type: Object, default: () => ({}) }, // Object cấu hình chứa param gốc
		apiConfig: { type: Object, default: () => ({}) } // Object chứa Link API insert/update
	},
	emits: ['update:modelValue', 'onReload'],
	data() {
		return {
			isValid: true,
			isLoading: false,
			formData: {},
			rules: {
				required: [(v) => !!v || 'Vui lòng nhập thông tin'],
			}
		}
	},
	computed: {
		internalValue: {
			get() { return this.modelValue; },
			set(val) { this.$emit('update:modelValue', val); }
		},
		dsNguoiDuyet() {
			return (this.formData.NguoiQuanLy_JSON || []).filter(x => x.Is_NguoiDuyet === 1);
		},
		dsNguoiTheoDoi() {
			return (this.formData.NguoiQuanLy_JSON || []).filter(x => x.Is_NguoiDuyet === 0);
		},
	},
	watch: {
		modelValue(val) {
			if (val) {
				// Khởi tạo formData từ schema.defaultValues (do uc-main cấu hình)
				this.formData = JSON.parse(JSON.stringify(this.schema.defaultValues || {}));
				// Reset validation để không hiện lỗi ngay khi dialog mở
				this.$nextTick(() => {
					this.$refs.form?.resetValidation();
				});
			}
		}
	},
	methods: {
		close() {
			this.internalValue = false;
		},
		async submit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.error('Vui lòng nhập đầy đủ thông tin bắt buộc');
				return;
			}

			const payload = {};
			const defaults = this.schema.defaultValues || {};

			// check 1: phải có ít nhất 1 quản lý
			const isHasQL = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.Is_NguoiDuyet === 1
			);

			if(isHasQL === -1){
				showToast.error('Vui lòng chọn ít nhất 1 quản lý!');
				return;
			}
			

			console.group("NguoiQuanLy_JSON")
			console.log(this.formData.NguoiQuanLy_JSON, isHasQL)
			console.groupEnd()

			Object.keys(defaults).forEach(key => {
				const val = this.formData[key];
				if (key === 'NguoiQuanLy_JSON') {
					// Serialize JSON array thành chuỗi
					payload[key] = JSON.stringify(
						(val || []).map(p => ({ NguoiQuanLy_Id: p.NguoiQuanLy_Id, Is_NguoiDuyet: p.Is_NguoiDuyet }))
					);
				} else if (Array.isArray(val)) {
					// Chuyển mảng thành chuỗi "1,2,3"
					payload[key] = val.join(',');
				} else if (key.startsWith('Is_')) {
					// Đảm bảo boolean
					payload[key] = !!val;
				} else {
					payload[key] = val ?? null;
				}
			});

			// group 
			console.group('Payload Submit ChinhSach');
			console.log('API target:', this.apiConfig.insert);
			console.log('Payload:', payload);
			console.log('NguoiQuanLy_JSON (parsed):', JSON.parse(payload.NguoiQuanLy_JSON || '[]'));
			console.groupEnd();

			this.isLoading = true;
			await apiCall(
				this.apiConfig.insert,
				payload,
				(res) => {
					showToast.success('Thêm chính sách thành công!', { position: 'top' });
					this.$emit('onReload');
					this.close();
				}
			)
			
			this.isLoading = false
		},
		onSelectNhanVien(nhanVienObj, typeDuyet) {
			if (!nhanVienObj) return;

			// Dùng trực tiếp object từ search (có sẵn TenNhanVien, MaNhanVien)
			const temp = {
				NguoiQuanLy_Id: nhanVienObj.NhanVien_Id || nhanVienObj.value,
				MaNhanVien: nhanVienObj.MaNhanVien || '',
				HoVaTenNhanVien: nhanVienObj.TenNhanVien || nhanVienObj.HoVaTenNhanVien || nhanVienObj.title || '',
				Is_NguoiDuyet: typeDuyet,
			};

			// Kiểm tra trùng bằng ID (đảm bảo chính xác ngay cả khi MaNhanVien rỗng)
			const nhanVienId = nhanVienObj.NhanVien_Id || nhanVienObj.value;

			// Check 1: đã có trong đúng nhóm muốn thêm
			const isHas = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.NguoiQuanLy_Id === nhanVienId && item.Is_NguoiDuyet === typeDuyet
			);
			if (isHas > -1) {
					showToast.error('Nhân sự đã có trong danh sách!', {
					position: 'top',
				})
				return;
			}

			// Check 2: đã có trong nhóm ngược lại (không được đồng thời 2 nhóm)
			const otherType = typeDuyet === 1 ? 0 : 1;
			const isInOtherGroup = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.NguoiQuanLy_Id === nhanVienId && item.Is_NguoiDuyet === otherType
			);
			if (isInOtherGroup > -1) {
				const groupName = typeDuyet === 1 ? 'Theo dõi' : 'Quản lý duyệt';
				showToast.error(`Nhân sự đã có trong nhóm "${groupName}", không thể thêm vào 2 nhóm cùng lúc!`, {
					position: 'top',
				});
				return;
			}

			this.formData.NguoiQuanLy_JSON.push(temp);
		},
		onRemoveNguoiQuanLyAt(user) {
			const idx = this.formData.NguoiQuanLy_JSON.findIndex(i =>
				(i.MaNhanVien === user.MaNhanVien || i.NguoiQuanLy_Id === user.NguoiQuanLy_Id || i.HoVaTenNhanVien === user.HoVaTenNhanVien) &&
				i.Is_NguoiDuyet === user.Is_NguoiDuyet
			);
			if (idx > -1) {
				this.formData.NguoiQuanLy_JSON.splice(idx, 1);
			}
		},
	}
}
</script>
