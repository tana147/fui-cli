<template>
	<div>
		<v-row>
			<v-col cols="2">
				<v-autocomplete v-model="NienKhoaValue" :items="DsNienKhoa" item-text="TenNienKhoa"
					item-value="NienKhoa" outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
			</v-col>
			<v-col class="pl-0" cols="3">
				<v-autocomplete v-model="major" :items="heArr" outlined dense hide-details label="Lọc theo ngành"
					item-text="TenNganh" item-value="NganhID" />
			</v-col>
			<v-col class="d-flex pt-0 pb-0 pl-0">
				<v-btn class="mt-3" @click="confirmBox(DSStudentFilter)" color="primary">
					<v-icon left>mdi-plus</v-icon>Thêm tất cả
				</v-btn>
				<!-- <v-btn class="mt-3 ml-3" @click="vueData.isOpenImport = true" color="success">
                    <v-icon left>mdi-update</v-icon>Cập nhật thông tin học viên
                </v-btn>
                <v-btn class="mt-3 ml-3" @click="vueData.isOpenDongBo = true">Đồng bộ GVHD</v-btn> -->
				<v-menu offset-y left>
					<template v-slot:activator="{ on, attrs }">
						<v-btn class="mt-3 ml-3" color="success" dark v-bind="attrs" v-on="on">
							<v-icon left>mdi-cog-outline</v-icon>
							Tùy chọn
							<v-icon right>mdi-chevron-down</v-icon>
						</v-btn>
					</template>
					<v-list class="py-1">
						<v-list-item @click="vueData.isOpenImport = true">
							<v-list-item-icon>
								<v-icon color="success">mdi-update</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Cập nhật thông tin học viên</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
						<v-list-item @click="vueData.isOpenDongBo = true">
							<v-list-item-icon>
								<v-icon color="primary">mdi-sync</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Đồng bộ dữ liệu phân công GVHD</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
					</v-list>
				</v-menu>
			</v-col>
			<v-col cols="12" class="pt-0">
				<info-table :dsstudentfilter="DSStudentFilter" :dsexiststudent="DsExistStudent" />
			</v-col>
		</v-row>
		<dialog-import-update-student :dsnienkhoa="DsNienKhoa" @reloadUpdateHV="reloadUpdateHV" />
		<dialog-upd-task :dsexiststudent="DsExistStudent" />
		<dialog-reset-student-process />
		<dialog-view-old-reset-process />
		<dialog-dong-bo-gvhd />
	</div>
</template>

