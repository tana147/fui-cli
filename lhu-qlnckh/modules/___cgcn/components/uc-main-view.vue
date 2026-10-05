<template>
	<v-card outlined class="rounded-xs elevation-1 d-flex flex-column flex-grow-1 cgcn-card">
		<!-- Tabs quy trình xét duyệt -->
		<v-tabs
			v-model="activeTab"
			background-color="transparent"
			color="primary"
			dense
			class="px-2 border-b"
		>
			<v-tab>
				Chờ xét duyệt
				<v-chip x-small class="ml-1" color="orange lighten-4" text-color="orange darken-4">
					{{ statusCounts.countPending || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Đã phê duyệt
				<v-chip x-small class="ml-1" color="green lighten-4" text-color="green darken-4">
					{{ statusCounts.countApproved || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Cần bổ sung
				<v-chip x-small class="ml-1" color="red lighten-4" text-color="red darken-4">
					{{ statusCounts.countRejected || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Dự thảo
				<v-chip x-small class="ml-1" color="grey lighten-2">
					{{ statusCounts.countDraft || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Tất cả
				<v-chip x-small class="ml-1" color="grey lighten-2">
					{{ statusCounts.totalAll || 0 }}
				</v-chip>
			</v-tab>
		</v-tabs>

		<!-- Toolbar -->
		<v-card-title class="py-2 px-3 d-flex flex-wrap align-center">
			<span class="primary--text font-weight-bold text-subtitle-1 mr-4">
				Quản lý hợp đồng & dự án chuyển giao công nghệ
			</span>
			<v-spacer />
			<div class="d-flex align-center flex-wrap cgcn-toolbar-actions">
				<v-select
					v-model="selectedYear"
					:items="yearOptions"
					label="Năm học"
					dense
					outlined
					hide-details
					clearable
					class="cgcn-year-select"
				/>
				<v-btn
					icon
					color="success"
					class="mr-2"
					:loading="isLoadingExport"
					title="Xuất file Excel"
					@click="onPrintExcel"
				>
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-text-field
					v-model="searchText"
					prepend-inner-icon="mdi-magnify"
					placeholder="Tìm kiếm..."
					single-line
					dense
					hide-details
					clearable
					class="c-underline-search mr-2 cgcn-search-input"
				/>
				<v-btn
					color="primary"
					small
					depressed
					@click="handleAdd"
				>
					<v-icon left small>mdi-plus</v-icon>
					Thêm mới
				</v-btn>
			</div>
		</v-card-title>

		<!-- Data Table -->
		<v-card-text class="pa-0 flex-grow-1 cgcn-card-body">
			<v-data-table
				dense
				fixed-header
				height="calc(100vh - 330px)"
				:headers="tableHeaders"
				:items="filteredRows"
				:search="searchText"
				item-key="CGCNID"
				:items-per-page="50"
				:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }"
				class="cgcn-table elevation-0"
			>
				<template v-slot:item.SoThuTu="{ item }">
					<div class="text-center">{{ getRowIndex(item) }}</div>
				</template>

				<!-- Trạng thái -->
				<template v-slot:item.TrangThai="{ item }">
					<v-chip
						x-small
						:color="getStatusChipColor(item.TrangThai)"
						:text-color="getStatusChipTextColor(item.TrangThai)"
						class="font-weight-medium"
					>
						{{ getStatusText(item.TrangThai) }}
					</v-chip>
				</template>

				<template v-slot:item.TenDuAn="{ item }">
					<div class="py-1">
						<div class="font-weight-medium">{{ item.TenDuAn }}</div>
						<div v-if="item.NhanVienSubmit" class="text-caption grey--text">
							Người nộp: {{ item.NhanVienSubmit }}
						</div>
						<div
							v-if="item.TrangThai === 4 && item.LyDoReject"
							class="red--text text-caption font-italic"
						>
							Lý do trả về: {{ item.LyDoReject }}
						</div>
					</div>
				</template>

				<template v-slot:item.GiaTriHopDong="{ item }">
					<span class="font-weight-medium">{{ formatMoney(item.GiaTriHopDong) }}</span>
				</template>

				<template v-slot:item.SoHopDong="{ item }">
					<v-btn
						v-if="item.SoHopDong && String(item.SoHopDong).trim() !== ''"
						x-small
						depressed
						color="success"
						@click="handleViewFiles(item)"
					>
						{{ item.SoHopDong }}
					</v-btn>
					<span v-else class="grey--text">-</span>
				</template>

				<template v-slot:item.minhChung="{ item }">
					<v-btn
						v-if="hasFiles(item)"
						icon
						small
						color="primary"
						title="Xem tập tin minh chứng"
						@click="handleViewFiles(item)"
					>
						<v-icon small>mdi-attachment</v-icon>
					</v-btn>
					<span v-else class="grey--text text-caption">-</span>
				</template>

				<template v-slot:item.actions="{ item }">
					<div class="d-flex justify-center align-center">
						<!-- Phê duyệt nhanh nếu đang Chờ duyệt -->
						<v-btn
							v-if="item.TrangThai === 2"
							icon
							x-small
							color="green darken-2"
							class="mr-1"
							title="Phê duyệt hồ sơ"
							@click="onApprove(item)"
						>
							<v-icon small>mdi-check-circle-outline</v-icon>
						</v-btn>

						<!-- Từ chối / Yêu cầu bổ sung nếu đang Chờ duyệt -->
						<v-btn
							v-if="item.TrangThai === 2"
							icon
							x-small
							color="red darken-2"
							class="mr-1"
							title="Yêu cầu bổ sung / Từ chối"
							@click="openRejectDialog(item)"
						>
							<v-icon small>mdi-close-circle-outline</v-icon>
						</v-btn>

						<!-- Sửa / Xem -->
						<v-btn
							icon
							x-small
							color="primary"
							class="mr-1"
							title="Xem chi tiết / Cập nhật"
							@click="handleEdit(item)"
						>
							<v-icon small>mdi-square-edit-outline</v-icon>
						</v-btn>

						<!-- Xóa -->
						<v-btn
							icon
							x-small
							color="red darken-3"
							title="Xóa"
							@click="handleDelete(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
					</div>
				</template>
			</v-data-table>
		</v-card-text>

		<!-- Dialog nhập lý do từ chối / yêu cầu bổ sung -->
		<v-dialog v-model="rejectDialog" max-width="500" persistent>
			<v-card>
				<v-card-title class="py-2 px-4 red lighten-1 white--text text-subtitle-1">
					<v-icon left color="white">mdi-alert-circle</v-icon>
					Yêu cầu bổ sung hồ sơ
				</v-card-title>
				<v-card-text class="pt-4 px-4 pb-1">
					<div class="text-body-2 mb-2">
						Dự án: <b>{{ rejectTargetItem ? rejectTargetItem.TenDuAn : "" }}</b>
					</div>
					<v-textarea
						v-model="rejectReason"
						label="Nội dung cần bổ sung / Lý do trả về *"
						rows="3"
						outlined
						dense
						autofocus
						placeholder="Nhập chi tiết các nội dung giảng viên cần bổ sung hoặc lý do từ chối..."
					/>
				</v-card-text>
				<v-card-actions class="py-2 px-4">
					<v-spacer />
					<v-btn text small @click="closeRejectDialog">Hủy</v-btn>
					<v-btn
						color="red"
						dark
						small
						depressed
						:loading="isSubmittingReject"
						@click="confirmReject"
					>
						Xác nhận trả về
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-card>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			tableRows: {
				type: Array,
				default: () => []
			},
			statusCounts: {
				type: Object,
				default: () => ({
					totalAll: 0,
					countDraft: 0,
					countPending: 0,
					countApproved: 0,
					countRejected: 0
				})
			}
		},
		emits: ["on-add", "on-edit", "on-delete", "on-view-files", "on-approve", "on-reject"],
		data() {
			return {
				activeTab: 0,
				isLoadingExport: false,
				searchText: "",
				selectedYear: null,

				// Reject dialog
				rejectDialog: false,
				rejectReason: "",
				rejectTargetItem: null,
				isSubmittingReject: false,

				tableHeaders: [
					{ text: "STT", value: "SoThuTu", align: "center", sortable: false, width: 65, cellClass: "text-center" },
					{ text: "Trạng thái", value: "TrangThai", align: "center", width: 110, cellClass: "text-center" },
					{ text: "Tên dự án / Hợp đồng", value: "TenDuAn", minWidth: 260 },
					{ text: "Chủ nhiệm", value: "ChuNhiemDeTai", width: 150 },
					{ text: "ĐV tiếp nhận", value: "DonViTiepNhan", width: 160 },
					{ text: "Giá trị HĐ", value: "GiaTriHopDong", align: "right", width: 130 },
					{ text: "Năm học", value: "NamHoc", align: "center", width: 95 },
					{ text: "Năm TH", value: "NamThucHien", align: "center", width: 85 },
					{ text: "Số HĐ", value: "SoHopDong", align: "center", width: 120 },
					{ text: "Minh chứng", value: "minhChung", align: "center", sortable: false, width: 90, exportIgnore: true },
					{ text: "Thao tác", value: "actions", align: "center", sortable: false, width: 130, exportIgnore: true }
				]
			}
		},
		computed: {
			yearOptions() {
				const years = []
				const rows = Array.isArray(this.tableRows) ? this.tableRows : []
				rows.forEach(item => {
					if (item && item.NamHoc && !years.includes(item.NamHoc)) {
						years.push(item.NamHoc)
					}
				})
				return years.sort().reverse()
			},
			filteredRows() {
				let rows = Array.isArray(this.tableRows) ? this.tableRows : []

				// Lọc theo tabs:
				// Tab 0: Chờ xét duyệt (TrangThai = 2)
				// Tab 1: Đã phê duyệt (TrangThai = 3)
				// Tab 2: Cần bổ sung (TrangThai = 4)
				// Tab 3: Dự thảo (TrangThai = 1)
				// Tab 4: Tất cả
				if (this.activeTab === 0) {
					rows = rows.filter(item => item && item.TrangThai === 2)
				} else if (this.activeTab === 1) {
					rows = rows.filter(item => item && item.TrangThai === 3)
				} else if (this.activeTab === 2) {
					rows = rows.filter(item => item && item.TrangThai === 4)
				} else if (this.activeTab === 3) {
					rows = rows.filter(item => item && item.TrangThai === 1)
				}

				if (this.selectedYear) {
					rows = rows.filter(item => item && item.NamHoc === this.selectedYear)
				}

				return rows
			}
		},
		methods: {
			getStatusText(status) {
				switch (Number(status)) {
					case 1: return "Dự thảo"
					case 2: return "Chờ duyệt"
					case 3: return "Đã duyệt"
					case 4: return "Cần bổ sung"
					default: return "Chưa rõ"
				}
			},
			getStatusChipColor(status) {
				switch (Number(status)) {
					case 1: return "grey lighten-2"
					case 2: return "orange lighten-4"
					case 3: return "green lighten-4"
					case 4: return "red lighten-4"
					default: return "grey lighten-2"
				}
			},
			getStatusChipTextColor(status) {
				switch (Number(status)) {
					case 1: return "grey darken-3"
					case 2: return "orange darken-4"
					case 3: return "green darken-4"
					case 4: return "red darken-4"
					default: return "grey darken-3"
				}
			},
			formatMoney(val) {
				if (val === null || val === undefined || val === "") return "0"
				if (typeof formatAsCurrency === "function") {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString("vi-VN")
			},
			getRowIndex(item) {
				if (item && item.SoThuTu) return item.SoThuTu
				const idx = this.filteredRows.indexOf(item)
				return idx >= 0 ? idx + 1 : ""
			},
			parseFiles(rawFileData) {
				if (!rawFileData) return []
				if (Array.isArray(rawFileData)) return rawFileData
				if (typeof rawFileData === "string") {
					try {
						const parsed = JSON.parse(rawFileData)
						return Array.isArray(parsed) ? parsed : []
					} catch (e) {
						return []
					}
				}
				return []
			},
			hasFiles(item) {
				return this.parseFiles(item && item.FileData).length > 0
			},
			handleAdd() {
				this.$emit("on-add")
			},
			handleEdit(item) {
				this.$emit("on-edit", item)
			},
			handleDelete(item) {
				this.$emit("on-delete", item)
			},
			handleViewFiles(item) {
				this.$emit("on-view-files", item)
			},
			onApprove(item) {
				confirm({
					title: `Phê duyệt dự án/hợp đồng chuyển giao công nghệ <b><i>${item.TenDuAn}</i></b>?`,
					action: () => {
						this.$emit("on-approve", item)
					}
				})
			},
			openRejectDialog(item) {
				this.rejectTargetItem = item
				this.rejectReason = item.LyDoReject || ""
				this.rejectDialog = true
			},
			closeRejectDialog() {
				this.rejectDialog = false
				this.rejectTargetItem = null
				this.rejectReason = ""
			},
			confirmReject() {
				if (!this.rejectReason || !this.rejectReason.trim()) {
					Vue.$toast.warning("Vui lòng nhập lý do từ chối / nội dung cần bổ sung", { position: "top" })
					return
				}
				this.$emit("on-reject", {
					item: this.rejectTargetItem,
					reason: this.rejectReason.trim()
				})
				this.closeRejectDialog()
			},
			onPrintExcel() {
				this.isLoadingExport = true
				try {
					const dataExport = this.filteredRows.map((item, idx) => ({
						"STT": item.SoThuTu || (idx + 1),
						"Trạng thái": this.getStatusText(item.TrangThai),
						"Tên dự án / Hợp đồng": item.TenDuAn || "",
						"Chủ nhiệm": item.ChuNhiemDeTai || "",
						"Thành viên": item.ThanhVienDeTai || "",
						"ĐV chủ nhiệm": item.DonViChuNhiem || "",
						"ĐV tiếp nhận": item.DonViTiepNhan || "",
						"Giá trị HĐ": Number(item.GiaTriHopDong) || 0,
						"Năm học": item.NamHoc || "",
						"Năm TH": item.NamThucHien || "",
						"Số HĐ": item.SoHopDong || "",
						"Người nộp": item.NhanVienSubmit || "",
						"Lý do trả về": item.LyDoReject || ""
					}))
					jsonToExcel({
						data: dataExport,
						filename: "Danh_Sach_Chuyen_Giao_Cong_Nghe_DEV.xlsx",
						worksheet: "CGCN"
					})
				} finally {
					this.isLoadingExport = false
				}
			}
		}
	}
</script>