<template>
	<div>
		<v-dialog v-model="vueData.isChangeTopic" transition="dialog-bottom-transition" max-width="1400px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isChangeTopic = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Dữ liệu đổi đề tài</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-card>
						<v-card-title class="primary--text">
							Danh sách học viên
							<v-spacer></v-spacer>
							<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
								hide-details />
						</v-card-title>

						<v-data-table :headers="headerTable" :items="DataArr" dense :search="search" items-per-page="-1"
							:footer-props="{'items-per-page-options':[50, 100, 150, -1]}">
							<template v-slot:item.File_QD_DoiDeTai="{ item, index }">
								<div class="d-flex align-center justify-end" style="gap:15px">
									<div>
										<f-file-upload v-model="item.File_QD_DoiDeTai" label=""
											:url="vueData.v_Set.apiFile" :filters="allFileRules"
											color="v-btn--outlined v-size--default info--text" />
									</div>
									<div class="mt-3">
										<div v-if="item.File_QD_DoiDeTai !== null">
											<v-chip label outlined close class="mb-3" color="deep-purple accent-4"
												@click:close="deleteFile">
												<v-icon left>mdi-file-check-outline</v-icon>
												<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_QD_DoiDeTai.Files[0].FILE_ID"
													target="_blank"
													style="color: deep-purple accent-4">{{item.File_QD_DoiDeTai.Files[0].FILE_NAME}}</a>
											</v-chip>
										</div>

										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>
								</div>
							</template>
							<template v-slot:item.File_QD="{ item, index }">
								<div class="d-flex align-center justify-end" style="gap:15px">
									<div>
										<f-file-upload v-model="item.File_QD" label="" :url="vueData.v_Set.apiFile"
											:filters="allFileRules"
											color="v-btn--outlined v-size--default info--text" />
									</div>
									<div class="mt-3">
										<div v-if="item.File_QD !== null">
											<v-chip label outlined close class="mb-3" color="deep-purple accent-4"
												@click:close="deleteFile">
												<v-icon left>mdi-file-check-outline</v-icon>
												<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_QD.Files[0].FILE_ID"
													target="_blank"
													style="color: deep-purple accent-4">{{item.File_QD.Files[0].FILE_NAME}}</a>
											</v-chip>
										</div>

										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>
								</div>
							</template>
						</v-data-table>
					</v-card>
				</v-card-text>

				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="restoreData" color="success">Khôi phục dữ liệu đổi đề tài</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["dataarr", "thstype"],
		data() {
			return {
				search: "",
				ThSNC_Enum: {
					Step_1: 18,
					Step_2: 34,
					Step_3: 2,
					Step_4: 3
				},
				ThSUD_Enum: {
					Step_1: 33,
					Step_2: 35,
					Step_3: 20,
					Step_4: 21
				},
				LoaiThs_Enum: {
					NghienCuu: 1,
					UngDung: 4
				},
	
				headerTable: [
					{
						text: "STT",
						value: "STT",
						align: "center",
						width: 50,
						sortable: false
					},
					{
						text: "Mã HV",
						value: "MaHV",
						width: 92,
					},
					{
						text: "Họ HV",
						value: "HoHV",
						width: 120,
					},
					{
						text: "Tên HV",
						value: "TenHV",
						width: 100
					},
					{
						text: "Đề tài",
						value: "DeTai",
						width: 295
					},
					{
						text: "GVHD 1",
						value: "GVHD_1",
						width: 176
					},
					{
						text: "GVHD 2",
						value: "GVHD_2",
						width: 176
					},
					{
						text: "SQD giao đề tài",
						value: "SQD_GiaoDeTai",
						width: 142,
						align: "center",
						sortable: false
					},
					{
						text: "Ngày ra QĐ giao đề tài",
						value: "Ngay_QD_GiaoDetTai",
						width: 182,
						align: "center",
						sortable: false
					},
					{
						text: "Tên đề tài thay đổi",
						value: "TenDeTaiThayDoi",
						width: 295
					},
					{
						text: "GVHD 1 được thay đổi",
						value: "GVHD1_ThayDOi",
						width: 184
					},
					{
						text: "GVHD 2 được thay đổi",
						value: "GVHD2_ThayDOi",
						width: 184
					},
					{
						text: "SQĐ thay đổi đề tài",
						value: "SQD_ThayDoi_DeTai",
						width: 164,
						align: "center",
						sortable: false
					},
					{
						text: "Ngày thay SQĐ giao đề tài",
						value: "Ngay_ThayQD_DeTai",
						width: 188,
						align: "center",
						sortable: false
					},
				],
			}
		},
		mounted() { },
		computed: {
			DataArr: function () {
				return this.dataarr.filter(item => item.SQD_ThayDoi_DeTai !== null)
			},
			ThsType: function () {
				return this.thstype
			},
		},
		watch: {},
		methods: {
			async restoreData() {
				let deTaiObject = []
	
				console.log("dataArr", this.DataArr)
	
				//Bước 1. Đăng ký tên đề tài dự kiến
				this.DataArr.forEach(hocVien => {
					//Tạo mới case
					this.onProcessStudent(hocVien.MaHV)

					deTaiObject.push([
						{
							StudentID: hocVien.MaHV,
							FieldName: 'ThesisNameSuggest',
							Text_Content: hocVien.DeTai
						},
						{
							StudentID: hocVien.MaHV,
							FieldName: 'ThesisesProfSuggest1',
							Text_Content: hocVien.GVHD_1
						},
						{
							StudentID: hocVien.MaHV,
							FieldName: 'isGVHDSigned',
							Text_Content: "True"
						},
						{
							StudentID: hocVien.MaHV,
							FieldName: 'fileDKDeTai',
							Text_Content: null
						},
					])
				})
	
				console.log("deTaiObject", deTaiObject)
	
				try {
					for (const deTai of deTaiObject) {
						if (this.ThsType === 1) {
							console.log("UD", this.ThsType)
							await this.restoreApi(this.ThSUD_Enum.Step_1, deTai, this.LoaiThs_Enum.UngDung);
						} else {
							console.log("NC", this.ThsType)
							await this.restoreApi(this.ThSNC_Enum.Step_1, deTai, this.LoaiThs_Enum.NghienCuu);
						}
					}
					console.log("Tất cả API bước 1 call thành công");
	
					//Bước 2. Giảng viên chính thức được phân công
					deTaiObject = []
					this.DataArr.forEach(hocVien => {
						deTaiObject.push([
							{
								StudentID: hocVien.MaHV,
								FieldName: 'ThesisesProf1',
								Text_Content: hocVien.GVHD_1
							},
							{
								StudentID: hocVien.MaHV,
								FieldName: 'ThesisesProf2',
								Text_Content: hocVien.GVHD_2
							},
						])
					})
					for (const deTai of deTaiObject) {
						if (this.ThsType === 1) {
							console.log("UD", this.ThsType)
							await this.restoreApi(this.ThSUD_Enum.Step_2, deTai, this.LoaiThs_Enum.UngDung);
						} else {
							console.log("NC", this.ThsType)
							await this.restoreApi(this.ThSNC_Enum.Step_2, deTai, this.LoaiThs_Enum.NghienCuu);
						}
					}
					console.log("Tất cả API bước 2 call thành công");
	
					//Bước 3. Nộp đề cương luận văn
					deTaiObject = []
					this.DataArr.forEach(hocVien => {
						deTaiObject.push([
							{
								StudentID: hocVien.MaHV,
								FieldName: 'ThesisName',
								Text_Content: hocVien.DeTai
							},
							{
								StudentID: hocVien.MaHV,
								FieldName: 'fileDeCuong',
								Text_Content: null
							},
						])
					})
	
					for (const deTai of deTaiObject) {
						if (this.ThsType === 1) {
							console.log("UD", this.ThsType)
							await this.restoreApi(this.ThSUD_Enum.Step_3, deTai, this.LoaiThs_Enum.UngDung);
						} else {
							console.log("NC", this.ThsType)
							await this.restoreApi(this.ThSNC_Enum.Step_3, deTai, this.LoaiThs_Enum.NghienCuu);
						}
					}
					console.log("Tất cả API bước 3 call thành công");
	
					//Bước 4. Ra quyết định giao đề tài luận văn
					deTaiObject = []
					this.DataArr.forEach(hocVien => {
						deTaiObject.push([
							{
								StudentID: hocVien.MaHV,
								FieldName: 'ThesisConfirm',
								Text_Content: null
								//hocVien.File_QD !== null ? hocVien.File_QD.Files[0] :
							},
							{
								StudentID: hocVien.MaHV,
								FieldName: 'ThesisConfirmNo',
								Text_Content: hocVien.SQD_GiaoDeTai
							},
						])
					})
	
					for (const deTai of deTaiObject) {
						if (this.ThsType === 1) {
							console.log("UD", this.ThsType)
							await this.restoreApi(this.ThSUD_Enum.Step_4, deTai, this.LoaiThs_Enum.UngDung);
						} else {
							console.log("NC", this.ThsType)
							await this.restoreApi(this.ThSNC_Enum.Step_4, deTai, this.LoaiThs_Enum.NghienCuu);
						}
					}
					console.log("Tất cả API bước 4 call thành công");
	
					Vue.$toast.success(`Khôi phục thành công`, { position: 'top' })
				} catch (error) {
					Vue.$toast.error(`Khôi phục thất bại: ${error}`, { position: 'top' })
					// Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Có lỗi xảy ra trong quá trình gọi API: ", error);
				}
			},
			async restoreApi(taskId, dataRestore, thesisType) {
				return new Promise((resolve, reject) => {
					ajaxCALL("/FlowDetail_Restore_ByStudentID", {
						Task_ID: taskId,
						DataRestore: dataRestore,
						LoaiThs: thesisType
					}, (res) => {
						console.log("success");
						resolve('success'); // Resolve the promise on success
					}, (error) => {
						console.log("error update restore", error.responseJSON.Message);
						reject('fail'); // Reject the promise on error
					});
				});
			},
	
			onProcessStudent(studentID) {
				const processAction = 1
				const expireDate = "2024-12-12"
				const insertNew = 0

				ajaxCALL("/Process_Student_Ins", {
					Process_Action: processAction,
					Student_ID: this.HocVienData.StudentID,
					Expire_Date: expireDate,
					insert_new: insertNew,
				}, (res) => {
					Vue.$toast.success(`Tạo mới quy trình đổi đề tài thành công`, { position: 'top' });
					console.log("Tạo mới quy trình đổi đề tài thành công")
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to Process_Student_Ins", error)
				})
			},
		},
	}
</script>