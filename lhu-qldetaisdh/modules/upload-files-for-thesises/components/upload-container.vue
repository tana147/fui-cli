<template>
	<div>
		<v-row>
			<v-col cols="2">
				<v-autocomplete v-model="NienKhoaValue" :items="DsNienKhoa" item-text="NienKhoa" item-value="NienKhoa"
					outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
			</v-col>
			<v-col class="pl-0" cols="3">
				<v-autocomplete v-model="major" :items="heArr" outlined dense hide-details label="Lọc theo ngành"
					item-text="TenNganh" item-value="NganhID" />
			</v-col>
		</v-row>
		<v-row>
			<v-col cols="4">
				<f-table :items="dsstudentfilter" :headers="existHeader" label="Danh sách học viên" showSearch="true"
					excel="false" :footer-props="{'items-per-page-options':[50, 100, 150, -1]}" dense />
			</v-col>
			<v-col cols="8">
				<f-table :items="StudentSelectedArr" :headers="selectedHeader" label="Danh sách học viên được chọn"
					showSearch="true" excel="false" :footer-props="{'items-per-page-options':[50, 100, 150, -1]}" dense />
			</v-col>
		</v-row>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				DsHeDaoTao: [],
				DsNienKhoa: [],
				NienKhoaValue: null,
				heArr: [],
				major: "",
				DsExistStudent: [],
				dsstudentfilter: [],
				dataTable: [],
	
				existHeader: [
					{
						text: "STT",
						value: "STT",
						align: "center",
						sortable: false
					},
					{
						text: "MSHV",
						value: "StudentID"
					},
					{
						text: "Họ và tên",
						value: "HoVaTen"
					},
					{
						text: "Niên khóa",
						value: "NienKhoa"
					},
					{
						text: "Tên ngành",
						value: "TenNganh"
					},
					{
						text: "Chọn",
						value: "select",
						el: "div",
						align: "center",
						sortable: false,
						innerHTML: `<v-btn @click='selectDeTai(item)' text color='success'>
											<v-icon>mdi-plus</v-icon>
										</v-btn>`
					},
				],
				selectedHeader: [
					{
						text: "STT",
						value: "STT",
						align: "center",
						sortable: false
					},
					{
						text: "MSHV",
						value: "StudentID"
					},
					{
						text: "Họ và tên",
						value: "HoVaTen"
					},
					{
						text: "Niên khóa",
						value: "NienKhoa"
					},
					{
						text: "Tên ngành",
						value: "TenNganh"
					},
					{
						value: "btnChucNang",
						align: "center",
						el: "div",
						innerHTML: `<v-tooltip left color="warning">
							<template v-slot:activator="{ on, attrs }">
								<v-btn @click="deleteSelectDeTai(item.STT)" v-on="on" x-small fab icon>
									<v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
								</v-btn>
							</template>
							<span>Xóa</span>
						</v-tooltip>`
					}
				]
			}
		},
		mounted() {
			this.getHeDaoTao()
			this.getNienKhoa()
		},
		computed: {
			StudentSelectedArr: function () {
				return vueData.studentSelectedArr
			}
		},
		watch: {
			async NienKhoaValue(val) {
				console.log("nien khoa")
				vueData.nienKhoaData = val
	
				// await this.onLoadStudentInfo(val) // SDH
				await this.onLoadStudentGetNienKhoa(val) // self
				this.major = null
			},
			"major": function (val) {
				if (val) {
					this.dsstudentfilter = this.DsExistStudent
					this.dsstudentfilter = this.DsExistStudent.filter(item => item.NganhID == val)
					console.log("filter", this.dsstudentfilter)
				}
	
			},
			dataTable: function(val){
				console.log("val xx")
				// let sortList = val.map((item, index) => {
				// 	return{
				// 		...item,
				// 		STT: index + 1
				// 	}
				// })
			}
		},
		methods: {
	
			getNienKhoa() {
				const $this = this
				$.ajax({
					type: "GET",
					headers: {
						authorization: $awt
					},
					url: `https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`,
					contentType: "application/json; charset=utf-8",
					dataType: "json",
					crossDomain: true,
					success: function (res) {
						$this.DsNienKhoa = res.data
						$this.NienKhoaValue = res.data[0].NienKhoa
					},
					error: function (xhr, ajaxOptions, thrownError) {
						$.dialog({
							icon: 'fas fa-exclamation',
							title: 'Error',
							content: (xhr.responseJSON ? xhr.responseJSON.Message : (xhr.responseText ? xhr.responseText : "")),
							type: 'red',
							columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
							closeIcon: true,
							buttons: {
								ok: {
									text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
									btnClass: 'btn-blue',
								}
							}
						});
					},
				})
			},
			getHeDaoTao() {
				const $this = this
				$.ajax({
					type: "GET",
					headers: {
						authorization: $awt
					},
					url: `https://tapi.lhu.edu.vn/hoso/AUTH/Public_SelectNganh_CaoHoc`,
					contentType: "application/json; charset=utf-8",
					dataType: "json",
					crossDomain: true,
					success: function (res) {
						$this.heArr = res.data
						console.log("$this.heArr", $this.heArr)
					},
					error: function (xhr, ajaxOptions, thrownError) {
						$.dialog({
							icon: 'fas fa-exclamation',
							title: 'Error',
							content: (xhr.responseJSON ? xhr.responseJSON.Message : (xhr.responseText ? xhr.responseText : "")),
							type: 'red',
							columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
							closeIcon: true,
							buttons: {
								ok: {
									text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
									btnClass: 'btn-blue',
								}
							}
						});
					},
				})
			},
			async onLoadStudentGetNienKhoa(nienKhoa) {
				const $this = this
				return new Promise(resolve => {
					ajaxCALL("/Student_Get_NienKhoa", {
						NienKhoa: nienKhoa
					}, (res) => {
						$this.DsExistStudent = res.data.map((item, index) => {
							return {
								...item,
								NgaySinh: new Date(item.NgaySinh),
								STT: index + 1,
								HoVaTen: item.HoSV + " " + item.TenSV
							}
						})
						$this.dsstudentfilter = res.data.map((item, index) => {
							return {
								...item,
								NgaySinh: new Date(item.NgaySinh),
								STT: index + 1,
								HoVaTen: item.HoSV + " " + item.TenSV
							}
						})
						console.log("$this.dsstudentfilter", $this.dsstudentfilter)
						// console.log("$this.DsExistStudent", $this.DsExistStudent)
						resolve()
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("Fail to load DsExistStudent", error)
					})
				})
	
			},
		},
	}
</script>