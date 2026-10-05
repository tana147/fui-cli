<template>
	<z-layout>
		<v-navigation-drawer permanent>
			<v-list-item>
				<template #title><b>Loại đề xuất</b> </template>
			</v-list-item>
			<v-list-item link v-for="item in navigations" :key="item.key" :title="item.label"
				:active="activeNavigation[0] === item.key" @click="activeNavigation = [item.key]" color="primary"
				class="mx-2 mb-1 rounded-lg" nav>
				<template #prepend>
					<v-icon :icon="item.icon" size="18"></v-icon>
				</template>
				<template #append>
					<v-icon v-if="activeNavigation[0] === item.key" icon="mdi-chevron-right" size="20"></v-icon>
				</template>
			</v-list-item>
		</v-navigation-drawer>
		<v-app-bar density="compact" :elevation="0" class="border-b">
			<v-toolbar-title class="">
				<b>Cấu hình đề xuất {{ getNavigation.label.toLowerCase() }}</b>
			</v-toolbar-title>

			<v-btn variant="flat" class="mr-2" color="primary" @click="openCreate">
				<v-icon icon="mdi-plus" size="24"></v-icon>
				Thêm mới
			</v-btn>
		</v-app-bar>
		<v-container fluid class="d-flex justify-center pa-0" style="height: 100%;">
			<v-data-table :headers="getHeaders || []" :items="dsChinhSach" :loading="isLoadingTable" :search="search"
				class="elevation-0" density="compact" hover items-per-page-text="Bản ghi"
				:items-per-page-options="[50, 100, 150, 200]" no-data-text="Không tìm thấy dữ liệu">

				<template v-slot:item.stt="{ index }">
					<div class="text-center">{{ (index + 1).toString().padStart(2, '0') }}</div>
				</template>

				<template v-slot:item.tenChinhSach="{ item, column }">
					<div class="font-weight-bold cursor-pointer text-primary" @click="onEdit(item)">
						{{ item[column.dataIndex] }}
					</div>
					<div v-if="column.subDataIndex" class="text-caption text-grey-darken-1">
						{{ item[column.subDataIndex] }}
					</div>
				</template>

				<template v-slot:item.isTamKhoa="{ item, column }">
					<v-chip size="small" :color="item[column.dataIndex] ? 'error' : 'success'" variant="tonal" filter
						label>
						<v-icon start size="14">{{ item[column.dataIndex] ? 'mdi-lock' : 'mdi-check-circle' }}</v-icon>
						{{ item[column.dataIndex] ? 'Tạm khóa' : 'Hoạt động' }}
					</v-chip>
				</template>

				<template v-slot:item.khoaNhanh="{ item }">
					<div class="d-flex justify-center">
						<v-switch :model-value="item.Is_TamKhoa" color="error" hide-details density="compact"
							@update:model-value="onToggleKhoaNhanh(item)" class="uc-switch-small"></v-switch>
					</div>
				</template>

				<template v-slot:item.Actions="{ item }">
					<v-btn icon="mdi-delete-outline" variant="text" size="small" color="error"
						@click="onDelete(item)"></v-btn>
				</template>
			</v-data-table>
		</v-container>

		<!-- Modals -->
		<uc-modal-add-chinh-sach v-model="isShowModalAdd" :schema="getParams.insert" :apiConfig="getApi"
			@onReload="fetchDsChinhSach" />
		<uc-modal-edit-chinh-sach v-model="isShowModalEdit" :schema="getParams.insert" :apiConfig="getApi"
			:editId="editItemId" :idKey="getParams.idField" @onReload="fetchDsChinhSach" />
	</z-layout>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				activeNavigation: ["1"],
				isLoadingTable: false,
				isShowModalAdd: false,
				isShowModalEdit: false,
				editItemId: null,
				search: "",
				navigations: [
					{ key: '1', label: 'Mua hàng', icon: 'mdi-cart-outline', },
					// { key: '2', label: 'Bảo trì | Sửa chữa', icon: 'mdi-wrench-outline' },
				],
				headers: {
					1: [
						{ title: '#', key: 'stt', width: 50, align: 'center', sortable: false },
						{ title: 'Tên chính sách', key: 'tenChinhSach', dataIndex: 'TenChinhSach_MuaHang', subDataIndex: 'MaChinhSach_MuaHang', width: 280 },
						{ title: 'Mô tả', key: 'MoTa', minWidth: 250 },
						{ title: 'Trạng thái', key: 'isTamKhoa', dataIndex: 'Is_TamKhoa', align: 'center', width: 120 },
						{ title: 'Khóa nhanh', key: 'khoaNhanh', width: 120, align: 'center', sortable: false },
						{ title: '', key: 'Actions', align: 'center', width: 80, sortable: false },
					]
				},
				apiChinhSach: {
					1: {
						select: 'work/HH_ChinhSach_MuaHang_Select',
						selectById: 'work/HH_ChinhSach_MuaHang_Select_By_Id',
						update: 'work/HH_ChinhSach_MuaHang_Update',
						insert: 'work/HH_ChinhSach_MuaHang_Insert',
						delete: 'work/HH_ChinhSach_MuaHang_Delete',
						nguoiQuanLyInsert: 'work/HH_ChinhSach_MuaHang_NguoiQuanLy_Insert',
						nguoiQuanLyDelete: 'work/HH_ChinhSach_MuaHang_NguoiQuanLy_Delete',
						nguoiQuanLyUpdate: 'work/HH_ChinhSach_MuaHang_NguoiQuanLy_Update',
					}
				},
				paramsApiChinhSach: {
					1: {
						idField: 'ChinhSach_MuaHang_Id', // Tên field ID dùng cho selectById, update
						selectById: {
							ChinhSach_MuaHang_Id: null,
						},
						insert: {
							// Giá trị mặc định khi mở form tạo mới
							defaultValues: {
								ListNhomNhanVien_Id: [],
								TenChinhSach_MuaHang: null,
								MaChinhSach_MuaHang: null,
								MoTa: "",
								GioiHan_GioDuyet: 0,
								GioiHan_NgayDeXuat: 0,
								Is_QuanLyTrucTiep_Duyet: false,
								Is_QuanLyTrucTiep_TheoDoi: false,
								Is_TamKhoa: false,
								NguoiQuanLy_JSON: [],
							},
							// Schema fields: quy định render form & validate
							fields: [
								{
									key: 'TenChinhSach_MuaHang',
									label: 'Tên chính sách',
									component: 'v-text-field',
									props: { placeholder: 'Nhập tên chính sách...' },
									span: 12,
									required: true,
									rules: [(v) => !!v || 'Vui lòng nhập tên chính sách'],
								},
								{
									key: 'MaChinhSach_MuaHang',
									label: 'Mã chính sách',
									component: 'v-text-field',
									props: { placeholder: 'Nhập mã chính sách...' },
									span: 6,
									required: true,
									rules: [(v) => !!v || 'Vui lòng nhập mã chính sách'],
								},
								{
									key: 'ListNhomNhanVien_Id',
									label: 'Nhóm nhân viên',
									component: 'uc-select-nhom-nhan-vien',
									props: {},
									span: 6,
									required: true,
									rules: [(v) => (Array.isArray(v) && v.length > 0) || 'Vui lòng chọn nhóm nhân viên'],
								},
								{
									key: 'GioiHan_GioDuyet',
									label: 'Thời hạn để duyệt',
									tooltip: 'Thời hạn (theo giờ) để duyệt đề xuất',
									component: 'v-text-field',
									props: { type: 'number', suffix: 'Giờ', placeholder: 'Nhập số giờ...' },
									span: 6,
									required: false,
									rules: [],
								},
								{
									key: 'GioiHan_NgayDeXuat',
									label: 'Ngày giới hạn đề xuất',
									tooltip: 'Số ngày tối thiểu tạo trước đề xuất. Điền số âm để cho phép tạo muộn.',
									component: 'v-text-field',
									props: { type: 'number', suffix: 'Ngày', placeholder: 'Nhập số ngày...' },
									span: 6,
									required: false,
									rules: [],
								},
								{
									key: 'MoTa',
									label: 'Mô tả',
									component: 'v-textarea',
									props: { placeholder: 'Nhập mô tả...', rows: 3, 'auto-grow': true },
									span: 12,
									required: false,
									rules: [],
								},
								{
									key: 'Is_QuanLyTrucTiep_Duyet',
									label: 'Cho phép quản lý trực tiếp duyệt',
									component: 'v-checkbox',
									props: { color: 'primary' },
									span: 6,
									required: false,
									rules: [],
								},
								{
									key: 'Is_QuanLyTrucTiep_TheoDoi',
									label: 'Cho phép quản lý trực tiếp theo dõi',
									component: 'v-checkbox',
									props: { color: 'primary' },
									span: 6,
									required: false,
									rules: [],
								},
								{
									key: 'Is_TamKhoa',
									label: 'Tạm khóa',
									component: 'v-checkbox',
									props: { color: 'error' },
									span: 6,
									required: false,
									rules: [],
									editOnly: true, // Chỉ hiển thị khi edit, không hiện khi thêm mới
								},
							]
						},
						nguoiQuanLyInsert: {
							ChinhSach_MuaHang_NguoiQuanLy_Id: null,
							Is_NguoiDuyet: false,
						},
						nguoiQuanLyDelete: {
							ChinhSach_MuaHang_NguoiQuanLy_Id: null
						},
						nguoiQuanLyUpdate: {
							ChinhSach_MuaHang_Id: null,
							Is_NguoiDuyet: false,
						},
					}
				},
				dsChinhSach: [],
	
			}
		},
		mounted() {
			this.fetchDsChinhSach();
		},
		computed: {
			getNavigation() {
				return this.navigations.find(i => i.key == this.activeNavigation[0])
			},
			getApi() {
				return this.apiChinhSach[this.activeNavigation[0]]
			},
			getParams() {
				return this.paramsApiChinhSach[this.activeNavigation[0]]
			},
			getHeaders() {
				return this.headers[this.activeNavigation[0]]
			},
	
		},
		watch: {
			// gọi lại API mỗi khi chuyển sang tab khác, hoặc nhắn vào chính tab đó sẽ refetch data *** tính năng không phải bug
			async activeNavigation() {
				await this.fetchDsChinhSach();
			}
		},
		methods: {
			async fetchDsChinhSach() {
				this.isLoadingTable = true;
				try {
					await apiCall(this.getApi.select, null, (response) => { this.dsChinhSach = response?.data || [] })
				}
				finally {
					this.isLoadingTable = false;
				}
			},
			openCreate() {
				this.isShowModalAdd = true;
			},
			onEdit(item) {
				this.editItemId = item[this.getParams.idField];
				this.isShowModalEdit = true;
			},
			onDelete(item) {
				const tenChinhSach = item[this.getHeaders.find(h => h.key === 'tenChinhSach').dataIndex];
				showConfirm(`Bạn muốn xóa chính sách "${tenChinhSach}"?`, () => {
					apiCall(
						this.getApi.delete,
						{
							[this.getParams.idField]: item[this.getParams.idField],
						},
						() => {
							showToast.success('Xóa thành công');
							this.fetchDsChinhSach();
						},
						(error) => {
							showToast.error('Xóa thất bại: ' + (error?.Message || 'Lỗi không xác định'));
						},
					);
				});
			},
			async onToggleKhoaNhanh(item) {
				const payload = {
					[this.getParams.idField]: item[this.getParams.idField],
					Is_TamKhoa: !item.Is_TamKhoa,
				};
	
				const fields = this.getParams.insert.fields || [];
				fields.forEach(f => {
					if (f.key === 'Is_TamKhoa' || f.key === 'NguoiQuanLy_JSON') return;
					const val = item[f.key];
					if (Array.isArray(val)) {
						payload[f.key] = val.join(',');
					} else if (f.key.startsWith('Is_')) {
						payload[f.key] = !!val;
					} else {
						payload[f.key] = val ?? null;
					}
				});
	
				apiCall(this.getApi.update, payload, (res) => {
					if (window.showToast) window.showToast.success('Cập nhật trạng thái thành công');
					this.fetchDsChinhSach();
				});
			}
		},
	}
</script>