<template>
	<v-card outlined :loading="loading" class="rounded-xs mb-3">
		<v-card-title class="py-2 px-4 d-flex align-center flex-wrap primary--text">
			<span class="mr-3 text-subtitle-1 font-weight-bold">
				{{ title || "" }}
				<v-chip v-if="detailTitle" small class="ml-2 white--text" color="primary" :href="hrefDetailTitle"
					target="_blank">
					<v-icon left small>mdi-code-tags</v-icon>{{ detailTitle }}
				</v-chip>
			</span>
			<v-btn rounded small outlined v-if="IsShowBtnDialog" @click="isOpenDialogCGCN = true" color="primary"
				class="mr-2 text-none">
				<v-icon left small>mdi-table-eye</v-icon>Xem chi tiết ({{ Data_CGCN.length || 0 }})
			</v-btn>
			<v-btn rounded small outlined v-if="IsShowBtnDialogGiaiThuong" @click="isOpenDialogGiaiThuong = true"
				color="primary" class="mr-2 text-none">
				<v-icon left small>mdi-table-eye</v-icon>Xem chi tiết
			</v-btn>
			<v-spacer></v-spacer>
			<div class="d-flex align-center ga-2 reponsive--rightTitle-mobile">
				<slot name="rightTitle"></slot>
			</div>
		</v-card-title>
		<v-divider></v-divider>
		<v-card-text class="pa-3 black--text">
			<slot name="renderBody"></slot>
		</v-card-text>

		<v-dialog v-model="isOpenDialogCGCN" width="96vw" max-width="96vw" scrollable persistent>
			<v-card outlined class="rounded-xs">
				<v-card-title class="py-2 px-4 primary white--text d-flex align-center">
					<span class="text-subtitle-1 font-weight-bold">
						Danh sách dự án/hợp đồng chuyển giao công nghệ ({{ Data_CGCN.length }})
					</span>
					<v-spacer></v-spacer>
					<v-btn icon dark small @click="isOpenDialogCGCN = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pa-3 overflow-hidden">
					<uc-dtable title="Danh sách dự án/hợp đồng chuyển giao công nghệ" :items="Data_CGCN"
						:headers="headers" :isSearch="true" itemKey="SoThuTu"
						tableHeight="calc(100vh - 280px)"></uc-dtable>
				</v-card-text>
			</v-card>
		</v-dialog>

		<v-dialog v-model="isOpenDialogGiaiThuong" width="96vw" max-width="96vw" scrollable persistent>
			<v-card outlined class="rounded-xs">
				<v-card-title class="py-2 px-4 primary white--text d-flex align-center">
					<span class="text-subtitle-1 font-weight-bold">
						{{ TenLoaiGiaiThuongPlain }} ({{ Data_GiaiThuong.length }})
					</span>
					<v-spacer></v-spacer>
					<v-btn icon dark small @click="isOpenDialogGiaiThuong = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pa-3 overflow-hidden">
					<div class="mb-2">
						<v-select label="Loại giải thưởng" v-model="LoaiGiaiThuongID" :items="LoaiGiaiThuong"
							item-text="TenLoaiGiaiThuong" item-value="LoaiGiaiThuongID" dense outlined hide-details
							class="dashboard-select-400"></v-select>
					</div>
					<uc-dtable :title="TenLoaiGiaiThuongPlain" :items="Data_GiaiThuong" :headers="headers_GiaiThuong"
						:isSearch="true" itemKey="SoThuTu" tableHeight="calc(100vh - 330px)"></uc-dtable>
				</v-card-text>
			</v-card>
		</v-dialog>
	</v-card>
</template>

