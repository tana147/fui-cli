<template>
	<div>

		<div style="margin-bottom:10px">
			<button @click="createPurchaseOrder">Lệnh báo mua hàng</button>
			<button @click="initData">Reload</button>
		</div>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 140px)" :options="tableOptions" />

	</div>
</template>

<script>
	export default {
	
		data() {
			return {
	
				isTableReady: false,
				isLoading: false,
	
				tableHeaders: [],
				tableRows: [],
	
				tableOptions: {
					pagination: true,
	
					cellEdited: (cell) => {
						let row = cell.getRow().getData()
						this.calculateRow(row)
						cell.getRow().update(row)
					},
	
					rowFormatter: (row) => {
						let data = row.getData()
	
						if (data.ThoiGianDenHan <= data.SoNgayGiaoHang) {
							row.getElement().style.background = "#ffe9e9"
						}
					}
				}
			}
		},
	
		mounted() {
			this.initData()
		},
	
		methods: {
	
			async fetchList() {
				this.tableRows = await apiCallPromise("/work/HH_DiaDiem_Select")
	
				this.tableRows.forEach(row => {
					this.calculateRow(row)
				})
			},
	
			async initData() {
	
				this.isTableReady = false
	
				try {
					this.isLoading = true
					await this.fetchList()
					this.initTableHeaders()
				}
				catch (error) {
					console.error(error)
				}
				finally {
					this.isLoading = false
					this.isTableReady = true
				}
	
			},
	
			initTableHeaders() {
	
				this.tableHeaders = [
					{
						title: "#",
						formatter: "rownum",
						width: 70,
						hozAlign: "center"
					},
	
					{
						title: "THÔNG TIN HÀNG HÓA",
						columns: [
							{ title: "Mã hàng", field: "MaHangHoa", width: 140, headerFilter: "input" },
							{ title: "Tên hàng", field: "TenHangHoa", width: 200, headerFilter: "input" },
							{ title: "ĐVT", field: "DonViTinh", width: 90, hozAlign: "center" },
							{ title: "Phân loại", field: "PhanLoaiHangHoa", width: 170, headerFilter: "input" },
							{ title: "Nhà cung cấp", field: "TenNhaCungCap", width: 200, headerFilter: "input" }
						]
					},
	
					{
						title: "BIẾN PHỤ THUỘC",
						columns: [
							{ title: "1. SL mua/tháng", field: "SLMuaThang", editor: "number", width: 150 },
							{ title: "2. SL sử dụng/tháng", field: "SLSuDungThang", editor: "number", width: 170 },
							{ title: "3. Ngày giao hàng", field: "SoNgayGiaoHang", editor: "number", width: 140 },
							{ title: "4. Ngày giữa các lần giao", field: "NgayGiuaLanGiao", editor: "number", width: 200 },
							{ title: "5. Tồn kho định mức", field: "TonKhoDinhMuc", editor: "number", width: 160 },
							{ title: "6. Tồn kho hiện tại", field: "TonKhoHienTai", editor: "number", width: 160 }
						]
					},
	
					{
						title: "TÍNH TOÁN",
						columns: [
							{ title: "7. Số lần nhập TB/tháng", field: "SoLanNhapTB", width: 180 },
							{ title: "8. SL dùng TB/tháng", field: "SLDungTBThang", width: 160 },
							{ title: "9. SL dùng TB/ngày", field: "SLDungTBNgay", width: 160 },
							{ title: "10. Thời gian đến hạn", field: "ThoiGianDenHan", width: 170 }
						]
					},
	
					{
						title: "KẾT QUẢ",
						columns: [
							{ title: "11. SL đặt hàng", field: "SLDatHang", width: 150 },
							{ title: "12. Thời gian đặt", field: "ThoiGianDat", width: 160 },
							{ title: "13. Đợt hàng", field: "DotHang", editor: "input", width: 140 },
							{ title: "14. Khu vực nhận", field: "KhuVucNhan", editor: "input", width: 160 },
							{ title: "15. Ghi chú", field: "GhiChu", editor: "input", width: 200 }
						]
					}
				]
	
			},
	
			calculateRow(row) {
	
				if (!row.NgayGiuaLanGiao || row.NgayGiuaLanGiao == 0) return
	
				row.SoLanNhapTB = 30 / row.NgayGiuaLanGiao
	
				row.SLDungTBThang = row.SLSuDungThang || 0
	
				row.SLDungTBNgay = row.SLDungTBThang / 30
	
				if (row.SLDungTBNgay > 0) {
	
					row.ThoiGianDenHan =
						(row.TonKhoHienTai - row.TonKhoDinhMuc) /
						row.SLDungTBNgay
	
				}
	
				row.SLDatHang =
					(row.SLDungTBNgay * (row.NgayGiuaLanGiao + row.SoNgayGiaoHang))
					+ row.TonKhoDinhMuc
					- row.TonKhoHienTai
	
				if (row.ThoiGianDenHan <= row.SoNgayGiaoHang) {
	
					row.ThoiGianDat = "ĐẶT NGAY"
	
				}
				else {
	
					row.ThoiGianDat = Math.round(row.ThoiGianDenHan - row.SoNgayGiaoHang) + " ngày"
	
				}
	
			},
	
			createPurchaseOrder() {
	
				let needBuy = this.tableRows.filter(r => r.SLDatHang > 0)
	
				if (needBuy.length === 0) {
	
					showToast.error("Không có hàng cần đặt")
	
					return
				}
	
				console.log("Danh sách cần đặt:", needBuy)
	
				showToast.success("Tạo lệnh báo mua hàng thành công!")
	
			}
	
		}
	
	}
	
</script>