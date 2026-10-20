<template>
	<v-form ref="validForm" lazy-validation>
		<v-row dense class="compact-form-row">
			<!-- 1. Chọn loại đề xuất khen thưởng -->
			<v-col cols="12" class="py-1 mb-2">
				<div class="d-flex align-center px-3 py-2 rounded-xs form-section-banner">
					<span class="text-subtitle-2 font-weight-bold primary--text mr-4">
						<v-icon small color="primary" class="mr-1">mdi-shape-outline</v-icon>
						Loại đề xuất:
					</span>
					<v-radio-group v-model="formCategory" row hide-details class="mt-0" @change="onCategoryChange">
						<v-radio label="Cuộc thi KH&CN / Cuộc thi Học thuật" :value="1" class="mr-6 font-weight-medium"></v-radio>
						<v-radio label="Hỗ trợ bảo hộ Sở hữu trí tuệ (SHTT)" :value="2" class="font-weight-medium"></v-radio>
					</v-radio-group>
				</div>
			</v-col>

			<!-- 2A. Nhóm trường Cuộc thi KH&CN -->
			<template v-if="formCategory === 1">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.LoaiHinhCuocThi" :items="loaiHinhCuocThiList" item-text="text"
						item-value="value" label="Phân loại cuộc thi *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.CapDoCuocThi" :items="capDoList" item-text="text"
						item-value="value" label="Cấp độ cuộc thi *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.GiaiThuong" :items="giaiThuongList" item-text="text"
						item-value="value" label="Giải thưởng đạt được *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="formData.TenCuocThi_CongTrinh"
						label="Tên cuộc thi / Tên công trình, đề tài dự thi *" outlined dense hide-details="auto"></v-text-field>
				</v-col>
			</template>

			<!-- 2B. Nhóm trường Sở hữu trí tuệ (SHTT) -->
			<template v-else-if="formCategory === 2">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.LoaiKhenThuong" :items="loaiSHTTStageList" item-text="text"
						item-value="value" label="Giai đoạn bảo hộ *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.LoaiSHTT" :items="loaiSHTTList" item-text="text"
						item-value="value" label="Loại đối tượng SHTT *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="formData.PhamViSHTT" :items="phamViSHTTList" item-text="text"
						item-value="value" label="Phạm vi bảo hộ *" outlined dense hide-details="auto"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="formData.TenCuocThi_CongTrinh"
						label="Tên sáng chế / Giải pháp hữu ích / Kiểu dáng / Tác phẩm *" outlined dense hide-details="auto"></v-text-field>
				</v-col>
				<v-col cols="12" class="py-1 pt-0">
					<v-checkbox v-model="formData.Is_DauRaDeTaiCoSo"
						label="Là kết quả đầu ra của Đề tài NCKH cấp cơ sở nghiệm thu đạt loại Khá trở lên (theo QĐ 371)"
						dense hide-details class="mt-0"></v-checkbox>
				</v-col>
			</template>

			<!-- 3. Thông tin Quyết định / Văn bằng & Chi trả -->
			<v-col cols="12" sm="4" class="py-1">
				<v-text-field v-model="formData.SoQuyetDinh_VanBang"
					:label="(formCategory === 1 ? 'Số QĐ khen thưởng / công nhận' : 'Số QĐ chấp nhận đơn / Số Bằng SHTT') + ' *'"
					outlined dense hide-details="auto"></v-text-field>
			</v-col>
			<v-col cols="12" sm="4" class="py-1">
				<v-menu
					v-model="menuNgayBanHanh"
					:close-on-content-click="false"
					transition="scale-transition"
					offset-y
					max-width="290px"
					min-width="290px"
				>
					<template v-slot:activator="{ on, attrs }">
						<v-text-field
							v-model="inputNgayBanHanh"
							label="Ngày ban hành *"
							placeholder="DD/MM/YYYY"
							prepend-inner-icon="mdi-calendar"
							v-bind="attrs"
							outlined
							dense
							hide-details="auto"
							:rules="[v => !!v || 'Bắt buộc nhập ngày ban hành', v => !v || isValidDate(v) || 'Ngày không đúng định dạng DD/MM/YYYY']"
							@click:prepend-inner="menuNgayBanHanh = !menuNgayBanHanh"
							@click="menuNgayBanHanh = true"
							@blur="onNgayBanHanhBlur"
						></v-text-field>
					</template>
					<v-date-picker
						v-model="pickerNgayBanHanh"
						no-title
						locale="vi-vn"
						@input="onPickerNgayBanHanh"
					></v-date-picker>
				</v-menu>
			</v-col>
			<v-col cols="12" sm="4" class="py-1">
				<v-select v-model="formData.HinhThucThanhToan" :items="hinhThucThanhToanList" item-text="text"
					item-value="value" label="Hình thức nhận tiền *" outlined dense hide-details="auto"
					@change="onHinhThucChange"></v-select>
			</v-col>
			<v-col cols="12" class="py-1">
				<v-textarea v-model="formData.GhiChu" label="Ghi chú hồ sơ" rows="2" auto-grow outlined dense hide-details></v-textarea>
			</v-col>
		</v-row>
	</v-form>
