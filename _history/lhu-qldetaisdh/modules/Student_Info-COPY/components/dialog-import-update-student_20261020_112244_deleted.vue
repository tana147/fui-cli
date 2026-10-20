<template>
	<v-dialog v-model="vueData.isOpenImport" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<c-toolbar @onClose="onClose">
				<template v-slot:title>
					<div class="title primary--text text-left">Cập nhật thông tin học viên</div>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-row>
					<v-col cols="3">
						<!-- <v-autocomplete
                            class="mb-3"
                            v-model="NienKhoaValue"
                            :items="DsNienKhoa"
                            item-text="TenNienKhoa"
                            item-value="NienKhoa"
                            outlined
                            dense
                            hide-details
                            placeholder="Chọn niên khóa"
                            label="Niên khóa"
                        /> -->
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

							<template v-slot:item.Email="{ item }">
								<v-text-field v-model="item.Email" placeholder="Email" dense hide-details />
							</template>

							<template v-slot:item.NoiSinh="{ item }">
								<v-text-field v-model="item.NoiSinh" placeholder="Nơi sinh" dense hide-details />
							</template>

							<template v-slot:item.SoDienThoai="{ item }">
								<v-text-field v-model="item.SoDienThoai" placeholder="Số điện thoại" dense
									hide-details />
							</template>

							<template v-slot:item.DanToc="{ item }">
								<v-text-field v-model="item.DanToc" placeholder="Dân tộc" dense hide-details />
							</template>

							<template v-slot:item.QuocTich="{ item }">
								<v-text-field v-model="item.QuocTich" placeholder="Quốc tịch" dense hide-details />
							</template>

							<template v-slot:item.CCCD="{ item }">
								<v-text-field v-model="item.CCCD" placeholder="Số CCCD" dense hide-details />
							</template>

							<!-- <template v-slot:item.NgayCap_CCCD="{ item }">
                                <f-date v-model="item.NgayCap_CCCD" dense hide-details />
                            </template> -->

							<template v-slot:item.ThoiGianTotNghiep_DaiHoc="{ item }">
								<!-- <f-date v-model="item.ThoiGianTotNghiep_DaiHoc" dense hide-details /> -->
								<v-text-field v-model="item.ThoiGianTotNghiep_DaiHoc" @keydown="onPrevent"
									placeholder="Nhập năm tốt nghiệp đại học" color="primary" dense hide-details />
							</template>

							<template v-slot:item.Truong_DaiHoc="{ item }">
								<v-text-field v-model="item.Truong_DaiHoc" placeholder="Trường Đại học" dense
									hide-details />
							</template>

							<template v-slot:item.Nganh_DaiHoc="{ item }">
								<v-text-field v-model="item.Nganh_DaiHoc" placeholder="Ngành Đại học" dense
									hide-details />
							</template>

							<template v-slot:item.XepLoai="{ item }">
								<v-text-field v-model="item.XepLoai" placeholder="Xếp loại" dense hide-details />
							</template>

							<template v-slot:item.NgoaiNgu_DauVao="{ item }">
								<v-text-field v-model="item.NgoaiNgu_DauVao" placeholder="Ngoại ngữ đầu vào" dense
									hide-details />
							</template>

							<template v-slot:item.StudentID="{ item }">
								<span class="primary--text"><b>{{ item.HoHV }} {{ item.TenHV }}</b></span><br /><b>{{
									item.StudentID }}</b>
							</template>

							<template v-slot:item.Loai_NgoaiNgu_DauVao="{ item }">
								<v-autocomplete v-model="item.Loai_NgoaiNgu_DauVao" placeholder="Loại ngoại ngữ đầu vào"
									:items="DsTenNgoaiNgu" item-text="text" item-value="value" dense hide-details />
							</template>

							<template v-slot:item.BoSungKienThuc="{ item }">
								<v-autocomplete v-model="item.BoSungKienThuc" placeholder="Bổ sung kiến thức"
									:items="DsYesNo" item-text="text" item-value="value" dense hide-details />
							</template>

							<template v-slot:item.CongBoKhoaHoc="{ item }">
								<v-autocomplete v-model="item.CongBoKhoaHoc" placeholder="Công bố khoa học"
									:items="DsYesNo" item-text="text" item-value="value" dense hide-details />
							</template>
						</v-data-table>
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click="onSave" color="success"> <v-icon left>mdi-content-save</v-icon>Lưu </v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ['dsnienkhoa'],
		emits: ['reloadUpdateHV'],
		data() {
			return {
				fileUpload: null,
				NienKhoaValue: null,
				fileTemplate_Id: '9A539D8929504A2797FC79D8174A8A96',
	
				excelData: [],
				DsTenNgoaiNgu: [],
				DsHocVien: [],
				DsYesNo: [],
	
				tableHeader: [
					{ text: 'STT', value: 'STT', align: 'center', width: 50, sortable: false },
					{ text: 'Mã số viên', value: 'StudentID', width: 200, sortable: false },
					{ text: 'Email', value: 'Email', width: 250, sortable: false },
					{ text: 'Nơi sinh', value: 'NoiSinh', width: 120, sortable: false },
					{ text: 'Dân tộc', value: 'DanToc', width: 100, sortable: false },
					{ text: 'Quốc tịch', value: 'QuocTich', width: 100, sortable: false },
					{ text: 'Số điện thoại', value: 'SoDienThoai', width: 120, sortable: false },
					{ text: 'Số CCCD', value: 'CCCD', width: 120, sortable: false },
					// { text: 'Ngày cấp CCCD', value: 'NgayCap_CCCD', width: 150, sortable: false },
					{ text: 'Trường Đại học', value: 'Truong_DaiHoc', width: 230, sortable: false },
					{ text: 'Ngành Đại học', value: 'Nganh_DaiHoc', width: 230, sortable: false },
					{ text: 'Năm tốt nghiệp đại học', value: 'ThoiGianTotNghiep_DaiHoc', width: 250, sortable: false },
					{ text: 'Xếp loại', value: 'XepLoai', width: 100, sortable: false },
					{ text: 'Loại ngoại ngữ đầu vào', value: 'Loai_NgoaiNgu_DauVao', width: 200, sortable: false },
					{ text: 'Ngoại ngữ đầu vào', value: 'NgoaiNgu_DauVao', width: 180, sortable: false },
					{ text: 'Bổ sung kiến thức', value: 'BoSungKienThuc', width: 150, sortable: false },
					{ text: 'Công bố khoa học', value: 'CongBoKhoaHoc', width: 150, sortable: false },
				],
			}
		},
		mounted() { },
		computed: {
			isOpenImport() {
				return vueData.isOpenImport
			},
	
			DsNienKhoa() {
				return this.dsnienkhoa.slice(1)
			},
		},
		watch: {
			isOpenImport(val) {
				if (val) {
					this.DsTenNgoaiNgu = NgoaiNgu_NameList()
					this.DsYesNo = YesNoArray()
				}
			},
	
			NienKhoaValue(val) {
				if (val) {
					this.onLoadHocVien_ByNienKhoa(val)
				}
			},
	
			fileUpload(val) {
				if (val) {
					this.readExcel(val)
				}
			},
		},
		methods: {
			onPrevent(e) {
				this.preventNegative(e)
				this.onlyNumber(e)
			},
	
			preventNegative(e) {
				if (e.key === '-' || e.key === 'e' || e.key === '+') {
					e.preventDefault()
				}
			},
	
			onlyNumber(e) {
				if (e.ctrlKey) {
					const allowCtrlKeys = ['a', 'c', 'v', 'x']
					if (allowCtrlKeys.includes(e.key.toLowerCase())) return
				}
				const allowKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab']
				if (allowKeys.includes(e.key)) return
				const value = e.target.value
				if (/^\d$/.test(e.key)) return
				if (e.key === ',') {
					if (value.includes(',')) e.preventDefault()
					return
				}
				e.preventDefault()
			},
	
			readExcel(file) {
				const reader = new FileReader()
	
				reader.onload = (e) => {
					try {
						const data = e.target.result
	
						const workbook = XLSX.read(data, { type: 'array' })
	
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet)
	
						console.log('Đọc file thành công (ArrayBuffer):', json)
	
						this.DsHocVien = json.map((item) => ({
							STT: item['STT'] ?? null,
							StudentID: item['MSHV'] ?? null,
							HoHV: item['Họ HV'] ?? null,
							TenHV: item['Tên HV'] ?? null,
							Email: item['Email'] ?? null,
							NoiSinh: item['Nơi sinh'] ?? null,
							DanToc: item['Dân tộc'] ?? null,
							QuocTich: item['Quốc tịch'] ?? null,
							CCCD: item['Số CCCD'] ?? null,
							NgayCap_CCCD: item['Ngày cấp CCCD'] ? moment(item['Ngày cấp CCCD'], ['DD/MM/YYYY', 'D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('YYYY-MM-DD') : null,
							Truong_DaiHoc: item['Trường Đại học'] ?? null,
							ThoiGianTotNghiep_DaiHoc: item['Năm tốt nghiệp đại học'] ?? null,
							// ThoiGianTotNghiep_DaiHoc: item['Năm tốt nghiệp đại học'] ? moment(item['Năm tốt nghiệp đại học'], ['DD/MM/YYYY', 'D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('YYYY-MM-DD') : null,
							Nganh_DaiHoc: item['Ngành Đại học'] ?? null,
							XepLoai: item['Xếp loại'] ?? null,
							SoDienThoai: item['Số điện thoại'] ?? null,
							NgoaiNgu_DauVao: item['Ngoại ngữ đầu vào'] ?? null,
							Loai_NgoaiNgu_DauVao: item['Loại ngoại ngữ đầu vào'] ?? null,
							BoSungKienThuc: item['Bổ sung kiến thức'] ?? 0,
							CongBoKhoaHoc: item['Công bố khoa học'] ?? null,
						}))
	
						console.log('this.DsHocVien', this.DsHocVien)
					} catch (error) {
						Vue.$toast.error(`${error}`, { position: 'top' })
						console.error('Lỗi đọc file:', error)
					}
				}
	
				// Đọc excel dưới dạng ArrayBuffer
				reader.readAsArrayBuffer(file)
			},
	
			onLoadHocVien_ByNienKhoa(nienKhoa) {
				const $this = this
				ajaxCALL(
					'/Student_Get_NienKhoa',
					{
						NienKhoa: nienKhoa,
					},
					(res) => {
						$this.DsHocVien = res.data
						console.log('$this.DsHocVien', $this.DsHocVien)
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load DsExistStudent', error)
					},
				)
			},
	
			onSave() {
				const arr = this.DsHocVien.map((item) => ({
					StudentID: item.StudentID ? item.StudentID.toString().trim() : null,
					DanToc: item.DanToc ? item.DanToc.trim() : null,
					Email: item.Email ? item.Email.trim() : null,
					NoiSinh: item.NoiSinh ? item.NoiSinh.trim() : null,
					QuocTich: item.QuocTich ? item.QuocTich.trim() : null,
					CCCD: item.CCCD ? item.CCCD.trim() : null,
					SoDienThoai: item.SoDienThoai ? item.SoDienThoai.trim() : null,
					// NgayCap_CCCD: item.NgayCap_CCCD,
					Truong_DaiHoc: item.Truong_DaiHoc ? item.Truong_DaiHoc.trim() : null,
					Nganh_DaiHoc: item.Nganh_DaiHoc ? item.Nganh_DaiHoc.trim() : null,
					ThoiGianTotNghiep_DaiHoc: item.ThoiGianTotNghiep_DaiHoc,
					XepLoai: item.XepLoai ? item.XepLoai.trim() : null,
					NgoaiNgu_DauVao: item.NgoaiNgu_DauVao ? item.NgoaiNgu_DauVao.trim() : null,
					Loai_NgoaiNgu_DauVao: item.Loai_NgoaiNgu_DauVao,
					BoSungKienThuc: item.BoSungKienThuc,
					CongBoKhoaHoc: item.CongBoKhoaHoc,
				}))
	
				console.log('arr', arr)
	
				if (arr.length > 0) {
					ajaxCALL(
						'/StudentInfor_Update_Import',
						{
							JsonData: JSON.stringify(arr),
						},
						() => {
							Vue.$toast.success(`Cập nhật thông tin học viên thành công`, { position: 'top' })
							this.$emit('reloadUpdateHV')
							this.onClose()
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							console.log('Fail to load DsExistStudent', error)
						},
					)
				}
			},
	
			onClose() {
				this.DsHocVien = []
				this.NienKhoaValue = null
				this.fileUpload = null
				vueData.isOpenImport = false
			},
		},
	}
</script>