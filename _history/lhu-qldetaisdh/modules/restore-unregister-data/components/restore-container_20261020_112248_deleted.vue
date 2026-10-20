<template>
	<div>
		<dialog-restore-change-topic :dataarr="DataArr" :thstype="ThsType" />
		<div class="d-flex align-center justify-end" style="gap:15px">
			<div v-if="fileData !== null">
				<v-btn @click="vueData.isChangeTopic = true" color="primary">Khôi phục dữ liệu đổi đề tài</v-btn>
			</div>
			<div>
				<v-autocomplete v-model="ThsType" :items="selectBoxData" item-text="text" item-value="value" outlined
					dense hide-details label="Loại thạc sĩ" />
			</div>
			<div>
				<f-file-upload label="" v-model="FILE_UPLOAD" :url="vueData.v_Set.apiFile" :filters="fileRules"
					color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="mt-3">
				<div v-if="File_ID !== null">
					<v-chip label outlined close class="mb-3" color="deep-purple accent-4" @click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + File_ID" target="_blank"
							style="color: deep-purple accent-4">{{File_Name}}</a>
					</v-chip>
				</div>

				<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
					Chưa upload file
				</v-chip>
			</div>
		</div>

		<div class="mt-2" v-if="fileData !== null">
			<v-card>
				<v-card-title class="primary--text">
					Danh sách học viên
					<v-spacer></v-spacer>
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
						hide-details />
				</v-card-title>

				<v-data-table :headers="headerTable" :items="DataArr" dense :search="search" items-per-page="-1"
					:footer-props="{'items-per-page-options':[50, 100, 150, -1]}">
					<template v-slot:item.stt="{ item, index }">
						{{index + 1}}
					</template>
					<template v-slot:item.File_QD_DoiDeTai="{ item, index }">
						<div class="d-flex align-center justify-end" style="gap:15px">
							<div>
								<f-file-upload v-model="item.File_QD_DoiDeTai" label="" :url="vueData.v_Set.apiFile"
									:filters="allFileRules" color="v-btn--outlined v-size--default info--text" />
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
									:filters="allFileRules" color="v-btn--outlined v-size--default info--text" />
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

		</div>

		<div v-if="fileData !== null" class="d-flex justify-end mt-5">
			<!-- <v-btn @click="onRestoreData" color="primary">Đọc dữ liệu</v-btn> -->
			<v-btn @click="restoreData" color="success">Khôi phục dữ liệu</v-btn>
		</div>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				FILE_UPLOAD: null,
				File_ID: null,
				File_Name: null,
				File_Url: null,
				item: null,
				fileData: null,
				fileDataHeader: null,
				DataArr: [],
				search: "",
				checkResolve: true,
				ThsType: 0,
				selectBoxData: [
					{
						text: "Thạc sĩ nghiên cứu",
						value: 0
					},
					{
						text: "Thạc sĩ ứng dụng",
						value: 1
					},
				],
				flowIdTest: 15782,
	
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
						value: "stt",
						align: "center",
						width: 50,
						sortable: false
					},
					{
						text: "Mã HV",
						value: "MaHV",
						width: 90,
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
						width: 182
					},
					{
						text: "GVHD 2 được thay đổi",
						value: "GVHD2_ThayDOi",
						width: 182
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
						width: 186,
						align: "center",
						sortable: false
					},
					// {
					// 	text: "File QĐ đổi đề tài",
					// 	value: "File_QD_DoiDeTai",
					// 	align: "center",
					// 	sortable: false
					// },
					// {
					// 	text: "File QĐ giao đề tài",
					// 	value: "File_QD",
					// 	align: "center",
					// 	sortable: false
					// },
				],
	
				fileRules: {
					"max_file_size": "100mb",
					"mime_types": [
						{
							"title": "Excel files",
							"extensions": "xlsx,xls"
						}
					]
				},
				allFileRules: {
					"max_file_size": "100mb",
					"mime_types": [
						{
							"title": "All files",
							"extensions": "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg"
						}
					]
				},
			}
		},
		mounted() { },
		computed: {
			switchLabel: function () {
				return this.ThsType ? "Thạc sĩ nghiên cứu" : "Thạc sĩ ứng dụng"
			}
		},
		watch: {
			FILE_UPLOAD: function (val) {
				if (val) {
					console.log("val", val.Files[0].FILE_NAME)
					this.File_ID = val.Files[0].FILE_ID
					this.File_Name = val.Files[0].FILE_NAME
					this.File_Url = val.Files[0].FILE_URL
					this.loadExcelFile()
				}
			},
			ThsType: function (val) {
				console.log("ThsType", val)
			}
		},
		methods: {
	
			async restoreData() {
				let deTaiObject = []
	
				console.log("dataArr", this.DataArr)
	
				//Bước 1. Đăng ký tên đề tài dự kiến
				this.DataArr.forEach(hocVien => {
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
							console.log("UD", "NC")
							await this.restoreApi(this.ThSUD_Enum.Step_3, deTai, this.LoaiThs_Enum.UngDung);
						} else {
							console.log("NC", "UD")
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
			async onRestoreData() {
				let flowArr = [];
				let rootArr = [];
				let detailArr = [];
	
				try {
					// Sử dụng Promise.all để chờ tất cả các yêu cầu hoàn thành
					const promises = this.DataArr.map((hocVien, hocVienIndex) => {
						return new Promise((resolve, reject) => {
							ajaxCALL("/Get_RootFlow", {
								StudentID: hocVien.MaHV,
								Process_Tree: 1
							}, (res) => {
								flowArr.push({
									studentId: hocVien.MaHV,
									data: res.data
								});
								resolve(flowArr); // Resolve promise với dataObject
							}, (error) => {
								reject(error); // Reject promise với error
							});
						});
					});
	
					// Chờ tất cả các promises hoàn thành
					await Promise.all(promises);
					console.log('All flow data:', flowArr);
	
					// Gọi API thứ hai sau khi tất cả các promises được resolve
					console.log("flowArr[i].length", flowArr.length)
					for (let i = 0; i < flowArr.length; i++) {
						let studentData = { studentId: flowArr[i].studentId, tasks: [] };
						if (flowArr[i].data.length > 0) {
							flowArr[i].data.forEach((item, index) => {
								// console.log(`Hoc vien ${i + 1}`, item);
								studentData.tasks.push(item);
							});
						} else {
							console.log("Học viên chưa có dữ liệu");
						}
	
						rootArr.push(studentData);
					}
	
					console.log('Root Array:', rootArr);
	
	
					ajaxCALL("/Get_FlowDetail", {
						Flow_ID: this.flowIdTest
					}, (res) => {
						console.log("Ngo Dinh Vu data", res.data)
					}, (error) => {
						console.log("error to load NDV detail", error.responseJSON.Message);
					})
					// const promisesFlowDetail = rootArr.map((item, index) => {
					// 	return new Promise((resolve, reject) => {
					// 		if (item.tasks.length > 0) {
					// 			item.tasks.forEach((detail, detailIndex) => {
					// 				// ajaxCALL("/Get_FlowDetail", {
					// 				// 	Flow_ID: detail.Flow_ID
					// 				// }, (res) =>)
					// 			})
					// 		} else {
					// 			console.log("Task này bị rỗng")
					// 		}
					// 	})
					// })
				} catch (error) {
					console.log("Có lỗi xảy ra: ", error);
				}
			},
	
			// console.log("flowArr[i].length", flowArr[i].length)
			// if (flowArr[i].length > 0) {
			// // let item = flowArr[i];
	
			// flowArr[i].forEach((item, index) => {
			// ajaxCALL("/Get_FlowDetail", {
			// Flow_ID: item[i].Flow_ID
			// }, (res) => {
			// console.log(`Flow detail ${index + 1}`, res.data);
			// }, (error) => {
			// console.log("error to load flow detail", error.responseJSON.Message);
			// });
			// })
			// } else {
			// console.log("Học viên chưa có dữ liệu")
			// }
	
			async loadExcelFile() {
				try {
					const url = "https://file.lhu.edu.vn/qldetaisdh/" + this.File_Url; // Replace with the actual URL
					const response = await fetch(url);
					if (!response.ok) throw new Error('Network response was not ok');
	
					const arrayBuffer = await response.arrayBuffer();
	
					const workbook = new ExcelJS.Workbook();
					await workbook.xlsx.load(arrayBuffer);
	
					const worksheet = workbook.getWorksheet(1); // Get the first worksheet
					const jsonData = [];
	
					worksheet.eachRow((row, rowNumber) => {
						const rowData = row.values.slice(1); // Remove empty first element
						jsonData.push(rowData);
					});
	
					if (jsonData.length > 0) {
						this.fileDataHeader = jsonData[1];
						jsonData.splice(0, 2);
						this.fileData = jsonData;
					}
	
					// Ensure each row has length 14 by adding empty elements
					const maxLength = 15;
					this.fileData = this.fileData.map(row => {
						while (row.length < maxLength) {
							row.push(''); // Add empty string or null as needed 
						} return row;
					});
	
					// Map fileData to objects and push to DataArr
					this.DataArr = this.fileData.map(row => {
						return {
							STT: row[0] || null,
							MaHV: row[1] || null,
							HoHV: row[2] || null,
							TenHV: row[3] || null,
							DeTai: row[4] || null,
							GVHD_1: row[5] || null,
							GVHD_2: row[6] || null,
							SQD_GiaoDeTai: row[7] || null,
							Ngay_QD_GiaoDetTai: row[8] !== "" ? moment(row[8]).format('DD/MM/YYYY') : null,
							TenDeTaiThayDoi: row[9] || null,
							GVHD1_ThayDOi: row[10] || null,
							GVHD2_ThayDOi: row[11] || null,
							SQD_ThayDoi_DeTai: row[12] || null,
							Ngay_ThayQD_DeTai: row[13] !== "" ? moment(row[13]).format('DD/MM/YYYY') : null,
							File_QD_DoiDeTai: row[14] || null, // Assuming this is the new field you want to add
							File_QD: row[15] || null // Assuming this is the new field you want to add
						};
					});
	
					console.log("this.DataArr", this.DataArr);
					console.log("this.fileDataHeader", this.fileDataHeader);
					console.log("this.fileData", this.fileData);
				}
				catch (error) {
					console.error('Error loading Excel file:', error);
				}
			},
	
			deleteFile() {
				this.File_ID = null
				this.File_Name = null
				this.fileData = null
			}
		}
	}
</script>