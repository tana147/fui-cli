<template>
	<!-- Desktop: v-dialog | Mobile: v-bottom-sheet full height -->
	<component :is="$isMobile ? 'v-bottom-sheet' : 'v-dialog'" v-model="internalValue" v-bind="$isMobile
		? { persistent: true, fullscreen: true }
		: { maxWidth: 1200, persistent: true, scrollable: true }">
		<v-card :rounded="$isMobile ? '0' : undefined">
			<!-- Toolbar -->
			<v-toolbar  density="compact">
				<v-toolbar-title class="text-subtitle-1 font-weight-bold">
					{{ isEditMode ? 'Chỉnh sửa đề xuất mua hàng' : 'Tạo đề xuất mua hàng' }}
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-icon @click="close" class="mr-5">mdi-close</v-icon>
			</v-toolbar>

			<v-card-text class="pa-3 bg-surface" :style="$isMobile
				? 'flex:1; overflow-y:auto;'
				: 'max-height: calc(100vh - 120px); overflow-y: auto;'">
				<!-- ── DESKTOP layout: 7/5 ── -->
				<div v-if="!$isMobile">
					<v-row dense>
						<v-col cols="12" md="7">
							<v-form ref="form" v-model="isValid" validate-on="submit" @submit.prevent>
								<v-row dense>
									<v-col cols="12">
										<v-card variant="flat" class="pa-5 border rounded-lg bg-white h-100 mb-2">
											<v-row dense>
												<v-col cols="12" sm="6" class="mb-2">
													<div class="text-subtitle-2 mb-1 d-flex align-center">
														Chính sách mua hàng <span class="text-error ml-1">*</span>
													</div>
													<v-select v-model="formData.ChinhSach_MuaHang_Id" density="compact"
														variant="outlined" hide-details="auto"
														placeholder="Chọn chính sách" :items="dsChinhSach"
														item-title="TenChinhSach_MuaHang"
														item-value="ChinhSach_MuaHang_Id" :clearable="false"
														:rules="[(v) => !!v || 'Vui lòng chọn chính sách']"
														@update:modelValue="onFieldChange('ChinhSach_MuaHang_Id', $event)"></v-select>
												</v-col>
												<v-col cols="12" sm="6" class="mb-2">
													<div class="text-subtitle-2 mb-1 d-flex align-center">
														Địa điểm nhận hàng <span class="text-error ml-1">*</span>
													</div>
													<v-autocomplete v-model="formData.DiaDiem_Id" :items="dsDiaDiem"
														:clearable="false" item-title="TenDiaDiem"
														item-value="DiaDiem_Id" density="compact" variant="outlined"
														hide-details="auto" placeholder="Chọn địa điểm nhận hàng"
														:loading="isLoadingDiaDiem"
														:rules="[(v) => !!v || 'Vui lòng chọn địa điểm']"
														@update:modelValue="onSelectDiaDiemDirect"></v-autocomplete>
												</v-col>
												<v-card variant="flat"
													class="border rounded-lg d-flex flex-column bg-white flex-grow-1 my-2"
													v-if="formData.DiaDiem_Id" style="width:100%;">
													<div
														class="bg-grey-lighten-4 pa-3 border-b text-subtitle-2 font-weight-bold d-flex justify-space-between align-center">
														Danh sách hàng hóa yêu cầu
														<div style="width: 300px">
															<v-autocomplete placeholder="Nhập mã, tên hàng hóa..."
																v-model="selectedHangHoa" :clearable="false"
																v-model:search="searchHangHoa" density="compact"
																variant="outlined" hide-details :items="dsOptionHangHoa"
																item-title="DisplayText" item-value="HangHoa_Id"
																return-object :loading="isLoadingHangHoa"
																@update:modelValue="onSelectHangHoa">
																<template v-slot:item="{ props, item }">
																	<v-list-item v-bind="props"
																		:subtitle="item.raw.MaHangHoa"></v-list-item>
																</template>
															</v-autocomplete>
														</div>
													</div>
													<v-table density="compact" class="flex-grow-1" style="max-height: 300px; overflow-y: auto; scrollbar-width: thin;">
														<thead>
															<tr>
																<th width="50" class="text-center font-weight-bold">STT
																</th>
																<th class="font-weight-bold">Tên hàng hóa</th>
																<th width="250" class="font-weight-bold">Ghi chú</th>
																<th width="50" class="text-center">Xóa</th>
															</tr>
														</thead>
														<tbody>
															<tr v-for="(item, index) in dsHangHoa"
																:key="item.HangHoa_Id">
																<td class="text-center">{{ index + 1 }}</td>
																<td>
																	<div class="font-weight-medium">{{ item.TenHangHoa
																		}}
																	</div>
																	<div class="text-grey text-caption"
																		style="font-size:11px!important;">{{
																			item.MaHangHoa
																		}}</div>
																</td>
																<td>
																	<v-text-field v-model="item.GhiChu"
																		:clearable="false" density="compact"
																		variant="outlined" hide-details
																		style="width:250px"></v-text-field>
																</td>
																<td class="text-center">
																	<v-btn icon="mdi-delete-outline" variant="text"
																		size="small" color="error"
																		@click="onRemoveHangHoa(index)"></v-btn>
																</td>
															</tr>
															<tr v-if="!dsHangHoa.length">
																<td colspan="5"
																	class="text-center text-caption text-grey py-4">Chưa
																	có
																	hàng hóa nào được chọn</td>
															</tr>
														</tbody>
													</v-table>
												</v-card>
												<v-col cols="12" class="mb-2">
													<div class="text-subtitle-2 mb-1">Mô tả / Ghi chú</div>
													<v-textarea v-model="formData.MoTa" density="compact"
														variant="outlined" hide-details="auto"
														placeholder="Nhập mô tả đề xuất..." rows="2" :clearable="false"
														auto-grow></v-textarea>
												</v-col>
											</v-row>
										</v-card>
									</v-col>
								</v-row>
							</v-form>
						</v-col>
						<v-col cols="12" md="5" class="d-flex flex-column gap-3">
							<v-card variant="flat"
								class="border rounded-lg d-flex flex-column bg-white flex-grow-1 mb-2">
								<div class="bg-grey-lighten-4 pa-2 px-3 border-b text-subtitle-2 font-weight-bold">
									<div class="mb-1">Quản lý duyệt</div>
									<uc-select-nhan-vien :model-value="null" auto-reset placeholder="Tìm..."
										:isHideDetail="true"
										@onSelect="(obj) => onSelectNhanVien(obj, 1)"></uc-select-nhan-vien>
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
												<div class="font-weight-medium text-body-2 text-no-wrap">{{
													item.HoVaTenNhanVien }}</div>
											</td>
											<td class="text-center"><v-btn icon="mdi-delete-outline" variant="text"
													size="small" color="error"
													@click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</td>
										</tr>
										<tr v-if="!dsNguoiDuyet.length">
											<td colspan="2" class="text-center text-caption text-grey py-4">
												<v-icon size="32" color="grey-lighten-1"
													class="mb-1">mdi-account-off-outline</v-icon><br />Chưa
												có dữ liệu
											</td>
										</tr>
									</tbody>
								</v-table>
							</v-card>
							<v-card variant="flat" class="border rounded-lg d-flex flex-column bg-white flex-grow-1">
								<div class="bg-grey-lighten-4 pa-2 px-3 border-b text-subtitle-2 font-weight-bold">
									<div class="mb-1">Người theo dõi</div>
									<uc-select-nhan-vien :model-value="null" auto-reset placeholder="Tìm..."
										:isHideDetail="true"
										@onSelect="(obj) => onSelectNhanVien(obj, 0)"></uc-select-nhan-vien>
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
												<div class="font-weight-medium text-body-2 text-no-wrap">{{
													item.HoVaTenNhanVien }}</div>
											</td>
											<td class="text-center"><v-btn icon="mdi-delete-outline" variant="text"
													size="small" color="error"
													@click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</td>
										</tr>
										<tr v-if="!dsNguoiTheoDoi.length">
											<td colspan="2" class="text-center text-caption text-grey py-4">
												<v-icon size="32" color="grey-lighten-1"
													class="mb-1">mdi-account-off-outline</v-icon><br />Chưa
												có dữ liệu
											</td>
										</tr>
									</tbody>
								</v-table>
							</v-card>
						</v-col>
					</v-row>
				</div>

				<!-- ── MOBILE layout: 1 cột, stepper tabs ── -->
				<div v-if="$isMobile">
					<v-form ref="form" v-model="isValid" validate-on="submit" @submit.prevent>

						<!-- Tabs điều hướng -->
						<v-tabs v-model="mobileFormTab" color="primary" density="compact"
							class="mb-3 border-b bg-white sticky-tabs">
							<v-tab value="info">Thông tin</v-tab>
							<v-tab value="hanghoa">Hàng hóa</v-tab>
							<v-tab value="nguoi">Người duyệt</v-tab>
						</v-tabs>

						<!-- Tabs content -->
						<div class="mt-2">
							<!-- Tab: Thông tin chung -->
							<div v-if="mobileFormTab === 'info'" class="d-flex flex-column ga-3">
								<div>
									<div class="text-subtitle-2 mb-1">Chính sách mua hàng <span
											class="text-error">*</span>
									</div>
									<v-select v-model="formData.ChinhSach_MuaHang_Id" density="compact"
										variant="outlined" hide-details="auto" placeholder="Chọn chính sách"
										:items="dsChinhSach" item-title="TenChinhSach_MuaHang"
										item-value="ChinhSach_MuaHang_Id" :clearable="false"
										:rules="[(v) => !!v || 'Vui lòng chọn chính sách']"
										@update:modelValue="onFieldChange('ChinhSach_MuaHang_Id', $event)"></v-select>
								</div>
								<div>
									<div class="text-subtitle-2 mb-1">Địa điểm nhận hàng <span
											class="text-error">*</span>
									</div>
									<v-autocomplete v-model="formData.DiaDiem_Id" :items="dsDiaDiem" :clearable="false"
										item-title="TenDiaDiem" item-value="DiaDiem_Id" density="compact"
										variant="outlined" hide-details="auto" placeholder="Chọn địa điểm nhận hàng"
										:loading="isLoadingDiaDiem" :rules="[(v) => !!v || 'Vui lòng chọn địa điểm']"
										@update:modelValue="onSelectDiaDiemDirect"></v-autocomplete>
								</div>
								<div>
									<div class="text-subtitle-2 mb-1">Mô tả / Ghi chú</div>
									<v-textarea v-model="formData.MoTa" density="compact" variant="outlined"
										hide-details="auto" placeholder="Nhập mô tả đề xuất..." rows="3"
										:clearable="false" auto-grow></v-textarea>
								</div>
							</div>

							<!-- Tab: Hàng hóa -->
							<div v-if="mobileFormTab === 'hanghoa'">
								<div v-if="!formData.DiaDiem_Id" class="text-center text-caption text-grey py-8">
									<v-icon size="36" color="grey-lighten-2">mdi-store-alert-outline</v-icon>
									<p class="mt-2">Vui lòng chọn địa điểm nhận hàng trước</p>
								</div>
								<template v-else>
									<div class="mb-3">
										<v-autocomplete placeholder="Nhập mã, tên hàng hóa..." v-model="selectedHangHoa"
											:clearable="false" v-model:search="searchHangHoa" density="compact"
											variant="outlined" hide-details :items="dsOptionHangHoa"
											item-title="DisplayText" item-value="HangHoa_Id" return-object
											:loading="isLoadingHangHoa" @update:modelValue="onSelectHangHoa">
											<template v-slot:item="{ props, item }">
												<v-list-item v-bind="props"
													:subtitle="item.raw.MaHangHoa"></v-list-item>
											</template>
										</v-autocomplete>
									</div>
									<div v-if="!dsHangHoa.length" class="text-center text-caption text-grey py-6">
										<v-icon size="36" color="grey-lighten-2">mdi-package-variant-closed</v-icon>
										<p class="mt-2">Chưa có hàng hóa nào được chọn</p>
									</div>
									<v-card v-for="(item, index) in dsHangHoa" :key="item.HangHoa_Id" variant="outlined"
										class="mb-2 rounded-lg">
										<v-card-text class="pa-3">
											<div class="d-flex justify-space-between align-start mb-2">
												<div>
													<div class="font-weight-medium text-body-2">{{ item.TenHangHoa }}
													</div>
													<div class="text-caption text-grey">{{ item.MaHangHoa }}</div>
												</div>
												<v-btn icon="mdi-delete-outline" variant="text" size="small"
													color="error" @click="onRemoveHangHoa(index)"></v-btn>
											</div>
											<v-text-field v-model="item.GhiChu" :clearable="false" density="compact"
												variant="outlined" hide-details placeholder="Ghi chú..."></v-text-field>
										</v-card-text>
									</v-card>
								</template>
							</div>

							<!-- Tab: Người duyệt & theo dõi -->
							<div v-if="mobileFormTab === 'nguoi'" class="d-flex flex-column ga-3">
								<!-- Quản lý duyệt -->
								<v-card variant="outlined" class="rounded-lg">
									<div class="bg-grey-lighten-4 pa-3 border-b">
										<div class="text-subtitle-2 font-weight-bold mb-2">Quản lý duyệt</div>
										<uc-select-nhan-vien :model-value="null" auto-reset
											placeholder="Tìm nhân viên..." :isHideDetail="true"
											@onSelect="(obj) => onSelectNhanVien(obj, 1)"></uc-select-nhan-vien>
									</div>
									<div v-if="!dsNguoiDuyet.length" class="text-center text-caption text-grey py-4">
										Chưa có
										dữ liệu</div>
									<v-list density="compact" v-else>
										<v-list-item v-for="item in dsNguoiDuyet" :key="item.NguoiQuanLy_Id"
											:title="item.HoVaTenNhanVien">
											<template v-slot:append>
												<v-btn icon="mdi-delete-outline" variant="text" size="small"
													color="error" @click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</template>
										</v-list-item>
									</v-list>
								</v-card>
								<!-- Người theo dõi -->
								<v-card variant="outlined" class="rounded-lg">
									<div class="bg-grey-lighten-4 pa-3 border-b">
										<div class="text-subtitle-2 font-weight-bold mb-2">Người theo dõi</div>
										<uc-select-nhan-vien :model-value="null" auto-reset
											placeholder="Tìm nhân viên..." :isHideDetail="true"
											@onSelect="(obj) => onSelectNhanVien(obj, 0)"></uc-select-nhan-vien>
									</div>
									<div v-if="!dsNguoiTheoDoi.length" class="text-center text-caption text-grey py-4">
										Chưa
										có dữ liệu</div>
									<v-list density="compact" v-else>
										<v-list-item v-for="item in dsNguoiTheoDoi" :key="item.NguoiQuanLy_Id"
											:title="item.HoVaTenNhanVien">
											<template v-slot:append>
												<v-btn icon="mdi-delete-outline" variant="text" size="small"
													color="error" @click="onRemoveNguoiQuanLyAt(item)"></v-btn>
											</template>
										</v-list-item>
									</v-list>
								</v-card>
							</div>
						</div>
					</v-form>
				</div>
			</v-card-text>

			<v-card-actions class="pa-3 bg-white border-t">
				<v-spacer></v-spacer>
				<v-btn variant="flat" color="primary" @click="submit" :loading="isLoading" :block="$isMobile"
					:width="$isMobile ? undefined : 100">
					<v-icon start>mdi-send</v-icon>{{ isEditMode ? 'Lưu' : 'Gửi' }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</component>
</template>

<script>
export default {
	props: {
		modelValue: { type: Boolean, default: false },
		schema: { type: Object, default: () => ({}) },
		apiConfig: { type: Object, default: () => ({}) },
		dsChinhSach: { type: Array, default: () => [] },
		editItemId: { type: [Number, String], default: null },
	},
	emits: ['update:modelValue', 'onReload'],
	data() {
		return {
			isValid: true,
			isLoading: false,
			formData: {},
			dsHangHoa: [],
			dsNguoiQuanLy: [],
			dsOptionHangHoa: [],
			isLoadingHangHoa: false,
			selectedHangHoa: null,
			searchHangHoa: null,
			dsDiaDiem: [],
			isLoadingDiaDiem: false,
			_suppressDiaDiemWatch: false,
			_editRawData: null,
			// Mobile form tab
			mobileFormTab: 'info',
			// Reactive mobile check
			isMobile: !!window.$isMobile,
		}
	},
	computed: {
		internalValue: {
			get() { return this.modelValue; },
			set(val) { this.$emit('update:modelValue', val); }
		},
		isEditMode() { return !!this.editItemId; },
		dsNguoiDuyet() { return this.dsNguoiQuanLy.filter(item => item.Is_NguoiDuyet); },
		dsNguoiTheoDoi() { return this.dsNguoiQuanLy.filter(item => !item.Is_NguoiDuyet); },
		$isMobile() { return this.isMobile; },
	},
	watch: {
		modelValue(val) {
			if (val) {
				this.dsHangHoa = [];
				this.dsNguoiQuanLy = [];
				this.dsOptionHangHoa = [];
				this._suppressDiaDiemWatch = false;
				this._editRawData = null;
				this.mobileFormTab = 'info';
				this.formData = JSON.parse(JSON.stringify(this.schema.defaultValues || {}));
				this.$nextTick(() => { this.$refs.form?.resetValidation(); });
				if (this.isEditMode) {
					this.fetchDsDiaDiemThenEdit();
				} else {
					this.fetchDsDiaDiem();
				}
			}
		},
		'formData.DiaDiem_Id': {
			handler(val) {
				if (this._suppressDiaDiemWatch) return;
				if (val) { this.fetchDsHangHoa(val); }
				else { this.dsOptionHangHoa = []; }
			}
		}
	},
	mounted() {
		window.addEventListener('resize', this._onResize);
		this._onResize();
	},
	beforeUnmount() {
		window.removeEventListener('resize', this._onResize);
	},
	methods: {
		_onResize() {
			this.isMobile = !!window.$isMobile;
		},
		close() { this.internalValue = false; },

		async fetchDsDiaDiemThenEdit() {
			this.isLoadingDiaDiem = true;
			await Promise.all([
				new Promise((resolve) => {
					apiCall('work/HH_DiaDiem_Select', null,
						(res) => { this.dsDiaDiem = res?.data || []; this.isLoadingDiaDiem = false; resolve(); },
						(err) => { this.isLoadingDiaDiem = false; console.error(err); resolve(); }
					);
				}),
				new Promise((resolve) => {
					const selectParams = {
						...(this.schema.select || {}),
						[this.schema.idField]: this.editItemId,
						PageIndex: 1, PageSize: 1,
					};
					apiCall(this.apiConfig.select, selectParams,
						(res) => { this._editRawData = res; resolve(); },
						(err) => {
							console.error('Lỗi load chi tiết đề xuất:', err);
							if (window.showToast) window.showToast.error('Không thể tải dữ liệu đề xuất');
							resolve();
						}
					);
				})
			]);
			this._fillEditForm(this._editRawData);
		},

		_fillEditForm(res) {
			const [, dataDeXuat, dsQuanLy] = res?.data ?? [];
			const item = dataDeXuat?.[0];
			if (!item) return;

			this._suppressDiaDiemWatch = true;
			Object.keys(this.schema.defaultValues || {}).forEach(key => {
				this.formData[key] = item[key] ?? this.schema.defaultValues[key];
			});
			this.formData[this.schema.idField] = this.editItemId;

			this.$nextTick(() => {
				this._suppressDiaDiemWatch = false;
				if (this.formData.DiaDiem_Id) { this.fetchDsHangHoa(this.formData.DiaDiem_Id); }
			});

			// Parse hàng hóa từ JSON string trong response
			let parsedDsHangHoa = [];
			if (item.DanhSachHangHoa) {
				try { parsedDsHangHoa = JSON.parse(item.DanhSachHangHoa); }
				catch (e) { console.error('Lỗi parse DanhSachHangHoa:', e); }
			}
			this.dsHangHoa = parsedDsHangHoa.map(h => ({
				HangHoa_Id: h.HangHoa_Id,
				MaHangHoa: h.MaHangHoa,
				TenHangHoa: h.TenHangHoa,
				TenDonViTinh: h.TenDonViTinh,
				GhiChu: h.GhiChu || '',
			}));

			this.dsNguoiQuanLy = (dsQuanLy ?? [])
				.filter(q => q.DeXuat_MuaHang_Id == this.editItemId)
				.map(p => ({
					NguoiQuanLy_Id: p.NguoiQuanLy_Id,
					HoVaTenNhanVien: p.MaNhanVien ? `${p.MaNhanVien} - ${p.HoVaTenNhanVien}` : (p.HoVaTenNhanVien || ''),
					MaNhanVien: p.MaNhanVien,
					AnhDaiDien_Url: p.AnhDaiDien_Url,
					Is_NguoiDuyet: p.Is_NguoiDuyet === true || p.Is_NguoiDuyet === 1,
				}));
		},

		fetchDsDiaDiem() {
			this.isLoadingDiaDiem = true;
			apiCall('work/HH_DiaDiem_Select', null,
				(res) => { this.dsDiaDiem = res?.data || []; this.isLoadingDiaDiem = false; },
				(err) => { this.isLoadingDiaDiem = false; console.error(err); }
			);
		},

		onFieldChange(key, value) {
			if (key === 'ChinhSach_MuaHang_Id' && value && !this.isEditMode) {
				this.fetchDsNguoiQuanLy(value);
			}
		},

		fetchDsNguoiQuanLy(chinhSachId) {
			apiCall(this.apiConfig.chinhSachSelectById, { ChinhSach_MuaHang_Id: chinhSachId },
				(res) => {
					const dsNguoiQuanLy = res?.data?.[1] || [];
					this.dsNguoiQuanLy = dsNguoiQuanLy.map(p => {
						const hoTen = p.MaNhanVien && !p.HoVaTenNhanVien?.startsWith(p.MaNhanVien)
							? `${p.MaNhanVien} - ${p.HoVaTenNhanVien}`
							: (p.HoVaTenNhanVien || '');
						return {
							NguoiQuanLy_Id: p.NguoiQuanLy_Id || p.NhanVien_Id,
							HoVaTenNhanVien: hoTen,
							MaNhanVien: p.MaNhanVien,
							AnhDaiDien_Url: p.AnhDaiDien_Url,
							Is_NguoiDuyet: p.Is_NguoiDuyet === true || p.Is_NguoiDuyet === 1,
						};
					});
				},
				(err) => {
					if (window.showToast) window.showToast.error('Lỗi tải danh sách người duyệt: ' + (err?.Message || 'Lỗi hệ thống'));
				}
			);
		},

		fetchDsHangHoa(diaDiemId) {
			this.isLoadingHangHoa = true;
			apiCall('work/HH_HangHoa_Select_DropDown_By_DiaDiem_Id', { DiaDiem_Id: diaDiemId },
				(res) => {
					this.dsOptionHangHoa = (res?.data || []).map(item => ({
						...item,
						DisplayText: `${item.LoaiHangHoa} - ${item.TenHangHoa}`
					}));
					this.isLoadingHangHoa = false;
				},
				(err) => {
					this.isLoadingHangHoa = false;
					if (window.showToast) window.showToast.error('Lỗi tải danh sách hàng hóa: ' + (err?.Message || 'Lỗi hệ thống'));
				}
			);
		},

		onSelectDiaDiemDirect(val) {
			const obj = this.dsDiaDiem.find(x => x.DiaDiem_Id === val);
			this.formData.TieuDe = obj ? obj.TenDiaDiem : '';
		},

		onSelectHangHoa(item) {
			if (!item) return;
			if (this.dsHangHoa.find(p => p.HangHoa_Id === item.HangHoa_Id)) {
				showToast.error('Hàng hóa này đã được chọn');
				this.$nextTick(() => { this.selectedHangHoa = null; this.searchHangHoa = null; });
				return;
			}
			this.dsHangHoa.push({
				HangHoa_Id: item.HangHoa_Id || item.value,
				MaHangHoa: item.MaHangHoa,
				TenHangHoa: item.TenHangHoa,
				TenDonViTinh: item.TenDonViTinh || item.DonViTinh,
				GhiChu: ''
			});
			this.$nextTick(() => { this.selectedHangHoa = null; this.searchHangHoa = null; });
		},

		onRemoveHangHoa(index) { this.dsHangHoa.splice(index, 1); },

		onSelectNhanVien(item, isDuyet) {
			if (!item) return;
			const nhanVienId = item.NhanVien_Id || item.value;
			if (this.dsNguoiQuanLy.find(p => p.NguoiQuanLy_Id === nhanVienId)) {
				showToast.error('Nhân viên này đã được chọn');
				return;
			}
			const displayFullName = item.title || (item.MaNhanVien
				? `${item.MaNhanVien} - ${item.HoVaTenNhanVien || item.TenNhanVien}`
				: (item.HoVaTenNhanVien || item.TenNhanVien));
			this.dsNguoiQuanLy.push({
				NguoiQuanLy_Id: nhanVienId,
				HoVaTenNhanVien: displayFullName,
				MaNhanVien: item.MaNhanVien || '',
				AnhDaiDien_Url: item.AnhDaiDien_Url,
				Is_NguoiDuyet: isDuyet === 1,
			});
		},

		onRemoveNguoiQuanLyAt(item) {
			const index = this.dsNguoiQuanLy.findIndex(p => p.NguoiQuanLy_Id === item.NguoiQuanLy_Id);
			if (index > -1) this.dsNguoiQuanLy.splice(index, 1);
		},

		async submit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				if (window.showToast) window.showToast.error('Vui lòng nhập đầy đủ thông tin bắt buộc');
				// Mobile: tự động nhảy về tab có lỗi
				if (this.$isMobile) {
					if (!this.formData.ChinhSach_MuaHang_Id || !this.formData.DiaDiem_Id) {
						this.mobileFormTab = 'info';
					}
				}
				return;
			}
			if (this.dsHangHoa.length === 0) {
				if (window.showToast) window.showToast.error('Vui lòng chọn ít nhất 1 hàng hóa');
				if (this.$isMobile) this.mobileFormTab = 'hanghoa';
				return;
			}

			const payload = {};
			Object.keys(this.schema.defaultValues || {}).forEach(key => {
				payload[key] = this.formData[key];
			});
			payload.HangHoa_JSON = JSON.stringify(
				this.dsHangHoa.map(p => ({ HangHoa_Id: p.HangHoa_Id, GhiChu: p.GhiChu }))
			);
			payload.NguoiQuanLy_JSON = JSON.stringify(
				this.dsNguoiQuanLy.map(p => ({ NguoiQuanLy_Id: p.NguoiQuanLy_Id, Is_NguoiDuyet: p.Is_NguoiDuyet }))
			);
			payload.NhanVien_Id = vueData.user.NhanVien_Id;
			if (this.isEditMode) { payload[this.schema.idField] = this.editItemId; }

			const apiEndpoint = this.isEditMode ? this.apiConfig.update : this.apiConfig.insert;
			const successMsg = this.isEditMode ? 'Cập nhật đề xuất thành công!' : 'Tạo đề xuất thành công!';

			this.isLoading = true;
			apiCall(
				apiEndpoint, payload,
				() => {
					this.isLoading = false;
					showToast.success(successMsg);
					this.$emit('onReload');
					this.close();
				}
			);
		}
	}
}
</script>