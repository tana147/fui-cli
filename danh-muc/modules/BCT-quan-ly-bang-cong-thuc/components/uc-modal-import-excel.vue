<template>
	<v-dialog v-model="modelValue" max-width="800" persistent>
		<v-card>
			<v-card-title class="bg-primary text-white d-flex align-center">
				<v-icon class="mr-2">mdi-file-excel</v-icon>
				Import Công Thức từ Excel
				<v-spacer />
				<v-btn icon="mdi-close" variant="text" @click="onClose" size="small"></v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<!-- Màn hình 1: Chọn file + Preview ngay bên dưới -->
				<div v-if="step === 1">
					<div class="text-h6 mb-3">
						Tải file excel mẫu
						<span>
							<v-btn size="small" color="primary" variant="flat" @click="downloadTemplate">
								Tải về
								<v-icon :size="20" class="ml-2">mdi-tray-arrow-down</v-icon>
							</v-btn>
						</span>
					</div>

					<v-file-input v-model="selectedFile" accept=".xlsx,.xls" label="Chọn file Excel"
						prepend-icon="mdi-file-excel" show-size clearable @update:modelValue="handleFileSelect"
						@click:clear="clearFile" />

					<!-- Loading preview -->
					<div v-if="selectedFile && isPreviewLoading">
						<v-alert type="info" variant="flat">
							<div class="d-flex align-center">
								<v-progress-circular indeterminate size="20" class="mr-2" />
								Đang đọc file và tạo preview...
							</div>
						</v-alert>
					</div>

					<!-- Preview ngay trong step 1 -->
					<div v-if="selectedFile && isPreviewReady">
						<div class="text-h6 mb-3">Kiểm tra dữ liệu</div>

						<v-card variant="outlined" class="mb-4">
							<v-card-title class="bg-blue-lighten-5">Thông tin sản phẩm chính</v-card-title>
							<v-card-text>
								<v-row dense>
									<v-col cols="12">
										<div class="text-caption text-grey">Tên sản phẩm</div>
										<div class="font-weight-bold">
											{{
											previewData.maSanPham && previewData.tenSanPham
											? previewData.maSanPham + ' - ' + previewData.tenSanPham
											: (previewData.tenSanPham || '-')
											}}
										</div>
									</v-col>

									<v-col cols="4">
										<div class="text-caption text-grey">Nơi sản xuất</div>
										<div class="font-weight-bold">{{ previewData.noiSanXuat || '-' }}</div>
									</v-col>
									<v-col cols="4">
										<div class="text-caption text-grey">Nơi sử dụng</div>
										<div class="font-weight-bold">{{ previewData.noiSuDung || '-' }}</div>
									</v-col>
									<v-col cols="4">
										<div class="text-caption text-grey">Khu vực chế biến</div>
										<div class="font-weight-bold">{{ previewData.khuVuc || '-' }}</div>
									</v-col>

									<v-col cols="4">
										<div class="text-caption text-grey">Đơn vị ĐL</div>
										<div class="font-weight-bold text-primary">{{ previewData.donViDL || '-' }}
										</div>
									</v-col>

									<v-col cols="4">
										<div class="text-caption text-grey">Sau khi nấu</div>
										<div class="font-weight-bold">{{ previewData.sauKhiNau || '-' }}</div>
									</v-col>
								</v-row>
							</v-card-text>
						</v-card>

						<v-card variant="outlined">
							<v-card-title class="bg-green-lighten-5 d-flex align-center">
								Danh sách nguyên liệu
								<v-spacer />
								<v-chip size="small" color="primary">
									{{ previewData.DsNguyenLieu?.length || 0 }} dòng
								</v-chip>
							</v-card-title>
							<v-card-text class="pa-0">
								<v-table density="compact" fixed-header height="300">
									<thead>
										<tr>
											<th>#</th>
											<th>Mã NL</th>
											<th>Tên nguyên liệu</th>
											<th>Đơn vị</th>
											<th class="text-right">Số lượng</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="(item, i) in previewData.DsNguyenLieu" :key="i">
											<td>{{ i + 1 }}</td>
											<td>{{ item.maNL }}</td>
											<td>{{ item.tenNL }}</td>
											<td>{{ item.donVi }}</td>
											<td class="text-right">{{ item.soLuong }}</td>
										</tr>
									</tbody>
								</v-table>
							</v-card-text>
						</v-card>

						<v-alert v-if="warnings.length > 0" type="warning" variant="flat" class="mt-4">
							<div class="font-weight-bold mb-2">Cảnh báo:</div>
							<ul>
								<li v-for="(warning, i) in warnings" :key="i">{{ warning }}</li>
							</ul>
						</v-alert>
					</div>
				</div>

				<!-- Step 3: Processing -->
				<div v-if="step === 3">
					<div class="text-center py-8">
						<v-progress-circular :size="80" :width="8" color="primary" indeterminate />
						<div class="text-h6 mt-4">{{ progressMessage }}</div>
						<div class="text-caption text-grey mt-2">{{ progressDetail }}</div>
						<v-progress-linear v-if="progressPercent > 0" :model-value="progressPercent" color="primary"
							height="8" class="mt-4" />
					</div>
				</div>

				<!-- Step 4: Kết quả -->
				<div v-if="step === 4">
					<div class="text-center py-8">
						<v-icon :size="80" :color="importSuccess ? 'success' : 'error'">
							{{ importSuccess ? 'mdi-check-circle' : 'mdi-alert-circle' }}
						</v-icon>
						<div class="text-h5 mt-4">
							{{ importSuccess ? 'Import thành công!' : 'Import thất bại!' }}
						</div>
						<div class="text-body-1 text-grey mt-2">{{ resultMessage }}</div>

						<v-card variant="outlined" class="mt-4 text-left">
							<v-card-text>
								<v-row dense>
									<v-col cols="6">
										<div class="text-caption text-grey">Tổng số dòng</div>
										<div class="text-h6 text-primary">{{ importResult.total }}</div>
									</v-col>
									<v-col cols="6">
										<div class="text-caption text-grey">Import thành công</div>
										<div class="text-h6 text-success">{{ importResult.success }}</div>
									</v-col>
									<v-col cols="6">
										<div class="text-caption text-grey">Bỏ qua</div>
										<div class="text-h6 text-warning">{{ importResult.skipped }}</div>
									</v-col>
									<v-col cols="6">
										<div class="text-caption text-grey">Lỗi</div>
										<div class="text-h6 text-error">{{ importResult.errors }}</div>
									</v-col>
								</v-row>
							</v-card-text>
						</v-card>

						<v-expansion-panels v-if="errorList.length > 0" class="mt-4">
							<v-expansion-panel>
								<v-expansion-panel-title>
									<v-icon class="mr-2" color="error">mdi-alert</v-icon>
									Chi tiết lỗi ({{ errorList.length }})
								</v-expansion-panel-title>
								<v-expansion-panel-text>
									<v-list density="compact">
										<v-list-item v-for="(err, i) in errorList" :key="i">
											<v-list-item-title>
												<v-icon size="small" color="error">mdi-circle-small</v-icon>
												{{ err }}
											</v-list-item-title>
										</v-list-item>
									</v-list>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
					</div>
				</div>
			</v-card-text>

			<v-divider />

			<v-card-actions class="pa-4">
				<!-- Step 1 -->
				<template v-if="step === 1">
					<v-btn variant="flat" @click="onClose">Hủy</v-btn>
					<v-spacer />
					<v-btn variant="flat" color="primary" @click="confirmImport"
						:disabled="!selectedFile || !isPreviewReady || hasMultiMaSP || isPreviewLoading">
						Xác nhận Import
					</v-btn>
				</template>

				<!-- Step 3 -->
				<template v-if="step === 3">
					<v-spacer />
					<v-btn variant="text" disabled>Đang xử lý...</v-btn>
				</template>

				<!-- Step 4 -->
				<template v-if="step === 4">
					<v-spacer />
					<v-btn v-if="!importSuccess" variant="flat" @click="step = 1">Thử lại</v-btn>
					<v-btn color="primary" @click="onClose">
						{{ importSuccess ? 'Hoàn tất' : 'Đóng' }}
					</v-btn>
				</template>
			</v-card-actions>
		</v-card>

		<!-- Hidden helper component để tái sử dụng logic từ uc-row-nguyen-lieu -->
		<div style="display: none;">
			<uc-row-nguyen-lieu v-for="helper in materialHelpers" :key="helper.id" :ref="'helper-' + helper.id"
				:rowData="helper.rowData" :isEditing="true" @update-row="onHelperUpdate(helper.id, $event)" />
		</div>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			modelValue: Boolean,
			dsDiaDiemSanXuat: Array,
			dsDiaDiemSuDung: Array,
			dsKhuVucCheBien: Array,
			dsDonViTinh: Array,
		},
		emits: ['update:modelValue', 'onImportSuccess'],
	
		data() {
			return {
				step: 1,
				selectedFile: null,
				isDragging: false,
	
				hangHoaObj: {},
				hangHoaMaNoiBo: null,
	
				// Preview state
				isPreviewLoading: false,
				isPreviewReady: false,
	
				previewData: {
					maSanPham: '',
					tenSanPham: '',
					noiSanXuat: '',
					noiSuDung: '',
					khuVuc: '',
					donViDL: '',
					sauKhiNau: '',
					DsNguyenLieu: [],
				},
	
				warnings: [],
				progressMessage: '',
				progressDetail: '',
				progressPercent: 0,
	
				importSuccess: false,
				resultMessage: '',
				importResult: { total: 0, success: 0, skipped: 0, errors: 0 },
				errorList: [],
	
				materialHelpers: [],
				helperResults: {},
				nextHelperId: 1,
	
				resolved: {
					hangHoa: null,
					productsByKey: {},
					materialsByKey: {},
				},
	
				hasMultiMaSP: false,
				multiMaSPList: [],
			}
		},
	
		watch: {
			modelValue(val) {
				if (val) this.resetModal()
			},
		},
	
		methods: {
			handleFileSelect(file) {
				this.selectFile(file)
			},
	
			handleDrop(e) {
				this.isDragging = false
				this.selectFile(e.dataTransfer.files[0])
			},
	
			selectFile(file) {
				if (!file) return
	
				const validTypes = [
					'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
					'application/vnd.ms-excel',
				]
				if (!validTypes.includes(file.type)) {
					showToast.error('Vui lòng chọn file Excel (.xlsx hoặc .xls)')
					return
				}
	
				if (file.size > 10 * 1024 * 1024) {
					showToast.error('File quá lớn! Tối đa 10MB')
					return
				}
	
				this.selectedFile = file
				this.processFile()
			},
	
			clearFile() {
				this.selectedFile = null
				this.isPreviewReady = false
				this.isPreviewLoading = false
				this.warnings = []
				this.previewData = {
					maSanPham: '',
					tenSanPham: '',
					noiSanXuat: '',
					noiSuDung: '',
					khuVuc: '',
					donViDL: '',
					sauKhiNau: '',
					DsNguyenLieu: [],
				}
				this.hasMultiMaSP = false
				this.multiMaSPList = []
				if (this.$refs.fileInput) this.$refs.fileInput.value = ''
			},
	
			formatFileSize(bytes) {
				if (bytes === 0) return '0 Bytes'
				const k = 1024,
					sizes = ['Bytes', 'KB', 'MB']
				const i = Math.floor(Math.log(bytes) / Math.log(k))
				return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
			},
	
			async processFile() {
				try {
					this.warnings = []
					this.errorList = []
					this.progressDetail = ''
					this.progressPercent = 0
	
					this.isPreviewLoading = true
					this.isPreviewReady = false
					this.hasMultiMaSP = false
					this.multiMaSPList = []
	
					const data = await this.readExcelFile(this.selectedFile)
					if (!data || data.length < 2) throw new Error('File Excel không có dữ liệu!')
	
					const headerRow = data[0]
					const colMap = this.validateAndMapColumns(headerRow)
					if (!colMap) throw new Error('File Excel không đúng định dạng!')
	
					this.extractPreviewData(data, colMap)
					this.isPreviewReady = true
				} catch (error) {
					console.error('Process file error:', error)
					showToast.error(error.message)
					this.isPreviewReady = false
				} finally {
					this.isPreviewLoading = false
				}
			},
	
			readExcelFile(file) {
				return new Promise((resolve, reject) => {
					const reader = new FileReader()
					reader.onload = (e) => {
						try {
							const data = new Uint8Array(e.target.result)
							const workbook = XLSX.read(data, { type: 'array' })
							const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
							const jsonData = XLSX.utils.sheet_to_json(firstSheet, { header: 1, defval: '' })
							resolve(jsonData)
						} catch (error) {
							reject(new Error('Không thể đọc file Excel'))
						}
					}
					reader.onerror = () => reject(new Error('Lỗi khi đọc file'))
					reader.readAsArrayBuffer(file)
				})
			},
	
			validateAndMapColumns(headerRow) {
				const requiredColumns = [
					'Tên Sản Phẩm',
					'Nơi sử dụng',
					'Khu vực chế biến',
					'Nơi sản xuất',
					'Mã NL',
					'Tên Nguyên Liệu',
					'Đơn vị sử dụng',
					'Số Lượng SD',
				]
	
				const optionalColumns = ['Đơn vị ĐL', 'Mã Sản Phẩm', 'Mã SP', 'Mã sản phẩm', 'Sau khi nấu']
	
				const colMap = {}
				const missingColumns = []
	
				requiredColumns.forEach((col) => {
					const normalizedCol = this.normalize(col)
					const index = headerRow.findIndex((h) => this.normalize(h) === normalizedCol)
					if (index === -1) missingColumns.push(col)
					else colMap[col] = index
				})
	
				optionalColumns.forEach((col) => {
					const normalizedCol = this.normalize(col)
					const index = headerRow.findIndex((h) => this.normalize(h) === normalizedCol)
					if (index !== -1) colMap[col] = index
				})
	
				if (missingColumns.length > 0) {
					showToast.error(`Thiếu các cột: ${missingColumns.join(', ')}`)
					return null
				}
	
				return colMap
			},
	
			extractPreviewData(data, colMap) {
				const firstRow = data[1] || []
	
				this.previewData = {
					maSanPham: this.getOptionalColumnValue(firstRow, colMap, ['Mã Sản Phẩm', 'Mã SP', 'Mã sản phẩm']),
					tenSanPham: firstRow[colMap['Tên Sản Phẩm']] ?? '',
					noiSanXuat: firstRow[colMap['Nơi sản xuất']] ?? '',
					noiSuDung: firstRow[colMap['Nơi sử dụng']] ?? '',
					khuVuc: firstRow[colMap['Khu vực chế biến']] ?? '',
					donViDL: this.getOptionalColumnValue(firstRow, colMap, ['Đơn vị ĐL']),
					sauKhiNau: this.getOptionalColumnValue(firstRow, colMap, ['Sau khi nấu']),
					DsNguyenLieu: [],
				}
	
				this.hasMultiMaSP = false
				this.multiMaSPList = []
	
				const maSPSet = new Set()
	
				for (let i = 1; i < data.length; i++) {
					const row = data[i]
	
					const maSP = this.getOptionalColumnValue(row, colMap, ['Mã Sản Phẩm', 'Mã SP', 'Mã sản phẩm'])
					if (maSP) maSPSet.add(maSP)
	
					const maNL = row[colMap['Mã NL']]
					const tenNL = row[colMap['Tên Nguyên Liệu']]
					if (!maNL && !tenNL) continue
	
					this.previewData.DsNguyenLieu.push({
						maNL: String(maNL || '').trim(),
						tenNL: String(tenNL || '').trim(),
						donVi: String(row[colMap['Đơn vị sử dụng']] || '').trim(),
						soLuong: row[colMap['Số Lượng SD']] || '',
					})
				}
	
				this.warnings = []
				if (!this.previewData.tenSanPham) this.warnings.push('Chưa có tên sản phẩm')
				if (!this.previewData.donViDL) this.warnings.push('Chưa có đơn vị định lượng')
				if (this.previewData.DsNguyenLieu.length === 0) this.warnings.push('Không có nguyên liệu nào')
	
				if (maSPSet.size > 1) {
					this.hasMultiMaSP = true
					this.multiMaSPList = [...maSPSet]
					this.warnings.push(`File có ${maSPSet.size} mã sản phẩm khác nhau: ${this.multiMaSPList.join(', ')}`)
				}
			},
	
			buildLookupPayloadFromExcel(data, colMap) {
				const firstRow = data[1] || []
				const maSP = this.getOptionalColumnValue(firstRow, colMap, ['Mã Sản Phẩm', 'Mã SP', 'Mã sản phẩm'])
				const tenSP = String(firstRow[colMap['Tên Sản Phẩm']] || '').trim()
	
				const list = []
				this.hangHoaMaNoiBo = maSP
	
				list.push({
					MaNoiBo: maSP,
					TenHangHoa: tenSP,
				})
	
				for (let i = 1; i < data.length; i++) {
					const row = data[i]
					const MaNoiBo = String(row[colMap['Mã NL']] || '').trim()
					const TenHangHoa = String(row[colMap['Tên Nguyên Liệu']] || '').trim()
	
					if (!MaNoiBo && !TenHangHoa) continue
					list.push({ MaNoiBo, TenHangHoa })
				}
	
				return list
			},
	
			resolveFromDB(JsonNguyenLieu) {
				return new Promise((resolve, reject) => {
					apiCall(
						'/work/MT_CongThuc_Import',
						{ JsonNguyenLieu: JsonNguyenLieu },
						(res) => {
							const data = res.data
	
							const hangHoaIndex = data.findIndex((d) => d.MaNoiBo === this.hangHoaMaNoiBo)
	
							let DsNguyenLieu = []
							let hangHoa = null
	
							if (hangHoaIndex !== -1) {
								hangHoa = data[hangHoaIndex]
								DsNguyenLieu = [...data.slice(0, hangHoaIndex), ...data.slice(hangHoaIndex + 1)]
							}
	
							resolve({ hangHoa, DsNguyenLieu })
						},
						(error) => {
							console.error('Resolve DB error:', error)
							reject(new Error('Không thể lấy thông tin từ DB'))
						}
					)
				})
			},
	
			makeKey(ma, ten) {
				const value = ma || ten || ''
				return String(value).trim().toLowerCase().replace(/\s+/g, '')
			},
	
			indexResolvedData(resolved) {
				this.resolved.hangHoa = resolved.hangHoa || null
				this.resolved.productsByKey = {}
				this.resolved.materialsByKey = {}
	
				if (this.resolved.hangHoa) {
					const p = this.resolved.hangHoa
					const maKey = this.makeKey(p.MaNoiBo, '')
					const tenKey = this.makeKey('', p.TenHangHoa || p.TenTinhChat)
	
					if (maKey) this.resolved.productsByKey[maKey] = p
					if (tenKey) this.resolved.productsByKey[tenKey] = p
				}
	
				for (const m of resolved.DsNguyenLieu || []) {
					const maKey = this.makeKey(m.MaNoiBo, '')
					const tenKey = this.makeKey('', m.TenHangHoa || m.TenTinhChat)
	
					if (maKey) this.resolved.materialsByKey[maKey] = m
					if (tenKey) this.resolved.materialsByKey[tenKey] = m
				}
			},
	
			async confirmImport() {
				try {
					if (this.hasMultiMaSP) {
						showToast.error('File có nhiều mã sản phẩm khác nhau, vui lòng tách file trước khi import!')
						return
					}
	
					this.step = 3
					this.progressMessage = 'Đang xử lý dữ liệu...'
					this.progressPercent = 10
					this.progressDetail = ''
	
					const data = await this.readExcelFile(this.selectedFile)
					const headerRow = data[0]
					const colMap = this.validateAndMapColumns(headerRow)
					if (!colMap) throw new Error('File Excel không đúng định dạng!')
	
					this.progressPercent = 20
	
					const JsonNguyenLieu = this.buildLookupPayloadFromExcel(data, colMap)
					const resolved = await this.resolveFromDB(JSON.stringify(JsonNguyenLieu))
					this.indexResolvedData(resolved)
	
					this.progressPercent = 30
	
					const result = await this.importData(data, colMap)
	
					this.progressPercent = 100
					this.importSuccess = result.success > 0
					this.importResult = result
					this.errorList = result.errorList || []
	
					if (this.importSuccess) {
						this.resultMessage = `Đã import thành công ${result.success}/${result.total} nguyên liệu`
					} else {
						this.resultMessage = 'Không thể import dữ liệu. Vui lòng kiểm tra lại file!'
					}
	
					this.step = 4
	
					if (this.importSuccess) {
						this.$emit('onImportSuccess', result.data)
					}
				} catch (error) {
					console.error('Import error:', error)
					this.importSuccess = false
					this.resultMessage = error.message || 'Có lỗi xảy ra trong quá trình import'
					this.step = 4
				}
			},
	
			async importData(data, colMap) {
				const result = {
					total: 0,
					success: 0,
					skipped: 0,
					errors: 0,
					errorList: [],
					data: {
						hangHoa: null,
						diaDiemSanXuat: null,
						diaDiemSuDung: null,
						khuVucCheBien: null,
						donViDinhLuong: null,
						sauKhiNau: null,
						DsNguyenLieu: [],
					},
				}
	
				try {
					const firstRow = data[1]
					const productInfo = await this.loadProductInfo(firstRow, colMap)
	
					if (!productInfo) throw new Error('Không tìm thấy sản phẩm chính')
					result.data.hangHoa = productInfo.hangHoa
					result.data.diaDiemSanXuat = productInfo.diaDiemSanXuat
					result.data.diaDiemSuDung = productInfo.diaDiemSuDung
					result.data.khuVucCheBien = productInfo.khuVucCheBien
					result.data.donViDinhLuong = productInfo.donViDinhLuong
					result.data.sauKhiNau = this.getOptionalColumnValue(firstRow, colMap, ['Sau khi nấu'])
	
					this.progressPercent = 50
	
					const DsNguyenLieu = []
					const totalRows = data.length - 1
	
					for (let i = 1; i < data.length; i++) {
						const row = data[i]
						result.total++
	
						this.progressPercent = 50 + Math.floor((i / totalRows) * 45)
						this.progressDetail = `Đang xử lý ${i}/${totalRows} dòng...`
	
						try {
							const material = await this.parseMaterialRowWithHelper(row, colMap, i)
							if (material) {
								DsNguyenLieu.push(material)
								result.success++
							} else {
								result.skipped++
							}
						} catch (error) {
							result.errors++
							result.errorList.push(`Dòng ${i + 1}: ${error.message}`)
						}
	
						if (i % 20 === 0) {
							await new Promise((resolve) => setTimeout(resolve, 10))
						}
					}
	
					result.data.DsNguyenLieu = DsNguyenLieu
				} catch (error) {
					result.errorList.push(error.message)
				}
	
				return result
			},
	
			async loadProductInfo(row, colMap) {
				const tenSanPham = String(row[colMap['Tên Sản Phẩm']] || '').trim()
				const noiSuDung = row[colMap['Nơi sử dụng']]
				const khuVuc = row[colMap['Khu vực chế biến']]
				const noiSanXuat = row[colMap['Nơi sản xuất']]
	
				const maSP = this.getOptionalColumnValue(row, colMap, ['Mã Sản Phẩm', 'Mã SP', 'Mã sản phẩm'])
				const donViDLFromExcel = this.getOptionalColumnValue(row, colMap, ['Đơn vị ĐL'])
	
				let hangHoa = null
				if (maSP) {
					const maKey = this.makeKey(maSP, '')
					hangHoa = this.resolved.productsByKey[maKey]
				}
	
				if (!hangHoa && tenSanPham) {
					const tenKey = this.makeKey('', tenSanPham)
					hangHoa = this.resolved.productsByKey[tenKey]
				}
	
				if (!hangHoa) {
					hangHoa = this.resolved.hangHoa
				}
	
				if (!hangHoa) {
					throw new Error(`Không tìm thấy sản phẩm: ${maSP || tenSanPham}`)
				}
	
				const diaDiemSuDung = this.findDiaDiem(noiSuDung, this.dsDiaDiemSuDung)
				const diaDiemSanXuat = this.findDiaDiem(noiSanXuat, this.dsDiaDiemSanXuat)
				const khuVucCheBien = this.findKhuVuc(khuVuc, diaDiemSanXuat, this.dsKhuVucCheBien)
	
				const loai = String(hangHoa.LoaiNguyenLieu || '').trim().toUpperCase()
				let donViDLKeyword = donViDLFromExcel
	
				if (loai === 'TP') donViDLKeyword = 'Phần'
				else if (loai === 'BTP') donViDLKeyword = 'Gram'
	
				const donViDinhLuong = this.finDonViDL(donViDLKeyword, this.dsDonViTinh)
	
				return {
					hangHoa,
					diaDiemSuDung,
					diaDiemSanXuat,
					khuVucCheBien,
					donViDinhLuong,
				}
			},
	
			finDonViDL(keyword, dsList) {
				if (!keyword || !dsList) return null
				const key = this.normalize(keyword)
				return dsList.find((d) => this.normalize(d.TenDonVi || '').includes(key))
			},
	
			findDiaDiem(keyword, dsList) {
				if (!keyword || !dsList) return null
				const key = this.normalize(keyword)
				return dsList.find((d) => this.normalize(d.TenDiaDiem || '').includes(key))
			},
	
			findKhuVuc(keyword, diaDiem, dsList) {
				if (!keyword || !dsList) return null
				const filtered = diaDiem ? dsList.filter((k) => k.DiaDiem_Id === diaDiem.DiaDiem_Id) : dsList
				const key = this.normalize(keyword)
				return filtered.find((k) => this.normalize(k.TenKhuVuc || '').includes(key))
			},
	
			getOptionalColumnValue(row, colMap, keys) {
				for (const key of keys) {
					if (colMap?.[key] != null) {
						const value = row[colMap[key]]
						if (value != null) return String(value).trim()
					}
				}
				return ''
			},
	
			async parseMaterialRowWithHelper(row, colMap, index) {
				const maNL = String(row[colMap['Mã NL']] || '').trim()
				const tenNL = String(row[colMap['Tên Nguyên Liệu']] || '').trim()
				const donViFromExcel = String(row[colMap['Đơn vị sử dụng']] || '').trim()
				const soLuong = parseFloat(String(row[colMap['Số Lượng SD']] || 0).replace(',', '.'))
	
				if (!maNL && !tenNL) return null
	
				let nguyenLieu = null
				if (maNL) {
					const maKey = this.makeKey(maNL, '')
					nguyenLieu = this.resolved.materialsByKey[maKey]
				}
	
				if (!nguyenLieu && tenNL) {
					const tenKey = this.makeKey('', tenNL)
					nguyenLieu = this.resolved.materialsByKey[tenKey]
				}
	
				if (!nguyenLieu) {
					throw new Error(`Không tìm thấy nguyên liệu: ${maNL || tenNL}`)
				}
	
				const hangHoaId = nguyenLieu.HangHoa_Id
	
				const helperId = this.nextHelperId++
				const helperData = {
					id: helperId,
					rowData: {
						STT: index,
						HangHoa_Id: hangHoaId,
						MaNoiBo: nguyenLieu.MaNoiBo || '',
						TenHangHoa: nguyenLieu.TenHangHoa || nguyenLieu.TenTinhChat || '',
						DinhLuongMotPhan: soLuong,
						DonVi: null,
						TenDonVi: donViFromExcel,
						GiaNguyenVatLieu: 0,
						ChiPhiSuDung: 0,
						GhiChu: '',
						Is_TinhDinhLuong: true,
						DonGia_ApDung: nguyenLieu.DonGia_ApDung || 0,
						DonGia_TrungBinh: nguyenLieu.DonGia_TrungBinh || 0,
						DonGia_MoiNhat: nguyenLieu.DonGia_MoiNhat || 0,
						LoaiNguyenLieu: nguyenLieu.LoaiNguyenLieu || '',
						TenLoaiNguyenLieu: nguyenLieu.TenLoaiNguyenLieu || '',
					},
				}
	
				this.materialHelpers.push(helperData)
				await this.$nextTick()
	
				const helperRef = this.$refs['helper-' + helperId]
				if (helperRef && helperRef[0]) {
					await new Promise((resolve) => {
						setTimeout(() => {
							helperRef[0].onSelectChange(nguyenLieu.HangHoa_Id)
							resolve()
						}, 50)
					})
	
					await this.waitForHelperResult(helperId, 5000)
	
					const result = this.helperResults[helperId]
					if (!result) throw new Error('Không thể load thông tin nguyên liệu')
	
					result.HangHoa_Id = hangHoaId
					result.STT = index
					result.DinhLuongMotPhan = soLuong
					result.GhiChu = ''
					result.Is_TinhDinhLuong = true
					result.NguyenVatLieu = nguyenLieu.TenHangHoa || nguyenLieu.TenTinhChat
					result.MaNoiBo = nguyenLieu.MaNoiBo || ''
					result.TenHangHoa = nguyenLieu.TenHangHoa || nguyenLieu.TenTinhChat
	
					this.matchDonViFromExcel(result, donViFromExcel)
					result.Is_TinhDinhLuong = this.isGramUnit(result.TenDonVi)
	
					this.materialHelpers = this.materialHelpers.filter((h) => h.id !== helperId)
					delete this.helperResults[helperId]
	
					return result
				}
	
				throw new Error('Không thể tạo helper component')
			},
	
			onHelperUpdate(helperId, updatedData) {
				this.helperResults[helperId] = updatedData
			},
	
			waitForHelperResult(helperId, timeout = 5000) {
				return new Promise((resolve, reject) => {
					const startTime = Date.now()
					const checkInterval = setInterval(() => {
						if (this.helperResults[helperId]) {
							clearInterval(checkInterval)
							resolve()
						} else if (Date.now() - startTime > timeout) {
							clearInterval(checkInterval)
							reject(new Error('Timeout chờ helper component'))
						}
					}, 100)
				})
			},
	
			matchDonViFromExcel(material, donViFromExcel) {
				const donViKey = String(donViFromExcel || '').toLowerCase()
	
				if (material.DonViCheck && material.DonViQuyDoiOptions) {
					let matched = material.DonViQuyDoiOptions.find(
						(x) => String(x.QuyDoi_DonViTinh_Ten || '').toLowerCase() === donViKey
					)
	
					if (!matched) matched = material.DonViQuyDoiOptions[0]
	
					if (matched) {
						material.DonVi = matched.QuyDoi_DonViTinh_Id
						material.TenDonVi = matched.QuyDoi_DonViTinh_Ten
						this.recalculatePrice(material)
					}
				} else {
					if (material.DonViGocOptions && material.DonViGocOptions.length > 0) {
						let gocMatched = material.DonViGocOptions.find((x) => String(x.TenDonVi || '').toLowerCase() === donViKey)
	
						if (!gocMatched) gocMatched = material.DonViGocOptions[0]
	
						if (gocMatched) {
							material.DonVi = gocMatched.DonViTinh_Id
							material.TenDonVi = gocMatched.TenDonVi
						}
					}
				}
			},
	
			recalculatePrice(material) {
				const donGia = Number(material.DonGia_ApDung || 0)
	
				if (material.DonViCheck && material.QuyDoiInfo) {
					const qd = material.QuyDoiInfo.find((x) => x.QuyDoi_DonViTinh_Id === material.DonVi)
					const heSo = Number(qd?.QuyDoi_HeSo || 0)
					material.GiaNguyenVatLieu = heSo > 0 ? donGia / heSo : 0
				} else {
					material.GiaNguyenVatLieu = donGia
				}
	
				material.ChiPhiSuDung = material.GiaNguyenVatLieu * material.DinhLuongMotPhan
			},
	
			resetModal() {
				this.step = 1
				this.selectedFile = null
				this.isDragging = false
	
				this.isPreviewLoading = false
				this.isPreviewReady = false
	
				this.previewData = {
					maSanPham: '',
					tenSanPham: '',
					noiSanXuat: '',
					noiSuDung: '',
					khuVuc: '',
					donViDL: '',
					sauKhiNau: '',
					DsNguyenLieu: [],
				}
	
				this.warnings = []
				this.progressMessage = ''
				this.progressDetail = ''
				this.progressPercent = 0
				this.importSuccess = false
				this.resultMessage = ''
				this.importResult = { total: 0, success: 0, skipped: 0, errors: 0 }
				this.errorList = []
	
				this.materialHelpers = []
				this.helperResults = {}
				this.nextHelperId = 1
	
				this.hasMultiMaSP = false
				this.multiMaSPList = []
	
				this.resolved = { hangHoa: null, productsByKey: {}, materialsByKey: {} }
	
				if (this.$refs.fileInput) this.$refs.fileInput.value = ''
			},
	
			onClose() {
				this.$emit('update:modelValue', false)
			},
	
			normalize(str) {
				return String(str || '')
					.toLowerCase()
					.replace(/\s+/g, '')
			},
	
			isGramUnit(unitName) {
				const u = String(unitName || '')
					.toLowerCase()
					.trim()
					.replace(/\s+/g, '')
				return ['gram'].includes(u)
			},
	
			downloadTemplate() {
				exportTemplateImportCongThuc()
			},
		},
	}
</script>