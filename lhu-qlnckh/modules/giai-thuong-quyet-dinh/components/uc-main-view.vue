<template>
	<v-card outlined class="rounded-xs elevation-1 d-flex flex-column flex-grow-1 gtqd-card">
		<v-card-title class="py-2 px-3 d-flex flex-wrap align-center">
			<span class="primary--text font-weight-bold text-subtitle-1 mr-4">
				Danh sách quyết định khen thưởng
			</span>

			<v-spacer />

			<div class="d-flex align-center flex-wrap">
				<v-btn
					color="secondary"
					small
					outlined
					class="mr-2"
					@click="handleBack"
				>
					<v-icon left small>mdi-arrow-left</v-icon>
					Quản lý giải thưởng
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
					class="c-underline-search mr-2 gtqd-search-input"
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

		<v-card-text class="pa-0 flex-grow-1">
			<v-data-table
				dense
				fixed-header
				height="calc(100vh - 290px)"
				:headers="tableHeaders"
				:items="tableRows"
				:search="searchText"
				item-key="QDID"
				:items-per-page="50"
				:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }"
				class="gtqd-table elevation-0"
				no-data-text="Không có quyết định nào"
			>
				<template v-slot:item.SoThuTu="{ item }">
					<div class="text-center">{{ getRowIndex(item) }}</div>
				</template>

				<template v-slot:item.MaSoQD="{ item }">
					<span :class="item.MaSoQD ? 'red--text font-weight-bold' : 'grey--text'">
						{{ item.MaSoQD || "Chưa có" }}
					</span>
				</template>

				<template v-slot:item.MoTaQD="{ item }">
					<div class="text-caption py-1">{{ item.MoTaQD || "-" }}</div>
				</template>

				<template v-slot:item.NgayQD="{ item }">
					<div class="text-center text-caption">{{ formatDate(item) }}</div>
				</template>

				<template v-slot:item.SoGiaiThuong="{ item }">
					<div class="text-center">
						<v-chip
							x-small
							:color="Number(item.SoGiaiThuong) > 0 ? 'primary' : 'grey lighten-2'"
							:class="Number(item.SoGiaiThuong) > 0 ? '' : 'grey--text text--darken-1'"
						>
							{{ Number(item.SoGiaiThuong) || 0 }}
						</v-chip>
					</div>
				</template>

				<template v-slot:item.SoTapTin="{ item }">
					<div class="text-center">
						<v-chip
							x-small
							:color="Number(item.SoTapTin) > 0 ? 'teal' : 'grey lighten-2'"
							:class="Number(item.SoTapTin) > 0 ? 'white--text' : 'grey--text text--darken-1'"
						>
							{{ Number(item.SoTapTin) || 0 }}
						</v-chip>
					</div>
				</template>

				<template v-slot:item.uploadFile="{ item }">
					<div class="text-center">
						<v-btn
							icon
							x-small
							color="primary"
							title="Quản lý tập tin quyết định"
							@click="handleManageFiles(item)"
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
		isLoadingExport: {
			type: Boolean,
			default: false
		}
	},
	emits: ["on-add", "on-edit", "on-delete", "on-manage-files"],
	data() {
		return {
			searchText: "",
			tableHeaders: [
				{ text: "STT", value: "SoThuTu", align: "center", sortable: false, width: 60 },
				{ text: "Số quyết định", value: "MaSoQD", width: 180 },
				{ text: "Mô tả / Trích yếu", value: "MoTaQD", width: 300 },
				{ text: "Ngày ký", value: "NgayQD", align: "center", width: 120 },
				{ text: "Đề tài", value: "SoGiaiThuong", align: "center", width: 80 },
				{ text: "Tập tin", value: "SoTapTin", align: "center", width: 80 },
				{ text: "Đính kèm", value: "uploadFile", align: "center", sortable: false, width: 85 },
				{ text: "Thao tác", value: "actions", align: "center", sortable: false, width: 95 }
			]
		}
	},
	methods: {
		handleBack() {
			window.location.href = "/giai-thuong-quan-ly"
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
		handleManageFiles(item) {
			this.$emit("on-manage-files", item)
		},
		getRowIndex(item) {
			return this.tableRows.indexOf(item) + 1
		},
		formatDate(item) {
			if (!item || !item.NamQD) return "--"
			const day = item.NgayQD || "--"
			const month = item.ThangQD || "--"
			return `${day}-${month}-${item.NamQD}`
		},
		onPrintExcel() {
			const exportData = this.tableRows.map((item, index) => ({
				"STT": index + 1,
				"Số quyết định": item.MaSoQD || "",
				"Mô tả": item.MoTaQD || "",
				"Ngày ký": this.formatDate(item),
				"Số đề tài": Number(item.SoGiaiThuong) || 0,
				"Số tập tin đính kèm": Number(item.SoTapTin) || 0
			}))

			jsonToExcel({
				data: exportData,
				filename: "DanhSachQuyetDinhKhenThuong.xlsx",
				worksheet: "QuyetDinh"
			})
		}
	}
	}
</script>