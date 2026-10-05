<template>
	<v-card :style="{ 'background-color': vueData.mode ? vueData.colorMode.dark.secondary : 'white' }"
		:loading="loading" class="mb-2">
		<v-card-title :class="vueData.mode ? 'white--text' : 'primary--text'">
			<span class="mr-5"> {{ title ?? "" }} <v-chip v-if="detailTitle" class="ml-1"
					:color="vueData.mode ? 'white' : 'primary'" :href="hrefDetailTitle" target="_blank"
					:style="{ color: vueData.mode ? 'black' : 'white' }">
					<v-icon left>mdi-code-tags</v-icon>{{ detailTitle }}</v-chip></span>
			<v-btn rounded v-if="IsShowBtnDialog" @click="btnOpenDialog = true" color="primary"><v-icon
					left>mdi-code-tags</v-icon>Xem chi tiết</v-btn>
			<v-btn rounded v-if="IsShowBtnDialogGiaiThuong" @click="btnOpenDialogGiaiThuong = true" color="primary">
				<v-icon left>mdi-code-tags</v-icon>Xem chi tiết
			</v-btn>
			<v-spacer></v-spacer>
			<div style="display:flex;gap:10px; align-items:center" class="reponsive--rightTitle-mobile">
				<slot name="rightTitle"></slot>
			</div>
		</v-card-title>
		<v-card-text :class="vueData.mode ? 'white--text' : 'black--text'">
			<slot name="renderBody"></slot>
		</v-card-text>
		<v-dialog v-model="btnOpenDialog" fullscreen hide-overlay>
			<v-card>
				<v-toolbar dark color="primary">
					<v-toolbar-title>Xem chi tiết</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon dark @click="btnOpenDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-btn class="mr-6" icon color="primary" @click="toExcel" style="display:none">
						<v-icon>mdi-microsoft-excel</v-icon>
					</v-btn>
					<f-table label="Danh sách dự án/hợp đồng chuyển giao công nghệ" :items="Data_CGCN"
						:headers="headers" class="mt-5" :excel="true" :show-search="true" :items-per-page="50"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"></f-table>
				</v-card-text>
			</v-card>
		</v-dialog>
		<v-dialog v-model="btnOpenDialogGiaiThuong" fullscreen hide-overlay>
			<v-card>
				<v-toolbar dark color="primary">
					<v-toolbar-title>Xem chi tiết</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon dark @click="btnOpenDialogGiaiThuong = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-select label="Loại giải thưởng" v-model="LoaiGiaiThuongID"
						@change="API_GiaiThuong_Get_ByLoaiGiaiThuongID" class="mt-5" :items="LoaiGiaiThuong"
						item-text="TenLoaiGiaiThuong" item-value="LoaiGiaiThuongID" dense outlined hide-details
						style="width:400px"></v-select>
					<f-table :label="TenLoaiGiaiThuong" :items="Data_GiaiThuong" :headers="headers_GiaiThuong"
						class="mt-5" :excel="true" :show-search="true" :items-per-page="50"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"></f-table>
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
			default: ''
		},
		detailTitle: {
			type: String,
			default: ''
		},
		loading: {
			type: Boolean,
			default: false
		},
		hrefDetailTitle: {
			type: String,
			default: ''
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
		},
	},
	data() {
		return {
			headers: [
				{ text: "STT", value: "SoThuTu" },
				{ text: "Tên Dự án/Hợp đồng", value: "TenDuAn" },
				{ text: "Chủ nhiệm", value: "ChuNhiemDeTai" },
				{ text: "Thành viên thực hiện", value: "ThanhVienDeTai" },
				{ text: "Đơn vị chủ nhiệm", value: "DonViChuNhiem" },
				{ text: "Đơn vị tiếp nhận", value: "DonViTiepNhan" },
				{ text: "Giá trị hợp đồng", value: "GiaTriHopDong", align: "right" },
				{ text: "Năm thực hiện", value: "NamThucHien", align: "center" },
			],
			headers_GiaiThuong: [
				{ text: "STT", value: "SoThuTu" },
				{ text: "Đề tài", value: "TenDeTai" },
				{ text: "Tác giả", value: "TacGia" },
				{ text: "Đơn vị", value: "DonVi" },
				{ text: "Giải", value: "Giai" },
				{ text: "Năm đạt giải", value: "NamDatGiai", align: "center" },
			],
			Data_CGCN: [],
			LoaiGiaiThuong: [],
			LoaiGiaiThuongID: 0,
			Data_GiaiThuong: [],
			TenLoaiGiaiThuong: "Danh sách giải thưởng: "
		}
	},
	mounted() {
	},
	created() {
		this.API_ChuyenGiaoCongNghe_Get()
		this.API_LoaiGiaiThuong_Get_All()
	},
	computed: {},
	watch: {
		LoaiGiaiThuongID: function (val) {
			this.API_GiaiThuong_Get_ByLoaiGiaiThuongID()
		}
	},
	methods: {
		API_ChuyenGiaoCongNghe_Get() {
			if (this.IsShowBtnDialog) {
				ajaxCALL("/ChuyenGiaoCongNghe_AUN_Get", {}, res => {
					this.Data_CGCN = res.data.map(item => ({ ...item, GiaTriHopDong: item.GiaTriHopDong.toLocaleString('vi-vn') }))
				}, err => {

				})
			}
		},
		API_LoaiGiaiThuong_Get_All() {
			if (this.IsShowBtnDialogGiaiThuong) {
				ajaxCALL("/LoaiGiaiThuong_Get_All", {}, res => {
					this.LoaiGiaiThuong = res.data
					this.LoaiGiaiThuongID = res.data[0].LoaiGiaiThuongID
				}, err => {

				})
			}
		},

		API_GiaiThuong_Get_ByLoaiGiaiThuongID() {
			ajaxCALL("/GiaiThuong_Get_ByLoaiGiaiThuongID", {
				LoaiGiaiThuongID: this.LoaiGiaiThuongID
			}, res => {
				this.Data_GiaiThuong = res.data
				this.TenLoaiGiaiThuong = "Danh sách giải thưởng: " + "<span class='red--text'>" + this.LoaiGiaiThuong.filter(item => item.LoaiGiaiThuongID === this.LoaiGiaiThuongID)[0].TenLoaiGiaiThuong + "</span>"
			}, err => {

			})
		},
		toExcel() {
			const $this = this
			var loadScript = new Loader()
			//sheet tổng hợp
			const initTitleColumn = [
				"STT",
				"Tên Dự án/ Hợp đồng",
				"Đơn vị tiếp nhận",
				"Giá trị HĐ",
				"Năm thực hiện",
				"Số/No. HĐ",
				"Ghi chú"
			]
			const titleColumn = [initTitleColumn]
			let handleFormatData = $this.Data_CGCN.map(item => {
				return {
					SoThuTu: item.SoThuTu,
					TenDuAn: item.TenDuAn,
					DonViTiepNhan: item.DonViTiepNhan,
					GiaTriHopDong: item.GiaTriHopDong,
					NamThucHien: item.NamThucHien,
					SoHopDong: item.SoHopDong,
					GhiChu: ''
				}
			})
			const keyDataExcel = Object.keys(handleFormatData[0])
			console.log('handleFormatData', handleFormatData)
			loadScript.require(['/include/xlsx/xlsx.full.min.js'], function () {
				var workbook = XLSX.utils.book_new()
				let dataGroupByKey = _.groupBy(handleFormatData, 'NamThucHien')
				let titleGroupByKey = Object.keys(dataGroupByKey)
				//BEGIN xử lý data từng sheet của file
				let tabs =
					[
						{
							tabName: "Tổng hợp",
							header: keyDataExcel,
							nameHeader: titleColumn,
							data: handleFormatData
						}
					]
				for (let i = 0; i <= titleGroupByKey.length - 1; i++) {
					let obj = {
						tabName: titleGroupByKey[i],
						header: keyDataExcel,
						nameHeader: titleColumn,
						data: dataGroupByKey[titleGroupByKey[i]]
					}
					tabs.push(obj)
				}
				//END xử lý data từng sheet của file
				//Ghi file
				for (var item of tabs) {
					if (item.header && item.header.length > 0) {
						writeExcelFile(workbook,
							item.data,
							item.nameHeader, item.tabName
						)
					} else {
						writeExcelFile(workbook,
							[],
							item.nameHeader, item.tabName
						)
					}
				}
				XLSX.writeFile(workbook, 'Danh-sach-CGCN.xlsx')
			})
			function writeExcelFile(workbook, data, headers, nameSheet) {
				var worksheet = XLSX.utils.json_to_sheet(data, { origin: 'A2', skipHeader: true })
				XLSX.utils.sheet_add_aoa(worksheet, headers, { origin: 'A1' })
				XLSX.utils.book_append_sheet(workbook, worksheet, nameSheet)
			}
		},

	},
}
</script>