<template>
	<z-layout>
		<uc-top-bar @add-new-emit="onAddNewEmit" @export-execl-emit="onExportEmit" />

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableData"
			height="calc(100vh - 48px)" :options="tableOptions" />

		<uc-modal-add v-model:isShow="isShowDialogAdd" :DSNhomTinhChat="DSNhomTinhChat" :DSNhomVTHH="DSNhomVTHH"
			:DSNhomTenSanPham="DSNhomTenSanPham" :DSDonViTinh="DSDonViTinh" @handle-add="onHandleAdd" />

		<uc-modal-edit v-model:isShow="isShowDialogEdit" :selectedItem="selectedItem" :DSNhomTinhChat="DSNhomTinhChat"
			:DSNhomVTHH="DSNhomVTHH" :DSNhomTenSanPham="DSNhomTenSanPham" :DSDonViTinh="DSDonViTinh"
			:DSDiaDiem="DSDiaDiem" @reload="onReload" />
	</z-layout>
</template>

<script>
	export default {
		data() {
			return {
				isTableReady: false,
	
				tableHeaders: [],
	
				tableData: [],
	
				tableOptions: {
					pagination: true,
					layout: "fitDataStretch",
				},
	
				isShowDialogAdd: false,
				isShowDialogEdit: false,
				selectedItem: {},
	
				DSNhomTinhChat: [],
				DSNhomVTHH: [],
				DSNhomTenSanPham: [],
				DSDonViTinh: [],
				DSDiaDiem: [],
			};
		},
	
		async mounted() {
			this.initTableHeaders();
			this.loadDSNhomTinhChat();
			this.loadDSNhomVTHH();
			this.loadDSNhomTenSanPham();
			this.loadDSDonViTinh();
			this.loadDSDiaDiem();
			this.initData();
		},
	
		methods: {
			async initData() {
				try {
					this.isTableReady = false;
	
					const data = await apiCallPromise("work/TS_CCDC_Select");
	
					this.tableData = (data || []).map((item) => ({
						...item,
					}));
				} finally {
					this.isTableReady = true;
				}
			},
	
			async loadDSNhomTinhChat() {
				this.DSNhomTinhChat = await apiCallPromise(
					"work/HH_PhanLoai_TinhChat_Select_Dropdown"
				);
			},
	
			async loadDSNhomVTHH() {
				this.DSNhomVTHH = await apiCallPromise(
					"work/HH_PhanLoai_NhomVatTu_Select_Dropdown"
				);
			},
	
			async loadDSNhomTenSanPham() {
				this.DSNhomTenSanPham = await apiCallPromise(
					"work/HH_PhanLoai_NhomSanPham_Select_Dropdown"
				);
			},
	
			async loadDSDonViTinh() {
				this.DSDonViTinh = await apiCallPromise("work/HH_DonViTinh_Select");
			},
	
			async loadDSDiaDiem() {
				this.DSDiaDiem = await apiCallPromise("work/HH_DiaDiem_Select");
			},
	
			initTableHeaders() {
				this.tableHeaders = [
					{ title: "#", formatter: "rownum", width: 60, hozAlign: "center" },
	
					{ title: "Mã nội bộ", field: "MaNoiBo", headerFilter: "input", width: 140 },
	
					{
						title: "Tên CCDC",
						field: "TenHangHoa",
						headerFilter: "input",
						minWidth: 250,
						formatter: (cell) => {
							return `<div class="text-primary font-weight-bold cursor-pointer">
	                      ${cell.getValue() || ""}
	                    </div>`;
						},
						cellClick: (e, cell) => {
							this.onEmitEdit(cell.getRow().getData());
						},
					},
	
					{ title: "Nhóm tính chất", field: "TenTinhChat", headerFilter: "input", minWidth: 180 },
					{ title: "Nhóm vật tư", field: "TenNhomVatTu", headerFilter: "input", minWidth: 180 },
					{ title: "Nhóm sản phẩm", field: "TenNhomSanPham", headerFilter: "input", minWidth: 180 },
	
					{
						title: "Giá mới nhất",
						field: "DonGia_MoiNhat",
						hozAlign: "right",
						width: 150,
						formatter: (cell) => {
							const v = cell.getValue();
							return v ? Number(v).toLocaleString("vi-VN") : "";
						},
						headerFilter: "input",
					},
					{
						title: "Giá trung bình",
						field: "DonGia_TrungBinh",
						hozAlign: "right",
						width: 150,
						formatter: (cell) => {
							const v = cell.getValue();
							return v ? Number(v).toLocaleString("vi-VN") : "";
						},
						headerFilter: "input",
					},
	
					{ title: "Độ ưu tiên", field: "DoUuTien", width: 120, hozAlign: "center", headerFilter: "input" },
					{ title: "Thương hiệu", field: "ThuongHieu", width: 150, headerFilter: "input" },
					{ title: "Địa điểm áp dụng", field: "TongDiaDiemApDung", width: 150, hozAlign: "center", headerFilter: "input" },
					{ title: "Mô tả", field: "MoTa", headerFilter: "input", minWidth: 200 },
	
					{
						title: "Tài sản",
						field: "Is_CaBiet",
						width: 100,
						hozAlign: "center",
						formatter: (cell) => (cell.getValue() ? "✔" : ""),
						headerFilter: "tickCross",
					},
	
					{
						title: "Tạm khoá",
						field: "Is_TamKhoa",
						width: 120,
						hozAlign: "center",
						formatter: (cell) => (cell.getValue() ? "🔒" : ""),
						headerFilter: "tickCross",
					},
	
					{
						title: "",
						width: 60,
						hozAlign: "center",
						headerSort: false,
						formatter: () =>
							'<i class="icon-table text-red mdi mdi-trash-can-outline"></i>',
						cellClick: (e, cell) => {
							const item = cell.getRow().getData();
							this.onDelete(item);
						},
					},
				];
			},
	
			onAddNewEmit() {
				this.isShowDialogAdd = true;
			},
	
			onEmitEdit(item) {
				this.selectedItem = { ...item };
				this.isShowDialogEdit = true;
			},
	
			onExportEmit() {
				this.$refs.refTable?.exportExcel("DanhSachCCDC");
			},
	
			onDelete(item) {
				const params = {
					HangHoa_Id: item.HangHoa_Id,
				};
	
				showConfirm(
					`Xác nhận xoá: <b>${item.TenHangHoa}</b><br/>Thuộc nhóm: <b>${item.TenNhomSanPham}</b>`,
					() => {
						apiCall("work/TS_CCDC_Delete", params, (res) => {
							if (res) showToast.success("Thành công");
							this.onReload();
						});
					}
				);
			},
	
			onHandleAdd(item, TinhTrang) {
				if (TinhTrang === "TIEP_TUC") {
					this.onEmitEdit(item);
				} else {
					this.onReload();
				}
			},
	
			onReload() {
				this.initData();
			},
		},
	}
</script>