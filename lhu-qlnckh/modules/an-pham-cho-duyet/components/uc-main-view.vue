<template>
	<v-card>
		<v-card-title class='pa-2 pb-1'>
			<v-row class="flex align-center" dense>
				<span class="primary--text font-weight-medium text-body-1 me-4">
					Danh sách các ấn phẩm đang chờ Tính tiền
				</span>

				<v-menu v-model="menuDashboard" offset-y :close-on-content-click="false">
					<template v-slot:activator="{ on, attrs }">
						<v-btn v-bind="attrs" v-on="on" color="primary" small :disabled="isDisabledSendDashboard">
							Gửi dữ liệu sang dashboard
						</v-btn>
					</template>
					<v-card class="p-4" style="width: 300px;">
						<v-card-text>
							<v-select label="Năm học" v-model="NamHoc" :items="['2024-2025']" dense outlined
								hide-details />
							<v-btn class="mt-2" color="primary" block @click="sendBaiBao">Xác nhận</v-btn>
						</v-card-text>
					</v-card>
				</v-menu>

				<v-btn color="warning" small class="ms-2" :disabled="isDisabledSendDashboard" @click="sendToStorage">
					Chuyển dữ liệu vào kho</v-btn>

				<v-chip v-if="isSelected.length > 0" small outlined color="primary" class="ms-3">
					Đã chọn {{ isSelected.length }}
				</v-chip>

				<v-spacer></v-spacer>
				<v-btn outlined small color="primary" class="mr-2" @click="$emit('on-manage-dotduyet')">
					<v-icon left small>mdi-calendar-check-outline</v-icon>Đợt duyệt
				</v-btn>
				<v-btn style="display:none" class="mr-2" icon color="green" @click="toExcel1">
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-btn class="mr-2" icon color="primary" small @click="toExcel">
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-menu v-model="menuExportDotDuyet" offset-y :close-on-content-click="false">
					<template v-slot:activator="{ on, attrs }">
						<v-btn v-bind="attrs" v-on="on" icon color="success" small class="mr-2"
							title="Xuất báo cáo theo đợt duyệt">
							<v-icon>mdi-file-export-outline</v-icon>
						</v-btn>
					</template>
					<v-card class="pa-3" style="width: 280px;">
						<v-select v-model="exportDotDuyetID" :items="dsdotduyet" item-text="TenDotDuyet"
							item-value="AnPham_DotDuyetID" label="Chọn đợt duyệt để xuất" outlined dense hide-details />
						<v-btn class="mt-2" color="success" block :loading="isExportingDotDuyet"
							:disabled="!exportDotDuyetID" @click="exportByDotDuyet">
							<v-icon left small>mdi-microsoft-excel</v-icon>Xuất Excel
						</v-btn>
					</v-card>
				</v-menu>
				<v-text-field v-model="search" prepend-icon="mdi-magnify" label="Tìm kiếm" single-line dense
					hide-details style="max-width: 220px" clearable></v-text-field>
			</v-row>
			<v-row class="flex flex-wrap align-center mt-1" dense>
				<v-select v-model="NhomAnPhamID" :items="LoaiBaiBao" item-text="TenLoai" item-value="LoaiID"
					label="Nhóm ấn phẩm" outlined dense hide-details class="mr-2 mb-1" style="max-width: 160px" />
				<v-select v-model="DMTC_Filter" :items="DanhMucLoaiAnPhamArr" item-text="TenLoaiAnPham"
					item-value="LoaiAnPhamID" label="Danh mục bài báo ấn phẩm" outlined dense hide-details
					@change="getDM_By_LoaiAnPhamID" class="mr-2 mb-1" style="max-width: 210px" />
				<v-select v-model="Thuoc_DMTC_Filter" :items="DMTC_Arr" item-text="TenLoaiSubAnPham"
					item-value="LoaiSubAnPhamID" label="Thuộc danh mục tạp chí" outlined dense hide-details
					@change="getTenDMTC_By_LoaiAnPhamID()" class="mr-2 mb-1" style="max-width: 210px" />
				<v-select v-model="Ten_DMTC_Filter" :items="Ten_DMTC_Arr" item-text="TenLoaiDanhMucTapChi"
					item-value="DanhMucLoaiTapChiID" label="Tên danh mục tạp chí" outlined dense hide-details
					class="mr-2 mb-1" style="max-width: 210px" />
				<v-select v-model="NamDangBaiFilter" :items="NamDangBaiFilterArr" label="Năm đăng" outlined dense
					hide-details class="mb-1" style="max-width: 130px" clearable />
			</v-row>
		</v-card-title>

		<v-tabs v-model="activeTab" class="px-2" height="40">
			<v-tab @click="TrangThaiID = 2">
				Chờ duyệt
				<v-chip x-small class="ml-2" color="warning" text-color="white">{{ countChoDuyet }}</v-chip>
			</v-tab>
			<v-tab @click="TrangThaiID = 3">
				Đã duyệt
				<v-chip x-small class="ml-2" color="success" text-color="white">{{ countDaDuyet }}</v-chip>
			</v-tab>
		</v-tabs>

		<v-card-text class="pa-2 pt-1">
			<div v-if="activeTab === 1" class="d-flex align-center px-3 py-2 mb-2"
				style="background:#f5f5f5; border-radius:4px;">
				<v-icon small color="primary" class="mr-2">mdi-cash-multiple</v-icon>
				<span class="text-body-2">
					Tổng chi phí dự kiến (Đã duyệt):
					<b class="primary--text">{{ formatMoney(tongChiPhiDuKien) }} đ</b>
					<span class="grey--text text-caption ms-2">({{ DSBaiBaoFilter.length }} ấn phẩm)</span>
				</span>
			</div>
			<v-data-table dense fixed-header :height="activeTab === 1 ? 'calc(100vh - 300px)' : 'calc(100vh - 258px)'"
				:headers="headersArticlesObj" v-model="isSelected" item-key="_UniqueKey" show-select
				:items="DSBaiBaoFilter" selectable-key="isSelectable"
				:footer-props="{ 'items-per-page-options': [100, 150, -1] }" :calculate-widths="true"
				class="table-custom">
				<template v-slot:item.TrangThai="{ item }">
					<v-chip small :color="getColorStatusAnPham(item.TrangThaiID)">
						{{ item.TrangThai }}
					</v-chip>
				</template>
				<template v-slot:item.NoiDangBai="{ item }">
					<div class="py-1">
						<div class="text-body-2">{{ item.NoiDangBai || '' }}</div>
						<div class="text-caption grey--text text--darken-1">Năm {{ item.NamDangBai || '' }}</div>
					</div>
				</template>
				<template v-slot:item.nhomanpham="{ item }">
					<div>
						<v-chip outlined color="primary" v-if="item.NhomAnPham == 1" small>Ấn phẩm khoa học</v-chip>
						<v-chip v-else-if="item.NhomAnPham == 2" outlined color="success" small>Hỗ trợ Đầu vào Cao học
						</v-chip>
						<v-chip v-else-if="item.NhomAnPham == 3" outlined color="orange" small>Có tham gia đào tạo
							nghiên cứu sinh</v-chip>
						<span v-else class="text-caption grey--text">-</span>
					</div>
				</template>
				<template v-slot:item.actions="{ item }">
					<div style="display: flex">
						<v-icon style="font-size: 18px" color="red darken-3" small class="mr-2"
							@click="deleteItem(item)">
							mdi-trash-can-outline
						</v-icon>
						<v-icon style="font-size: 18px" color="green darken-2" small class="mr-2"
							@click="editItem(item)">
							mdi-square-edit-outline
						</v-icon>
						<v-icon v-if="item.TrangThaiID == 3" style="font-size: 18px" color="blue darken-2" small
							title="Chuyển đợt duyệt" @click="openChuyenDot(item)">
							mdi-swap-horizontal-bold
						</v-icon>
						<v-icon style="font-size: 18px" color="grey darken-2" small class="ml-2" title="Xem lịch xử lý"
							@click="openLichSu(item)">
							mdi-history
						</v-icon>
					</div>
				</template>
				<template v-slot:item.dotduyet="{ item }">
					<div>
						<v-chip v-if="item.DotDuyet" x-small outlined color="blue">{{ getTenDotDuyet(item.DotDuyet) }}
						</v-chip>
						<span v-else class="text-caption grey--text">-</span>
					</div>
				</template>
				<template v-slot:item.TongTienKhenThuong="{ item }">
					<span class="font-weight-medium success--text">{{ formatMoney(item.TongTienKhenThuong) }} đ</span>
				</template>
				<template v-slot:item.tongtienkhenthuong="{ item }">
					<span class="font-weight-medium success--text">{{ formatMoney(item.TongTienKhenThuong) }} đ</span>
				</template>
				<template v-slot:item.thongtintapchi="{ item }">
					<div class="py-1">
						<div class="text-body-2">{{ (item.TenLoaiAnPham && item.TenLoaiAnPham.length > 0) ?
							item.TenLoaiAnPham : '-' }}</div>
						<div class="text-caption grey--text text--darken-1">
							{{ (item.TenTapChi && item.TenTapChi.length > 0) ? item.TenTapChi : '-' }}<span
								v-if="item.TenLoaiDanhMucTapChi"> · {{ item.TenLoaiDanhMucTapChi }}</span>
						</div>
					</div>
				</template>
				<template v-slot:item.TenAnPham="{ item }">
					<div class="d-flex w-100 flex-column py-1">
						<span class="font-weight-medium">{{ item.TenAnPham }}</span>
						<span class="text-caption grey--text text--darken-1">{{ item.TacGia }} · {{ item.DonViDaiDien
							}}</span>
					</div>
				</template>
			</v-data-table>
		</v-card-text>

		<v-dialog v-model="chuyenDotDialog" max-width="420">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
					<span class="subtitle-1 font-weight-bold primary--text">Chuyển đợt duyệt</span>
					<v-spacer></v-spacer>
					<v-btn small icon @click="chuyenDotDialog = false">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-2">
					<div class="text-body-2 mb-3" v-if="chuyenDotItem">
						{{ chuyenDotItem.TenAnPham }}
					</div>
					<v-select v-model="chuyenDotTargetID" :items="chuyenDotOptions" item-text="TenDotDuyet"
						item-value="AnPham_DotDuyetID" label="Chuyển đến đợt duyệt" outlined dense hide-details
						no-data-text="Chưa có đợt duyệt nào đang mở" />
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn small @click="chuyenDotDialog = false">Đóng</v-btn>
					<v-btn small class="ml-2" color="primary" elevation="0" :loading="isChuyenDotLoading"
						:disabled="!chuyenDotTargetID" @click="confirmChuyenDot">Xác nhận</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<uc-lichsu-modal v-model="lichSuDialog" :anphamid="lichSuAnPhamID" />
	</v-card>
