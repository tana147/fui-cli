<template>
	<div style="height: 100dvh; overflow-y: hidden;">
		<v-card class="pt-2 mx-auto text-center" style="height: 100dvh; overflow-y: auto;" elevation="0">
			<v-card-title class="primary--text text-h6 font-weight-bold justify-center pb-5">
				<v-btn v-if="CT_HoaDon?.HoaDonID > 0 && !showDialog" @click="onGoBack" icon variant="flat"
					color="primary" class="mr-3">
					<v-icon>mdi-keyboard-backspace</v-icon>
				</v-btn>
				THÔNG TIN HÓA ĐƠN ĐIỆN TỬ
			</v-card-title>
			<!-- kiểm tra hóa đơn có tồn tại -->
			<template v-if="CT_HoaDon?.HoaDonID > 0">
				<!-- case 1: không có thông tin -->
				<v-card-text v-if="caseType === 1">
					<div v-if="!isShowFormEdit" class="d-flex flex-column justify-center align-center py-8"
						style="height: calc(100vh - 147px)">
						<v-icon size="48" color="grey">mdi-inbox</v-icon>
						<p class="mt-2 text-center">
							<b>Chưa có thông tin xuất hóa đơn</b><br />
							<small>Vui lòng nhập thông tin nếu muốn xuất hóa đơn điện tử</small>
						</p>
						<v-btn color="primary" @click="openEdit" elevation="0">
							<v-icon left>mdi-draw-pen</v-icon>
							Nhập thông tin
						</v-btn>
					</div>
					<div v-else>
						<v-row class="pa-0">
							<v-col>
								<v-text-field label="Mã hóa đơn" v-model="CT_HoaDon.MaHoaDon" readonly />
							</v-col>
							<v-col>
								<v-text-field label="Trạng thái" value="Chưa có thông tin" readonly variant="outlined"
									density="compact" />
							</v-col>
						</v-row>
						<v-row class="pa-0">
							<v-col>
								<v-text-field label="Ngày" v-model="CT_HoaDon.NgayThemMoi" readonly />
							</v-col>
							<v-col>
								<v-text-field label="Thời gian" v-model="CT_HoaDon.GioThemMoi" readonly />
							</v-col>
						</v-row>
						<v-text-field v-for="field in allFields" :key="field.key" v-model="form[field.key]"
							:label="field.label" variant="outlined" density="compact" />
						<div class="text-right mt-6">
							<v-btn @click="cancelEdit" elevation="0">Hủy</v-btn>
							<v-btn color="primary" class="ml-2" @click="saveData" elevation="0">Gửi yêu cầu</v-btn>
						</div>
					</div>
				</v-card-text>
				<!-- case 2: đã có thông tin -> chờ xuất -->
				<v-card-text v-else-if="caseType === 2">
					<div v-if="!showDialog">
						<div class="d-flex flex-column">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-inbox-full</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Khách hàng đã có thông tin xuất hóa
										đơn
									</p>
									<p class="mb-0 primary--text font-weight-bold">{{CT_HoaDon.Invoice_ResultInvoiceNo}}
									</p>
								</div>
							</div>
							<v-row>
								<v-col cols="6">
									<v-text-field label="Mã hóa đơn" v-model="CT_HoaDon.MaHoaDon" readonly
										hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Trạng thái" value="Đã phát hành" readonly variant="outlined"
										density="compact" hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Ngày" v-model="CT_HoaDon.NgayThemMoi" readonly hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Thời gian" v-model="CT_HoaDon.GioThemMoi" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Mã số thuế" v-model="CT_HoaDon.Invoice_BuyerTaxCode" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Tên" v-model="CT_HoaDon.Invoice_BuyerLegalName" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Số điện thoại" v-model="CT_HoaDon.Invoice_BuyerPhoneNumber"
										readonly hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Địa chỉ" v-model="CT_HoaDon.Invoice_BuyerAddressLine" readonly
										hide-details />

								</v-col>
								<v-col cols="12">
									<v-text-field label="Email" v-model="CT_HoaDon.Invoice_BuyerEmail" readonly
										hide-details />
								</v-col>
							</v-row>
							<div class="mt-10">
								<p class="red--text mt-2">
									<small>
										Quý khách vui lòng nhập thông tin muốn điều chỉnh bằng cách chọn ô yêu cầu cập
										nhật thông tin dưới đây.
									</small>
								</p>
								<v-btn color="primary" block @click="openAlter('mst')" elevation="0">Yêu cầu cập nhật
									thông tin</v-btn>
							</div>
						</div>
					</div>
					<div v-else>
						<div v-if="selectedKey === 'mst'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-office-building-cog-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin</p>
									<p class="mb-0 primary--text font-weight-bold">Mã số thuế
									</p>
								</div>
							</div>
							<v-text-field v-model="form.maSoThue" label="Mã số thuế" variant="outlined"
								density="compact" />
						</div>
						<div v-if="selectedKey === 'contact'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-card-account-phone-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin</p>
									<p class="mb-0 primary--text font-weight-bold">Tên - Địa chỉ - Số điện thoại
									</p>
								</div>
							</div>
							<v-text-field v-model="form.ten" label="Tên" variant="outlined" density="compact" />
							<v-text-field v-model="form.diaChi" label="Địa chỉ" variant="outlined" density="compact" />
							<v-text-field v-model="form.sdt" label="SĐT" variant="outlined" density="compact" />
						</div>
						<div v-if="selectedKey === 'email'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-email-edit-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin</p>
									<p class="mb-0 primary--text font-weight-bold">Email
									</p>
								</div>
							</div>
							<v-text-field v-model="form.email" label="Email" variant="outlined" density="compact" />
						</div>
						<div class="info-bottom">
							<div class="text-center mt-6">
								<v-btn @click="cancelEdit" elevation="0" text>Hủy</v-btn>
								<v-btn color="primary" class="ml-2" @click="saveData" elevation="0">Gửi yêu cầu</v-btn>
							</div>
						</div>
					</div>
				</v-card-text>
				<!-- case 3: hóa đơn đã được phát hành -> chọn thay thế hóa đơn -->
				<v-card-text v-else-if="caseType === 3">
					<div v-if="!showDialog">
						<div class="d-flex flex-column">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-text-box-check-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Hóa đơn đã được phát hành</p>
									<p class="mb-0 primary--text font-weight-bold">{{CT_HoaDon.Invoice_ResultInvoiceNo}}
									</p>
								</div>
							</div>
							<v-row>
								<v-col cols="6">
									<v-text-field label="Mã hóa đơn" v-model="CT_HoaDon.MaHoaDon" readonly
										hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Trạng thái" value="Đã phát hành" readonly variant="outlined"
										density="compact" hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Ngày" v-model="CT_HoaDon.NgayThemMoi" readonly hide-details />
								</v-col>
								<v-col cols="6">
									<v-text-field label="Thời gian" v-model="CT_HoaDon.GioThemMoi" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Mã số thuế" v-model="CT_HoaDon.Invoice_BuyerTaxCode" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Tên" v-model="CT_HoaDon.Invoice_BuyerLegalName" readonly
										hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Số điện thoại" v-model="CT_HoaDon.Invoice_BuyerPhoneNumber"
										readonly hide-details />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Địa chỉ" v-model="CT_HoaDon.Invoice_BuyerAddressLine" readonly
										hide-details />

								</v-col>
								<v-col cols="12">
									<v-text-field label="Email" v-model="CT_HoaDon.Invoice_BuyerEmail" readonly
										hide-details />
								</v-col>
							</v-row>
							<div class="mt-10">
								<p class="red--text mt-2">
									<small>
										Quý khách vui lòng nhập thông tin muốn điều chỉnh bằng cách chọn ô yêu cầu cập
										nhật thông tin dưới đây.
									</small>
								</p>
								<v-btn color="primary" block @click="openAlter('mst')" elevation="0">Yêu cầu cập nhật
									thông tin</v-btn>
							</div>
						</div>
					</div>
					<div v-else>
						<div v-if="selectedKey === 'mst'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-office-building-cog-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin thay thế</p>
									<p class="mb-0 primary--text font-weight-bold">Mã số thuế
									</p>
								</div>
							</div>
							<v-text-field v-model="form.maSoThue" label="Mã số thuế" variant="outlined"
								density="compact" />
							<!-- Sử dụng bằng trigger -->
							<!-- <div>
								<v-text-field v-model="fileName" label="Chọn ảnh thay thế" solo flat dense hide-details
									readonly append-icon="mdi-image-plus" @click:append="triggerFile" />
								<input ref="fileInput" type="file" accept="image/*" style="display: none"
									@change="handleFileChange" />
								<img v-if="preview" :src="preview"
									style="max-width:120px; margin-top:10px; border-radius:6px" />
							</div> -->
							<f-file-upload color="primary" elevation="0" block v-model="filelist" :url="uploadUrl"
								:filters="fileEX" :onclose="onUploadDone" label="Tải lên biên bản thay thế"
								class="mb-4" />
							<div style="color: #218541;" v-for="file in filelist?.Files" :key="file.FileID">
								<v-icon color="#218541">mdi-file-cog-outline</v-icon>
								{{file.FileName}}
							</div>
							<img v-if="preview" :src="preview"
								style="max-width:120px; margin-top:10px; border-radius:6px" />
							<div class="mb-6 status-main">
								<div class="text-start">
									<small class="mb-0 font-weight-bold error--text">Hoá đơn mới sẽ được phát hành thay
										thế cho hoá đơn số <b class="font-weight-bold">
											({{CT_HoaDon.Invoice_ResultInvoiceNo}} - ngày {{CT_HoaDon.NgayThemMoi}})
										</b>khi
										Zen nhận được biên bản đã ký của Quý Khách hàng.</small> <br />
									<small class="mb-0 error--text font-weight-bold">
										Khi nào quý khách hàng đính kèm gửi trả về cho Zen thì lúc đó mới ghi nhận và
										thực hiện xử lý các thông tin thay thế.
									</small>
								</div>
							</div>
						</div>
						<div v-if="selectedKey === 'contact'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-card-account-phone-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin thay thế</p>
									<p class="mb-0 primary--text font-weight-bold">Tên - Địa chỉ - Số điện thoại
									</p>
								</div>
							</div>
							<v-text-field v-model="form.ten" label="Tên" variant="outlined" density="compact" />
							<v-text-field v-model="form.diaChi" label="Địa chỉ" variant="outlined" density="compact" />
							<v-text-field v-model="form.sdt" label="SĐT" variant="outlined" density="compact" />
							<div class="d-flex mb-6 status-main">
								<div class="text-start">
									<small class="mb-0 font-weight-bold error--text">ZEN sẽ gửi thông báo sai sót về
										email
										cho khách sau khi nhận được xác nhận từ CQT.</small>
								</div>
							</div>
						</div>
						<div v-if="selectedKey === 'email'">
							<div class="d-flex mb-6 status-msg">
								<v-icon class="primary--text text-h3">mdi-email-edit-outline</v-icon>
								<div class="text-start">
									<p class="mb-0 font-weight-bold text-uppercase">Cập nhật thông tin thay thế</p>
									<p class="mb-0 primary--text font-weight-bold">Email
									</p>
								</div>
							</div>
							<v-text-field v-model="form.email" label="Email" variant="outlined" density="compact" />
						</div>
						<div class="info-bottom">
							<div class="text-center mt-6">
								<v-btn @click="cancelEdit" elevation="0" text>Hủy</v-btn>
								<v-btn color="primary" class="ml-2" @click="saveData" elevation="0">Gửi yêu cầu</v-btn>
							</div>
						</div>
					</div>
				</v-card-text>
				<!-- các thông tin cần chỉnh sửa -->
				<div v-if="showDialog && CT_HoaDon?.HoaDonID > 0 && (caseType === 2 ||caseType === 3)"
					class="bottom-sheet">
					<v-bottom-navigation :elevation="0" grow>
						<v-btn icon @click="openAlter('mst')" elevation="0">
							<v-icon color="#218541">mdi-domain</v-icon>
							<span>Mã số thuế</span>
						</v-btn>
						<v-btn icon @click="openAlter('contact')" elevation="0">
							<v-icon color="#218541">mdi-card-account-phone-outline</v-icon>
							<span>Thông tin</span>
						</v-btn>
						<v-btn icon @click="openAlter('email')" elevation="0">
							<v-icon color="#218541">mdi-email-outline</v-icon>
							<span>Email</span>
						</v-btn>
					</v-bottom-navigation>
				</div>
			</template>
			<!-- Không tìm thấy -->
			<template v-else>
				<div style="height: 100%" class="d-flex flex-column justify-center align-center py-12">
					<v-icon size="48" color="#adadad">mdi-inbox</v-icon>
					<p class="mt-2 text-center">
						<b>Không tìm thấy thông tin hoá đơn</b><br />
						<small><i>Vui lòng kiểm tra lại</i></small>
					</p>
				</div>
			</template>
		</v-card>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				CT_HoaDon: null,
				isShowFormEdit: false,
				showUpload: false,
				showDialog: false,
				selectedKey: null,
				allFields: [
					{ key: 'maSoThue', label: 'Mã số thuế' },
					{ key: 'ten', label: 'Tên đơn vị' },
					{ key: 'diaChi', label: 'Địa chỉ' },
					{ key: 'sdt', label: 'Số điện thoại' },
					{ key: 'email', label: 'Email' }
				],
				form: {
					maSoThue: '',
					ten: '',
					diaChi: '',
					sdt: '',
					email: ''
				},
				fileEX: {
					max_file_size: '500mb',
					mime_types: [
						{
							title: 'All files',
							extensions: 'jpg,doc,png'
						}
					]
				},
				filelist: null,
				file: null,
				fileName: '',
				preview: '',
				uploadResponse: null
			}
		},
		computed: {
			caseType() {
				if (!this.CT_HoaDon) return 0
				if (!this.CT_HoaDon.Invoice_BuyerEmail) return 1
				if (this.CT_HoaDon.Invoice_BuyerEmail && !this.CT_HoaDon.Invoice_ResultInvoiceNo) return 2
				return 3
			},
			uploadUrl() {
				return `https://file.zentea.vn/eorder/upload/FileData`;
			},
			mobileClass() {
				const height = window.innerHeight
	
				if (height > 640) {
					return 'min'
				} else {
					return 'max'
				}
			}
		},
		mounted() {
			this.getChiTietHoaDon()
		},
		methods: {
			getChiTietHoaDon() {
				ajaxCALL('/eordertest/auth/HoaDon_Select_HoaDonDienTu', { HoaDonID: vueData.HoaDonID }, res => {
					this.CT_HoaDon = res.data[0] ?? null
					if (this.CT_HoaDon) this.loadFormData()
				})
			},
			loadFormData() {
				this.form = {
					maSoThue: this.CT_HoaDon.maSoThue || '',
					ten: this.CT_HoaDon.ten || '',
					diaChi: this.CT_HoaDon.diaChi || '',
					sdt: this.CT_HoaDon.sdt || '',
					email: this.CT_HoaDon.email || ''
				}
			},
			openEdit() {
				this.isShowFormEdit = true
				this.form = { maSoThue: '', ten: '', diaChi: '', sdt: '', email: '' }
			},
			openAlter(key) {
				this.selectedKey = key
				this.showDialog = true
			},
			cancelEdit() {
				this.isShowFormEdit = false
				this.showDialog = false
				this.selectedKey = null
				if (this.CT_HoaDon) this.loadFormData()
			},
			saveData() {
				// Xử lý FileID_List cho case 3 (nếu có filelist)
				let fileIdList = ''
				if (this.filelist?.Files && this.filelist.Files.length > 0) {
					fileIdList = this.filelist.Files.map(f => f.FileID).join(',')
				}
				const payload = {
					HoaDonID: this.CT_HoaDon?.HoaDonID,
					Invoice_BuyerTaxCode: this.form.maSoThue || this.CT_HoaDon.Invoice_BuyerTaxCode || '',
					Invoice_BuyerLegalName: this.form.ten || this.CT_HoaDon.Invoice_BuyerLegalName || '',
					Invoice_BuyerPhoneNumber: this.form.sdt || this.CT_HoaDon.Invoice_BuyerPhoneNumber || '',
					Invoice_BuyerAddressLine: this.form.diaChi || this.CT_HoaDon.Invoice_BuyerAddressLine || '',
					Invoice_BuyerEmail: this.form.email || this.CT_HoaDon.Invoice_BuyerEmail || '',
					FileID_List: fileIdList
				}
				ajaxCALL('/eordertest/auth/HoaDon_Update_HoaDonDienTu', payload, (res) => {
					this.cancelEdit()
					this.getChiTietHoaDon()
					showMessage({ title: 'Kính đề nghị Quý khách kiểm tra kỹ thông tin trước khi xác nhận để tránh phát sinh việc điều chỉnh/thay thế hóa đơn sau khi biên bản phát hành.' });
				});
			},
	
			onUploadDone() {
				this.$emit('notify', {
					type: 'success',
					shoMessage: 'Upload hình ảnh thành công!'
				});
			},
			onGoBack() {
				const url = `https://eorder.zenfoodcourt.vn/hd?hdid=` + this.CT_HoaDon.HoaDonID;
				window.location.href = url;
			},
			// triggerFile() {
			// 	this.$refs.fileInput.click()
			// },
			// handleFileChange(e) {
			// 	const file = e.target.files[0]
			// 	if (!file) return
			// 	this.file = file
			// 	this.fileName = file.name
			// 	this.preview = URL.createObjectURL(file)
			// 	this.uploadFile(file)
			// },
			// async uploadFile(file) {
			// 	const formData = new FormData()
			// 	formData.append('file', file)
			// 	try {
			// 		const res = await fetch(this.uploadUrl, {
			// 			method: 'POST',
			// 			body: formData,
			// 			credentials: 'same-origin',
			// 		})
			// 		if (!res.ok) {
			// 			console.error('Upload failed with status:', res.status)
			// 			if (res.status === 401) {
			// 				alert('Phiên đăng nhập hết hạn hoặc không có quyền upload. Vui lòng đăng nhập lại.')
			// 			} else {
			// 				alert('Upload thất bại. Lỗi: ' + res.status)
			// 			}
			// 			throw new Error(`HTTP error! status: ${res.status}`)
			// 		}
	
			// 		const data = await res.json()
			// 		this.uploadResponse = data
			// 		console.log('Upload thành công:', data)
			// 		this.onUploadDone(data)
			// 	} catch (err) {
			// 		console.error('Upload lỗi:', err)
			// 	}
			// },
			// onUploadDone(res) {
			// 	this.$emit('notify', {
			// 		type: 'success',
			// 		message: 'Upload thành công!'
			// 	})
			// }
		}
	}
</script>