</template>

<script>
	export default {
		name: 'uc-form-an-pham',
		props: {
			khenThuongObj: { type: Object, default: () => ({}) },
			value: { type: Object, default: null },
			filesList: { type: Array, default: () => [] },
			urlReturnFile: { type: String, default: '' },
		},
		data() {
			return {
				formCategory: 1,
				loaiHinhCuocThiList: [
					{ text: 'Cuộc thi KH&CN', value: 1 },
					{ text: 'Cuộc thi Học thuật', value: 2 },
				],
				capDoList: [
					{ text: 'Quốc tế', value: 1 },
					{ text: 'Khu vực Quốc tế', value: 2 },
					{ text: 'Quốc gia', value: 3 },
					{ text: 'Khu vực trong nước', value: 4 },
					{ text: 'Cấp Tỉnh', value: 5 },
					{ text: 'Cấp Trường', value: 6 },
				],
				giaiThuongList: [
					{ text: 'Giải Nhất', value: 1 },
					{ text: 'Giải Nhì', value: 2 },
					{ text: 'Giải Ba', value: 3 },
					{ text: 'Khuyến khích', value: 4 },
					{ text: 'Báo cáo ngày hội', value: 5 },
				],
				loaiSHTTStageList: [
					{ text: 'Chấp nhận đơn hợp lệ', value: 2 },
					{ text: 'Cấp văn bằng bảo hộ', value: 3 },
				],
				loaiSHTTList: [
					{ text: 'Sáng chế / Giống cây trồng', value: 1 },
					{ text: 'Giải pháp hữu ích', value: 2 },
					{ text: 'Kiểu dáng công nghiệp', value: 3 },
					{ text: 'Quyền tác giả', value: 4 },
				],
				phamViSHTTList: [
					{ text: 'Việt Nam & các quốc gia khác', value: 1 },
					{ text: 'Quốc tế lớn (Mỹ, EU, Nhật, Úc, Hàn...)', value: 2 },
				],
				hinhThucThanhToanList: [
					{ text: 'Chuyển khoản từng cá nhân', value: 1 },
					{ text: 'Ủy quyền đại diện nhận thay', value: 2 },
				],
				menuNgayBanHanh: false,
				inputNgayBanHanh: '',
			}
		},
		computed: {
			formData() {
				return this.value || this.khenThuongObj || {}
			},
			displayNgayBanHanh() {
				const val = this.formData && this.formData.NgayBanHanh
				if (!val) return ''
				if (typeof moment !== 'undefined') {
					const m = moment(val, ['YYYY-MM-DD', 'YYYY-MM-DDTHH:mm:ss', 'DD/MM/YYYY'])
					if (m.isValid()) return m.format('DD/MM/YYYY')
				}
				const parts = String(val).substring(0, 10).split('-')
				if (parts.length === 3 && parts[0].length === 4) {
					return `${parts[2]}/${parts[1]}/${parts[0]}`
				}
				return val
			},
			pickerNgayBanHanh: {
				get() {
					if (this.inputNgayBanHanh && typeof moment !== 'undefined') {
						const m = moment(this.inputNgayBanHanh, ['DD/MM/YYYY', 'D/M/YYYY', 'D/MM/YYYY', 'DD/M/YYYY'], true)
						if (m.isValid()) return m.format('YYYY-MM-DD')
					}
					const val = this.formData && this.formData.NgayBanHanh
					if (!val) return ''
					if (typeof moment !== 'undefined') {
						const m = moment(val, ['YYYY-MM-DD', 'YYYY-MM-DDTHH:mm:ss', 'DD/MM/YYYY'])
						if (m.isValid()) return m.format('YYYY-MM-DD')
					}
					return String(val).substring(0, 10)
				},
				set(val) {
					if (this.formData) {
						this.formData.NgayBanHanh = val
						if (typeof moment !== 'undefined') {
							this.inputNgayBanHanh = moment(val).format('DD/MM/YYYY')
						}
					}
				}
			}
		},
		watch: {
			inputNgayBanHanh(val) {
				if (val && typeof moment !== 'undefined') {
					const m = moment(val, ['DD/MM/YYYY', 'D/M/YYYY', 'D/MM/YYYY', 'DD/M/YYYY'], true)
					if (m.isValid()) {
						const iso = m.format('YYYY-MM-DD')
						if (this.formData && this.formData.NgayBanHanh !== iso) {
							this.formData.NgayBanHanh = iso
						}
					}
				}
			},
			'formData.LoaiKhenThuong': {
				immediate: true,
				handler(val) {
					if (val === 2 || val === 3) {
						this.formCategory = 2
					} else {
						this.formCategory = 1
					}
				},
			},
			'formData.NgayBanHanh': {
				immediate: true,
				handler(val) {
					if (val && typeof moment !== 'undefined') {
						let m = moment(val, 'YYYY-MM-DD')
						if (!m.isValid()) m = moment(val, 'DD/MM/YYYY')
						if (m.isValid()) {
							const formatted = m.format('YYYY-MM-DD')
							if (this.formData.NgayBanHanh !== formatted) {
								this.formData.NgayBanHanh = formatted
							}
							const display = m.format('DD/MM/YYYY')
							if (this.inputNgayBanHanh !== display) {
								this.inputNgayBanHanh = display
							}
						}
					} else if (!val) {
						this.inputNgayBanHanh = ''
					}
				},
			},
		},
		methods: {
			isValidDate(val) {
				if (!val) return true
				if (typeof moment === 'undefined') return true
				const m = moment(val, ['DD/MM/YYYY', 'D/M/YYYY', 'D/MM/YYYY', 'DD/M/YYYY', 'YYYY-MM-DD'], true)
				return m.isValid()
			},
			onNgayBanHanhBlur() {
				if (!this.inputNgayBanHanh) {
					if (this.formData) this.formData.NgayBanHanh = ''
					return
				}
				if (typeof moment !== 'undefined') {
					const m = moment(this.inputNgayBanHanh, ['DD/MM/YYYY', 'D/M/YYYY', 'D/MM/YYYY', 'DD/M/YYYY', 'YYYY-MM-DD'], true)
					if (m.isValid()) {
						const iso = m.format('YYYY-MM-DD')
						if (this.formData) this.formData.NgayBanHanh = iso
						this.inputNgayBanHanh = m.format('DD/MM/YYYY')
					}
				}
			},
			onPickerNgayBanHanh(val) {
				if (this.formData) {
					this.formData.NgayBanHanh = val
					if (typeof moment !== 'undefined') {
						this.inputNgayBanHanh = moment(val).format('DD/MM/YYYY')
					}
				}
				this.menuNgayBanHanh = false
			},
			onCategoryChange(val) {
				if (val === 1) {
					this.formData.LoaiKhenThuong = 1
					this.formData.LoaiSHTT = null
					this.formData.PhamViSHTT = null
				} else {
					if (!this.formData.LoaiKhenThuong || this.formData.LoaiKhenThuong === 1) {
						this.formData.LoaiKhenThuong = 2
					}
					this.formData.LoaiHinhCuocThi = null
					this.formData.CapDoCuocThi = null
					this.formData.GiaiThuong = null
				}
			},
			onHinhThucChange(val) {
				this.$emit('input', { ...this.formData, HinhThucThanhToan: val })
			},
		},
	}
</script>