<script>
	export default {
		props: ['dshedaotao'],
		data() {
			return {
				DsNienKhoa: [],
				DsStudentInfo: [],
				DSStudentFilter: [],
				DsExistStudent: [],
				NienKhoaValue: null,
				type: '',
				major: '',
				heArr: [],
				searchObj: {
					NienKhoa: null,
					MaHV: null,
				},
			}
		},
		mounted() {
			// Danh sách niên khóa
			this.getNienKhoa()
			// Danh sách ngành
			this.getHeDaoTao()
		},
		computed: {
			reloadStuNienKhoa() {
				return vueData.reloadStuNienKhoa
			},
	
			reloadXuLyHocVu() {
				return vueData.reloadXuLyHocVu
			},
		},
		watch: {
			reloadStuNienKhoa: function (val) {
				this.onLoadStudentGetNienKhoa(vueData.nienKhoaData)
			},
	
			reloadXuLyHocVu: function (val) {
				console.log('sadasdas')
				this.onLoadStudentGetNienKhoa(vueData.nienKhoaData)
			},
	
			async NienKhoaValue(val) {
				console.log('nien khoa')
				vueData.nienKhoaData = val
	
				await this.onLoadStudentInfo(val) // SDH
				this.major = null
			},
			major: function (val) {
				if (val) {
					const $this = this
					if (val !== '0') {
						this.DSStudentFilter = this.DsStudentInfo
						this.DSStudentFilter = this.DsStudentInfo.filter((item) => item.NganhID == val)
	
						const newStudents = this.getNewStudents(val)
						this.DSStudentFilter.push(...newStudents)
	
						// reset isCanDelete
						if ($this.DsExistStudent.length > 0) {
							$this.DSStudentFilter.map((item) => {
								const findStudent = $this.DsExistStudent.find((x) => x.StudentID === item.StudentID)
								if (findStudent) {
									// Seq = 1 là bước 1
									item.isCanDelete = findStudent.Seq === 1 && findStudent.Flow_Status === 'W' && findStudent.TotalChangeThesis === 1 ? true : false
								} else {
									item.isCanDelete = false
								}
	
								return item
							})
						}
	
						this.DSStudentFilter = this.resetSTT(this.DSStudentFilter)
					} else {
						this.DSStudentFilter = this.DsStudentInfo
	
						const newStudents = this.getNewStudents(val)
						this.DSStudentFilter.push(...newStudents)
	
						// reset isCanDelete
						if ($this.DsExistStudent.length > 0) {
							$this.DSStudentFilter.map((item) => {
								const findStudent = $this.DsExistStudent.find((x) => x.StudentID === item.StudentID)
								if (findStudent) {
									// Seq = 1 là bước 1
									item.isCanDelete = findStudent.Seq === 1 && findStudent.Flow_Status === 'W' && findStudent.TotalChangeThesis === 1 ? true : false
								} else {
									item.isCanDelete = false
								}
	
								return item
							})
						}
	
						this.DSStudentFilter = this.resetSTT(this.DSStudentFilter)
					}
				}
			},
			//SDH
			DsStudentInfo: {
				async handler(val) {
					const $this = this
	
					await this.onLoadStudentGetNienKhoa(vueData.nienKhoaData)
					console.log('YYYYYYYYYYYYY', this.DsExistStudent)
					if (this.DsExistStudent) {
						const arrDSHocSinh = val.map((student) => {
							const exist = this.DsExistStudent.find((x) => x.StudentID === student.StudentID)
							if (exist) {
								student.isExist = true
							} else {
								student.isExist = false
							}
							return student
						})
						this.DSStudentFilter = arrDSHocSinh // Gán DSStudentFilter bằng val, không phải this.DsStudentInfo
	
						const newStudents = this.getNewStudents()
						this.DSStudentFilter.push(...newStudents)
	
						if ($this.DsExistStudent.length > 0) {
							$this.DSStudentFilter.map((item) => {
								const findStudent = $this.DsExistStudent.find((x) => x.StudentID === item.StudentID)
								if (findStudent) {
									// Seq = 1 là bước 1
									item.isCanDelete = findStudent.Seq === 1 && findStudent.Flow_Status === 'W' && findStudent.TotalChangeThesis === 1 ? true : false
									item.HasResetProcess = findStudent.HasResetProcess
								} else {
									item.isCanDelete = false
								}
	
								return item
							})
						}
	
						this.DSStudentFilter = this.resetSTT(this.DSStudentFilter)
						console.log('this.DSStudentFilter', this.DSStudentFilter)
					}
				}, //, deep: true
			},
		},
		methods: {
			confirmBox(ds) {
				const $this = this
				confirm({
					title: 'Bạn có muốn thêm tất cả không?',
					content: ``,
					action: async () => {
						onSave(ds)
					},
				})
			},
	
			reloadUpdateHV() {
				this.onLoadStudentGetNienKhoa(vueData.nienKhoaData)
			},
	
			async onAdvanceSearch() {
				const $this = this
				for (const nienKhoa of $this.searchObj.NienKhoa) {
					await $this.onLoadStudentInfo(nienKhoa) // Gọi API
	
					await $this.$nextTick() // Chờ Vue cập nhật xong watch
	
					const students = $this.DSStudentFilter.filter((item) => item.StudentID === $this.searchObj.MaHV)
					if (students.length > 0) {
						console.log('students xxxxxx', students)
						$this.DSStudentFilter = students
						return
					}
				}
			},
	
			getNewStudents(nganhID = null) {
				return this.DsExistStudent.filter((item) => (!nganhID || item.NganhID == nganhID) && !this.DSStudentFilter.some((x) => x.StudentID === item.StudentID)).map((item) => ({
					...item,
					STT: 0,
					HoTen: `${item.HoSV} ${item.TenSV}`,
					NgaySinh: moment(item.NgaySinh, ['ddd MMM DD YYYY HH:mm:ss [GMT]ZZ (z)'], true).isValid() ? moment(item.NgaySinh).format('DD/MM/YYYY') : null,
					isExist: true,
					isSelect: false,
					isCanDelete: false,
				}))
			},
			resetSTT(ds) {
				ds.forEach((item, index) => {
					item.stt = index + 1
				})
				return ds
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
							TenNienKhoa: '- Tất cả học viên đã được thêm -',
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
			//SDH
			async onLoadStudentInfo(nienKhoa) {
				const $this = this
				return new Promise((resolve) => {
					$.ajax({
						type: 'GET',
						headers: {
							authorization: $awt,
						},
						url: `https://tapi.lhu.edu.vn/hoso/StudentInfoByStudentID_CaoHoc?NienKhoa=${nienKhoa}`,
						contentType: 'application/json; charset=utf-8',
						dataType: 'json',
						crossDomain: true,
						success: function (res) {
							$this.DsStudentInfo = res.data.map((item, index) => {
								return {
									...item,
									stt: index + 1,
									HoTen: item.HoSV + ' ' + item.TenSV,
									Email: item.Email ? item.Email : '',
									NoiSinh: item.NoiSinh ? item.NoiSinh : '',
									SoDienThoai: item.SoDienThoai ? item.SoDienThoai : '',
									HasResetProcess: null,
									isExist: false,
									isSelect: false,
									isCanDelete: true,
									// NgaySinh: moment(item.NgaySinh).format('DD/MM/YYYY')
								}
							})
							$this.DSStudentFilter = res.data.map((item, index) => {
								return {
									...item,
									stt: index + 1,
									HoTen: item.HoSV + ' ' + item.TenSV,
									isExist: false,
									isSelect: false,
									isCanDelete: true,
									// NgaySinh: moment(item.NgaySinh).format('DD/MM/YYYY')
								}
							})
							resolve()
							//console.log("$this.DsStudentInfo", $this.DsStudentInfo)
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
				})
			},
			//SELF
			async onLoadStudentGetNienKhoa(nienKhoa) {
				const $this = this
				return new Promise((resolve) => {
					ajaxCALL(
						'/Student_Get_NienKhoa',
						{
							NienKhoa: nienKhoa,
						},
						(res) => {
							// $this.DsExistStudent = res.data.map((item) => {
							// 	return {
							// 		...item,
							// 		NgaySinh: new Date(item.NgaySinh),
							// 	}
							// })
							// console.log("$this.DsExistStudent", $this.DsExistStudent)
							$this.DsExistStudent = res.data.map((item) => {
								let ngaySinh = null;
								if (item.NgaySinh) {
									const [d, m, y] = item.NgaySinh.split('/');
									ngaySinh = new Date(y, m - 1, d);
								}
	
								return {
									...item,
									NgaySinh: ngaySinh,
								};
							});
							resolve()
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							console.log('Fail to load DsExistStudent', error)
						},
					)
				})
			},
			async getHeDaoTao() {
				this.heArr = await getNganhCaoHocPromise({ hasAllOption: true });
			},
		},
	}
</script>