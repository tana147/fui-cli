<template>
	<div class="article-table-section">
		<v-card class="article-table-card rounded-xs" outlined>
			<v-card-title class="pa-3 d-flex flex-wrap align-center justify-space-between">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Danh sách đề xuất khen thưởng Cuộc thi & SHTT
				</span>
				<div class="d-flex align-center flex-wrap">
					<v-btn icon color="success" class="mr-2" @click="onExportExcel" title="Xuất file Excel">
						<v-icon>mdi-microsoft-excel</v-icon>
					</v-btn>
					<v-text-field v-model="search" class="c-underline-search mr-3 article-search-input" prepend-inner-icon="mdi-magnify"
						label="Tìm kiếm nhanh..." dense hide-details single-line clearable></v-text-field>
					<v-btn color="primary" small elevation="0" @click="openAdd">
						<v-icon left small>mdi-plus</v-icon>Thêm đề xuất
					</v-btn>
				</div>
			</v-card-title>

			<v-card-text class="pa-0 flex-grow-1 overflow-hidden">
				<v-data-table dense fixed-header height="calc(100vh - 380px)" :headers="tableHeaders"
					:items="formattedItems" :search="search" :loading="!isTableReady" :items-per-page="50"
					:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }">
					<template v-slot:item.TrangThaiText="{ item }">
						<v-tooltip bottom v-if="item.TrangThai === 4 && item.LyDoReject">
							<template v-slot:activator="{ on, attrs }">
								<v-chip x-small color="error" outlined v-bind="attrs" v-on="on">
									{{ item.TrangThaiText }}
									<v-icon right x-small>mdi-alert-circle-outline</v-icon>
								</v-chip>
							</template>
							<span>Lý do: {{ item.LyDoReject }}</span>
						</v-tooltip>
						<v-chip x-small v-else :color="getStatusColor(item.TrangThai)" outlined>
							{{ item.TrangThaiText }}
						</v-chip>
					</template>

					<template v-slot:item.TongTienThuong="{ item }">
						<span class="font-weight-medium">{{ formatCurrency(item.TongTienThuong) }}</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<div class="d-flex align-center justify-center">
							<v-icon
								small
								:color="item.TrangThai === 2 || item.TrangThai === 3 ? 'primary' : 'green darken-2'"
								class="mr-2"
								:title="item.TrangThai === 2 || item.TrangThai === 3 ? 'Xem chi tiết' : 'Chỉnh sửa'"
								@click="editItem(item)">
								{{ item.TrangThai === 2 || item.TrangThai === 3 ? 'mdi-eye-outline' : 'mdi-square-edit-outline' }}
							</v-icon>
							<v-icon
								v-if="item.TrangThai === 1 || item.TrangThai === 4"
								small
								color="red darken-3"
								title="Xóa đề xuất"
								@click="deleteItem(item)">
								mdi-trash-can-outline
							</v-icon>
						</div>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: 'uc-main-view',
		props: {
			tableRows: { type: Array, default: () => [] },
			isTableReady: { type: Boolean, default: true },
		},
		emits: ['on-add', 'on-edit', 'on-delete'],
		data() {
			return {
				search: '',
				tableHeaders: [
					{ text: '#', value: 'STT', align: 'center', width: 50, sortable: false },
					{ text: 'Tên cuộc thi / Công trình', value: 'TenCuocThi_CongTrinh', width: 260 },
					{ text: 'Phân loại', value: 'TenLoaiKhenThuong', width: 140 },
					{ text: 'Cấp độ', value: 'TenCapDo', width: 130 },
					{ text: 'Giải thưởng / Bằng', value: 'TenGiaiThuong', width: 140 },
					{ text: 'Số QĐ / Bằng', value: 'SoQuyetDinh_VanBang', width: 130 },
					{ text: 'Ngày BH', value: 'NgayBanHanhFormatted', align: 'center', width: 110 },
					{ text: 'Tiền thưởng (đ)', value: 'TongTienThuong', align: 'right', width: 130 },
					{ text: 'Trạng thái', value: 'TrangThaiText', align: 'center', width: 120 },
					{ text: 'Thao tác', value: 'actions', align: 'center', width: 90, sortable: false },
				],
			}
		},
		computed: {
			formattedItems() {
				return (this.tableRows || []).map((item, index) => {
					let tenLoai = ''
					if (item.LoaiKhenThuong === 1) {
						tenLoai = item.LoaiHinhCuocThi === 2 ? 'Cuộc thi Học thuật' : 'Cuộc thi KH&CN'
					} else if (item.LoaiKhenThuong === 2) {
						tenLoai = 'SHTT (Chấp nhận đơn)'
					} else if (item.LoaiKhenThuong === 3) {
						tenLoai = 'SHTT (Cấp văn bằng)'
					}

					let tenCapDo = ''
					switch (item.CapDoCuocThi) {
						case 1: tenCapDo = 'Quốc tế'; break
						case 2: tenCapDo = 'Khu vực QT'; break
						case 3: tenCapDo = 'Quốc gia'; break
						case 4: tenCapDo = 'Khu vực trong nước'; break
						case 5: tenCapDo = 'Cấp tỉnh'; break
						case 6: tenCapDo = 'Cấp trường'; break
						default: tenCapDo = ''
					}

					let tenGiai = ''
					if (item.LoaiKhenThuong === 1) {
						switch (item.GiaiThuong) {
							case 1: tenGiai = 'Giải Nhất'; break
							case 2: tenGiai = 'Giải Nhì'; break
							case 3: tenGiai = 'Giải Ba'; break
							case 4: tenGiai = 'Khuyến khích'; break
							case 5: tenGiai = 'Báo cáo ngày hội'; break
							default: tenGiai = ''
						}
					} else {
						switch (item.LoaiSHTT) {
							case 1: tenGiai = 'Sáng chế / Giống cây trồng'; break
							case 2: tenGiai = 'Giải pháp hữu ích'; break
							case 3: tenGiai = 'Kiểu dáng công nghiệp'; break
							case 4: tenGiai = 'Quyền tác giả'; break
							default: tenGiai = ''
						}
					}

					let trangThaiText = 'Dự thảo'
					switch (item.TrangThai) {
						case 1: trangThaiText = 'Dự thảo'; break
						case 2: trangThaiText = 'Chờ duyệt'; break
						case 3: trangThaiText = 'Đã duyệt'; break
						case 4: trangThaiText = 'Từ chối'; break
					}

					return {
						...item,
						STT: index + 1,
						TenLoaiKhenThuong: tenLoai,
						TenCapDo: tenCapDo,
						TenGiaiThuong: tenGiai,
						TrangThaiText: trangThaiText,
						NgayBanHanhFormatted: item.NgayBanHanhFormatted || this.formatDateDisplay(item.NgayBanHanh),
					}
				})
			},
		},
		methods: {
			formatDateDisplay(val) {
				if (!val) return ''
				if (typeof val === 'string' && /^\d{2}\/\d{2}\/\d{4}$/.test(val)) return val
				if (typeof moment !== 'undefined') {
					let m = moment(val, 'YYYY-MM-DD')
					if (m.isValid()) return m.format('DD/MM/YYYY')
					m = moment(val)
					if (m.isValid()) return m.format('DD/MM/YYYY')
				}
				return val
			},
			openAdd() {
				this.$emit('on-add')
			},
			editItem(item) {
				this.$emit('on-edit', item)
			},
			deleteItem(item) {
				this.$emit('on-delete', item)
			},
			getStatusColor(status) {
				switch (status) {
					case 1: return 'grey'
					case 2: return 'warning'
					case 3: return 'success'
					case 4: return 'error'
					default: return 'grey'
				}
			},
			formatCurrency(val) {
				return Number(val || 0).toLocaleString('vi-VN')
			},
			onExportExcel() {
				const exportData = (this.formattedItems || []).map(row => ({
					STT: row.STT,
					'Tên cuộc thi / Công trình': row.TenCuocThi_CongTrinh,
					'Phân loại': row.TenLoaiKhenThuong,
					'Cấp độ': row.TenCapDo,
					'Giải thưởng / Văn bằng': row.TenGiaiThuong,
					'Số QĐ / Bằng': row.SoQuyetDinh_VanBang,
					'Ngày ban hành': row.NgayBanHanhFormatted,
					'Tiền thưởng (VNĐ)': row.TongTienThuong,
					'Trạng thái': row.TrangThaiText,
					'Lý do từ chối (nếu có)': row.LyDoReject || '',
				}))

				jsonToExcel({
					data: exportData,
					filename: 'DeXuatKhenThuong_ThiKHCN.xlsx',
					worksheet: 'DanhSachDeXuat',
				})
			},
		},
	}
</script>