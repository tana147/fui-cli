<template>
	<v-dialog v-model="internalValue" max-width="1100" persistent scrollable>
		<v-card>
			<v-toolbar density="compact">
				<v-toolbar-title class="text-subtitle-1 font-weight-bold">Chỉnh sửa cấu hình đề xuất</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" variant="text" @click="close"></v-btn>
			</v-toolbar>

			<v-card-text class="pa-3 bg-surface"
				style="max-height: calc(100vh - 120px); overflow-y: auto; position: relative;">

				<v-form ref="form" v-model="isValid" validate-on="submit" @submit.prevent>
					<v-row dense>
						<!-- Cột trái: Thông tin chung -->
						<v-col cols="12" md="7">
							<v-card variant="flat" class="pa-5 border rounded-lg bg-white h-100">
								<v-row dense>
									<!-- Dynamic render theo schema.fields (tái sử dụng từ insert) -->
									<v-col v-for="field in schema.fields" :key="field.key" :cols="12"
										:sm="field.span < 12 ? field.span : 12" class="mb-2">
										<!-- Label -->
										<div v-if="field.component !== 'v-checkbox'"
											class="text-subtitle-2 mb-1 d-flex align-center">
											{{ field.label }}
											<span v-if="field.required" class="text-error ml-1">*</span>
											<v-tooltip v-if="field.tooltip" :text="field.tooltip" location="top"
												max-width="300">
												<template v-slot:activator="{ props }">
													<v-icon v-bind="props" size="16" color="primary"
														class="ml-1 cursor-help">mdi-information-outline</v-icon>
												</template>
											</v-tooltip>
										</div>

										<!-- Dynamic Component -->
										<component :is="field.component" v-model="formData[field.key]" v-bind="{
											...field.props,
											density: 'compact',
											variant: field.component !== 'v-checkbox' ? 'outlined' : undefined,
											clearable: field.component !== 'v-checkbox' ? false : undefined,
											hideDetails: 'auto',
											rules: field.rules || [],
											label: field.component === 'v-checkbox' ? field.label : undefined,
											color: field.component === 'v-checkbox' ? 'primary' : undefined,
										}"></component>
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
														<div class="font-weight-medium text-body-2">{{ item.HoVaTenNhanVien }}</div>
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
														<div class="font-weight-medium text-body-2">{{ item.HoVaTenNhanVien }}</div>
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
				<v-btn variant="flat" color="primary" @click="submit" :loading="isSaving" :disabled="isLoadingData"
					width="100">
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
		schema: { type: Object, default: () => ({}) },     // Tái sử dụng schema insert từ uc-main
		apiConfig: { type: Object, default: () => ({}) },  // Object chứa Link API
		editId: { type: [Number, String], default: null }, // ID bản ghi cần sửa
		idKey: { type: String, default: 'Id' },            // Tên field ID (vd: 'ChinhSach_MuaHang_Id')
	},
	emits: ['update:modelValue', 'onReload'],
	data() {
		return {
			isValid: true,
			isLoadingData: false,
			isSaving: false,
			formData: {},
			// Snapshot danh sách người quản lý khi load từ DB (dùng để diff insert/delete)
			originalNguoiQuanLy: [],
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
			if (val && this.editId) {
				this.loadData();
			}
		}
	},
	methods: {
		apiCallPromiseLocal(url, params = null) {
			return new Promise((resolve, reject) => {
				$.ajax({
					type: "POST",
					headers: { authorization: $awt },
					url: vueData.v_Set.apiDomain + url,
					contentType: "application/json; charset=utf-8",
					dataType: "json",
					crossDomain: true,
					data: JSON.stringify(params),
					success: function (d) {
						resolve(d)
					},
					error: function (xhr) {
						console.error("API:", url, "", params, "", xhr)
						reject(xhr)
					},
				})
			})
		},

		close() {
			this.internalValue = false;
		},

		loadData() {
			if (this.isLoadingData) return;
			this.isLoadingData = true;
			this.formData = {};
			this.originalNguoiQuanLy = [];

			const params = { [this.idKey]: this.editId };

			apiCall(
				this.apiConfig.selectById,
				params,
				(res) => {
					// Response trả về array 2 dataset:
					// res.data[0] = array chính sách, res.data[1] = array NguoiQuanLy
					const datasets = res?.data || [];
					const dsList = datasets[0] || [];
					const dsNguoiQuanLy = datasets[1] || [];

					// Lọc đúng bản ghi theo editId
					const data = dsList.find(r => r[this.idKey] == this.editId) || dsList[0] || {};

					// ListNhomNhanVien_Id là string "42" → parse thành array [42]
					const listNhom = Array.isArray(data.ListNhomNhanVien_Id)
						? data.ListNhomNhanVien_Id
						: (data.ListNhomNhanVien_Id
							? String(data.ListNhomNhanVien_Id).split(',').map(Number).filter(Boolean)
							: []);

					// Normalize NguoiQuanLy: Is_NguoiDuyet từ boolean (DB) → integer (1/0)
					const nguoiQuanLy = dsNguoiQuanLy.map(p => {
						let hoTen = p.MaNhanVien + ' - ' + p.HoVaTenNhanVien || '';
						let maNV = p.MaNhanVien || '';

						return {
							...p,
							HoVaTenNhanVien: hoTen,
							MaNhanVien: maNV,
							Is_NguoiDuyet: p.Is_NguoiDuyet === true || p.Is_NguoiDuyet === 1 ? 1 : 0,
						};
					});

					this.formData = {
						...data,
						ListNhomNhanVien_Id: listNhom,
						NguoiQuanLy_JSON: nguoiQuanLy,
					};

					// Snapshot để diff sau khi submit
					this.originalNguoiQuanLy = JSON.parse(JSON.stringify(nguoiQuanLy));

					this.isLoadingData = false;
					this.$nextTick(() => {
						this.$refs.form?.resetValidation();
					});
				},
				(err) => {
					showToast.error('Không thể tải dữ liệu: ' + (err?.Message || 'Lỗi không xác định'));
					console.error(err);
					this.isLoadingData = false;
				}
			);
		},

		async submit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.error('Vui lòng nhập đầy đủ thông tin bắt buộc');
				return;
			}

			// check 1: phải có ít nhất 1 quản lý
			const isHasQL = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.Is_NguoiDuyet === 1
			);
			
			if(isHasQL === -1){
				showToast.error('Vui lòng chọn ít nhất 1 quản lý!');
				return;
			}

			// Build payload update (tương tự insert nhưng có thêm ID, bỏ NguoiQuanLy_JSON)
			const payload = { [this.idKey]: this.editId };
			const defaults = this.schema.defaultValues || {};

			Object.keys(defaults).forEach(key => {
				if (key === 'NguoiQuanLy_JSON') return; // Xử lý riêng bên dưới
				const val = this.formData[key];
				if (Array.isArray(val)) {
					payload[key] = val.join(',');
				} else if (key.startsWith('Is_')) {
					payload[key] = !!val;
				} else {
					payload[key] = val ?? null;
				}
			});

			// Tính diff NguoiQuanLy
			const currentList = this.formData.NguoiQuanLy_JSON || [];
			const originalList = this.originalNguoiQuanLy;

			// Thêm mới: có trong current nhưng không có trong original
			const added = currentList.filter(cur =>
				!originalList.some(orig =>
					orig.NguoiQuanLy_Id === cur.NguoiQuanLy_Id && orig.Is_NguoiDuyet === cur.Is_NguoiDuyet
				)
			);

			// Xóa: có trong original nhưng không có trong current
			const removed = originalList.filter(orig =>
				!currentList.some(cur =>
					cur.NguoiQuanLy_Id === orig.NguoiQuanLy_Id && cur.Is_NguoiDuyet === orig.Is_NguoiDuyet
				)
			);

			console.group('Payload Submit Edit ChinhSach');
			console.log('API target:', this.apiConfig.update);
			console.log('Payload:', payload);
			console.log('NguoiQuanLy added:', added);
			console.log('NguoiQuanLy removed:', removed);
			console.groupEnd();

			this.isSaving = true;

			try {
				// Bước 1: Update main record
				// FIX: dùng apiCallPromiseLocal để đảm bảo onError được reject đúng
				await this.apiCallPromiseLocal(this.apiConfig.update, payload).catch(err => {
					showToast.error('Lỗi cập nhật: ' + (err?.responseJSON?.Message || err?.Message || 'Không thể cập nhật'));
					console.error(err);
					// throw để nhảy vào finally, dừng không chạy bước 2
					throw err;
				});

				// Bước 2: Xử lý parallel insert/delete NguoiQuanLy
				// FIX: Chạy tuần tự thay vì song song để tránh loadingPage counter bị cộng dồn
				for (const person of added) {
					await this.apiCallPromiseLocal(
						this.apiConfig.nguoiQuanLyInsert,
						{
							[this.idKey]: this.editId,
							NguoiQuanLy_Id: person.NguoiQuanLy_Id,
							Is_NguoiDuyet: person.Is_NguoiDuyet,
						}
					).catch(err => {
						console.error('Lỗi insert NguoiQuanLy:', err);
						// Không throw, tiếp tục xử lý các người còn lại
					});
				}

				for (const person of removed) {
					await this.apiCallPromiseLocal(
						this.apiConfig.nguoiQuanLyDelete,
						{
							ChinhSach_MuaHang_NguoiQuanLy_Id: person.ChinhSach_MuaHang_NguoiQuanLy_Id,
						}
					).catch(err => {
						console.error('Lỗi delete NguoiQuanLy:', err);
						// Không throw, tiếp tục xử lý các người còn lại
					});
				}

				showToast.success('Cập nhật chính sách thành công!');
				// FIX: emit onReload TRƯỚC khi close để main fetch lại data
				// sau đó mới close dialog, tránh race condition
				this.$emit('onReload');
				this.close();

			} catch (err) {
				console.error('Submit thất bại:', err);
			} finally {
				this.isSaving = false;
			}
		},

		onSelectNhanVien(nhanVienObj, typeDuyet) {
			if (!nhanVienObj) return;

			let maNV = nhanVienObj.MaNhanVien || '';
			let hoTen = nhanVienObj.TenNhanVien || nhanVienObj.HoVaTenNhanVien || nhanVienObj.title || '';

			// Nếu hoTen có định dạng "Mã - Tên" thì tách ra
			if (hoTen.includes(' - ')) {
				const parts = hoTen.split(' - ');
				if (!maNV) maNV = parts[0].trim();
				hoTen = parts[1].trim();
			}

			const temp = {
				NguoiQuanLy_Id: nhanVienObj.NhanVien_Id || nhanVienObj.value,
				MaNhanVien: maNV,
				HoVaTenNhanVien: hoTen,
				Is_NguoiDuyet: typeDuyet,
				// ChinhSach_MuaHang_NguoiQuanLy_Id = null vì đây là record mới chưa có trong DB
				ChinhSach_MuaHang_NguoiQuanLy_Id: null,
			};

			const nhanVienId = nhanVienObj.NhanVien_Id || nhanVienObj.value;

			// Check 1: đã có trong đúng nhóm muốn thêm
			const isHas = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.NguoiQuanLy_Id === nhanVienId && item.Is_NguoiDuyet === typeDuyet
			);
			if (isHas > -1) {
				showToast.error('Nhân sự đã có trong danh sách!');
				return;
			}

			// Check 2: đã có trong nhóm ngược lại
			const otherType = typeDuyet === 1 ? 0 : 1;
			const isInOtherGroup = this.formData.NguoiQuanLy_JSON?.findIndex(item =>
				item.NguoiQuanLy_Id === nhanVienId && item.Is_NguoiDuyet === otherType
			);
			if (isInOtherGroup > -1) {
				const groupName = typeDuyet === 1 ? 'Theo dõi' : 'Quản lý duyệt';
				showToast.error(`Nhân sự đã có trong nhóm "${groupName}", không thể thêm vào 2 nhóm cùng lúc!`);
				return;
			}

			this.formData.NguoiQuanLy_JSON.push(temp);
		},

		onRemoveNguoiQuanLyAt(user) {
			const idx = this.formData.NguoiQuanLy_JSON.findIndex(i =>
				(i.MaNhanVien === user.MaNhanVien || i.NguoiQuanLy_Id === user.NguoiQuanLy_Id) &&
				i.Is_NguoiDuyet === user.Is_NguoiDuyet
			);
			if (idx > -1) {
				this.formData.NguoiQuanLy_JSON.splice(idx, 1);
			}
		},
	}
}
</script>