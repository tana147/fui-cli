<template>
	<z-layout>
		<!-- ── DESKTOP APP BAR ── -->
		<v-app-bar v-if="!$isMobile" density="compact" :elevation="0" class="border-b" title="Dữ liệu đề xuất mua hàng">
			<v-spacer></v-spacer>	
			<v-text-field v-model="paramsApiDeXuatInsert.select.TimKiem" placeholder="Tìm kiếm..." density="compact"
				variant="outlined" hide-details clearable prepend-inner-icon="mdi-magnify" style="max-width: 220px;"
				class="mr-2" @update:modelValue="onFilterChange"></v-text-field>
			<v-select v-model="paramsApiDeXuatInsert.select.TrangThai" :items="dsTrangThai" item-title="label"
				item-value="value" density="compact" variant="outlined" hide-details style="max-width: 160px;"
				class="mr-2" @update:modelValue="onFilterChange"></v-select>
			<v-select v-model="paramsApiDeXuatInsert.select.ChinhSach_MuaHang_Id"
				:items="[{ TenChinhSach_MuaHang: 'Tất cả chính sách', ChinhSach_MuaHang_Id: 0 }, ...dsChinhSach]"
				item-title="TenChinhSach_MuaHang" item-value="ChinhSach_MuaHang_Id" density="compact" variant="outlined"
				hide-details style="max-width: 200px;" class="mr-2" @update:modelValue="onFilterChange"></v-select>
			<v-btn variant="flat" class="mr-2" color="primary" @click="openCreate">
				<v-icon icon="mdi-plus" size="24"></v-icon>
				Tạo đề xuất
			</v-btn>
		</v-app-bar>

		<!-- ── DESKTOP TABLE ── -->
		<v-container v-if="!$isMobile" fluid class="d-flex justify-center pa-0" style="height: 100%;">
			<v-data-table :headers="getHeaders" :items="dsDeXuat" :loading="isLoadingTable" class="elevation-0"
				density="compact" hover items-per-page-text="Bản ghi" :items-per-page-options="[50, 100, 150, 200]"
				v-model:items-per-page="paramsApiDeXuatInsert.select.PageSize"
				v-model:page="paramsApiDeXuatInsert.select.PageIndex" :items-length="totalItems"
				no-data-text="Không tìm thấy dữ liệu" @update:items-per-page="onFilterChange"
				@update:page="fetchDsDeXuat">
				<template v-slot:item.stt="{ index }">
					<div class="text-center">{{ (index + 1).toString().padStart(2, '0') }}</div>
				</template>
				
				<!-- trạng thái đã duyệt thì không cho chỉnh sửa -->
				<template v-slot:item.TieuDe="{ item }">
					<div class="font-weight-bold" :class="{ 'cursor-pointer text-primary': !item.Is_Duyet && !item.Is_TuChoi }" @click="!item.Is_Duyet && !item.Is_TuChoi && onEdit(item)">{{ item.TieuDe }}
					</div>

					<div class="text-caption text-grey-darken-1">{{ item.MaChinhSach_MuaHang }}</div>
				</template>
				<template v-slot:item.DanhSachHangHoa="{ item }">
					<div v-if="item._dsHangHoa && item._dsHangHoa.length" class="d-flex flex-column py-1">
						<div v-for="(hh, idx) in item._dsHangHoa" :key="idx" class="text-caption"
							style="line-height:1.2;">
							<v-icon size="14" color="grey-lighten-1" class="mr-1">mdi-circle-small</v-icon>
							<span class="font-weight-medium text-grey-darken-4">{{ hh.TenHangHoa }}</span>
							<span class="text-grey ml-1" v-if="hh.GhiChu">({{ hh.GhiChu }})</span>
						</div>
					</div>
				</template>
				<template v-slot:item.NguoiTao="{ item }">
					<div class="d-flex align-center ga-2">
						<uc-avatar :AnhDaiDien_Url="item.NguoiTao_AnhDaiDien_Url"
							:Ten="item.NguoiTao_HoVaTenNhanVien" />
						<div>
							<div class="font-weight-medium text-no-wrap">{{ item.NguoiTao_HoVaTenNhanVien }}</div>
							<div class="text-caption text-grey-darken-1">{{ item.NgayTao }} {{ item.GioTao }}</div>
						</div>
					</div>
				</template>
				<template v-slot:item.trangThai="{ item }">
					<v-chip size="small" :color="getStatusColor(item)" filter label variant="tonal">{{ getStatusText(item) }}</v-chip>
				</template>
				<template v-slot:item.nguoiDuyet="{ item }">
					<div class="d-flex align-center ga-2" v-if="item.Is_Duyet">
						<uc-avatar :AnhDaiDien_Url="item.Duyet_AnhDaiDien_Url" :Ten="item.Duyet_HoVaTenNhanVien" />
						<div>
							<div class="font-weight-medium text-no-wrap">{{ item.Duyet_HoVaTenNhanVien }}</div>
							<div class="text-caption text-grey-darken-1">{{ item.NgayDuyet }} {{ item.GioDuyet }}</div>
						</div>
					</div>
				</template>
				<template v-slot:item.nguoiTuChoi="{ item }">
					<div class="d-flex align-center ga-2" v-if="item.Is_TuChoi">
						<uc-avatar :AnhDaiDien_Url="item.TuChoi_AnhDaiDien_Url" :Ten="item.TuChoi_HoVaTenNhanVien" />
						<div>
							<div class="font-weight-medium text-no-wrap">{{ item.TuChoi_HoVaTenNhanVien }}</div>
							<div class="text-caption text-grey-darken-1">{{ item.NgayTuChoi }} {{ item.GioTuChoi }}
							</div>
						</div>
					</div>
				</template>
				<template v-slot:item.Actions="{ item }">
					<v-menu v-if="!item.Is_Duyet && !item.Is_TuChoi">
						<template v-slot:activator="{ props }">
							<v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="props"></v-btn>
						</template>
						<v-list density="compact" min-width="160">
							<v-list-item prepend-icon="mdi-check-circle-outline" title="Duyệt"
								@click="onDuyet(item)"></v-list-item>
							<v-list-item prepend-icon="mdi-close-circle-outline" title="Từ chối" class="text-error"
								@click="openTuChoi(item)"></v-list-item>
						</v-list>
					</v-menu>
				</template>
			</v-data-table>
		</v-container>

		<!-- ══════════════════════════════════════════════════════════════ -->
		<!-- ── MOBILE VIEW ──                                             -->
		<!-- ══════════════════════════════════════════════════════════════ -->
		<template v-if="$isMobile">
			<!-- Mobile Header -->
			<v-app-bar density="compact" :elevation="0" class="border-b" color="white">
				<v-toolbar-title class="text-subtitle-1 font-weight-bold text-primary">
					Đề xuất mua hàng
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon variant="text" @click="isMobileSearchOpen = !isMobileSearchOpen">
					<v-icon>{{ isMobileSearchOpen ? 'mdi-close' : 'mdi-magnify' }}</v-icon>
				</v-btn>
			</v-app-bar>

			<div style="flex:1; display:flex; flex-direction:column; overflow:hidden;">
				<!-- Search bar collapse -->
				<v-expand-transition>
					<div v-if="isMobileSearchOpen" class="px-3 pt-2 pb-1 bg-white border-b">
						<v-text-field v-model="paramsApiDeXuatInsert.select.TimKiem" placeholder="Tìm kiếm đề xuất..."
							density="compact" variant="outlined" hide-details clearable autofocus
							prepend-inner-icon="mdi-magnify" @update:modelValue="onFilterChange"></v-text-field>
					</div>
				</v-expand-transition>

				<!-- Filter chips -->
				<div class="px-3 py-2 bg-white border-b d-flex ga-2"
					style="overflow-x:auto; white-space:nowrap; scrollbar-width:none;">
					<v-chip v-for="t in dsTrangThai" :key="t.value" size="small"
						:variant="paramsApiDeXuatInsert.select.TrangThai === t.value ? 'flat' : 'outlined'"
						:color="paramsApiDeXuatInsert.select.TrangThai === t.value ? 'primary' : 'default'"
						class="cursor-pointer" @click="onMobileFilterTrangThai(t.value)">{{ t.label }}</v-chip>
				</div>

				<!-- Card list -->
				<div style="flex:1; overflow-y:auto; min-height:calc(100vh - 205px); max-height:calc(100vh - 205px);" class="pa-3 d-flex flex-column ga-3 bg-grey-lighten-5">
					<!-- Loading skeleton -->
					<template v-if="isLoadingTable">
						<v-skeleton-loader v-for="i in 4" :key="i" type="list-item-three-line"
							class="rounded-lg"></v-skeleton-loader>
					</template>

					<!-- Empty state -->
					<div v-else-if="!dsDeXuat.length" class="d-flex flex-column align-center justify-center"
						style="height:200px;">
						<v-icon size="48" color="grey-lighten-2">mdi-folder-search-outline</v-icon>
						<p class="text-caption text-grey mt-2">Chưa có dữ liệu</p>
					</div>

					<!-- Cards -->
					<v-card v-else v-for="item in dsDeXuat" :key="item.DeXuat_MuaHang_Id" variant="flat"