</template>

<script>
	export default {
		name: 'uc-main-view',
	props: {
		dsbaibao: { type: Array, default: () => [] },
		dsdanhmucloaianpham: { type: Array, default: () => [] },
		dsnganhang: { type: Array, default: () => [] },
		dsdotduyet: { type: Array, default: () => [] },
	},
	emits: ['on-reload', 'on-edit', 'on-delete', 'on-manage-dotduyet'],
	data() {
		return {
			checkAll: null,
			NamHoc: "",
			search: "",
			menuDashboard: false,
			menuExportDotDuyet: false,
			chuyenDotDialog: false,
			chuyenDotItem: null,
			chuyenDotTargetID: null,
			isChuyenDotLoading: false,
			lichSuDialog: false,
			lichSuAnPhamID: null,
			exportDotDuyetID: null,
			isExportingDotDuyet: false,
			isSelected: [],
			isDisabledSendDashboard: true,
			LoaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có tham gia đào tạo nghiên cứu sính", LoaiID: 3 },
				{ TenLoai: "Tất cả", LoaiID: 4 },
			],
			headersArticlesBase: [
				{
					text: "STT",
					sortable: false,
					value: "STT",
					align: "center",
					width: "10",
				},
				{
					text: "Tên bài báo",
					sortable: false,
					value: "TenAnPham",
				},
				{
					text: "Thông tin tạp chí",
					sortable: false,
					value: "thongtintapchi",
				},
				{
					text: "Thông tin đăng bài",
					value: "NoiDangBai",
					sortable: true,
					width: "180",
				},
				{ text: "Nhóm ấn phẩm", value: "nhomanpham", sortable: false },
				{
					text: "Ngày nhập",
					sortable: true,
					value: "ThoiGianGui",
					width: "100",
					align: "center",
				},
				{
					text: "Trạng thái",
					sortable: true,
					value: "TrangThai",
					width: "100",
					align: "center",
				},
				{
					text: "Đợt duyệt",
					sortable: false,
					value: "dotduyet",
					width: "140",
					align: "center",
				},
				{ text: "Thao tác", value: "actions", sortable: false, width: "70", align: "center", class: "text-no-wrap" },
			],
				NhomAnPhamID: 4,
			activeTab: 0,
			TrangThaiID: 2,
			TrangThaiArr: [
				{ TenTrangThai: "Tất cả", TrangThaiID: 1 },
				{ TenTrangThai: "Chờ duyệt", TrangThaiID: 2 },
				{ TenTrangThai: "Đã duyệt", TrangThaiID: 3 }
			],
			DMTC_Filter: -1,
			Thuoc_DMTC_Filter: null,
			Ten_DMTC_Filter: null,
			DMTC_Arr: [],
			Ten_DMTC_Arr: [],
			DS_BaiBaoKhenThuong: [],
			NamDangBaiFilter: null,
		}
	},
	computed: {
		chuyenDotOptions() {
			return (this.dsdotduyet || []).filter(item => item && item.TinhTrang === 1)
		},
		countChoDuyet() {
			return (this.dsbaibao || []).filter(item => item && item.TrangThaiID == 2).length
		},
		countDaDuyet() {
			return (this.dsbaibao || []).filter(item => item && item.TrangThaiID == 3).length
		},
		tongChiPhiDuKien() {
			return this.DSBaiBaoFilter.reduce((sum, item) => sum + (Number(item.TongTienKhenThuong) || 0), 0)
		},
		headersArticlesObj() {
			const headers = [...this.headersArticlesBase]
			if (this.activeTab === 1 || this.TrangThaiID === 3) {
				headers.splice(headers.length - 1, 0, {
					text: "Tổng tiền khen thưởng",
					value: "TongTienKhenThuong",
					width: "150",
					align: "right",
					sortable: true,
				})
			}
			return headers
		},
		NamDangBaiFilterArr() {
			const years = (this.dsbaibao || []).reduce((result, item) => {
				if (item && item.NamDangBai && !result.includes(item.NamDangBai)) {
					result.push(item.NamDangBai)
				}
				return result
			}, [])
			return years.sort((a, b) => b - a)
		},
		DanhMucLoaiAnPhamArr() {
			return [
				{ LoaiAnPhamID: -1, TenLoaiAnPham: "Tất cả" },
				...(this.dsdanhmucloaianpham || []).map(item => ({ ...item }))
			]
		},
		DSBaiBao() {
			return (this.dsbaibao || []).filter(item => item && typeof item === 'object').map((item, idx) => {
				const uniqueId = `item_${item.AnPhamID != null ? item.AnPhamID : 'noid'}_${idx}`
				return {
					...item,
					_UniqueKey: uniqueId,
					AnPhamID: item.AnPhamID,
					STT: item.STT || (idx + 1),
					TenAnPham_TacGia: (item.TenAnPham || '') + ' ' + (item.TacGia || ''),
					TongTienKhenThuong: item.TongTienKhenThuong || 0,
					tongtienkhenthuong: item.TongTienKhenThuong || 0,
				}
			})
		},
		DSBaiBaoFilter() {
			const targetTrangThaiID = (this.activeTab === 1 || this.TrangThaiID === 3) ? 3 : 2
			let result = this.DSBaiBao.filter(item => {
				if (!item) return false
				if (item.TrangThaiID != targetTrangThaiID) {
					return false
				}
				if (this.NhomAnPhamID && this.NhomAnPhamID != 4 && item.NhomAnPham != this.NhomAnPhamID) {
					return false
				}
				if (this.DMTC_Filter !== -1 && this.DMTC_Filter !== null && this.DMTC_Filter !== undefined && item.LoaiAnPhamID != this.DMTC_Filter) {
					return false
				}
				if (this.Thuoc_DMTC_Filter && item.LoaiSubAnPhamID != this.Thuoc_DMTC_Filter) {
					return false
				}
				if (this.Ten_DMTC_Filter && item.DanhMucLoaiTapChiID != this.Ten_DMTC_Filter) {
					return false
				}
				if (this.NamDangBaiFilter && item.NamDangBai != this.NamDangBaiFilter) {
					return false
				}
				return true
			})

			if (this.search && this.search.trim()) {
				const q = this.search.trim().toLowerCase()
				const qNoTone = this.removeVietnameseTones(q)
				const qTokens = q.split(/\s+/).filter(Boolean)
				const qNoToneTokens = qNoTone.split(/\s+/).filter(Boolean)

				result = result.filter(item => {
					const dotDuyetName = (item.DotDuyet ? this.getTenDotDuyet(item.DotDuyet) : '') || ''
					const rawFields = [
						item.TenAnPham,
						item.TacGia,
						item.DonViDaiDien,
						item.TenTapChi,
						item.TenLoaiAnPham,
						item.TenLoaiDanhMucTapChi,
						item.NoiDangBai,
						item.NamDangBai,
						item.ThoiGianGui,
						item.TrangThai,
						item.TongTienKhenThuong,
						dotDuyetName !== '-' ? dotDuyetName : ''
					].filter(val => val !== null && val !== undefined && val !== '').map(val => String(val).trim())

					const rawText = rawFields.join(' ').toLowerCase()
					const textNoTone = this.removeVietnameseTones(rawText)

					if (rawText.includes(q) || textNoTone.includes(qNoTone)) {
						return true
					}

					return qTokens.every((token, idx) => {
						const tokenNoTone = qNoToneTokens[idx] || token
						return rawText.includes(token) || textNoTone.includes(tokenNoTone)
					})
				})
			}

			return result
		},
	},
	watch: {
		isSelected(val) {
			this.isDisabledSendDashboard = val.length === 0
		},
		activeTab(val) {
			this.isSelected = []
			this.TrangThaiID = val === 1 ? 3 : 2
		},
	},
	methods: {
		sendBaiBao() {
			const $this = this
			if ($this.NamHoc.length === 0) {
				Vue.$toast.error("Vui lòng chọn năm học!", { position: "top" })
				return
			}
			confirm({
				title: "Xác nhận",
				content: "Xác nhận gửi bài báo sang dashboard",
				action: async function () {
					let AnPhamIDArr = $this.isSelected.map(item => ({ AnPhamID: item.AnPhamID }))
					if (AnPhamIDArr.length > 0) {
						await ajaxCALLPromise('/AnPham_Ins_ToRPT', {
							AnPhamObjArr: AnPhamIDArr,
							NamHoc: $this.NamHoc
						})
						$this.isSelected = []
						$this.NamHoc = ""
						$this.$emit('on-reload')
						Vue.$toast.success("Gửi dữ liệu thành công", { position: "top" })
					} else {
						Vue.$toast.warning("Chưa chọn dữ liệu để gửi", { position: "top" })
					}
				},
			})
		},
		editItem(item) {
			this.$emit('on-edit', item)
		},
		deleteItem(item) {
			this.$emit('on-delete', item)
		},
		async getDM_By_LoaiAnPhamID() {
			if (this.DMTC_Filter) {
				this.DMTC_Arr = await ajaxCALLPromise('/AnPham_Loai_Sub_Get', { LoaiAnPhamID: this.DMTC_Filter })
			}
		},
		async getTenDMTC_By_LoaiAnPhamID() {
			if (this.Thuoc_DMTC_Filter) {
				this.Ten_DMTC_Arr = await ajaxCALLPromise('/LoaiDMTapChi_Get_ByLoaiSubAnPhamID', { LoaiSubAnPhamID: this.Thuoc_DMTC_Filter })
			}
		},
		async toExcel1() {
			const data = await ajaxCALLPromise('/AnPham_Get_ByTrangThai', { TrangThai: "2,3" })
			let convertDSBaiBao = data.map(item => ({
				STT: item.STT,
				AnPhamID: item.AnPhamID,
				"Tác giả bài báo": item.TacGia,
				"Đơn vị": item.TenKhoa,
				"Tên bài báo": item.TenAnPham,
				"Tên tạp chí": item.TenTapChi,
				"Năm đăng": item.NamDangBai,
				"Nơi đăng": item.NoiDangBai,
				"Thuộc danh mục tạp chí": item.TenNhomHienThiExcel,
				"Thời gian nhập dữ liệu": item.ThoiGianGui,
				"Ghi chú": item.GhiChu,
				"Thông tin thanh toán": item.TenNhanVienDaiDien
			}))
			jsonToExcel({ data: convertDSBaiBao })
			Vue.$toast.success("Đã xuất Excel", { position: 'top' })
		},
		async toExcel() {
			const data = await ajaxCALLPromise('/AnPham_Get_ByTrangThai', { TrangThai: "2,3" })
			let convertDSBaiBao = data.map(item => {
				let TenNhomAnPham = ''
				if (item.NhomAnPham === 1) TenNhomAnPham = 'Ấn phẩm khoa học'
				else if (item.NhomAnPham === 2) TenNhomAnPham = 'Hỗ trợ Đầu vào Cao học'
				else if (item.NhomAnPham === 3) TenNhomAnPham = 'Có hướng dẫn Cao học'
				return {
					STT: item.STT,
					"Tên bài báo": item.TenAnPham,
					"Tác giả": item.TacGia,
					"Đơn vị": item.DonViDaiDien,
					"Danh mục bài báo/ ấn phẩm": item.TenLoaiAnPham,
					"Tên tạp chí": item.TenTapChi,
					"Tên danh mục tạp chí": item.TenLoaiDanhMucTapChi,
					"Năm đăng": item.NamDangBai,
					"Nơi đăng": item.NoiDangBai,
					"Nhóm ấn phẩm": TenNhomAnPham,
					"Ngày nhập": item.ThoiGianGui,
					"Trạng thái": item.TrangThai,
					"Thông tin thanh toán": item.TenNhanVienDaiDien
				}
			})
			jsonToExcel({ data: convertDSBaiBao })
			Vue.$toast.success("Đã xuất Excel", { position: 'top' })
		},
		async exportByDotDuyet() {
			this.isExportingDotDuyet = true
			try {
				const data = await ajaxCALLPromise('/AnPham_RPT_ByDotDuyet', { DotDuyetID: this.exportDotDuyetID })
				if (!data || data.length === 0) {
					Vue.$toast.warning("Đợt duyệt này chưa có ấn phẩm nào", { position: 'top' })
					return
				}
				jsonToExcel({ data: data })
				this.menuExportDotDuyet = false
				Vue.$toast.success("Đã xuất Excel theo đợt duyệt", { position: 'top' })
			} finally {
				this.isExportingDotDuyet = false
			}
		},
		formatMoney(val) {
			if (typeof formatAsCurrency === 'function') {
				return formatAsCurrency(Number(val) || 0, 0)
			}
			return Number(val || 0).toLocaleString('vi-VN')
		},
		getTenDotDuyet(id) {
			if (!id || !Array.isArray(this.dsdotduyet)) return '-'
			const found = this.dsdotduyet.find(item => item && item.AnPham_DotDuyetID == id)
			return found ? found.TenDotDuyet : '-'
		},
		getColorStatusAnPham(statusId) {
			if (typeof getColorStatusAnPham === 'function') {
				return getColorStatusAnPham(statusId)
			}
			const colors = { 1: '', 2: 'warning', 3: 'primary', 4: 'success', 5: 'error', 6: '' }
			return colors[statusId] || ''
		},
		openLichSu(item) {
			this.lichSuAnPhamID = item.AnPhamID
			this.lichSuDialog = true
		},
		openChuyenDot(item) {
			this.chuyenDotItem = item
			this.chuyenDotTargetID = null
			this.chuyenDotDialog = true
		},
		async confirmChuyenDot() {
			if (!this.chuyenDotTargetID) {
				Vue.$toast.error("Vui lòng chọn đợt duyệt cần chuyển đến", { position: 'top' })
				return
			}
			this.isChuyenDotLoading = true
			try {
				await ajaxCALLPromise('/AnPham_ChuyenDotDuyet', {
					AnPhamID: this.chuyenDotItem.AnPhamID,
					DotDuyetID: this.chuyenDotTargetID,
				})
				Vue.$toast.success("Đã chuyển đợt duyệt", { position: 'top' })
				this.chuyenDotDialog = false
				this.$emit('on-reload')
			} finally {
				this.isChuyenDotLoading = false
			}
		},
		removeVietnameseTones(str) {
			if (!str) return ''
			return str
				.toString()
				.normalize('NFD')
				.replace(/[\u0300-\u036f]/g, '')
				.replace(/đ/g, 'd')
				.replace(/Đ/g, 'D')
		},
		sendToStorage() {
			const $this = this
			confirm({
				title: "Xác nhận",
				content: "Xác nhận chuyển dữ liệu vào kho",
				action: async function () {
					let AnPhamIDArr = $this.isSelected.map(item => ({ AnPhamID: item.AnPhamID }))
					if (AnPhamIDArr.length > 0) {
						await ajaxCALLPromise('/AnPham_Upd_LocalStorage', {
							AnPhamObjArr: AnPhamIDArr,
							Is_Store: 1
						})
						$this.isSelected = []
						$this.$emit('on-reload')
						Vue.$toast.success("Chuyển dữ liệu vào kho thành công!", { position: "top" })
					} else {
						Vue.$toast.warning("Vui lòng chọn dữ liệu để chuyển!", { position: "top" })
					}
				},
			})
		},
	},
	}
</script>