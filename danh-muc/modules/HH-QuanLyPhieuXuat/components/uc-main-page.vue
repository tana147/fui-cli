<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Quản lý phiếu xuất" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="isShowDialogAdd = true">Thêm mới</v-btn>
			</template>
		</v-app-bar>
		<uc-table-phieu-xuat ref="refTablePhieuXuat" :DSPhieuXuat="DSPhieuXuat" :DSDiaDiem="DSDiaDiem"
			@view-detail-emit="onViewDetailEmit" @load-data="handleLoadData"></uc-table-phieu-xuat>
		<uc-drawer-view-detail v-model:isShow="isShowDialogViewDetail"
			:selectedItem="selectedItem" @print-emit="onDrawerPrint"></uc-drawer-view-detail>
		<uc-modal-add v-model:isShow="isShowDialogAdd" :loadDSPhieuXuat="loadDSPhieuXuat" :DSNhanVien="DSNhanVien"
			:DSDiaDiem="DSDiaDiem"></uc-modal-add>
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			isShowDialogAdd: false,
			isShowDialogViewDetail: false,
			filter: {
				DiaDiem_Id: 0,
				Nam: new Date().getFullYear(),
				Thang: new Date().getMonth() + 1
			},

			selectedItem: {},
			DSPhieuXuat: [],
			DSDiaDiem: [],
			DSNhanVien: [],
		}
	},

	mounted() {
		this.loadData()
	},

	methods: {
		async loadData() {
			const [_, __, ___] = await Promise.all([
				this.loadDSPhieuXuat(),
				this.loadDSNhanVien(),
				this.loadDSDiaDiem()
			])
		},

		async loadDSPhieuXuat(params = {}) {
			this.filter = {
				DiaDiem_Id: params.DiaDiem_Id ?? this.filter.DiaDiem_Id,
				Nam: params.Nam ?? this.filter.Nam,
				Thang: params.Thang ?? this.filter.Thang,
			}
			const data = await apiCallPromise('work/HH_PhieuXuat_Select', this.filter)
			this.DSPhieuXuat = data
		},

		async loadDSNhanVien() {
			const data = await apiCallPromise('work/HH_NhanVien_Select')
			this.DSNhanVien = data
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = data
		},

		handleLoadData(params) {
			this.loadDSPhieuXuat(params)
		},

		async onViewDetailEmit(item) {
			const data = await apiCallPromise('work/HH_PhieuXuat_Select_ById', {
				PhieuXuat_Id: item.PhieuXuat_Id
			})
			const arrayHangHoa = [...data[0], ...data[1]]
			this.selectedItem = { ...item, arrayHangHoa: arrayHangHoa }
			this.isShowDialogViewDetail = true
		},

		onDrawerPrint(item) {
			this.isShowDialogViewDetail = false
			this.$refs.refTablePhieuXuat?.onPrint(item)
		},
	}
}
</script>