@click="!item.Is_Duyet && !item.Is_TuChoi && onEdit(item)">

						<v-card-text class="pa-3">
							<!-- Row 1: Tiêu đề + badge trạng thái -->
							<div class="d-flex justify-space-between align-start mb-1">
								<div class="font-weight-medium text-body-2 text-primary"
									style="flex:1; margin-right:8px; line-height:1.3;">
									{{ item.TieuDe }}
								</div>
								<v-chip size="x-small" :color="getStatusColor(item)" variant="flat"
									style="flex-shrink:0;">
									{{ getStatusText(item) }}
								</v-chip>
							</div>

							<!-- Row 2: Mã chính sách + ngày -->
							<div class="d-flex justify-space-between align-center mb-2">
								<span class="text-caption text-grey-darken-1">{{ item.MaChinhSach_MuaHang }}</span>
								<span class="text-caption text-grey-darken-1">{{ item.NgayTao }} {{ item.GioTao }}</span>
							</div>

							<!-- Danh sách hàng hóa -->
							<div v-if="item._dsHangHoa && item._dsHangHoa.length" class="mb-2">
								<div v-for="(hh, idx) in item._dsHangHoa.slice(0, 3)" :key="idx"
									class="text-caption text-grey-darken-2 d-flex align-center"
									style="line-height:1.6;">
									<v-icon size="10" color="grey" class="mr-1">mdi-circle-small</v-icon>
									<span>{{ hh.TenHangHoa }}</span>
									<span v-if="hh.GhiChu" class="text-grey ml-1">({{ hh.GhiChu }})</span>
								</div>
								<div v-if="item._dsHangHoa.length > 3" class="text-caption text-grey">
									+{{ item._dsHangHoa.length - 3 }} mặt hàng khác
								</div>
							</div>

							<!-- Divider -->
							<v-divider class="mb-2"></v-divider>

							<!-- Row bottom: Người tạo + action button -->
							<div class="d-flex justify-space-between align-center">
								<div class="d-flex align-center ga-2">
									<uc-avatar :AnhDaiDien_Url="item.NguoiTao_AnhDaiDien_Url"
										:Ten="item.NguoiTao_HoVaTenNhanVien" size="24" />
									<div>
										<div class="text-caption font-weight-medium">{{ item.NguoiTao_HoVaTenNhanVien }}
										</div>
										<div class="text-caption text-grey" style="font-size:10px;">{{
											item.NguoiTao_MaNhanVien }}</div>
									</div>
								</div>
								<!-- Nút 3 chấm chỉ hiện khi Chờ duyệt -->
								<v-btn v-if="!item.Is_Duyet && !item.Is_TuChoi" icon="mdi-dots-vertical" variant="text"
									size="small" @click.stop="openMobileAction(item)"></v-btn>
							</div>

							<!-- Người duyệt / từ chối -->
							<template v-if="item.Is_Duyet">
								<v-divider class="my-2"></v-divider>
								<div class="d-flex align-center ga-2">
									<uc-avatar :AnhDaiDien_Url="item.Duyet_AnhDaiDien_Url"
										:Ten="item.Duyet_HoVaTenNhanVien" size="22" />
									<div class="text-caption">
										<span class="text-success font-weight-medium">Đã duyệt</span> bởi {{
											item.Duyet_HoVaTenNhanVien }}
										· {{ item.NgayDuyet }}
									</div>
								</div>
							</template>
							<template v-if="item.Is_TuChoi">
								<v-divider class="my-2"></v-divider>
								<div class="d-flex align-center ga-2">
									<uc-avatar :AnhDaiDien_Url="item.TuChoi_AnhDaiDien_Url"
										:Ten="item.TuChoi_HoVaTenNhanVien" size="22" />
									<div class="text-caption">
										<span class="text-error font-weight-medium">Từ chối</span> bởi {{
											item.TuChoi_HoVaTenNhanVien }}
										· {{ item.NgayTuChoi }}
									</div>
								</div>
							</template>
						</v-card-text>
					</v-card>
					<!-- Thêm một khoảng trống ở cuối list để scroll mượt hơn -->
					<div class="py-1"></div>
				</div>

				<!-- Mobile Footer: Nút tạo đề xuất -->
				<div class="pa-3 bg-white border-t shrink-0">
					<v-btn block color="primary" variant="flat" size="large" @click="openCreate">
						<v-icon start>mdi-plus</v-icon>
						TẠO ĐỀ XUẤT
					</v-btn>
				</div>
			</div>

			<!-- ── Bottom Sheet: Action (Duyệt / Từ chối / Chỉnh sửa) ── -->
			<v-bottom-sheet v-model="isMobileActionSheetOpen" inset>
				<v-card rounded="t-xl">
					<div class="d-flex justify-center pt-3 pb-1">
						<div style="width:36px; height:4px; border-radius:2px; background:#e0e0e0;"></div>
					</div>
					<v-list-item v-if="mobileActionItem" :title="mobileActionItem.TieuDe"
						:subtitle="mobileActionItem.MaChinhSach_MuaHang" class="px-4 pb-2"></v-list-item>
					<v-divider></v-divider>
					<v-list density="comfortable">
						<v-list-item prepend-icon="mdi-pencil-outline" title="Chỉnh sửa"
							@click="onMobileEdit(mobileActionItem)"></v-list-item>
						<v-list-item prepend-icon="mdi-check-circle-outline" title="Duyệt" base-color="success"
							@click="onMobileDuyet(mobileActionItem)"></v-list-item>
						<v-list-item prepend-icon="mdi-close-circle-outline" title="Từ chối" base-color="error"
							@click="onMobileTuChoi(mobileActionItem)"></v-list-item>
					</v-list>
					<div class="pa-3">
						<v-btn block variant="text" @click="isMobileActionSheetOpen = false">Hủy</v-btn>
					</div>
				</v-card>
			</v-bottom-sheet>

			<!-- ── Bottom Sheet: Nhập lý do từ chối ── -->
			<v-bottom-sheet v-model="isMobileTuChoiSheetOpen" inset persistent>
				<v-card rounded="t-xl">
					<div class="d-flex justify-center pt-3 pb-1">
						<div style="width:36px; height:4px; border-radius:2px; background:#e0e0e0;"></div>
					</div>
					<v-card-text class="px-4 pt-2 pb-3">
						<div class="text-subtitle-2 font-weight-bold mb-1">Từ chối đề xuất</div>
						<div class="text-caption text-grey-darken-1 mb-3">{{ tuChoiItem?.TieuDe }}</div>
						<div class="text-caption mb-1">Lý do từ chối <span class="text-error">*</span></div>
						<v-textarea v-model="lyDoTuChoi" density="compact" variant="outlined" hide-details="auto"
							placeholder="Nhập lý do từ chối..." rows="3" auto-grow></v-textarea>
					</v-card-text>
					<v-card-actions class="px-4 pb-4 pt-0 gap-2">
						<v-btn variant="outlined" @click="isMobileTuChoiSheetOpen = false" style="flex:1;">Hủy</v-btn>
						<v-btn variant="flat" color="error" :loading="isLoadingTuChoi" @click="submitTuChoi"
							style="flex:2;">
							<v-icon start>mdi-close-circle</v-icon>Xác nhận từ chối
						</v-btn>
					</v-card-actions>
				</v-card>
			</v-bottom-sheet>
		</template>
		<!-- ══ END MOBILE ══ -->

		<!-- Modal Tạo mới -->
		<uc-modal-add-mua-hang v-model="isShowModalAdd" :apiConfig="apiDeXuat" :schema="paramsApiDeXuatInsert"
			:dsChinhSach="dsChinhSach" @onReload="fetchDsDeXuat" />

		<!-- Modal Chỉnh sửa -->
		<uc-modal-add-mua-hang v-model="isShowModalEdit" :apiConfig="apiDeXuat" :schema="paramsApiDeXuatInsert"
			:dsChinhSach="dsChinhSach" :editItemId="editItemId" @onReload="fetchDsDeXuat" />

		<!-- Dialog Từ chối (desktop) -->
		<v-dialog v-model="isShowDialogTuChoi" max-width="460" persistent>
			<v-card>
				<v-toolbar color="error" density="compact">
					<v-toolbar-title class="text-subtitle-1 font-weight-bold">Từ chối đề xuất</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-icon @click="isShowDialogTuChoi = false" class="mr-5">mdi-close</v-icon>
				</v-toolbar>
				<v-card-text class="pa-4">
					<div class="text-body-2 mb-3">Đề xuất: <strong>{{ tuChoiItem?.TieuDe }}</strong></div>
					<div class="text-subtitle-2 mb-1">Lý do từ chối <span class="text-error">*</span></div>
					<v-textarea v-model="lyDoTuChoi" density="compact" variant="outlined" hide-details="auto"
						placeholder="Nhập lý do từ chối..." rows="3" auto-grow></v-textarea>
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="isShowDialogTuChoi = false">Hủy</v-btn>
					<v-btn variant="flat" color="error" :loading="isLoadingTuChoi" @click="submitTuChoi" width="100">
						<v-icon start>mdi-close-circle</v-icon>Từ chối
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</z-layout>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			isLoadingTable: false,
			isShowModalAdd: false,
			isShowModalEdit: false,
			editItemId: null,
			totalItems: 0,
			_filterTimeout: null,
			// Desktop - từ chối dialog
			isShowDialogTuChoi: false,
			isLoadingTuChoi: false,
			tuChoiItem: null,
			lyDoTuChoi: '',
			// Mobile state
			isMobileSearchOpen: false,
			isMobileActionSheetOpen: false,
			isMobileTuChoiSheetOpen: false,
			mobileActionItem: null,
			dsTrangThai: [
				{ label: 'Tất cả', value: 0 },
				{ label: 'Chờ duyệt', value: 1 },
				{ label: 'Đã duyệt', value: 2 },
				{ label: 'Từ chối', value: 3 },
			],
			apiDeXuat: {
				select: 'work/HH_DeXuat_MuaHang_Select',
				insert: 'work/HH_DeXuat_MuaHang_Insert',
				update: 'work/HH_DeXuat_MuaHang_Update',
				duyet: 'work/HH_DeXuat_MuaHang_Duyet',
				tuChoi: 'work/HH_DeXuat_MuaHang_TuChoi',
				delete: 'work/HH_DeXuat_MuaHang_Delete',
				chinhSachSelect: 'work/HH_ChinhSach_MuaHang_Select',
				chinhSachSelectById: 'work/HH_ChinhSach_MuaHang_Select_By_Id',
			},
			paramsApiDeXuatInsert: {
				idField: 'DeXuat_MuaHang_Id',
				defaultValues: {
					TieuDe: '',
					ChinhSach_MuaHang_Id: null,
					DiaDiem_Id: null,
					MoTa: '',
				},
				select: {
					TimKiem: "",
					TrangThai: 0,
					ChinhSach_MuaHang_Id: 0,
					PageIndex: 1,
					PageSize: 50,
				},
			},
			dsDeXuat: [],
			dsChinhSach: [],
		}
	},
	mounted() {
		this.fetchMyInfo();
		this.fetchDsDeXuat();
		this.fetchDataDependencies();
	},
	computed: {
		getHeaders() {
			return HEADERS_BY_TRANGTHAI[this.paramsApiDeXuatInsert.select.TrangThai]
				?? HEADERS_BY_TRANGTHAI[0];
		},
		$isMobile() {
			return !!window.$isMobile;
		},
	},
	methods: {
		onFilterChange() {
			clearTimeout(this._filterTimeout);
			this._filterTimeout = setTimeout(() => {
				this.paramsApiDeXuatInsert.select.PageIndex = 1;
				this.fetchDsDeXuat();
			}, 300);
		},

		// ── Mobile tab ──────────────────────────────────────────────────
		onMobileTabChange(val) {
			// val: 'mine' | 'forme'
			if (val === 'forme') {
				this.paramsApiDeXuatInsert.select.IsGuiChoToi = 1;
			} else {
				this.paramsApiDeXuatInsert.select.IsGuiChoToi = null;
			}
			this.onFilterChange();
		},
		onMobileFilterTrangThai(val) {
			this.paramsApiDeXuatInsert.select.TrangThai = val;
			this.onFilterChange();
		},

		// ── Mobile action sheet ─────────────────────────────────────────
		openMobileAction(item) {
			this.mobileActionItem = item;
			this.isMobileActionSheetOpen = true;
		},
		onMobileEdit(item) {
			this.isMobileActionSheetOpen = false;
			this.$nextTick(() => { this.onEdit(item); });
		},
		onMobileDuyet(item) {
			this.isMobileActionSheetOpen = false;
			this.$nextTick(() => { this.onDuyet(item); });
		},
		onMobileTuChoi(item) {
			this.isMobileActionSheetOpen = false;
			this.$nextTick(() => {
				this.tuChoiItem = item;
				this.lyDoTuChoi = '';
				this.isMobileTuChoiSheetOpen = true;
			});
		},

		fetchMyInfo() {
			apiCall(
				'/work/HR_NhanVien_Select_Search',
				{ TimKiem: vueData.user.UserID },
				(res) => { vueData.user.NhanVien_Id = res?.data[0]?.NhanVien_Id || null; }
			);
		},
		fetchDataDependencies() {
			apiCall(this.apiDeXuat.chinhSachSelect, null, (res) => {
				this.dsChinhSach = res?.data.filter(x => !x.Is_TamKhoa) || [];
			});
		},
		async fetchDsDeXuat() {
			this.isLoadingTable = true;
			try {
				await apiCall(this.apiDeXuat.select, this.paramsApiDeXuatInsert.select, (response) => {
					const [pagination, dataDeXuat, dsQuanLy] = response?.data ?? [];
					this.totalItems = pagination?.[0]?.TotalRow ?? 0;
					this.dsDeXuat = (dataDeXuat ?? []).map(item => {
						let _dsHangHoa = [];
						if (item.DanhSachHangHoa) {
							try { _dsHangHoa = JSON.parse(item.DanhSachHangHoa); }
							catch (e) { console.error('Lỗi parse DanhSachHangHoa:', e); }
						}
						return {
							...item,
							_dsHangHoa,
							dsNguoiDuyet: (dsQuanLy ?? []).filter(q => q.DeXuat_MuaHang_Id === item.DeXuat_MuaHang_Id && q.Is_NguoiDuyet),
							dsNguoiTheoDoi: (dsQuanLy ?? []).filter(q => q.DeXuat_MuaHang_Id === item.DeXuat_MuaHang_Id && !q.Is_NguoiDuyet),
						};
					});
				});
			} finally {
				this.isLoadingTable = false;
			}
		},
		openCreate() {
			this.isShowModalAdd = true;
		},
		onEdit(item) {
			this.editItemId = item[this.paramsApiDeXuatInsert.idField];
			this.isShowModalEdit = true;
		},
		onDuyet(item) {
			showConfirm(`Xác nhận duyệt đề xuất "${item.TieuDe}"?`, () => {
				apiCall(
					this.apiDeXuat.duyet,
					{ DeXuat_MuaHang_Id: item[this.paramsApiDeXuatInsert.idField] },
					() => {
						showToast.success('Duyệt thành công');
						this.fetchDsDeXuat();
					}
				);
			});
		},
		openTuChoi(item) {
			this.tuChoiItem = item;
			this.lyDoTuChoi = '';
			// Desktop dùng dialog, mobile dùng bottom sheet
			if (this.$isMobile) {
				this.isMobileTuChoiSheetOpen = true;
			} else {
				this.isShowDialogTuChoi = true;
			}
		},
		submitTuChoi() {
			if (!this.lyDoTuChoi?.trim()) {
				showToast.error('Vui lòng nhập lý do từ chối');
				return;
			}
			this.isLoadingTuChoi = true;
			apiCall(
				this.apiDeXuat.tuChoi,
				{
					DeXuat_MuaHang_Id: this.tuChoiItem[this.paramsApiDeXuatInsert.idField],
					LyDoTuChoi: this.lyDoTuChoi.trim(),
				},
				() => {
					showToast.success('Đã từ chối đề xuất');
					this.isShowDialogTuChoi = false;
					this.isMobileTuChoiSheetOpen = false;
					this.isLoadingTuChoi = false;
					this.fetchDsDeXuat();
				},
				(err) => {
					this.isLoadingTuChoi = false;
					showToast.error('Lỗi: ' + (err?.Message || 'Không thể từ chối'));
				}
			);
		},
		getStatusColor(item) {
			if (item.Is_TuChoi) return 'error';
			if (item.Is_Duyet) return 'success';
			return 'warning';
		},
		getStatusText(item) {
			if (item.Is_TuChoi) return 'Từ chối';
			if (item.Is_Duyet) return 'Đã duyệt';
			return 'Chờ duyệt';
		},
	},
}
</script>