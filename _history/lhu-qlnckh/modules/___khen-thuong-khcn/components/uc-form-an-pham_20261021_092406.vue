<template>
	<v-form ref="validForm" v-model="isValid" lazy-validation>
		<v-row dense class="compact-form-row">
			<!-- 1. Chọn loại đề xuất khen thưởng (Không mặc định) -->
			<v-col cols="12" class="py-1 mb-2">
				<div class="d-flex align-center px-3 py-2 rounded-xs form-section-banner">
					<span class="text-subtitle-2 font-weight-bold primary--text mr-4">
						<v-icon small color="primary" class="mr-1">mdi-shape-outline</v-icon>
						Loại đề xuất:
					</span>
					<v-radio-group v-model="formCategory" row hide-details class="mt-0" :disabled="readonly" @change="onCategoryChange">
						<v-radio label="Cuộc thi KH&CN / Cuộc thi Học thuật" :value="1" class="mr-6 font-weight-medium"></v-radio>
						<v-radio label="Hỗ trợ bảo hộ Sở hữu trí tuệ (SHTT)" :value="2" class="font-weight-medium"></v-radio>
					</v-radio-group>
				</div>
			</v-col>

			<!-- 2. Thông tin chi tiết theo phân loại -->
			<!-- Khối 2A: Cuộc thi KH&CN / Học thuật -->
			<template v-if="formCategory === 1">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiHinhCuocThi" :items="loaiHinhCuocThiList" item-text="text"
						item-value="value" label="Phân loại cuộc thi *" placeholder="Chọn phân loại..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn phân loại cuộc thi']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.CapDoCuocThi" :items="capDoList" item-text="text"
						item-value="value" label="Cấp độ cuộc thi *" placeholder="Chọn cấp độ..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn cấp độ cuộc thi']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.GiaiThuong" :items="giaiThuongList" item-text="text"
						item-value="value" label="Giải thưởng đạt được *" placeholder="Chọn giải thưởng..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn giải thưởng đạt được']"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="khenThuongObj.TenCuocThi_CongTrinh"
						label="Tên cuộc thi / Tên công trình, đề tài dự thi *" placeholder="Nhập đầy đủ tên cuộc thi / đề tài..." outlined dense hide-details="auto"
						:readonly="readonly" :rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập tên cuộc thi/công trình']"></v-text-field>
				</v-col>
			</template>

			<!-- Khối 2B: Hoạt động Sở hữu trí tuệ -->
			<template v-else-if="formCategory === 2">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiKhenThuong" :items="loaiSHTTStageList" item-text="text"
						item-value="value" label="Giai đoạn bảo hộ *" placeholder="Chọn giai đoạn bảo hộ..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn giai đoạn bảo hộ']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiSHTT" :items="loaiSHTTList" item-text="text"
						item-value="value" label="Loại đối tượng SHTT *" placeholder="Chọn đối tượng SHTT..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn đối tượng SHTT']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.PhamViSHTT" :items="phamViSHTTList" item-text="text"
						item-value="value" label="Phạm vi bảo hộ *" placeholder="Chọn phạm vi..." outlined dense hide-details="auto"
						:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn phạm vi bảo hộ']"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="khenThuongObj.TenCuocThi_CongTrinh"
						label="Tên sáng chế / Giải pháp hữu ích / Kiểu dáng / Tác phẩm *" placeholder="Nhập tên đối tượng SHTT..." outlined dense hide-details="auto"
						:readonly="readonly" :rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập tên đối tượng SHTT']"></v-text-field>
				</v-col>
				<v-col cols="12" class="py-1 pt-0">
					<v-checkbox v-model="khenThuongObj.Is_DauRaDeTaiCoSo"
						label="Là kết quả đầu ra của Đề tài NCKH cấp cơ sở nghiệm thu đạt loại Khá trở lên (theo QĐ 371)"
						dense hide-details :disabled="readonly" class="mt-0"></v-checkbox>
				</v-col>
			</template>

			<!-- 3. Minh chứng Quyết định / Văn bằng & Hình thức thanh toán -->
			<v-col cols="12" sm="4" class="py-1">
				<v-text-field v-model="khenThuongObj.SoQuyetDinh_VanBang"
					:label="(formCategory === 1 ? 'Số QĐ khen thưởng / công nhận' : 'Số QĐ chấp nhận đơn / Số Bằng SHTT') + ' *'"
					placeholder="Ví dụ: 1234/QĐ-BGDĐT" outlined dense hide-details="auto"
					:readonly="readonly" :rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập số quyết định/văn bằng']"></v-text-field>
			</v-col>
			<v-col cols="12" sm="4" class="py-1">
				<v-menu
					v-model="menuNgayBanHanh"
					:close-on-content-click="false"
					:disabled="readonly"
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
							:readonly="readonly"
							v-bind="attrs"
							outlined
							dense
							hide-details="auto"
							:rules="[v => !!v || 'Bắt buộc nhập ngày ban hành', v => !v || isValidDate(v) || 'Ngày không đúng định dạng DD/MM/YYYY']"
							@click:prepend-inner="!readonly && (menuNgayBanHanh = !menuNgayBanHanh)"
							@click="!readonly && (menuNgayBanHanh = true)"
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
				<v-select v-model="khenThuongObj.HinhThucThanhToan" :items="hinhThucThanhToanList" item-text="text"
					item-value="value" label="Hình thức nhận tiền *" placeholder="Chọn hình thức nhận tiền..." outlined dense hide-details="auto"
					:disabled="readonly" :rules="[v => !!v || 'Bắt buộc chọn hình thức nhận tiền']" @change="onHinhThucChange"></v-select>
			</v-col>
			<v-col cols="12" class="py-1">
				<v-textarea v-model="khenThuongObj.GhiChu" label="Ghi chú thêm" placeholder="Nhập ghi chú bổ sung nếu có..." rows="2" auto-grow outlined dense hide-details
					:readonly="readonly"></v-textarea>
			</v-col>
		</v-row>
	</v-form>
