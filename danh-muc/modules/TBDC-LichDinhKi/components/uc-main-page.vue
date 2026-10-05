<template>
	<z-layout>
		<uc-top-bar @add-new-emit="onAddNewEmit"></uc-top-bar>

		<uc-table :DSLichDinhKi="DSLichDinhKi" @edit-emit="onEditEmit" @view-list-emit="onViewListEmit"
			@load-data="handleLoadData" :loadDSLichDinhKi="loadDSLichDinhKi"></uc-table>

		<uc-modal-add v-if='isShowDialogAdd' v-model:isShow="isShowDialogAdd" :DSHangHoaTree="DSHangHoaTree"
			:DSDiaDiem='DSDiaDiem' :loadDSLichDinhKi="loadDSLichDinhKi"></uc-modal-add>

		<uc-modal-edit v-model:isShow="isShowDialogEdit" :selectedItem="selectedItem"
			:DSHangHoaTree="TempDanhSachHangHoaTree" :DSDiaDiem='DSDiaDiem'
			:loadDSLichDinhKi="loadDSLichDinhKi"></uc-modal-edit>

		<uc-modal-list v-model:isShow="isShowDialogList" :items="ListPhieu" :selectedItem="selectedItem"
			@load-danh-sach-lich='onLoadDanhSachLich' />
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
	
				DSLichDinhKi: [],
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
				this.loadDSLichDinhKi()
				this.loadDSDiaDiem()
				this.loadDSHangHoaTree()
			},
	
			async loadDSLichDinhKi(params = {}) {
				let data = await apiCallPromise('work/TS_LichDinhKi_Select')
				data.forEach((item) => {
					const DSDiaDiem = JSON.parse(item.DSDiaDiem ?? '[]')
					const DSHangHoa = JSON.parse(item.DSHangHoa ?? '[]')
					item.DSDiaDiem = DSDiaDiem
					item.DSHangHoa = DSHangHoa
				})
				this.DSLichDinhKi = data
			},
	
			async loadDSDiaDiem() {
				const data = await apiCallPromise('work/HH_DiaDiem_Select')
				this.DSDiaDiem = data
			},
	
			async loadDSHangHoaTree() {
				let data = await apiCallPromise('work/TS_HangHoa_Select_Tree')
				data.forEach((item) => {
					item.children = []
				})
				this.DSHangHoaTree = data
			},
	
			handleLoadData(params) {
				this.loadDSLichDinhKi(params)
			},
	
			onAddNewEmit() {
				this.isShowDialogAdd = true
			},
	
			async loadChildrenInfoByListId(ListHangHoa_Id) {
				const data = await apiCallPromise('work/TS_HangHoa_Select_Tree_Children_By_ListId', {
					ListHangHoa_Id: ListHangHoa_Id
				})
				return data
			},
	
			async loadChildrenAndSelected(item) {
				let data = await apiCallPromise('work/TS_HangHoa_Select_Tree_Children', {
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
				this.selectedItem.taskList = this.selectedItem.ListCongViec
					.split(',')
					.map(item => ({ taskName: item }))
				const tasks = this.TempDanhSachHangHoaTree
					.filter(parent => arrayParentId.includes(parent.id))
					.map(parent => this.loadChildrenAndSelected(parent))
	
				await Promise.all(tasks)
				this.isShowDialogEdit = true
			},
	
			async loadListLichById() {
				const payload = {
					LichDinhKi_Id: this.selectedItem.LichDinhKi_Id,
				}
				const data = await apiCallPromise('work/TS_LichDinhKi_Select_By_Id', payload)
				this.ListPhieu = data
			},
	
			onViewListEmit(item) {
				this.selectedItem = { ...item }
				this.loadListLichById()
				this.isShowDialogList = true
			},
	
			onLoadDanhSachLich() {
				this.loadListLichById()
			},
		},
	}
</script>