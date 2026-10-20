<template>
	<div>
		<v-row class="mb-3">
			<v-col cols="2">
				<v-select v-model="type" label="Chọn theo hệ đào tạo" outlined dense :items="DsHeDaoTao"
					item-text="VALUE" item-value="KEY" hide-details />
			</v-col>
			<v-col cols="3">
				<v-select v-model="major" :items="HeCaoHoc" outlined dense hide-details label="Lọc theo ngành"
					item-text="Ten_Nganh_HienThi" item-value="Nganh_ID" />
			</v-col>
		</v-row>

		<div>
			<!-- DSHoiDong -->
			<c-table isSearch label="Danh sách đề tài bảo vệ luận văn" :headers="headerCTable" :items="mockDeTaiData"
				isNew="false" isEdit="false">
				<template v-slot:item.Student_ID="{item}">
					<span class='green--text'>
						<b> {{item.Ho_SV}} {{ item.Ten_SV}}</b>
					</span>
					<br />
					<b>{{item.Student_ID}}</b>
					<span class='amber--text'> [{{item.Lop_ID}}]</span>
				</template>
				<template v-slot:item.Thesises_Prof1="{item}">
					<span>
						{{item.Thesises_Prof1}}</br>{{item.Thesises_Prof2}}
					</span>
				</template>

			</c-table>
		</div>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				DSHoiDong: [],
				nganh: 0,
				type: "C",
				major: "",
				DsHeDaoTao: [],
				HeCaoHoc: [],
	
				headerCTable: [
					{
						text: "STT",
						value: "STT",
						sortable: false,
						align: "center"
					},
					{
						text: "Học viên",
						value: "Student_ID",
					},
					{
						text: "Ngành",
						value: "Ten_Nganh"
					},
					{
						text: "Tên đề tài",
						value: "Thesis_Name",
					},
					{
						text: "Hướng dẫn Khoa học 1",
						value: "Thesises_Prof1",
						class: "customCol"
					},
					{
						text: "Hướng dẫn Khoa học 2",
						value: "Thesises_Prof2",
						class: "customCol"
					},
					{
						text: "Ngày bảo vệ",
						value: "NgayBaoVe",
					},
				],
				mockDeTaiData: [
					{
						STT: 1,
						Student_ID: 9220000456,
						Ho_SV: "Lưu Vân",
						Ten_SV: "Anh",
						Ten_Nganh: "Quản trị kinh doanh",
						Thesis_Name: "Quản lý tiền tệ, tài chính",
						Thesises_Prof1: "TS. Trân Vân Phượng",
						Thesises_Prof2: "",
						NgayBaoVe: "21/12/2024",
						HoiDongID: 54,
					},
					{
						STT: 2,
						Student_ID: 9220000456,
						Ho_SV: "Trần Thanh",
						Ten_SV: "Hà",
						Ten_Nganh: "Tài chính - Ngân hàng",
						Thesis_Name: "Quản lý tiền tệư",
						Thesises_Prof1: "TS. Trân Vân Phượng",
						Thesises_Prof2: "",
						NgayBaoVe: "21/12/2024",
						HoiDongID: 55,
					},
					{
						STT: 3,
						Student_ID: 9220000456,
						Ho_SV: "Lê Bảo",
						Ten_SV: "Lương",
						Ten_Nganh: "Kỹ thuật điện",
						Thesis_Name: "Nghiên cứu tụ điện 1 chiều",
						Thesises_Prof1: "TS. Lê Thành",
						Thesises_Prof2: "",
						NgayBaoVe: "16/8/2024",
						HoiDongID: 56,
					},
					{
						STT: 4,
						Student_ID: 9220000456,
						Ho_SV: "Lý Tiểu",
						Ten_SV: "Công",
						Ten_Nganh: "Công nghệ thông tin",
						Thesis_Name: "Ứng dụng AI vào học tập",
						Thesises_Prof1: "PGS. Trần Tuấn",
						Thesises_Prof2: "",
						NgayBaoVe: "28/10/2024",
						HoiDongID: 57,
					},
				],
			}
		},
		mounted() {
			this.onLoadHoiDong(this.nganh)
			this.onloadDsHeDaoTao()
			this.onLoadHeCaoHoc("C")
		},
		computed: {},
		watch: {
			type: function (val) {
				if (val) {
					this.onLoadHeCaoHoc(val)
				}
			}
		},
		methods: {
			onLoadHoiDong(nganhID) {
				ajaxCALL("/HoiDong_DeTai_Get", {
					NganhID: nganhID
				}, (res) => {
					this.DSHoiDong = res.data.filter(item => item.HoiDongID)
					console.log("this.DSHoiDong", this.DSHoiDong)
	
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to load hoi dong de tai", error)
				})
			},
			onloadDsHeDaoTao() {
				ajaxCALL("/hedaotao_get", null,
					(res) => {
						this.DsHeDaoTao = res.data
						console.log("this.DsHeDaoTao", this.DsHeDaoTao)
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("Fail to load danh sach he dao tao", error)
					})
			},
			onLoadHeCaoHoc(caoHocData) {
				ajaxCALL("/Nganh_Get_ByHeID", {
					HeID: caoHocData
				}, (res) => {
					this.HeCaoHoc = res.data
					console.log("this.HeCaoHoc", this.HeCaoHoc)
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to load he cao hoc", error)
				})
			}
		},
	}
</script>