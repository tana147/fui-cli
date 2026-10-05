<template>
	<div>
		<v-row>
			<v-col cols="2">
				<v-select v-model="typeSelect" :items="TypeList" outlined dense hide-details label="Loại thống kê"
					item-text="text" item-value="value" />
			</v-col>

			<v-col cols="2">
				<v-select v-model="major" :items="NganhGiangDay" outlined dense hide-details label="Lọc theo ngành"
					item-text="TenNganh" item-value="NganhID" />
			</v-col>

			<v-col cols="1">
				<v-autocomplete v-model="NienKhoaValue" :items="DsNienKhoa" item-text="TenNienKhoa"
					item-value="NienKhoa" outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
			</v-col>

			<v-col v-if="typeSelect === '1'" cols="2">
				<v-select v-model="trangThaiBaiBaoSelect" :items="TrangThaiBaiBaoList" outlined dense hide-details
					label="Trạng thái bài báo" item-text="text" item-value="value" />
			</v-col>

			<v-col v-if="typeSelect === '2'" cols="2">
				<v-select v-model="doiDieuChinhSelect" :items="DoiOrDieuChinhList" outlined dense hide-details
					label="Đổi/Điều chỉnh đề tài" item-text="text" item-value="value" />
			</v-col>

			<v-col cols="2">
				<v-btn color="indigo" @click="onFilter" dark><v-icon left>mdi-filter</v-icon> Lọc</v-btn>
			</v-col>
		</v-row>
		<br />

		<div v-if="typeSelect === '1'">
			<thong-ke-bai-bao :dsbaibaokhoahoc="DsBaiBaoKhoaHoc" :trangthaibaibao="trangThaiBaiBaoSelect"
				:nganhid="major" :nganhgiangday="NganhGiangDay" />
		</div>

		<div v-if="typeSelect === '2'">
			<thong-ke-doi-dieu-chinh-de-tai :dsdoidieuchinhdetai="DsDoiDieuChinhDeTai" :nganhid="major"
				:nganhgiangday="NganhGiangDay" />
		</div>

		<div v-if="typeSelect === '3'">
			<thong-ke-hoan-thanh-sau-bao-ve :dshoanthanhsbv="DsHoanThanhSBV" />
		</div>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				NganhGiangDay: [],
				major: '0',
				NienKhoaValue: null,
				DsNienKhoa: [],
				DsBaiBaoKhoaHoc: [],
				DsBaiBaoKhoaHocRoot: [],
				DsDoiDieuChinhDeTai: [],
				DsDoiDieuChinhDeTaiRoot: [],
				DsHoanThanhSBV: [],
				DsHoanThanhSBVRoot: [],
				typeSelect: '1',
				trangThaiBaiBaoSelect: '0',
				doiDieuChinhSelect: '0',
	
				TrangThaiBaiBaoList: [
					{
						text: '- Tất cả -',
						value: '0',
					},
					{
						text: 'Đã đăng bài',
						value: '1',
					},
					{
						text: 'Chưa đăng bài',
						value: '2',
					},
				],
	
				TypeList: [
					{
						text: 'Bài báo khoa học',
						value: '1',
					},
					{
						text: 'Đổi/điều chỉnh đề tài',
						value: '2',
					},
					{
						text: 'Hoàn thành sau bảo vệ',
						value: '3',
					},
				],
	
				DoiOrDieuChinhList: [
					{
						text: '- Tất cả -',
						value: '0',
					},
					{
						text: 'Đổi đề tài',
						value: '1',
					},
					{
						text: 'Điều chỉnh đề tài',
						value: '2',
					},
				],
			}
		},
		mounted() {
			this.onLoadNganhGiangDay()
			this.onLoadBaiBaoKhoaHoc(0, this.trangThaiBaiBaoSelect)
			this.getNienKhoa()
		},
		computed: {},
		watch: {
			major: function (val) {
				if (this.typeSelect === '1') {
					this.onLoadBaiBaoKhoaHoc(val, this.trangThaiBaiBaoSelect)
				} else if (this.typeSelect === '2') {
					this.onLoadDoiDieuChinhDeTai(val)
				} else if (this.typeSelect === '3') {
					this.onLoadHoanThanhSBV(val)
				}
				this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
			},
			typeSelect: function (val) {
				this.major = '0'
				this.NienKhoaValue = '0'
				if (val === '1') {
					this.onLoadBaiBaoKhoaHoc(this.major, '0')
				} else if (val === '2') {
					this.onLoadDoiDieuChinhDeTai(0)
				} else if (this.typeSelect === '3') {
					this.onLoadHoanThanhSBV(0)
				}
			},
			trangThaiBaiBaoSelect: function (val) {
				this.major = '0'
				this.NienKhoaValue = '0'
	
				this.onLoadBaiBaoKhoaHoc(this.major, val)
			},
		},
		methods: {
			onFilter() {
				const map = {
					1: { target: 'DsBaiBaoKhoaHoc', source: 'DsBaiBaoKhoaHocRoot' },
					2: { target: 'DsDoiDieuChinhDeTai', source: 'DsDoiDieuChinhDeTaiRoot' },
					3: { target: 'DsHoanThanhSBV', source: 'DsHoanThanhSBVRoot' },
				}
	
				const config = map[this.typeSelect]
				if (!config) return
	
				const { target, source } = config
	
				let data = this.NienKhoaValue !== '0'
					? this[source].filter(item => item.Nien_Khoa === this.NienKhoaValue)
					: [...this[source]]
	
				// Chỉ áp dụng cho danh sách Đổi/Điều chỉnh đề tài
				if (this.typeSelect == 2 && this.doiDieuChinhSelect !== '0') {
					data = data.filter(
						item => String(item.IsDoiDeTaiOrDieuChinh) === String(this.doiDieuChinhSelect)
					)
				}
	
				this[target] = data
			},
	
			getNienKhoa() {
				const $this = this
				$.ajax({
					type: 'GET',
					headers: {
						authorization: $awt,
					},
					url: `https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`,
					contentType: 'application/json; charset=utf-8',
					dataType: 'json',
					crossDomain: true,
					success: function (res) {
						const obj = {
							TenNienKhoa: '- Tất cả -',
							NienKhoa: '0',
						}
	
						$this.DsNienKhoa = res.data.map((item) => {
							return {
								...item,
								TenNienKhoa: item.NienKhoa,
								NienKhoa: item.NienKhoa,
							}
						})
						$this.DsNienKhoa.unshift(obj)
						$this.NienKhoaValue = $this.DsNienKhoa[0]?.NienKhoa
					},
					error: function (xhr, ajaxOptions, thrownError) {
						$.dialog({
							icon: 'fas fa-exclamation',
							title: 'Error',
							content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
							type: 'red',
							columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
							closeIcon: true,
							buttons: {
								ok: {
									text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
									btnClass: 'btn-blue',
								},
							},
						})
					},
				})
			},
	
			onLoadHoanThanhSBV(nganhID) {
				ajaxCALL(
					'/SDH_Get_HoanThanhSauBaoVe',
					{
						NganhID: parseInt(nganhID),
					},
					(res) => {
						this.DsHoanThanhSBV = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
							}
						})
						this.DsHoanThanhSBVRoot = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
							}
						})
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load hoan thanh sau bao ve', error)
					},
				)
			},
	
			onLoadBaiBaoKhoaHoc(nganhID, trangThai) {
				ajaxCALL(
					'/Student_BaiBaoKhoaHoc_Get',
					{
						Nganh_ID: parseInt(nganhID),
						BaiBaoStatus: parseInt(trangThai),
					},
					(res) => {
						this.DsBaiBaoKhoaHoc = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
							}
						})
	
						this.DsBaiBaoKhoaHocRoot = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
							}
						})
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load thong ke bai bao khoa hoc', error)
					},
				)
			},
	
			onLoadDoiDieuChinhDeTai(nganhID) {
				ajaxCALL(
					'/SDH_Get_DoiDieuChinh_DeTai',
					{
						Nganh_ID: nganhID,
					},
					(res) => {
						this.DsDoiDieuChinhDeTai = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
								ThoiGianQD: item.Decision_ID ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD : '',
							}
						})
	
						this.DsDoiDieuChinhDeTaiRoot = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
								ThoiGianQD: item.Decision_ID ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD : '',
							}
						})
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load thong ke doi dieu chinh de tai', error)
					},
				)
			},
			onLoadNganhGiangDay() {
				const $this = this
				$.ajax({
					type: 'GET',
					headers: {
						authorization: $awt,
					},
					url: `https://tapi.lhu.edu.vn/hoso/SDH_SelectNganh_CaoHoc`,
					contentType: 'application/json; charset=utf-8',
					dataType: 'json',
					crossDomain: true,
					success: function (res) {
						const obj = {
							TenNganh: '- Tất cả -',
							NganhID: '0',
						}
	
						$this.NganhGiangDay = res.data.map((item, index, array) => {
							// Kiểm tra trùng lặp tên ngành (không phân biệt hoa/thường)
							const isDuplicate = array.some((el, i) => i !== index && el.TenNganh.toLowerCase() === item.TenNganh.toLowerCase())
	
							// Nếu trùng thì gắn thêm KhoaID
							const rawName = isDuplicate ? `${item.TenNganh} (${item.KhoaID})` : item.TenNganh
	
							// Gộp xử lý removeHocHam vào chung 1 vòng map
							return {
								...item,
								TenNganh: removeHocHam(rawName),
							}
						})
						$this.NganhGiangDay.unshift(obj)
						console.log('NganhGiangDay', $this.NganhGiangDay)
					},
					error: function (xhr, ajaxOptions, thrownError) {
						$.dialog({
							icon: 'fas fa-exclamation',
							title: 'Error',
							content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
							type: 'red',
							columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
							closeIcon: true,
							buttons: {
								ok: {
									text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
									btnClass: 'btn-blue',
								},
							},
						})
					},
				})
			},
		},
	}
</script>