<script>
	export default {
		props: {
		title: {
			type: String,
			default: ""
		},
		detailTitle: {
			type: String,
			default: ""
		},
		loading: {
			type: Boolean,
			default: false
		},
		hrefDetailTitle: {
			type: String,
			default: ""
		},
		IsShowBtnDialog: {
			type: Boolean,
			default: false
		},
		btnOpenDialog: {
			type: Boolean,
			default: false
		},
		btnOpenDialogGiaiThuong: {
			type: Boolean,
			default: false
		},
		IsShowBtnDialogGiaiThuong: {
			type: Boolean,
			default: false
		}
	},
	data() {
		return {
			isOpenDialogCGCN: false,
			isOpenDialogGiaiThuong: false,
			headers: [
				{ text: "STT", value: "SoThuTu", width: "70px", align: "center" },
				{ text: "Tên Dự án/Hợp đồng", value: "TenDuAn" },
				{ text: "Chủ nhiệm", value: "ChuNhiemDeTai" },
				{ text: "Thành viên thực hiện", value: "ThanhVienDeTai" },
				{ text: "Đơn vị chủ nhiệm", value: "DonViChuNhiem" },
				{ text: "Đơn vị tiếp nhận", value: "DonViTiepNhan" },
				{ text: "Giá trị hợp đồng", value: "GiaTriHopDong", align: "right" },
				{ text: "Năm thực hiện", value: "NamThucHien", align: "center" }
			],
			headers_GiaiThuong: [
				{ text: "STT", value: "SoThuTu", width: "70px", align: "center" },
				{ text: "Đề tài", value: "TenDeTai" },
				{ text: "Tác giả", value: "TacGia" },
				{ text: "Đơn vị", value: "DonVi" },
				{ text: "Giải", value: "Giai" },
				{ text: "Năm đạt giải", value: "NamDatGiai", align: "center" }
			],
			Data_CGCN: [],
			LoaiGiaiThuong: [],
			LoaiGiaiThuongID: 0,
			Data_GiaiThuong: [],
			TenLoaiGiaiThuongPlain: "Danh sách giải thưởng"
		}
	},
	async mounted() {
		await Promise.all([
			this.API_ChuyenGiaoCongNghe_Get(),
			this.API_LoaiGiaiThuong_Get_All()
		])
	},
	watch: {
		isOpenDialogCGCN(val) {
			if (val && this.Data_CGCN.length === 0) {
				this.API_ChuyenGiaoCongNghe_Get()
			}
		},
		isOpenDialogGiaiThuong(val) {
			if (val && this.LoaiGiaiThuong.length === 0) {
				this.API_LoaiGiaiThuong_Get_All()
			}
		},
		LoaiGiaiThuongID() {
			this.API_GiaiThuong_Get_ByLoaiGiaiThuongID()
		}
	},
	methods: {
		async API_ChuyenGiaoCongNghe_Get() {
			if (!this.IsShowBtnDialog) return
			const res = await ajaxCALLPromise("/ChuyenGiaoCongNghe_AUN_Get", {})
			const rows = Array.isArray(res) ? res : []
			this.Data_CGCN = rows.map((item, idx) => ({
				...item,
				SoThuTu: item.SoThuTu || (idx + 1),
				GiaTriHopDong: item.GiaTriHopDong != null ? Number(item.GiaTriHopDong).toLocaleString("vi-vn") : ""
			}))
		},
		async API_LoaiGiaiThuong_Get_All() {
			if (!this.IsShowBtnDialogGiaiThuong) return
			const res = await ajaxCALLPromise("/LoaiGiaiThuong_Get_All", {})
			const rows = Array.isArray(res) ? res : []
			this.LoaiGiaiThuong = rows
			if (rows.length > 0) {
				this.LoaiGiaiThuongID = rows[0].LoaiGiaiThuongID
				await this.API_GiaiThuong_Get_ByLoaiGiaiThuongID()
			}
		},
		async API_GiaiThuong_Get_ByLoaiGiaiThuongID() {
			if (this.LoaiGiaiThuongID === null || this.LoaiGiaiThuongID === undefined) return
			const res = await ajaxCALLPromise("/GiaiThuong_Get_ByLoaiGiaiThuongID", {
				LoaiGiaiThuongID: this.LoaiGiaiThuongID
			})
			const rows = Array.isArray(res) ? res : []
			this.Data_GiaiThuong = rows.map((item, idx) => ({
				...item,
				SoThuTu: item.SoThuTu || (idx + 1)
			}))
			const found = this.LoaiGiaiThuong.find(item => item.LoaiGiaiThuongID === this.LoaiGiaiThuongID)
			this.TenLoaiGiaiThuongPlain = "Danh sách giải thưởng: " + (found ? found.TenLoaiGiaiThuong : "Tất cả")
		}
	}
	}
</script>