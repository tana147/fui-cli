<template>
	<v-card outlined class="rounded-xs duyet-main-card">
		<!-- Toolbar & Filters -->
		<v-card-title class="pa-3 pb-1 d-flex flex-wrap align-center justify-space-between">
			<span class="primary--text font-weight-bold text-subtitle-1 me-3">
				Hội đồng thẩm định khen thưởng Cuộc thi & SHTT
			</span>

			<div class="d-flex align-center flex-wrap">
				<!-- Quản lý đợt nộp đề xuất của Giảng viên -->
				<v-btn outlined small color="indigo" class="mr-2 text-capitalize" @click="$emit('on-manage-dot-dexuat')">
					<v-icon left small>mdi-bullhorn-outline</v-icon>Đợt nộp đề xuất
				</v-btn>

				<!-- Quản lý đợt duyệt -->
				<v-btn outlined small color="primary" class="mr-2 text-capitalize" @click="$emit('on-manage-dotduyet')">
					<v-icon left small>mdi-calendar-check-outline</v-icon>Đợt duyệt chi
				</v-btn>

				<!-- Xuất báo cáo theo đợt duyệt -->
				<v-menu v-model="menuExport" offset-y :close-on-content-click="false">
					<template v-slot:activator="{ on, attrs }">
						<v-btn v-bind="attrs" v-on="on" icon color="success" class="mr-2"
							title="Xuất danh sách chi tiền theo đợt duyệt">
							<v-icon>mdi-microsoft-excel</v-icon>
						</v-btn>
					</template>
					<v-card class="pa-3 rounded-xs" style="width: 300px;">
						<div class="text-subtitle-2 font-weight-bold mb-2">Xuất báo cáo chi tiền</div>
						<v-select v-model="exportDotDuyetID" :items="dsdotduyet" item-text="TenDotDuyet"
							item-value="DotDuyetID" label="Chọn đợt duyệt" outlined dense hide-details />
						<v-btn class="mt-2" color="success" elevation="0" block :loading="isExporting"
							:disabled="!exportDotDuyetID" @click="exportByDotDuyet">
							<v-icon left small>mdi-download</v-icon>Tải file Excel
						</v-btn>
					</v-card>
				</v-menu>

				<!-- Ô tìm kiếm nhanh chuẩn AGENTS.md -->
				<v-text-field v-model="search" class="c-underline-search" prepend-inner-icon="mdi-magnify"
					label="Tìm kiếm nhanh..." single-line dense hide-details clearable
					style="max-width: 250px;"></v-text-field>
			</div>
		</v-card-title>

		<!-- Bộ lọc thứ cấp -->
		<div class="px-3 pt-2 d-flex flex-wrap align-center">
			<v-select v-model="filterDotDuyetID" :items="dotDuyetFilterOptions" item-text="text" item-value="value"
				label="Lọc theo đợt duyệt" outlined dense hide-details class="select-filter-dotduyet mr-2 mb-2"
				clearable></v-select>

			<v-select v-model="filterLoaiHinh" :items="loaiHinhFilterOptions" item-text="text" item-value="value"
				label="Lọc theo loại hình" outlined dense hide-details class="mr-2 mb-2"
				style="max-width: 200px;"></v-select>

			<v-select v-model="filterCapDo" :items="capDoFilterOptions" item-text="text" item-value="value"
				label="Lọc theo cấp độ" outlined dense hide-details class="mr-2 mb-2"
				style="max-width: 180px;"></v-select>

			<v-spacer></v-spacer>

			<v-btn icon small color="primary" class="mb-2" title="Làm mới" @click="$emit('on-reload')">
				<v-icon small>mdi-refresh</v-icon>
			</v-btn>
		</div>

		<!-- Tabs trạng thái -->
		<v-tabs v-model="activeTab" class="px-3" height="40">
			<v-tab>
				Chờ duyệt
				<v-chip x-small class="ml-2" color="warning" text-color="white">{{ countChoDuyet }}</v-chip>
			</v-tab>
			<v-tab>
				Đã duyệt
				<v-chip x-small class="ml-2" color="success" text-color="white">{{ countDaDuyet }}</v-chip>
			</v-tab>
			<v-tab>
				Bị từ chối
				<v-chip x-small class="ml-2" color="error" text-color="white">{{ countTuChoi }}</v-chip>
			</v-tab>
		</v-tabs>

		<!-- Bảng dữ liệu chính cuộn nội bộ -->
		<v-card-text class="pa-2 pt-1 flex-grow-1 overflow-hidden">
			<!-- Thống kê duy nhất 1 dòng giống approve-request -->
			<div v-if="activeTab === 1" class="d-flex align-center px-3 py-2 mb-2"
				style="background:#f5f5f5; border-radius:4px;">
				<v-icon small color="primary" class="mr-2">mdi-cash-multiple</v-icon>
				<span class="text-body-2">
					Tổng chi phí dự kiến (Đã duyệt):
					<b class="primary--text">{{ formatMoney(tongChiPhiDuKien) }} đ</b>
					<span class="grey--text text-caption ms-2">({{ filteredItems.length }} ấn phẩm)</span>
				</span>
			</div>

			<v-data-table dense fixed-header :height="activeTab === 1 ? 'calc(100vh - 300px)' : 'calc(100vh - 258px)'"
				:headers="headers" :items="filteredItems" :search="search" :loading="isLoading" :items-per-page="50"
				:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }">
				<template v-slot:item.STT="{ index }">
					{{ index + 1 }}
				</template>

				<template v-slot:item.TongTienThuong="{ item }">
					<span class="font-weight-medium primary--text">{{ formatCurrency(item.TongTienThuong) }}</span>
				</template>

				<template v-slot:item.TrangThaiText="{ item }">
					<v-tooltip bottom v-if="item.TrangThai === 4 && item.LyDoReject">
						<template v-slot:activator="{ on, attrs }">
							<v-chip x-small color="error" outlined v-bind="attrs" v-on="on">
								Bị từ chối
								<v-icon right x-small>mdi-alert-circle-outline</v-icon>
							</v-chip>
						</template>
						<span>Lý do: {{ item.LyDoReject }}</span>
					</v-tooltip>
					<v-chip x-small v-else :color="item.TrangThai === 3 ? 'success' : (item.TrangThai === 4 ? 'error' : 'warning')" outlined>
						{{ item.TrangThai === 3 ? 'Đã duyệt' : (item.TrangThai === 4 ? 'Bị từ chối' : 'Chờ duyệt') }}
					</v-chip>
				</template>

				<template v-slot:item.TenDotDuyet="{ item }">
					<span v-if="item.TenDotDuyet" class="font-weight-medium text-caption">{{ item.TenDotDuyet }}</span>
					<span v-else class="grey--text text-caption">Chưa gán</span>
				</template>

				<template v-slot:item.actions="{ item }">
					<v-btn small color="primary" elevation="0" class="px-2" height="28" @click="openEdit(item)">
						<v-icon left x-small>mdi-file-check-outline</v-icon>Thẩm định
					</v-btn>
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		name: 'uc-main-view',
		props: {
			dsbaibao: { type: Array, default: () => [] },
			dsdotduyet: { type: Array, default: () => [] },
			isLoading: { type: Boolean, default: false },
		},
		emits: ['on-edit', 'on-reload', 'on-manage-dotduyet'],
		data() {
			return {
				search: '',
				activeTab: 0,
				menuExport: false,
				isExporting: false,
				exportDotDuyetID: null,
				filterDotDuyetID: null,
				filterLoaiHinh: null,
				filterCapDo: null,
				headers: [
					{ text: '#', value: 'STT', width: 45, align: 'center', sortable: false },
					{ text: 'Tên cuộc thi / Công trình', value: 'TenCuocThi_CongTrinh', width: 250 },
					{ text: 'Phân loại', value: 'TenLoaiKhenThuong', width: 140 },
					{ text: 'Cấp độ', value: 'TenCapDo', width: 120 },
					{ text: 'Giải thưởng / Bằng', value: 'TenGiaiThuong', width: 130 },
					{ text: 'Số QĐ / Bằng', value: 'SoQuyetDinh_VanBang', width: 120 },
					{ text: 'Người nộp', value: 'NhanVienSubmit', width: 100 },
					{ text: 'Tiền thưởng (đ)', value: 'TongTienThuong', align: 'right', width: 130 },
					{ text: 'Đợt chi tiền', value: 'TenDotDuyet', width: 130 },
					{ text: 'Trạng thái', value: 'TrangThaiText', align: 'center', width: 110 },
					{ text: 'Thao tác', value: 'actions', align: 'center', width: 110, sortable: false },
				],
				loaiHinhFilterOptions: [
					{ text: 'Tất cả loại hình', value: null },
					{ text: 'Cuộc thi KH&CN', value: 1 },
					{ text: 'Cuộc thi Học thuật', value: 2 },
					{ text: 'Sở hữu trí tuệ', value: 3 },
				],
				capDoFilterOptions: [
					{ text: 'Tất cả cấp độ', value: null },
					{ text: 'Cấp Quốc tế', value: 1 },
					{ text: 'Cấp Khu vực QT', value: 2 },
					{ text: 'Cấp Quốc gia', value: 3 },
					{ text: 'Cấp Khu vực trong nước', value: 4 },
					{ text: 'Cấp Tỉnh', value: 5 },
					{ text: 'Cấp Trường', value: 6 },
				],
			}
		},
		computed: {
			dotDuyetFilterOptions() {
				const opts = (this.dsdotduyet || []).map(d => ({
					text: d.TenDotDuyet,
					value: d.DotDuyetID,
				}))
				return [{ text: 'Tất cả đợt duyệt', value: null }, ...opts]
			},
			formattedList() {
				return (this.dsbaibao || []).map(item => {
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
					}

					let tenGiai = ''
					if (item.LoaiKhenThuong === 1) {
						switch (item.GiaiThuong) {
							case 1: tenGiai = 'Giải Nhất'; break
							case 2: tenGiai = 'Giải Nhì'; break
							case 3: tenGiai = 'Giải Ba'; break
							case 4: tenGiai = 'Khuyến khích'; break
							case 5: tenGiai = 'Báo cáo ngày hội'; break
						}
					} else {
						switch (item.LoaiSHTT) {
							case 1: tenGiai = 'Sáng chế/Giống'; break
							case 2: tenGiai = 'Giải pháp hữu ích'; break
							case 3: tenGiai = 'Kiểu dáng CN'; break
							case 4: tenGiai = 'Quyền tác giả'; break
						}
					}

					return {
						...item,
						TenLoaiKhenThuong: tenLoai,
						TenCapDo: tenCapDo,
						TenGiaiThuong: tenGiai,
					}
				})
			},
			countChoDuyet() {
				return this.formattedList.filter(x => x.TrangThai === 2).length
			},
			countDaDuyet() {
				return this.formattedList.filter(x => x.TrangThai === 3).length
			},
			countTuChoi() {
				return this.formattedList.filter(x => x.TrangThai === 4).length
			},
			filteredItems() {
				const targetStatus = this.activeTab === 0 ? 2 : (this.activeTab === 1 ? 3 : 4)
				return this.formattedList.filter(item => {
					if (item.TrangThai !== targetStatus) return false
					if (this.filterDotDuyetID && item.DotDuyetID !== this.filterDotDuyetID) return false
					if (this.filterCapDo && item.CapDoCuocThi !== this.filterCapDo) return false
					if (this.filterLoaiHinh) {
						if (this.filterLoaiHinh === 1 && (item.LoaiKhenThuong !== 1 || item.LoaiHinhCuocThi !== 1)) return false
						if (this.filterLoaiHinh === 2 && (item.LoaiKhenThuong !== 1 || item.LoaiHinhCuocThi !== 2)) return false
						if (this.filterLoaiHinh === 3 && item.LoaiKhenThuong === 1) return false
					}
					return true
				})
			},
			tongChiPhiDuKien() {
				return (this.filteredItems || []).reduce((sum, item) => sum + (Number(item.TongTienThuong) || 0), 0)
			},
		},
		methods: {
			openEdit(item) {
				this.$emit('on-edit', item)
			},
			formatMoney(val) {
				if (typeof formatAsCurrency === 'function') {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString('vi-VN')
			},
			formatCurrency(val) {
				return this.formatMoney(val)
			},
			async exportByDotDuyet() {
				if (!this.exportDotDuyetID) return
				this.isExporting = true
				try {
					const data = await ajaxCALLPromise('/ThiKHCN_RPT_ByDotDuyet', { DotDuyetID: this.exportDotDuyetID })
					if (!data || data.length === 0) {
						Vue.$toast.warning('Đợt duyệt này chưa có hồ sơ nào được phê duyệt!', { position: 'top' })
						return
					}

					const selectedDot = (this.dsdotduyet || []).find(d => d.DotDuyetID === this.exportDotDuyetID)
					const dotName = selectedDot ? selectedDot.TenDotDuyet : 'DotDuyet'

					const exportRows = data.map((row, idx) => ({
						STT: idx + 1,
						'Họ và tên': row.HoTen,
						'Mã ĐD': row.MaDinhDanh || '',
						'Vai trò': row.VaiTro,
						'Đơn vị / Khoa': row.TenPhongBan || '',
						'Số tài khoản': row.SoTaiKhoan || '',
						'Ngân hàng': row.NganHang || '',
						'Chủ tài khoản': row.TenChuTaiKhoan || '',
						'Số tiền thưởng (VNĐ)': row.SoTienThuong,
						'Tên cuộc thi / Công trình': row.TenCuocThi_CongTrinh,
						'Giải thưởng / Văn bằng': row.TenGiai_HinhThuc,
						'Cấp độ': row.TenCapDo,
						'Số Quyết định / Bằng': row.SoQuyetDinh_VanBang || '',
						'Ngày ban hành': row.NgayBanHanh || '',
						'Đợt duyệt': row.TenDotDuyet || dotName,
					}))

					jsonToExcel({
						data: exportRows,
						filename: `DanhSachChiTien_${dotName}.xlsx`,
						worksheet: 'DanhSachChiTien',
					})
					Vue.$toast.success('Xuất file Excel thành công!', { position: 'top' })
					this.menuExport = false
				} finally {
					this.isExporting = false
				}
			},
		},
	}
</script>