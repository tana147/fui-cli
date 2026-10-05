<template>
	<div>
		<v-btn @click="onPrintExcel" class="mb-3" color="success"><v-icon dense smal
				left>mdi-microsoft-excel</v-icon>Xuất file excel</v-btn>

		<c-table :items="DsDoiDieuChinhDeTai" :label="labelTable" :headers="tableHeader" dense items-per-page="-1"
			isNew="false" isEdit="false" isSearch :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:item.STT="{ item, index }">
				{{index + 1}}
			</template>
			<template v-slot:item.HoTenMaSV="{ item }">
				<span class="primary--text">
					<b> {{ item.HoSV }} {{ item.TenSV }}</b>
				</span>
				<br />
				<b>{{ item.Student_ID }}</b>
				<span class="amber--text"> [{{ item.LopID }}]</span>
			</template>
			<template v-slot:item.detailBtn="{ item }">
				<v-btn @click="detailInfo(item)" color="primary" text>Xem chi tiết</v-btn>
			</template>
			<template v-slot:item.Decision_ID="{ item }">
				<v-chip v-if="item.Decision_ID" color="primary">
					<a :href="vueData.v_Set.urlReadFile + item.DecisionFile_Url" target="_blank" style="color: white">{{
						item.Decision_SoQD }}</a>
				</v-chip>
			</template>
		</c-table>
		<detail-doi-dieu-chinh-dialog :detaildata="DetailData" />
	</div>
</template>

<script>
	export default {
		props: ['dsdoidieuchinhdetai', 'nganhid', 'nganhgiangday'],
		data() {
			return {
				DetailData: null,
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						sortable: false,
						align: 'center',
						width: 50,
					},
					{
						text: 'Học viên',
						value: 'HoTenMaSV',
						width: 200,
					},
					{
						text: 'Niên khóa',
						value: 'Nien_Khoa',
						sortable: false,
						align: 'center',
						width: 110,
					},
					{
						text: 'Tên ngành',
						value: 'TenNganh',
						sortable: false,
						width: 200,
					},
					{
						text: 'Ngày QĐ',
						value: 'ThoiGianQD',
						width: 120,
						sortable: false,
						align: 'center',
					},
					{
						text: 'Tên đề tài mới',
						value: 'NewThesisName',
						sortable: false,
						width: 500,
					},
					{
						text: 'GVHD 1',
						value: 'ThesisesProf1',
						sortable: false,
						width: 180,
					},
					{
						text: 'GVHD 2',
						value: 'ThesisesProf2',
						sortable: false,
						width: 180,
					},
					{
						text: 'Số lần đổi/điều chỉnh đề tài',
						value: 'SoLanDoiDieuChinh',
						sortable: false,
						align: 'center',
						width: 120,
					},
					{
						text: 'Quyết định đổi/điều chỉnh',
						value: 'Decision_ID',
						sortable: false,
						align: 'center',
						width: 120,
					},
					{
						text: '',
						value: 'detailBtn',
						sortable: false,
						align: 'center',
						width: 80,
					},
				],
			}
		},
		mounted() { },
		computed: {
			DsDoiDieuChinhDeTai: function () {
				return this.dsdoidieuchinhdetai.map((item, index) => {
					return {
						...item,
						HoTenMaSV: `${item.HoSV} ${item.TenSV} ${item.Student_ID} ${item.LopID}`
					};
				});
			},
			labelTable() {
				return `Danh sách học viên đã đổi/điều chỉnh đề tài (${this.DsDoiDieuChinhDeTai.length})`
			},
			NganhGiangDay() {
				return this.nganhgiangday
			},
		},
		watch: {},
		methods: {
			detailInfo(item) {
				this.DetailData = item
				vueData.IsDetailDoiDieuChinhModal = true
			},
			nganhName(nganhid) {
				const nganh = this.NganhGiangDay.find((item) => item.NganhID === nganhid)
				return nganh ? nganh.TenNganh?.toUpperCase() : ''
			},
	
			onPrintExcel() {
				const dataArr = []
				this.DsDoiDieuChinhDeTai.forEach((item, index) => {
					const data = {
						STT: index + 1,
						MSHV: item.Student_ID,
						HoHV: item.HoSV,
						TenHV: item.TenSV,
						NienKhoa: item.Nien_Khoa,
						LopID: item.LopID,
						TenDeTaiMoi: item.NewThesisName,
						Nganh: item.TenNganh,
						GVHD1: item.ThesisesProf1,
						GVHD2: item.ThesisesProf2,
					}
					dataArr.push(data)
				})
	
				const apiData = {
					Nganh: this.nganhid === '0' ? '' : this.nganhName(this.nganhid),
					DanhSach: dataArr,
				}
	
				const myHeaders = new Headers()
				myHeaders.append('Content-Type', 'application/json')
				const requestOptions = {
					method: 'POST',
					headers: myHeaders,
					body: JSON.stringify(apiData),
					redirect: 'follow',
				}
				// https://gendocx.iotsoftvn.com
				// http://localhost:5244
				fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke-doi-dieu-chinh', requestOptions)
					.then((response) => response.blob())
					.then((blob) => {
						var url = window.URL.createObjectURL(blob)
						var a = document.createElement('a')
						a.href = url
						a.download = `Danh sách đổi/điều chỉnh đề tài.xlsx`
						document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
						a.click()
						a.remove() //afterwards we remove the element again
					})
					.catch((error) => console.error(error))
			},
		},
	}
</script>