</template>

<script>
	export default {
		name: 'uc-form-an-pham',
		props: {
			value: {
				type: Object,
				default: () => ({
					KhenThuongObj: {},
					MembersObjArr: [],
					FilesObjArr: [],
				}),
			},
			readonly: {
				type: Boolean,
				default: false,
			},
			apiFile: { type: String, default: '' },
			urlReturnFile: { type: String, default: '' },
		},
		emits: ['input'],
		data() {
			return {
				isValid: true,
				formCategory: null, // 1: Cuộc thi, 2: SHTT, null: chưa chọn
				loaiHinhCuocThiList: [
					{ text: 'Cuộc thi KH&CN', value: 1 },
					{ text: 'Cuộc thi Học thuật (Hệ số 2/3)', value: 2 },
				],
				capDoList: [
					{ text: 'Cấp Quốc tế', value: 1 },
					{ text: 'Cấp Khu vực Quốc tế', value: 2 },
					{ text: 'Cấp Quốc gia', value: 3 },
					{ text: 'Cấp Khu vực (trong nước)', value: 4 },
					{ text: 'Cấp Tỉnh / Ngành', value: 5 },
					{ text: 'Cấp Trường / Ngày hội Lạc Hồng', value: 6 },
				],
				giaiThuongList: [
					{ text: 'Giải Nhất', value: 1 },
					{ text: 'Giải Nhì', value: 2 },
					{ text: 'Giải Ba', value: 3 },
					{ text: 'Giải Khuyến khích', value: 4 },
					{ text: 'Báo cáo ngày hội (Cấp trường)', value: 5 },
				],
				loaiSHTTStageList: [
					{ text: 'Chấp nhận đơn hợp lệ', value: 2 },
					{ text: 'Được cấp văn bằng bảo hộ', value: 3 },
				],
				loaiSHTTList: [
					{ text: 'Sáng chế / Giống cây trồng', value: 1 },
					{ text: 'Giải pháp hữu ích', value: 2 },
					{ text: 'Kiểu dáng công nghiệp', value: 3 },
					{ text: 'Bản quyền tác giả', value: 4 },
				],
				phamViSHTTList: [
					{ text: 'Việt Nam & các quốc gia khác', value: 1 },
					{ text: 'Quốc tế lớn (Mỹ, Châu Âu, Nhật, Úc, Hàn...)', value: 2 },
				],
				hinhThucThanhToanList: [
					{ text: 'Chuyển khoản từng thành viên', value: 1 },
					{ text: 'Đại diện nhận thay cho nhóm', value: 2 },
				],
				menuNgayBanHanh: false,
				inputNgayBanHanh: '',
			}
		},
		computed: {
			khenThuongObj() {
				return this.value.KhenThuongObj || this.value || {}
			},
			displayNgayBanHanh() {
				const val = this.khenThuongObj && this.khenThuongObj.NgayBanHanh
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
					const val = this.khenThuongObj && this.khenThuongObj.NgayBanHanh
					if (!val) return ''
					if (typeof moment !== 'undefined') {
						const m = moment(val, ['YYYY-MM-DD', 'YYYY-MM-DDTHH:mm:ss', 'DD/MM/YYYY'])
						if (m.isValid()) return m.format('YYYY-MM-DD')
					}
					return String(val).substring(0, 10)
				},
				set(val) {
					if (this.khenThuongObj) {
						this.khenThuongObj.NgayBanHanh = val
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
						if (this.khenThuongObj && this.khenThuongObj.NgayBanHanh !== iso) {
							this.khenThuongObj.NgayBanHanh = iso
						}
					}
				}
			},
			'khenThuongObj.LoaiKhenThuong': {
				immediate: true,
				handler(val) {
					if (val === 2 || val === 3) {
						this.formCategory = 2
					} else if (val === 1) {
						this.formCategory = 1
					} else {
						this.formCategory = null
					}
				},
			},
			'khenThuongObj.NgayBanHanh': {
				immediate: true,
				handler(val) {
					if (val && typeof moment !== 'undefined') {
						let m = moment(val, 'YYYY-MM-DD')
						if (!m.isValid()) m = moment(val, 'DD/MM/YYYY')
						if (m.isValid()) {
							const formatted = m.format('YYYY-MM-DD')
							if (this.khenThuongObj.NgayBanHanh !== formatted) {
								this.khenThuongObj.NgayBanHanh = formatted
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
					if (this.khenThuongObj) this.khenThuongObj.NgayBanHanh = ''
					return
				}
				if (typeof moment !== 'undefined') {
					const m = moment(this.inputNgayBanHanh, ['DD/MM/YYYY', 'D/M/YYYY', 'D/MM/YYYY', 'DD/M/YYYY', 'YYYY-MM-DD'], true)
					if (m.isValid()) {
						const iso = m.format('YYYY-MM-DD')
						if (this.khenThuongObj) this.khenThuongObj.NgayBanHanh = iso
						this.inputNgayBanHanh = m.format('DD/MM/YYYY')
					}
				}
			},
			onPickerNgayBanHanh(val) {
				if (this.khenThuongObj) {
					this.khenThuongObj.NgayBanHanh = val
					if (typeof moment !== 'undefined') {
						this.inputNgayBanHanh = moment(val).format('DD/MM/YYYY')
					}
				}
				this.menuNgayBanHanh = false
			},
			onCategoryChange(val) {
				if (val === 1) {
					this.khenThuongObj.LoaiKhenThuong = 1
					this.khenThuongObj.LoaiHinhCuocThi = null
					this.khenThuongObj.CapDoCuocThi = null
					this.khenThuongObj.GiaiThuong = null
				} else if (val === 2) {
					this.khenThuongObj.LoaiKhenThuong = null
					this.khenThuongObj.LoaiSHTT = null
					this.khenThuongObj.PhamViSHTT = null
				}
			},
			onHinhThucChange(val) {
				this.$set(this.khenThuongObj, 'HinhThucThanhToan', val)
				this.$emit('input', this.value)
			},
			validate() {
				if (!this.formCategory) {
					Vue.$toast.warning('Vui lòng chọn loại đề xuất (Cuộc thi hoặc SHTT)!', { position: 'top' })
					return false
				}
				const isFormValid = this.$refs.validForm ? this.$refs.validForm.validate() : false
				if (!isFormValid) {
					Vue.$toast.warning('Vui lòng điền đầy đủ các thông tin đề xuất bắt buộc!', { position: 'top' })
					return false
				}
				return true
			},
		},
	}
</script>