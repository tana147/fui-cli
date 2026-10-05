<template>
	<z-layout>
		<uc-top-bar @add-new-emit="onAddNewEmit"></uc-top-bar>

		<uc-table :DSPhieuDinhKi="DSPhieuDinhKi" @edit-emit="onEditEmit" @view-list-emit="onViewListEmit"
			@load-data="handleLoadData" :loadDSPhieuDinhKi="loadDSPhieuDinhKi"></uc-table>

		<uc-modal-add v-if='isShowDialogAdd' v-model:isShow="isShowDialogAdd" :DSHangHoaTree="DSHangHoaTree"
			:DSDiaDiem='DSDiaDiem' :loadDSPhieuDinhKi="loadDSPhieuDinhKi"></uc-modal-add>

		<uc-modal-edit v-model:isShow="isShowDialogEdit" :selectedItem="selectedItem"
			:DSHangHoaTree="TempDanhSachHangHoaTree" :DSDiaDiem='DSDiaDiem'
			:loadDSPhieuDinhKi="loadDSPhieuDinhKi"></uc-modal-edit>

		<uc-modal-list v-model:isShow="isShowDialogList" :items="ListPhieu" :loadListPhieuById="loadListPhieuById"
			:selectedItem="selectedItem" />
	</z-layout>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			isShowDialogAdd: null,
			isShowDialogEdit: null,
			isShowDialogList: null,

			DSPhieuDinhKi: [],
			DSDiaDiem: [],
			DSHangHoaTree: [],
			TempDanhSachHangHoaTree: [],
			ListPhieu: [],
			selectedItem: {}
		}
	},
	mounted() {
		this.loadData()
	},
	computed: {},
	watch: {},
	methods: {
		loadData() {
			this.loadDSPhieuDinhKi()
			this.loadDSDiaDiem()
			this.loadDSHangHoaTree()
		},

		async loadDSPhieuDinhKi(params = {}) {
			let data = await apiCallPromise('work/HH_PhieuDinhKi_Select')
			data.forEach((item) => {
				const DSDiaDiem = JSON.parse(item.DSDiaDiem ?? '[]')
				const DSHangHoa = JSON.parse(item.DSHangHoa ?? '[]')
				item.DSDiaDiem = DSDiaDiem
				item.DSHangHoa = DSHangHoa
			})
			this.DSPhieuDinhKi = data
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = data
		},

		async loadDSHangHoaTree() {
			let data = await apiCallPromise('work/HH_HangHoa_Select_Tree')
			data.forEach((item) => {
				item.children = []
			})
			this.DSHangHoaTree = data
		},

		handleLoadData(params) {
			this.loadDSPhieuDinhKi(params)
		},

		onAddNewEmit() {
			this.isShowDialogAdd = true
		},

		async loadChildrenInfoByListId(ListHangHoa_Id) {
			const data = await apiCallPromise('work/HH_HangHoa_Select_Tree_Children_By_ListId', {
				ListHangHoa_Id: ListHangHoa_Id
			})
			return data
		},

		async loadChildrenAndSelected(item) {
			let data = await apiCallPromise('work/HH_HangHoa_Select_Tree_Children', {
				NhomTenSanPham_Id: item.id
			})
			data.forEach((child) => {
				const Is_Selected = this.selectedItem.DSDaChon.find((x) => x.id === child.id)?.Is_Selected
				child.Is_Selected = Is_Selected ?? false
			})
			item.children = [...data]
		},

		async onEditEmit(item) {
			let optionLoaiDinhKiThang = null
			let optionLoaiDinhKiNam = null
			let tempDSHangHoa = await this.loadChildrenInfoByListId(item.DSHangHoa.map(HangHoa => HangHoa.HangHoa_Id).join(','))
			tempDSHangHoa.forEach((item) => item.Is_Selected = true)
			if (item.LoaiDinhKi === 'TUAN') {
				item.NgayTrongTuan = String(item.NgayTrongTuan ?? '')
					.split(',')
					.map(s => s.trim())
					.filter(Boolean)
					.filter(n => n >= 1 && n <= 7)
					.map(item => item.toString())
			}
			else if (item.LoaiDinhKi === 'THANG') {
				// LOAI DINH KI = THANG
				if (item.NgayTrongThang !== null) optionLoaiDinhKiThang = 'NGAY_TRONG_THANG'
				else if (item.NgayTrongTuan !== null && item.TuanThuTrongThang !== null) optionLoaiDinhKiThang = 'NGAY_TRONG_TUAN_TRONG_THANG'
				else optionLoaiDinhKiThang = 'DAU_CUOI_THANG'
			} else {
				// LOAI DINH KI = NAM
				if (item.NgayTrongNam !== null) optionLoaiDinhKiNam = 'NGAY_TRONG_NAM'
				else optionLoaiDinhKiNam = 'THANG_TRONG_NAM'
			}
			this.TempDanhSachHangHoaTree = _.cloneDeep(this.DSHangHoaTree)
			const arrayParentId = [...new Set(tempDSHangHoa.map(item => item.parent_Id))];
			let arrayExpanded = arrayParentId
			this.selectedItem = { ...item }
			this.selectedItem.DSDaChon = tempDSHangHoa
			this.selectedItem.expanded = arrayExpanded
			this.selectedItem.selectedDiaDiem = item.DSDiaDiem.map(DiaDiem => DiaDiem.DiaDiem_Id)
			this.selectedItem.optionLoaiDinhKiThang = optionLoaiDinhKiThang
			this.selectedItem.optionLoaiDinhKiNam = optionLoaiDinhKiNam

			const tasks = this.TempDanhSachHangHoaTree
				.filter(parent => arrayParentId.includes(parent.id))
				.map(parent => this.loadChildrenAndSelected(parent))

			await Promise.all(tasks)
			this.isShowDialogEdit = true
		},

		async loadListPhieuById(params = {}) {
			const payload = {
				PhieuDinhKi_Id: params.PhieuDinhKi_Id ?? this.selectedItem.PhieuDinhKi_Id,
			}
			const data = await apiCallPromise('work/HH_PhieuDinhKi_Select_By_Id', payload)
			this.ListPhieu = data
		},

		onViewListEmit(item) {
			this.selectedItem = { ...item }
			this.loadListPhieuById(item)
			this.isShowDialogList = true
		}
	},
}
</script>
