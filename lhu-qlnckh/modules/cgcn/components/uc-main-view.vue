<template>
	<v-card outlined class="rounded-xs elevation-1 d-flex flex-column flex-grow-1 cgcn-card">
		<v-card-title class="py-2 px-3 d-flex flex-wrap align-center">
			<span class="primary--text font-weight-bold text-subtitle-1 mr-4">
				Danh sách dự án / hợp đồng chuyển giao công nghệ
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

		<v-card-text class="pa-0 flex-grow-1 cgcn-card-body">
			<v-data-table
				dense
				fixed-header
				height="calc(100vh - 295px)"
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

				<template v-slot:item.TenDuAn="{ item }">
					<div class="py-1 font-weight-medium">{{ item.TenDuAn }}</div>
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
						<v-btn
							icon
							x-small
							color="green darken-2"
							class="mr-1"
							title="Cập nhật"
							@click="handleEdit(item)"
						>
							<v-icon small>mdi-square-edit-outline</v-icon>
						</v-btn>
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
	</v-card>
</template>

<script>
	export default {
		name: "uc-main-view",
	props: {
		tableRows: {
			type: Array,
			default: () => []
		}
	},
	emits: ["on-add", "on-edit", "on-delete", "on-view-files"],
	data() {
		return {
			// 1. Static / Table headers
			tableHeaders: [
				{ text: "STT", value: "SoThuTu", align: "center", sortable: false, width: 70, class: "text-center text-no-wrap", cellClass: "text-center" },
				{ text: "Tên dự án / Hợp đồng", value: "TenDuAn", width: 300 },
				{ text: "Chủ nhiệm", value: "ChuNhiemDeTai", width: 160 },
				{ text: "Thành viên", value: "ThanhVienDeTai", width: 180 },
				{ text: "ĐV chủ nhiệm", value: "DonViChuNhiem", width: 160 },
				{ text: "ĐV tiếp nhận", value: "DonViTiepNhan", width: 160 },
				{ text: "Giá trị HĐ", value: "GiaTriHopDong", align: "right", width: 130 },
				{ text: "Năm học", value: "NamHoc", align: "center", width: 100 },
				{ text: "Năm TH", value: "NamThucHien", align: "center", width: 90 },
				{ text: "Số HĐ", value: "SoHopDong", align: "center", width: 130 },
				{ text: "Minh chứng", value: "minhChung", align: "center", sortable: false, width: 95, exportIgnore: true },
				{ text: "Thao tác", value: "actions", align: "center", sortable: false, width: 90, exportIgnore: true }
			],

			// 2. Local filter state
			isLoadingExport: false,
			searchText: "",
			selectedYear: null
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
			const rows = Array.isArray(this.tableRows) ? this.tableRows : []
			if (!this.selectedYear) {
				return rows
			}
			return rows.filter(item => item && item.NamHoc === this.selectedYear)
		}
	},
	methods: {
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
		onPrintExcel() {
			this.isLoadingExport = true
			try {
				const dataExport = this.filteredRows.map((item, idx) => ({
					"STT": item.SoThuTu || (idx + 1),
					"Tên dự án / Hợp đồng": item.TenDuAn || "",
					"Chủ nhiệm": item.ChuNhiemDeTai || "",
					"Thành viên": item.ThanhVienDeTai || "",
					"ĐV chủ nhiệm": item.DonViChuNhiem || "",
					"ĐV tiếp nhận": item.DonViTiepNhan || "",
					"Giá trị HĐ": Number(item.GiaTriHopDong) || 0,
					"Năm học": item.NamHoc || "",
					"Năm TH": item.NamThucHien || "",
					"Số HĐ": item.SoHopDong || ""
				}))
				jsonToExcel({
					data: dataExport,
					filename: "Danh_Sach_Chuyen_Giao_Cong_Nghe.xlsx",
					worksheet: "CGCN"
				})
			} finally {
				this.isLoadingExport = false
			}
		}
	}
	}
</script>