<template>
	<v-card outlined class="rounded-xs elevation-1 d-flex flex-column flex-grow-1 gtql-card">
		<v-card-title class="py-2 px-3 d-flex flex-wrap align-center">
			<span class="primary--text font-weight-bold text-subtitle-1 mr-4">
				Danh sách giải thưởng:
				<span class="grey--text text--darken-2 font-weight-medium">
					{{ selectedLoaiGiaiThuongName || "Tất cả" }}
				</span>
			</span>

			<v-spacer />

			<div class="d-flex align-center flex-wrap">
				<v-select
					v-model="currentTypeId"
					:items="listLoaiGiaiThuong"
					item-value="LoaiGiaiThuongID"
					item-text="TenLoaiGiaiThuong"
					label="Loại giải thưởng"
					dense
					outlined
					hide-details
					class="gtql-type-select mr-2"
					@change="handleTypeChange"
					@update:model-value="handleTypeChange"
				/>

				<v-btn
					color="secondary"
					small
					outlined
					class="mr-2"
					@click="handleAddType"
				>
					<v-icon left small>mdi-plus</v-icon>
					Thêm loại
				</v-btn>

				<v-btn
					color="primary"
					small
					outlined
					class="mr-2"
					@click="handleNavDecision"
				>
					<v-icon left small>mdi-file-document-edit-outline</v-icon>
					Nhập số QĐ
				</v-btn>

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
					class="c-underline-search mr-2 gtql-search-input"
				/>

				<v-btn
					color="primary"
					small
					depressed
					@click="handleAddReward"
				>
					<v-icon left small>mdi-plus</v-icon>
					Thêm mới
				</v-btn>
			</div>
		</v-card-title>

		<v-card-text class="pa-0 flex-grow-1">
			<v-data-table
				dense
				fixed-header
				height="calc(100vh - 290px)"
				:headers="tableHeaders"
				:items="tableRows"
				:search="searchText"
				item-key="GiaiThuongID"
				:items-per-page="50"
				:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }"
				class="gtql-table elevation-0"
				no-data-text="Không có giải thưởng nào thuộc loại này"
			>
				<template v-slot:item.SoThuTu="{ item }">
					<div class="text-center">{{ item.SoThuTu || getRowIndex(item) }}</div>
				</template>

				<template v-slot:item.TenDeTai="{ item }">
					<div class="py-1 font-weight-medium text-subtitle-2">{{ item.TenDeTai }}</div>
				</template>

				<template v-slot:item.TacGia="{ item }">
					<div class="text-caption">{{ item.TacGia || "-" }}</div>
				</template>

				<template v-slot:item.DonVi="{ item }">
					<div class="text-caption">
						<div>{{ item.DonVi || "-" }}</div>
						<div class="font-weight-medium primary--text">{{ item.Giai || "" }}</div>
					</div>
				</template>

				<template v-slot:item.NamDatGiai="{ item }">
					<div class="text-center text-caption">
						{{ formatTime(item) }}
					</div>
				</template>

				<template v-slot:item.MaSoQD="{ item }">
					<div class="text-center">
						<v-btn
							v-if="item.QDID && item.QDID > 0"
							x-small
							depressed
							color="green darken-1"
							class="white--text"
							@click="handleViewDecision(item)"
						>
							{{ item.MaSoQD || "Xem QĐ" }}
						</v-btn>
						<span v-else class="grey--text text-caption">--</span>
					</div>
				</template>

				<template v-slot:item.SoTapTin="{ item }">
					<div class="text-center">
						<v-chip
							x-small
							:color="Number(item.SoTapTin) > 0 ? 'primary' : 'grey lighten-2'"
							:class="Number(item.SoTapTin) > 0 ? '' : 'grey--text text--darken-1'"
						>
							{{ getFileCount(item) }}
						</v-chip>
					</div>
				</template>

				<template v-slot:item.minhChung="{ item }">
					<div class="text-center">
						<v-btn
							icon
							x-small
							color="primary"
							title="Quản lý minh chứng"
							@click="handleOpenProofs(item)"
						>
							<v-icon small>mdi-attachment</v-icon>
						</v-btn>
					</div>
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
		},
		listLoaiGiaiThuong: {
			type: Array,
			default: () => []
		},
		selectedLoaiGiaiThuongId: {
			type: [Number, String],
			default: null
		},
		selectedLoaiGiaiThuongName: {
			type: String,
			default: ""
		},
		isLoadingExport: {
			type: Boolean,
			default: false
		}
	},
	emits: [
		"on-change-type",
		"on-add-reward-type",
		"on-add-reward",
		"on-edit-reward",
		"on-delete-reward",
		"on-open-proofs",
		"on-view-decision"
	],
	data() {
		return {
			searchText: "",
			currentTypeId: this.selectedLoaiGiaiThuongId,
			tableHeaders: [
				{ text: "STT", value: "SoThuTu", align: "center", sortable: false, width: 60 },
				{ text: "Đề tài / Cuộc thi", value: "TenDeTai", width: 280 },
				{ text: "Tác giả", value: "TacGia", width: 200 },
				{ text: "Đơn vị / Giải", value: "DonVi", width: 180 },
				{ text: "Thời gian", value: "NamDatGiai", align: "center", width: 100 },
				{ text: "Số quyết định", value: "MaSoQD", align: "center", width: 130 },
				{ text: "File MC", value: "SoTapTin", align: "center", width: 75 },
				{ text: "Minh chứng", value: "minhChung", align: "center", sortable: false, width: 85 },
				{ text: "Thao tác", value: "actions", align: "center", sortable: false, width: 95 }
			]
		}
	},
	watch: {
		selectedLoaiGiaiThuongId(val) {
			this.currentTypeId = val
		}
	},
	methods: {
		handleTypeChange(val) {
			this.$emit("on-change-type", val)
		},
		handleAddType() {
			this.$emit("on-add-reward-type")
		},
		handleAddReward() {
			this.$emit("on-add-reward")
		},
		handleEdit(item) {
			this.$emit("on-edit-reward", item)
		},
		handleDelete(item) {
			this.$emit("on-delete-reward", item)
		},
		handleOpenProofs(item) {
			this.$emit("on-open-proofs", item)
		},
		handleViewDecision(item) {
			this.$emit("on-view-decision", item)
		},
		handleNavDecision() {
			window.location.href = "/giai-thuong-quyet-dinh"
		},
		getRowIndex(item) {
			return this.tableRows.indexOf(item) + 1
		},
		formatTime(item) {
			if (!item || !item.NamDatGiai) return "--"
			const month = item.ThangDatGiai ? item.ThangDatGiai : "--"
			return `${month}/${item.NamDatGiai}`
		},
		getFileCount(item) {
			const count = parseInt(item.SoTapTin, 10)
			return isNaN(count) ? 0 : count
		},
		onPrintExcel() {
			const exportData = this.tableRows.map((item, index) => ({
				"STT": item.SoThuTu || (index + 1),
				"Tên đề tài / Cuộc thi": item.TenDeTai || "",
				"Tác giả": item.TacGia || "",
				"Đơn vị": item.DonVi || "",
				"Đạt giải": item.Giai || "",
				"Tháng đạt giải": item.ThangDatGiai || "",
				"Năm đạt giải": item.NamDatGiai || "",
				"Số quyết định": item.MaSoQD || "",
				"Số tập tin minh chứng": this.getFileCount(item)
			}))

			jsonToExcel({
				data: exportData,
				filename: `DanhSachGiaiThuong_${this.selectedLoaiGiaiThuongName || "All"}.xlsx`,
				worksheet: "DanhSach"
			})
		}
	}
	}
</script>