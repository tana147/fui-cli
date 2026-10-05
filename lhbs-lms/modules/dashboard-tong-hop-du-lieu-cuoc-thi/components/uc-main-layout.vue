<template>
	<div>
		<v-card class="mb-2">
			<v-card-title class="d-flex align-center flex-wrap ga-2">
				<span class="text-primary font-weight-bold">{{ isEn ? 'Competition Data Summary' : 'Tổng hợp dữ liệu cuộc thi' }}<span v-if="CapTitle"> • {{ CapTitle }}</span></span>
				<v-spacer />
				<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
					<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
					</v-btn>
					<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
					</v-btn>
				</v-btn-toggle>
			</v-card-title>
			<v-card-text>
				<v-row align="center" dense>
					<v-col cols="12" sm="3">
						<v-select
							:key="'cap_' + isEn"
							v-model="CapID"
							:label="isEn ? 'Select level' : 'Chọn cấp'"
							:items="DSCap"
							item-value="value"
							item-title="title"
							:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
						/>
					</v-col>
					<v-col cols="12" sm="3">
						<v-select
							:key="'lop_' + isEn"
							v-model="LopItem"
							:label="isEn ? 'Select class' : 'Chọn lớp'"
							:items="DSLop"
							item-title="TenLop"
							item-value="LopID"
							return-object
							:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
						/>
					</v-col>
					<v-col cols="12" sm="6" class="d-flex align-center ga-2 flex-wrap flex-md-nowrap">
						<v-btn variant="outlined" color="primary" prepend-icon="mdi-magnify" @click="onSearch">
							{{ isEn ? 'Search' : 'Tìm kiếm' }}
						</v-btn>
						<v-spacer />
						<uc-btn-dialog-add @onLoadFinish="onSearch" :LopItem :CapID :isEn />
						<uc-btn-dialog-add-multiple @onLoadFinish="onSearch" :LopItem :CapID :isEn />
						<v-btn variant="outlined" color="success" prepend-icon="mdi-file-excel" @click="onExportExcel">
							{{ isEn ? 'Export Excel' : 'Xuất Excel' }}
						</v-btn>
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
		<v-card>
			<v-data-table
				:key="'tbl_' + isEn"
				:items="items"
				:headers="headers"
				:loading="loading"
				:loading-text="isEn ? 'Loading data...' : 'Đang tải dữ liệu...'"
				:items-per-page-text="isEn ? 'Items per page:' : 'Dữ liệu trên mỗi trang:'"
				:page-text="isEn ? '{0}-{1} of {2}' : '{0}-{1} trên {2}'"
				:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
				style="height: calc(-140px + 100dvh)"
			>
				<template #no-data>
					<div class="text-center py-4 text-grey">
						{{ isEn ? 'No data available' : 'Chưa có dữ liệu' }}
					</div>
				</template>
				<template #item.HocKi="{ item }">
					<span>{{ formatHocKi(item.HocKi) }}</span>
				</template>
				<template #item.actions="{ item }">
					<div style="min-width: 70px;">
						<v-btn @click="deleteItem(item)" icon="mdi-trash-can-outline" size="small" color="red-darken-1"
							density="comfortable" variant="plain"></v-btn>

						<v-btn @click="editItem(item)" icon="mdi-square-edit-outline" size="small"
							color="green-darken-2" density="comfortable" variant="plain"></v-btn>
					</div>
				</template>
			</v-data-table>
		</v-card>
		<uc-dialog-edit v-model="isDialogEdit" :CapID :LopItem @onLoadFinish="onSearch" :item="THItem" :isEn />
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				isEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
				items: [],
				loading: false,
				LopItem: null,
				DSLop: [],
				CapID: null,
				isDialogEdit: false,
				THItem: null,
				vueData,
			}
		},
		computed: {
			CapTitle() {
				const capId = parseInt(this.CapID || vueData.capid)
				if (Number.isNaN(capId)) return ''
				if (this.isEn) {
					if (capId === 1) return 'Primary'
					if (capId === 2) return 'Secondary'
					if (capId === 3) return 'High School'
					return 'Level ' + capId
				}
				return typeof renderText === 'function' ? renderText(capId) : ('Cấp ' + capId)
			},
			DSCap() {
				let dscap = [
					{ title: this.isEn ? "Primary" : "Cấp 1", value: 1 },
					{ title: this.isEn ? "Secondary" : "Cấp 2", value: 2 },
					{ title: this.isEn ? "High School" : "Cấp 3", value: 3 },
				]
				if (vueData.capid) {
					dscap = dscap.filter(x => x.value == vueData.capid)
				}
				return dscap
			},
			headers() {
				return [
					{
						title: this.isEn ? "COMPETITION DATA SUMMARY" : "TỔNG HỢP DỮ LIỆU CUỘC THI",
						align: "center",
						children: [
							{ title: this.isEn ? 'No.' : 'STT', value: 'STT', fixed: true, minWidth: 80, width: 80 },
							{ title: this.isEn ? 'Student ID' : 'Mã học sinh', value: 'HocSinhID', fixed: true, minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Student Name' : 'Học sinh', value: 'HoTen', fixed: true, minWidth: 150, width: 150 },
							{ title: this.isEn ? 'Exam Date' : 'Thời gian thi', value: 'ThoiGianThi', minWidth: 100, width: 100 },
							{ title: this.isEn ? 'Semester' : 'Học kì', value: 'HocKi', minWidth: 80, width: 80 },
							{ title: this.isEn ? 'Competition Name' : 'Tên cuộc thi', value: 'TenCuocThi', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Project Field' : 'Lĩnh vực dự án', value: 'LinhVucDuAn', minWidth: 100, width: 100 },
							{ title: this.isEn ? 'Brief Description / Objective' : 'Mô tả ngắn gọn nội dung/mục tiêu', value: 'MoTaNganGonNoiDung_MucTieu', minWidth: 200, width: 200 },
							{ title: this.isEn ? 'Advisor Teacher' : 'GV hướng dẫn', value: 'GVHuongDan', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Department' : 'Tổ/bộ phận', value: 'To_BoPhan', minWidth: 100, width: 100 },
							{ title: this.isEn ? 'Support Teacher / Dept.' : 'GV/tổ hỗ trợ', value: 'GV_ToHoTro', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Recognizing Organization' : 'Tổ chức công nhận', value: 'ToChucCongNhan', minWidth: 130, width: 130 },
							{ title: this.isEn ? 'Award Level' : 'Cấp độ giải thưởng', value: 'CapDoGiaiThuong', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Award Won' : 'Giải thưởng đạt được', value: 'GiaiThuongDatDuoc', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Proof / Decision No. / Link' : 'Minh chứng', value: 'MinhChung_SoHieuQD_LinkChungNhan', minWidth: 120, width: 120 },
							{ title: this.isEn ? 'Additional Notes' : 'Ghi chú bổ sung', value: 'GhiChuBoSung', minWidth: 200, width: 200 },
							{ title: this.isEn ? 'Actions' : 'Thao tác', value: 'actions', fixed: true, minWidth: 80, width: 80 }
						]
					}
				]
			}
		},
		mounted() {
			window.addEventListener('storage', this.handleStorageChange)
			if (this.$vuetify?.locale) this.$vuetify.locale.current = this.isEn ? 'en' : 'vi'
			if (this.$vuetify?.lang) this.$vuetify.lang.current = this.isEn ? 'en' : 'vi'
			this.CapID = this.DSCap[0]?.value ?? null
		},
		beforeUnmount() {
			window.removeEventListener('storage', this.handleStorageChange)
		},
		watch: {
			CapID: function () {
				this.onLoadLop()
			},
			LopItem: function () {
				this.onSearch()
			}
		},
		methods: {
			setLanguage(val) {
				this.isEn = val
				if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi'
				if (this.$vuetify?.locale) this.$vuetify.locale.current = val ? 'en' : 'vi'
				if (this.$vuetify?.lang) this.$vuetify.lang.current = val ? 'en' : 'vi'
				localStorage.setItem('IsLanguage', JSON.stringify(val))
			},
			handleStorageChange(event) {
				if (event.key === 'IsLanguage') {
					this.isEn = JSON.parse(event.newValue) ?? false
					if (this.$i18n) this.$i18n.locale = this.isEn ? 'en' : 'vi'
					if (this.$vuetify?.locale) this.$vuetify.locale.current = this.isEn ? 'en' : 'vi'
					if (this.$vuetify?.lang) this.$vuetify.lang.current = this.isEn ? 'en' : 'vi'
				}
			},
			formatHocKi(val) {
				if (!val) return ''
				if (this.isEn) {
					if (val === 'GK_HK1') return 'Mid Sem 1'
					if (val === 'CK_HK1') return 'End Sem 1'
					if (val === 'GK_HK2') return 'Mid Sem 2'
					if (val === 'CK_HK2') return 'End Sem 2'
					if (val === 'HK1') return 'Semester 1'
					if (val === 'HK2') return 'Semester 2'
				} else {
					if (val === 'GK_HK1') return 'Giữa HK1'
					if (val === 'CK_HK1') return 'Cuối HK1'
					if (val === 'GK_HK2') return 'Giữa HK2'
					if (val === 'CK_HK2') return 'Cuối HK2'
				}
				return val
			},
			async onSearch() {
				this.loading = true
				const items = await ajaxCALLPromise('lms/TongHopDuLieuCuocThi_Get', {
					NienKhoa: vueData.NienKhoa,
					LopID: this.LopItem?.LopID ?? 0
				}).finally(() => this.loading = false)
				this.items = items.map((x, idx) => ({ ...x, STT: idx + 1 }))
			},
			async onLoadLop() {
				this.DSLop = await ajaxCALLPromise("lms/Lop_Get_By_CapID", { NienKhoa: vueData.NienKhoa, CapID: this.CapID })
			},
			editItem(item) {
				this.THItem = Object.assign({}, item)
				this.isDialogEdit = true
			},
			deleteItem(item) {
				const $this = this
				confirm({
					title: this.isEn ? "Confirm deletion" : "Xác nhận xóa",
					message: this.isEn ? "Are you sure you want to delete this record?" : "Bạn có chắc chắn muốn xóa dữ liệu này?",
					action: function () {
						ajaxCALLPromise("lms/TongHopDuLieuCuocThi_Del", {
							TongHopDuLieuCuocThiID: item.TongHopDuLieuCuocThiID
						}).then(() => {
							Vue.$toast.success($this.isEn ? "Deleted successfully" : "Xóa thành công", { position: "top" })
							$this.onSearch()
						})
					}
				})
			},
			async onExportExcel() {
				if (!this.items || this.items.length === 0) {
					Vue.$toast.warning(this.isEn ? "No data to export" : "Không có dữ liệu để xuất", { position: "top" })
					return
				}
	
				try {
					// Tạo workbook và worksheet
					const wb = XLSX.utils.book_new()
	
					// Chuẩn bị dữ liệu
					const wsData = []
	
					// Lấy thông tin từ headers
					const mainHeaderInfo = this.headers[0]
					const subHeaders = mainHeaderInfo.children.filter(x => x.value !== 'actions')
	
					// Header chính (dòng 1) - gộp tất cả các cột
					wsData.push([mainHeaderInfo.title])
	
					// Sub-headers (dòng 2)
					const subHeaderTitles = subHeaders.map(h => h.title)
					wsData.push(subHeaderTitles)
	
					// Thêm dữ liệu
					this.items.forEach(item => {
						const row = subHeaders.map(header => {
							if (header.value === 'HocKi') return this.formatHocKi(item[header.value])
							return item[header.value] || ''
						})
						wsData.push(row)
					})
	
					// Tạo worksheet từ dữ liệu
					const ws = XLSX.utils.aoa_to_sheet(wsData)
	
					// Số cột (không tính cột actions)
					const colCount = subHeaders.length
	
					// Thiết lập merge cells cho header chính (dòng 1)
					ws['!merges'] = [
						{ s: { r: 0, c: 0 }, e: { r: 0, c: colCount - 1 } }
					]
	
					// Thiết lập độ rộng cột dựa trên minWidth trong headers
					ws['!cols'] = subHeaders.map(h => ({
						wch: Math.max((h.minWidth || 100) / 8, 10) // Chuyển đổi px sang character width
					}))
	
					// Style cho header chính
					const headerStyle = {
						font: { bold: true, sz: 14, color: { rgb: "FFFFFF" } },
						fill: { fgColor: { rgb: "4472C4" } },
						alignment: { horizontal: "center", vertical: "center" }
					}
	
					// Style cho sub-headers
					const subHeaderStyle = {
						font: { bold: true, sz: 11, color: { rgb: "FFFFFF" } },
						fill: { fgColor: { rgb: "5B9BD5" } },
						alignment: { horizontal: "center", vertical: "center", wrapText: true }
					}
	
					// Áp dụng style cho header chính (A1)
					if (!ws['A1'].s) ws['A1'].s = {}
					ws['A1'].s = headerStyle
	
					// Áp dụng style cho sub-headers (dòng 2)
					const colLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')
					for (let i = 0; i < colCount; i++) {
						const cell = colLetters[i] + '2'
						if (!ws[cell]) ws[cell] = { v: '' }
						if (!ws[cell].s) ws[cell].s = {}
						ws[cell].s = subHeaderStyle
					}
	
					// Thêm worksheet vào workbook
					XLSX.utils.book_append_sheet(wb, ws, this.isEn ? 'Competition Data' : 'Dữ liệu cuộc thi')
	
					// Xuất file
					const tenLop = this.LopItem?.TenLop || (this.isEn ? 'All' : 'TatCa')
					const fileName = `TongHopDuLieuCuocThi_${tenLop}_${vueData.NienKhoa}.xlsx`
					XLSX.writeFile(wb, fileName)
	
					Vue.$toast.success(this.isEn ? "Exported Excel successfully" : "Xuất Excel thành công", { position: "top" })
	
				} catch (error) {
					console.error('Lỗi xuất Excel:', error)
					Vue.$toast.error(this.isEn ? "Error exporting Excel" : "Có lỗi khi xuất Excel", { position: "top" })
				}
			}
		}
	}
</script>