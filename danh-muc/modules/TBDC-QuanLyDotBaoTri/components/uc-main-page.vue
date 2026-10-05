<template>
	<z-layout>
		<uc-top-bar @on-add-new-lich-bao-tri="onAddNewLichBaoTri"></uc-top-bar>
		<uc-table-bao-tri :DSDotBaoTri="DSDotBaoTri" @on-view-detail="onViewDetail" :loadDSDotBaoTri="loadDSDotBaoTri">
		</uc-table-bao-tri>
		
		<uc-modal-them-lich-bao-tri v-if="isShowDialogThemLichBaoTri" v-model:isShow="isShowDialogThemLichBaoTri"
			:DSDiaDiem="DSDiaDiem" :DSCaBiet="DSCaBiet" :DSDoiTac="DSDoiTac" :DSNhanVien="DSNhanVien"
			:loadDSDotBaoTri="loadDSDotBaoTri"></uc-modal-them-lich-bao-tri>

		<uc-modal-detail-bao-tri v-model:isShow="isShowDialogDetailBaoTri" :selectedItem="selectedItem"
			:DSDoiTacBaoTri="DSDoiTac" :DSNhanVien="DSNhanVien"></uc-modal-detail-bao-tri>
	</z-layout>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				isShowDialogThemLichBaoTri: false,
				isShowDialogDetailBaoTri: false,
	
				DSDiaDiem: [],
				DSCaBiet: [],
				DSDoiTac: [],
				DSNhanVien: [],
				DSDotBaoTri: [],
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
				this.loadDSDiaDiem()
				this.loadDSNhanVien()
				this.loadDSDoiTac()
				this.loadDSDotBaoTri()
			},
	
			async loadDSDiaDiem() {
				const data = await apiCallPromise('work/HH_DiaDiem_Select')
				this.DSDiaDiem = data
			},
	
			async loadDSDoiTac() {
				const data = await apiCallPromise('work/TS_DoiTacBaoTri_Select')
				this.DSDoiTac = data
			},
	
	
			async loadDSNhanVien() {
				const data = await apiCallPromise('work/HH_NhanVien_Select')
				this.DSNhanVien = data
			},
	
			async loadDSDotBaoTri() {
				const data = await apiCallPromise('work/TS_DotBaoTri_Select')
				this.DSDotBaoTri = data
			},
	
			onAddNewLichBaoTri() {
				this.isShowDialogThemLichBaoTri = true
			},
			async onViewDetail(item) {
				this.selectedItem = item
				const params = {
					DotBaoTri_Id: item.DotBaoTri_Id
				}
				const data = await apiCallPromise('work/TS_DotBaoTri_Select_By_Id', params)
				let temp_TaskList = data[1].map(task => ({
					...task,
					DaThucHien: false,
					CheckList_Id: 0,
				}))
	
				let temp_Detail = data[0]
					.map((item, index) => ({
						...item,
						STT: index + 1,
						CheckList: JSON.parse(item.CheckList ?? '[]')
					}))
					.map(detail => ({
						...detail,
						CheckList: detail.CheckList?.length
							? detail.CheckList.map(i => ({ ...i }))
							: temp_TaskList.map(i => ({ ...i })),
					}))
	
				const NguoiGiamSat = data[2]
					.filter(i => i.LoaiTrachNhiem === 'GIAM_SAT')
					.map(i => i.DoiTuong_Id);
	
				const listBaoTri = data[2].filter(i => i.LoaiTrachNhiem === 'BAO_TRI');
	
				const NguoiThucHien = this.selectedItem.LoaiHinhThucHien === 'NOI_BO'
					? listBaoTri.map(i => i.DoiTuong_Id)
					: null
				const DoiTacThucHien = this.selectedItem.LoaiHinhThucHien === 'THUE_NGOAI' ? Number(listBaoTri[0].DoiTuong_Id) : null
	
				this.selectedItem = {
					...this.selectedItem,
					Detail: temp_Detail,
					TaskList: temp_TaskList,
					DSNhanVien: data[2],
					NguoiThucHien: NguoiThucHien,
					NguoiGiamSat: NguoiGiamSat,
					DoiTacThucHien: DoiTacThucHien,
				}
				this.isShowDialogDetailBaoTri = true
			},
		},
	}
</script>