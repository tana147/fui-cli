<template>
	<v-dialog v-model="vueData.isOpenDongBo" transition="dialog-bottom-transition" max-width="1500px" persistent="">
		<v-card>
			<c-toolbar @onClose="onClose">
				<template v-slot:title>
					<div class="title primary--text text-left">Đồng bộ dữ liệu phân công GVHD</div>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-row>
					<v-col cols="4">
						<div class="d-flex align-center">
							<v-file-input v-model="fileUpload" dense hide-details
								accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
								label="Chọn file Excel" outlined />
							<v-chip class="ml-3" color="deep-purple accent-4" outlined label hide-details>
								<v-icon left>mdi-file-check-outline</v-icon>
								<a style="color: deep-purple accent-4"
									:href="vueData.v_Set.urlReadFile + 'fileData/' + fileTemplate_Id">File template
									mẫu</a>
							</v-chip>
						</div>
					</v-col>

					<v-col cols="12">
						<v-data-table class="container-wrapper" :headers="tableHeader" :items="DsHocVien"
							:items-per-page="50" dense fixed-header>
							<template v-slot:item.STT="{ item, index }">
								{{ index + 1 }}
							</template>

							<template v-slot:item.StudentID="{ item }">
								<span class='primary--text'><b>{{item.HoHV}}
										{{item.TenHV}}</b></span>
								<br />
								<b>{{item.StudentID}}</b><span class='amber--text'>
									[{{item.LopID}}]</span>
							</template>

							<template v-slot:item.Email="{ item }">
								<p class="mb-0">{{item.Email}}</p>
								<b>{{item.DienThoai}}</b>
							</template>
						</v-data-table>
					</v-col>
				</v-row>

			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click="onSave" color="success"> <v-icon left="">mdi-content-save</v-icon>Lưu </v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				fileUpload: null,
				fileTemplate_Id: 'D462392FE2C042D9909537208A729858',
	
				DsHocVien: [],
	
				tableHeader: [
					{ text: 'STT', value: 'STT', align: 'center', width: 50, sortable: false },
					{ text: 'Học viên', value: 'StudentID', width: 200, sortable: false },
					{ text: 'Ngày sinh', value: 'NgaySinh', width: 100, sortable: false },
					{ text: 'Email/Điện thoại', value: 'Email', width: 60, sortable: false },
					{ text: 'Đề tài', value: 'DeTai', width: 300, sortable: false },
					{ text: 'GVHD 1', value: 'GVHD1', width: 160, sortable: false },
					{ text: 'GVHD 2', value: 'GVHD2', width: 160, sortable: false },
				],
			}
		},
		mounted() { },
		computed: {},
		watch: {
			fileUpload(val) {
				if (val) {
					this.readExcel(val)
				} else {
					this.DsHocVien = []
				}
			},
		},
		methods: {
			readExcel(file) {
				const reader = new FileReader()
	
				reader.onload = (e) => {
					try {
						const data = e.target.result
	
						const workbook = XLSX.read(data, { type: 'array' })
	
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet, {
							range: 6, // bỏ 6 dòng đầu (index bắt đầu từ 0)
						})
	
						console.log('Đọc file thành công (ArrayBuffer):', json)
	
						this.DsHocVien = json.map((item) => ({
							STT: item['STT'] ?? null,
							LopID: item['Lớp'] ?? null,
							StudentID: item['MSHV'] ?? null,
							HoHV: item['Họ'] ?? null,
							TenHV: item['Tên'] ?? null,
							NgaySinh: item['Ngày sinh'] ?? null,
							DienThoai: item['Điện thoại'] ?? null,
							Email: item['Email'] ?? null,
							DeTai: item['Tên đề tài'] ?? null,
							GVHD1: item['Giảng viên hướng dẫn 1'] ?? "",
							GVHD2: item['Giảng viên hướng dẫn 2'] ?? "",
						}))
							.filter(item => item.StudentID)
	
						console.log('this.DsHocVien', this.DsHocVien)
					} catch (error) {
						Vue.$toast.error(`${error}`, { position: 'top' })
						console.error('Lỗi đọc file:', error)
					}
				}
	
				// Đọc excel dưới dạng ArrayBuffer
				reader.readAsArrayBuffer(file)
			},
	
			onSave() {
				const dataArr = this.DsHocVien
					.map(item => {
						return {
							StudentID: item.StudentID,
							GVHD1: item.GVHD1,
							GVHD2: item.GVHD2,
						}
					})
	
				ajaxCALL(
					'/Student_GVHD_Update',
					{
						StudentObjArr: JSON.stringify(dataArr),
					},
					() => {
						Vue.$toast.success(`Đồng bộ GVHD thành công`, { position: 'top' })
						this.onClose()
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load DsExistStudent', error)
					},
				)
			},
	
			onClose() {
				this.fileUpload = null
				this.DsHocVien = []
				vueData.isOpenDongBo = false
			},
		},
	}
</script>