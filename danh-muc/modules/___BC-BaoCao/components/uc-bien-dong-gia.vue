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
	
				const rows = data.map(item => {
					let children = []
	
					if (item.Detail) {
						try {
							children = JSON.parse(item.Detail).map(child => ({
								...child,
	
								// copy field của parent để tree render
								TenHangHoa: item.TenHangHoa,
								MaNoiBo: item.MaNoiBo,
								TenDonVi: item.TenDonVi,
								PhanLoaiHangHoa: item.PhanLoaiHangHoa,
								PhanLoaiNhaCungCap: child.PhanLoaiNhaCungCap
									?.map(x => x.TenNhomPhanLoai)
									.join(", ")
							}))
						} catch (e) {
							children = []
						}
					}
	
					return {
						...item,
						_children: children
					}
				})
	
				console.log('Danh sách chuẩn: ', rows.find(x => x.TenHangHoa === "Bình chữa cháy ABC 2Kg"))
				this.tableRows = rows
	
	
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
						title: "THÔNG TIN NHÀ CUNG CẤP",
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
								field: "PhanLoaiNhaCungCap",
								width: 150,
								headerFilter: "input",
								// formatter: this.parentOnlyFormatter
							}
						]
					},
	
					{
						title: "THÔNG TIN MUA",
						columns: [
							{
								title: "Ngày mua kỳ này",
								field: "NgayNhap",
								width: 170,
								headerFilter: "input",
								hozAlign: "center",
								formatter: this.dateFormatter
							},
							{
								title: "Giá mua kỳ trước",
								field: "GiaMuaKyTruoc",
								width: 170,
								headerFilter: "input",
							},
							{
								title: "Giá mua kỳ này",
								field: "GiaMuaKyNay",
								width: 170,
								headerFilter: "input",
							},
							{
								title: "SL mua kỳ này",
								field: "SoLuongMuaKyNay",
								width: 170,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenFormatter(cell, "SoLuongMuaKyNay")
							}
						]
					},
	
					{
						title: "THÔNG TIN CHI PHÍ",
						columns: [
							{
								title: "Trước thuế",
								field: "DonGia",
								width: 140,
								hozAlign: "right",
								headerFilter: "input",
								formatter: (cell) => this.sumChildrenMoneyFormatter(cell, "DonGia")
							},
							{
								title: "Thuế GTGT",
								field: "ThueGTGT",
								width: 130,
								hozAlign: "right",
								headerFilter: "input",
							},
							{
								title: "Thuế khác",
								field: "ThueKhac",
								width: 140,
								hozAlign: "right",
								headerFilter: "input",
							},
							{
								title: "Thuế nhập khẩu",
								field: "ThueNhapKhau",
								width: 160,
								hozAlign: "right",
								headerFilter: "input",
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
			},
	
			dateFormatter(cell) {
				const value = cell.getValue()
				if (!value) return ""
	
				return new Date(value).toLocaleDateString("vi-VN")
			}
		}
	}
</script>