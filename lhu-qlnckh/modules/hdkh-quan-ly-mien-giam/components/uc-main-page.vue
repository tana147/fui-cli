<template>
	<v-container fluid>
		<uc-main-view v-model="khoaId" :khoaList="khoaList" :dsNhanVien="dsNhanVien" @on-view-detail="openModal"
			@on-add-nhan-vien="openAddNhanVienModal" @on-edit-nhan-vien="openEditNhanVienModal"
			@on-delete-nhan-vien="handleDeleteNhanVien" />
		<uc-modal-mien-giam v-model="isModalOpen" :nhanVien="selectedNhanVien" :details="detailByNhanVienId"
			:selectedYear="selectedYear" @on-reload="handleReloadChiTiet" />
		<uc-modal-nhan-vien-add v-model="isAddNhanVienModalOpen" :khoaList="khoaList" :khoaId="khoaId"
			:hocViList="hocViList" @on-reload="reloadNhanVienList" />
		<uc-modal-nhan-vien-edit v-model="isEditNhanVienModalOpen" :khoaList="khoaList" :khoaId="khoaId"
			:hocViList="hocViList" :editItem="selectedNhanVienToEdit" @on-reload="reloadNhanVienList" />
	</v-container>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				isModalOpen: false,
				selectedYear: new Date().getFullYear(),
				khoaList: [],
				khoaId: null,
				dsNhanVien: null,
				selectedNhanVien: null,
				detailByNhanVienId: [],
				isAddNhanVienModalOpen: false,
				isEditNhanVienModalOpen: false,
				selectedNhanVienToEdit: null,
				hocViList: []
			}
		},
		watch: {
			khoaId(newVal) {
				if (newVal) {
					this.fetchDanhSachNhanVien(newVal);
				} else {
					this.dsNhanVien = null;
				}
			}
		},
		mounted() {
			this.fetchDanhSachKhoa();
			this.fetchHocViList();
		},
		methods: {
			async fetchDanhSachKhoa() {
				const res = await ajaxCALLPromise("/HDKH_Admin_GetDanhSachKhoa");
				if (res && Array.isArray(res)) {
					this.khoaList = res;
				} else {
					this.khoaList = [];
				}
			},
			async fetchDanhSachNhanVien(khoaId) {
				const res = await ajaxCALLPromise("/HDKH_Admin_MienGiam_GetTongHopByKhoa", { KhoaID: khoaId, NamHoc: this.selectedYear });
				this.dsNhanVien = res || [];
			},
			async fetchChiTietMienGiam(nhanVien) {
				const res = await ajaxCALLPromise("/HDKH_Admin_MienGiam_GetChiTietByNhanVien", { NamHoc: this.selectedYear, NhanVienID: nhanVien.NhanVienID });
				this.detailByNhanVienId = res || [];
			},
			async openModal(nhanVien) {
				this.selectedNhanVien = nhanVien;
				await this.fetchChiTietMienGiam(nhanVien);
				this.isModalOpen = true;
			},
			async handleReloadChiTiet() {
				if (this.selectedNhanVien) {
					await this.fetchChiTietMienGiam(this.selectedNhanVien);
					if (this.khoaId) {
						await this.fetchDanhSachNhanVien(this.khoaId);
					}
				}
			},
			openAddNhanVienModal() {
				this.isAddNhanVienModalOpen = true;
			},
			openEditNhanVienModal(item) {
				this.selectedNhanVienToEdit = item;
				this.isEditNhanVienModalOpen = true;
			},
			handleDeleteNhanVien(item) {
				confirm({
					title: `Bạn có muốn xóa nhân viên <br/><b>${item.HoTen} (${item.NhanVienID})</b>?`,
					action: async () => {
						await ajaxCALLPromise("/HDKH_Admin_NhanVien_Delete", { MaNV: item.NhanVienID });
						Vue.$toast.success("Xóa nhân viên thành công", { position: "top" });
						this.reloadNhanVienList();
					}
				});
			},
			reloadNhanVienList() {
				if (this.khoaId) {
					this.fetchDanhSachNhanVien(this.khoaId);
				}
			},
			async fetchHocViList() {
				const res = await ajaxCALLPromise("/HDKH_DM_ChucDanhHocVi_GetList");
				this.hocViList = (res || []).map(item => ({
					HocViID: item.HocViID !== undefined ? item.HocViID : (item.ID !== undefined ? item.ID : item.ChucDanhHocViID),
					TenHocVi: item.TenHocVi || item.TenChucDanh || item.Ten || ""
				}));
			}
		}
	}
</script>