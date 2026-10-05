<template>
	<z-layout>
		<uc-top-bar></uc-top-bar>
		<uc-table-bao-tri :DSDotBaoTri="DSDotBaoTri" :DSDiaDiem="DSDiaDiem" @on-execute='onExecute'
			@load-data="onLoadData"></uc-table-bao-tri>
		<uc-modal-detail v-model:isShow="isShowDialogDetail" :selectedItem="selectedItem" :DSDoiTacBaoTri="DSDoiTacBaoTri"
			:DSNhanVien="DSNhanVien" @load-data="onLoadData" @load-data-detail="onLoadDataDetail"
			:DiaDiem_Id="filter.DiaDiem_Id"></uc-modal-detail>
	</z-layout>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			isShowDialogDetail: false,

			DSDiaDiem: [],
			DSDoiTacBaoTri: [],
			DSNhanVien: [],
			filter: {
				DiaDiem_Id: null,
			},

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
			this.loadDSDoiTacBaoTri()
			this.loadDSNhanVien()
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = data
		},

		async loadDSDoiTacBaoTri() {
			const data = await apiCallPromise('work/TS_DoiTacBaoTri_Select')
			this.DSDoiTacBaoTri = data
		},

		async loadDSNhanVien() {
			const data = await apiCallPromise('work/HH_NhanVien_Select')
			this.DSNhanVien = data
		},

		async loadDSDotBaoTri(params) {
			const data = await apiCallPromise('work/TS_DotBaoTri_Select_By_DiaDiem_Id', params)
			this.DSDotBaoTri = data
		},

		async loadChiTietBaoTriById(params) {
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
		},

		async onExecute(item) {
			const params = {
				DotBaoTri_Id: item.DotBaoTri_Id,
			}
			this.selectedItem = item
			await this.loadChiTietBaoTriById(params)
			this.isShowDialogDetail = true
		},

		onLoadData(params = {}) {
			this.filter = {
				DiaDiem_Id: params.DiaDiem_Id ?? this.filter.DiaDiem_Id
			}
			this.loadDSDotBaoTri(this.filter)
		},

		async onLoadDataDetail() {
			const params = {
				DotBaoTri_Id: this.selectedItem.DotBaoTri_Id,
			}
			await this.loadChiTietBaoTriById(params)
		}
	},
}
</script>