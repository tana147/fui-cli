<template>
	<v-card outlined class="rounded-xs elevation-1 d-flex flex-column flex-grow-1 cgcn-card">
		<!-- Tabs trạng thái hồ sơ -->
		<v-tabs
			v-model="activeTab"
			background-color="transparent"
			color="primary"
			dense
			class="px-2 border-b"
		>
			<v-tab>
				Tất cả
				<v-chip x-small class="ml-1" color="grey lighten-2">
					{{ statsData.totalAll || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Dự thảo
				<v-chip x-small class="ml-1" color="grey lighten-2">
					{{ statsData.countDraft || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Chờ xét duyệt
				<v-chip x-small class="ml-1" color="orange lighten-4" text-color="orange darken-4">
					{{ statsData.countPending || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Cần bổ sung
				<v-chip x-small class="ml-1" color="red lighten-4" text-color="red darken-4">
					{{ statsData.countRejected || 0 }}
				</v-chip>
			</v-tab>
			<v-tab>
				Đã phê duyệt
				<v-chip x-small class="ml-1" color="green lighten-4" text-color="green darken-4">
					{{ statsData.countApproved || 0 }}
				</v-chip>
			</v-tab>
		</v-tabs>

		<!-- Toolbar tìm kiếm và nút kê khai -->
		<v-card-title class="py-2 px-3 d-flex flex-wrap align-center">
			<span class="primary--text font-weight-bold text-subtitle-1 mr-4">
				Hồ sơ chuyển giao công nghệ của tôi
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
					title="Xuất file Excel cá nhân"
					@click="onPrintExcel"
				>
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-text-field
					v-model="searchText"
					prepend-inner-icon="mdi-magnify"
					placeholder="Tìm kiếm dự án, số HĐ, đối tác..."
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
					Kê khai mới
				</v-btn>
			</div>
		</v-card-title>

		<!-- Bảng dữ liệu -->
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
				<!-- Cột STT -->
				<template v-slot:item.SoThuTu="{ item }">
					<div class="text-center">{{ getRowIndex(item) }}</div>
				</template>

				<!-- Cột Trạng thái -->
				<template v-slot:item.TrangThai="{ item }">
					<v-chip
						x-small
						:color="getStatusChipColor(item.TrangThai)"
						:text-color="getStatusChipTextColor(item.TrangThai)"
						class="font-weight-medium"
					>
						<v-icon left x-small>{{ getStatusIcon(item.TrangThai) }}</v-icon>
						{{ getStatusText(item.TrangThai) }}
					</v-chip>
				</template>

				<!-- Cột Tên dự án -->
				<template v-slot:item.TenDuAn="{ item }">
					<div class="py-1">
						<div class="font-weight-medium text-body-2">{{ item.TenDuAn }}</div>
						<!-- Cảnh báo nếu cần bổ sung -->
						<div
							v-if="item.TrangThai === 4 && item.LyDoReject"
							class="red--text text-caption font-weight-medium mt-1 d-flex align-center"
						>
							<v-icon x-small color="red" class="mr-1">mdi-alert-circle</v-icon>
							Yêu cầu sửa: {{ item.LyDoReject }}
						</div>
					</div>
				</template>

				<!-- Cột Giá trị hợp đồng -->
				<template v-slot:item.GiaTriHopDong="{ item }">
					<span class="font-weight-medium primary--text">
						{{ formatMoney(item.GiaTriHopDong) }}
					</span>
				</template>

				<!-- Cột Số hợp đồng -->
				<template v-slot:item.SoHopDong="{ item }">
					<span v-if="item.SoHopDong">{{ item.SoHopDong }}</span>
					<span v-else class="grey--text">-</span>
				</template>

				<!-- Cột Minh chứng -->
				<template v-slot:item.minhChung="{ item }">
					<v-btn
						v-if="hasFiles(item)"
						icon
						small
						color="primary"
						title="Xem tập tin minh chứng"
						@click="handleViewFiles(item)"
					>
						<v-badge
							:content="getFileCount(item)"
							color="primary"
							overlap
							x-small
						>
							<v-icon small>mdi-attachment</v-icon>
						</v-badge>
					</v-btn>
					<span v-else class="grey--text text-caption">-</span>
				</template>

				<!-- Cột Thao tác -->
				<template v-slot:item.actions="{ item }">
					<div class="d-flex justify-center align-center">
						<!-- Xem / Chỉnh sửa -->
						<v-btn
							icon
							x-small
							:color="item.TrangThai === 2 || item.TrangThai === 3 ? 'primary' : 'green darken-2'"
							class="mr-1"
							:title="item.TrangThai === 2 || item.TrangThai === 3 ? 'Xem chi tiết' : 'Chỉnh sửa hồ sơ'"
							@click="handleEdit(item)"
						>
							<v-icon small>
								{{ item.TrangThai === 2 || item.TrangThai === 3 ? 'mdi-eye-outline' : 'mdi-square-edit-outline' }}
							</v-icon>
						</v-btn>

						<!-- Nộp duyệt (Nếu là Dự thảo hoặc Cần bổ sung) -->
						<v-btn
							v-if="item.TrangThai === 1 || item.TrangThai === 4"
							icon
							x-small
							color="orange darken-3"
							class="mr-1"
							title="Gửi hồ sơ thẩm định"
							@click="handleSubmit(item)"
						>
							<v-icon small>mdi-send</v-icon>
						</v-btn>

						<!-- Xóa (Chỉ cho phép xóa khi là Dự thảo) -->
						<v-btn
							v-if="item.TrangThai === 1"
							icon
							x-small
							color="red darken-3"
							title="Xóa dự thảo"
							@click="handleDelete(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
					</div>
				</template>
			</v-data-table>
		</v-card-text>
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
			statsData: {
				type: Object,
				default: () => ({
					totalAll: 0,
					countDraft: 0,
					countPending: 0,
					countRejected: 0,
					countApproved: 0
				})
			}
		},
		emits: ["on-add", "on-edit", "on-delete", "on-submit", "on-view-files"],
		data() {
			return {
				activeTab: 0,
				isLoadingExport: false,
				searchText: "",
				selectedYear: null,
				tableHeaders: [
					{ text: "STT", value: "SoThuTu", align: "center", sortable: false, width: 60, cellClass: "text-center" },
					{ text: "Trạng thái", value: "TrangThai", align: "center", width: 120, cellClass: "text-center" },
					{ text: "Tên dự án / Hợp đồng", value: "TenDuAn", minWidth: 260 },
					{ text: "Chủ nhiệm", value: "ChuNhiemDeTai", width: 150 },
					{ text: "Đơn vị tiếp nhận (Đối tác)", value: "DonViTiepNhan", width: 180 },
					{ text: "Giá trị HĐ (VNĐ)", value: "GiaTriHopDong", align: "right", width: 130 },
					{ text: "Số HĐ", value: "SoHopDong", align: "center", width: 120 },
					{ text: "Năm học", value: "NamHoc", align: "center", width: 100 },
					{ text: "Minh chứng", value: "minhChung", align: "center", sortable: false, width: 90 },
					{ text: "Thao tác", value: "actions", align: "center", sortable: false, width: 100 }
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

				// Lọc theo tab
				// Tab 0: Tất cả
				// Tab 1: Dự thảo (TrangThai = 1)
				// Tab 2: Chờ xét duyệt (TrangThai = 2)
				// Tab 3: Cần bổ sung (TrangThai = 4)
				// Tab 4: Đã phê duyệt (TrangThai = 3)
				if (this.activeTab === 1) {
					rows = rows.filter(item => item && item.TrangThai === 1)
				} else if (this.activeTab === 2) {
					rows = rows.filter(item => item && item.TrangThai === 2)
				} else if (this.activeTab === 3) {
					rows = rows.filter(item => item && item.TrangThai === 4)
				} else if (this.activeTab === 4) {
					rows = rows.filter(item => item && item.TrangThai === 3)
				}

				// Lọc theo năm học
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
			getStatusIcon(status) {
				switch (Number(status)) {
					case 1: return "mdi-file-document-edit-outline"
					case 2: return "mdi-clock-outline"
					case 3: return "mdi-check-circle-outline"
					case 4: return "mdi-alert-circle-outline"
					default: return "mdi-help-circle-outline"
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
			getFileCount(item) {
				return this.parseFiles(item && item.FileData).length
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
			handleSubmit(item) {
				this.$emit("on-submit", item)
			},
			handleViewFiles(item) {
				this.$emit("on-view-files", item)
			},
			onPrintExcel() {
				this.isLoadingExport = true
				try {
					const dataExport = this.filteredRows.map((item, idx) => ({
						"STT": idx + 1,
						"Trạng thái": this.getStatusText(item.TrangThai),
						"Tên dự án / Hợp đồng": item.TenDuAn || "",
						"Chủ nhiệm": item.ChuNhiemDeTai || "",
						"Thành viên": item.ThanhVienDeTai || "",
						"ĐV chủ nhiệm": item.DonViChuNhiem || "",
						"ĐV tiếp nhận (Đối tác)": item.DonViTiepNhan || "",
						"Giá trị HĐ (VNĐ)": Number(item.GiaTriHopDong) || 0,
						"Số HĐ": item.SoHopDong || "",
						"Năm học": item.NamHoc || "",
						"Năm TH": item.NamThucHien || "",
						"Lý do trả về (nếu có)": item.LyDoReject || ""
					}))
					jsonToExcel({
						data: dataExport,
						filename: "Ho_So_Chuyen_Giao_Cong_Nghe_Ca_Nhan.xlsx",
						worksheet: "CGCN_CaNhan"
					})
				} finally {
					this.isLoadingExport = false
				}
			}
		}
	}
</script>