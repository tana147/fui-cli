<template>
	<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows" height="calc(100vh - 140px)"
		:options="tableOptions" />
</template>

<script>
	export default {
		props: ['DsBienDongGia'],
		data() {
			return {
				isTableReady: false,
				isLoading: false,
	
				tableHeaders: [],
				tableRows: [],
	
				tableOptions: {
					dataTree: true,
					dataTreeStartExpanded: false,
					dataTreeChildField: "_children",
					dataTreeElementColumn: "TenHangHoa",
	
					pagination: true,
	
					rowFormatter: function (row) {
						const data = row.getData()
	
						if (data._children) {
							row.getElement().style.fontWeight = "bold"
							row.getElement().style.background = "#f6f8fa"
						}
					}
				},
	
				// tableData: [
				// 	{
				// 		MaHangHoa: "HH001",
				// 		TenHangHoa: "Bột mì A",
				// 		DonViTinh: "Kg",
				// 		PhanLoaiHangHoa: "Nguyên liệu",
	
				// 		MaNhaCungCap: "NCC01",
				// 		TenNhaCungCap: "Minh Phát",
				// 		NhomNhaCungCap: "Nội địa",
	
				// 		_children: [
				// 			{
				// 				MaHangHoa: "HH001",
				// 				TenHangHoa: "Bột mì A",
				// 				DonViTinh: "Kg",
				// 				PhanLoaiHangHoa: "Nguyên liệu",
	
				// 				MaNhaCungCap: "NCC01",
				// 				TenNhaCungCap: "Minh Phát",
				// 				NhomNhaCungCap: "Nội địa",
	
				// 				NgayNhap: "01/03/2026",
				// 				SoChungTu: "PO001",
				// 				DiaDiem: "Kho A",
				// 				SoLuong: 123,
	
				// 				ChiPhiTruocThue: 12000,
				// 				ThueSuat: 10,
				// 				TienThue: 1200,
				// 				ChiPhiSauThue: 13200,
	
				// 				GiaBQLuyKe: 12000,
				// 				ChenhLechBQ: 0
				// 			},
				// 			{
				// 				MaHangHoa: "HH001",
				// 				TenHangHoa: "Bột mì A",
				// 				DonViTinh: "Kg",
				// 				PhanLoaiHangHoa: "Nguyên liệu",
	
				// 				MaNhaCungCap: "NCC01",
				// 				TenNhaCungCap: "Minh Phát",
				// 				NhomNhaCungCap: "Nội địa",
	
				// 				NgayNhap: "05/03/2026",
				// 				SoChungTu: "PO015",
				// 				DiaDiem: "Kho B",
				// 				SoLuong: 50,
	
				// 				ChiPhiTruocThue: 13000,
				// 				ThueSuat: 10,
				// 				TienThue: 1300,
				// 				ChiPhiSauThue: 14300,
	
				// 				GiaBQLuyKe: 12333,
				// 				ChenhLechBQ: 333
				// 			}
				// 		]
				// 	},
	
				// 	{
				// 		MaHangHoa: "HH002",
				// 		TenHangHoa: "Đường trắng",
				// 		DonViTinh: "Kg",
				// 		PhanLoaiHangHoa: "Nguyên liệu",
	
				// 		MaNhaCungCap: "NCC02",
				// 		TenNhaCungCap: "Hòa Bình",
				// 		NhomNhaCungCap: "Nội địa",
	
				// 		_children: [
				// 			{
				// 				MaHangHoa: "HH002",
				// 				TenHangHoa: "Đường trắng",
				// 				DonViTinh: "Kg",
				// 				PhanLoaiHangHoa: "Nguyên liệu",
	
				// 				MaNhaCungCap: "NCC02",
				// 				TenNhaCungCap: "Hòa Bình",
				// 				NhomNhaCungCap: "Nội địa",
	
				// 				NgayNhap: "02/03/2026",
				// 				SoChungTu: "PO021",
				// 				DiaDiem: "Kho A",
				// 				SoLuong: 80,
	
				// 				ChiPhiTruocThue: 15000,
				// 				ThueSuat: 10,
				// 				TienThue: 1500,
				// 				ChiPhiSauThue: 16500,
	
				// 				GiaBQLuyKe: 15000,
				// 				ChenhLechBQ: 0
				// 			},
				// 			{
				// 				MaHangHoa: "HH002",
				// 				TenHangHoa: "Đường trắng",
				// 				DonViTinh: "Kg",
				// 				PhanLoaiHangHoa: "Nguyên liệu",
	
				// 				MaNhaCungCap: "NCC02",
				// 				TenNhaCungCap: "Hòa Bình",
				// 				NhomNhaCungCap: "Nội địa",
	
				// 				NgayNhap: "08/03/2026",
				// 				SoChungTu: "PO035",
				// 				DiaDiem: "Kho C",
				// 				SoLuong: 120,
	
				// 				ChiPhiTruocThue: 16000,
				// 				ThueSuat: 10,
				// 				TienThue: 1600,
				// 				ChiPhiSauThue: 17600,
	
				// 				GiaBQLuyKe: 15600,
				// 				ChenhLechBQ: 600
				// 			}
				// 		]
				// 	}
				// ]
			}
		},
	
		watch: {
			DsBienDongGia(val) {
				if (val) {
					this.initData(val)
				}
			}
		},
	
		mounted() { },
	
		methods: {
			async initData(data) {
				this.isTableReady = false
	
				this.initTableHeaders()
	
				// this.tableRows = this.tableData
				this.tableRows = data
	
				this.isTableReady = true
			},
	
			initTableHeaders() {
				this.tableHeaders = [
					{
						title: "#",
						formatter: "rownum",
						width: 70,
						hozAlign: "center",
					},
	
					{
						title: "THÔNG TIN HÀNG HÓA",
						columns: [
							{
								title: "Mã hàng hóa",
								field: "MaNoiBo",
								width: 130,
								headerFilter: "input",
								formatter: this.parentOnlyFormatter
							},
							{
								title: "Tên hàng hóa",
								field: "TenHangHoa",
								width: 180,
								headerFilter: "input",
								formatter: this.parentOnlyFormatter
							},
							{
								title: "ĐVT",
								field: "TenDonVi",
								width: 90,
								hozAlign: "center",
								headerFilter: "input",
								formatter: this.parentOnlyFormatter
							},
							{
								title: "Phân loại",
								field: "PhanLoaiHangHoa",
								width: 150,
								headerFilter: "input",
								formatter: this.parentOnlyFormatter
							},
						]
					},
	
					{
						title: "THÔNG TIN NCC",
						columns: [
							{
								title: "Mã NCC",
								field: "MaNhaCungCap",
								width: 120,
								headerFilter: "input",
								// formatter: this.parentOnlyFormatter
							},
							{
								title: "Tên NCC",
								field: "TenNhaCungCap",
								width: 160,
								headerFilter: "input",
								// formatter: this.parentOnlyFormatter
							},
							{
								title: "Nhóm NCC",
								field: "NhomNhaCungCap",
								width: 150,
								headerFilter: "input",
								// formatter: this.parentOnlyFormatter
							}
						]
					},
	
					{
						title: "THÔNG TIN NHẬP",
						columns: [
							{
								title: "Ngày nhập",
								field: "NgayNhap",
								width: 130,
								headerFilter: "input",
								hozAlign: "center"
							},
							{
								title: "Số chứng từ",
								field: "SoChungTu",
								width: 140,
								headerFilter: "input",
							},
							{
								title: "Địa điểm",
								field: "DiaDiem",
								width: 120,
								headerFilter: "input",
							},
							{
								title: "Số lượng",
								field: "SoLuong",
								width: 120,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "SoLuong")
							}
						]
					},
	
					{
						title: "THÔNG TIN CHI PHÍ",
						columns: [
							{
								title: "Trước thuế",
								field: "ChiPhiTruocThue",
								width: 140,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "ChiPhiTruocThue")
							},
							{
								title: "Thuế GTGT",
								field: "ThueGTGT",
								width: 120,
								hozAlign: "center",
								headerFilter: "input",
								formatter: "money",
								formatterParams: {
									decimal: ",",
									thousand: ".",
									symbol: "",
									symbolAfter: false,
									precision: 2
								}
							},
							{
								title: "Thuế khác",
								field: "ThueKhac",
								width: 140,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "ThueKhac")
							},
							{
								title: "Thuế nhập khẩu",
								field: "ThueNhapKhau",
								width: 160,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "ThueNhapKhau")
							},
							{
								title: "Sau thuế",
								field: "ChiPhiSauThue",
								width: 140,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "ChiPhiSauThue")
							}
						]
					},
	
					{
						title: "CHỈ TIÊU TÍNH TOÁN",
						columns: [
							{
								title: "Giá BQ lũy kế",
								field: "GiaBQLuyKe",
								width: 150,
								hozAlign: "right",
								headerFilter: "input",
								formatter: "money",
								formatterParams: {
									decimal: ",",
									thousand: ".",
									symbol: "",
									symbolAfter: false,
									precision: 2
								}
							},
							{
								title: "Chênh lệch BQ",
								field: "ChenhLechBQ",
								width: 150,
								hozAlign: "right",
								headerFilter: "input",
								formatter: "money",
								formatterParams: {
									decimal: ",",
									thousand: ".",
									symbol: "",
									symbolAfter: false,
									precision: 2
								}
							},
							{
								title: "CP mua tăng",
								field: "ChiPhiMuaHangTang",
								width: 160,
								hozAlign: "right",
								headerFilter: "input",
								formatter: "money",
								formatterParams: {
									decimal: ",",
									thousand: ".",
									symbol: "",
									symbolAfter: false,
									precision: 2
								}
								// formatter: this.parentOnlyFormatter
							},
							{
								title: "Tổng chênh lệch",
								field: "TongChenhLechChiPhi",
								width: 170,
								hozAlign: "right",
								headerFilter: "input",
								formatter: "money",
								formatterParams: {
									decimal: ",",
									thousand: ".",
									symbol: "",
									symbolAfter: false,
									precision: 2
								}
							}
						]
					}
				]
			},
	
			parentOnlyFormatter(cell) {
				const row = cell.getRow()
	
				if (row.getTreeParent()) return ""
	
				return cell.getValue()
			},
	
			sumChildrenFormatter(cell, fieldName) {
	
				const row = cell.getRow()
				const data = row.getData()
	
				if (data._children) {
	
					let total = 0
	
					row.getTreeChildren().forEach(child => {
						total += Number(child.getData()[fieldName] || 0)
					})
	
					return total.toLocaleString("vi-VN")
				}
	
				return cell.getValue()
			},
	
			sumChildrenMoneyFormatter(cell, fieldName) {
	
				const row = cell.getRow()
				const data = row.getData()
	
				let value
	
				if (data._children) {
	
					let total = 0
	
					row.getTreeChildren().forEach(child => {
						total += Number(child.getData()[fieldName] || 0)
					})
	
					value = total
				}
				else {
					value = cell.getValue()
				}
	
				if (value == null) return ""
	
				return Number(value).toLocaleString("vi-VN", {
					minimumFractionDigits: 2,
					maximumFractionDigits: 2
				})
			}
		}
	}
</script>