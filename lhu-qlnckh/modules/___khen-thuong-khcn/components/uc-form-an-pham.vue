<template>
	<v-form ref="validForm" v-model="isValid" lazy-validation>
		<v-row dense class="compact-form-row">
			<!-- 1. Chọn loại đề xuất khen thưởng (Không mặc định) -->
			<v-col cols="12" class="py-1 mb-2">
				<div class="d-flex align-center px-3 py-2 rounded-xs" style="background: #eef2f6; border-left: 4px solid #1976d2;">
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

			<!-- 2. Thông tin chi tiết theo phân loại -->
			<!-- Khối 2A: Cuộc thi KH&CN / Học thuật -->
			<template v-if="formCategory === 1">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiHinhCuocThi" :items="loaiHinhCuocThiList" item-text="text"
						item-value="value" label="Phân loại cuộc thi *" placeholder="Chọn phân loại..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn phân loại cuộc thi']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.CapDoCuocThi" :items="capDoList" item-text="text"
						item-value="value" label="Cấp độ cuộc thi *" placeholder="Chọn cấp độ..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn cấp độ cuộc thi']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.GiaiThuong" :items="giaiThuongList" item-text="text"
						item-value="value" label="Giải thưởng đạt được *" placeholder="Chọn giải thưởng..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn giải thưởng đạt được']"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="khenThuongObj.TenCuocThi_CongTrinh"
						label="Tên cuộc thi / Tên công trình, đề tài dự thi *" placeholder="Nhập đầy đủ tên cuộc thi / đề tài..." outlined dense hide-details="auto"
						:rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập tên cuộc thi/công trình']"></v-text-field>
				</v-col>
			</template>

			<!-- Khối 2B: Hoạt động Sở hữu trí tuệ -->
			<template v-else-if="formCategory === 2">
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiKhenThuong" :items="loaiSHTTStageList" item-text="text"
						item-value="value" label="Giai đoạn bảo hộ *" placeholder="Chọn giai đoạn bảo hộ..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn giai đoạn bảo hộ']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.LoaiSHTT" :items="loaiSHTTList" item-text="text"
						item-value="value" label="Loại đối tượng SHTT *" placeholder="Chọn đối tượng SHTT..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn đối tượng SHTT']"></v-select>
				</v-col>
				<v-col cols="12" sm="4" class="py-1">
					<v-select v-model="khenThuongObj.PhamViSHTT" :items="phamViSHTTList" item-text="text"
						item-value="value" label="Phạm vi bảo hộ *" placeholder="Chọn phạm vi..." outlined dense hide-details="auto"
						:rules="[v => !!v || 'Bắt buộc chọn phạm vi bảo hộ']"></v-select>
				</v-col>
				<v-col cols="12" class="py-1">
					<v-text-field v-model="khenThuongObj.TenCuocThi_CongTrinh"
						label="Tên sáng chế / Giải pháp hữu ích / Kiểu dáng / Tác phẩm *" placeholder="Nhập tên đối tượng SHTT..." outlined dense hide-details="auto"
						:rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập tên đối tượng SHTT']"></v-text-field>
				</v-col>
				<v-col cols="12" class="py-1 pt-0">
					<v-checkbox v-model="khenThuongObj.Is_DauRaDeTaiCoSo"
						label="Là kết quả đầu ra của Đề tài NCKH cấp cơ sở nghiệm thu đạt loại Khá trở lên (theo QĐ 371)"
						dense hide-details class="mt-0"></v-checkbox>
				</v-col>
			</template>

			<!-- 3. Minh chứng Quyết định / Văn bằng & Hình thức thanh toán -->
			<v-col cols="12" sm="4" class="py-1">
				<v-text-field v-model="khenThuongObj.SoQuyetDinh_VanBang"
					:label="(formCategory === 1 ? 'Số QĐ khen thưởng / công nhận' : 'Số QĐ chấp nhận đơn / Số Bằng SHTT') + ' *'"
					placeholder="Ví dụ: 1234/QĐ-BGDĐT" outlined dense hide-details="auto"
					:rules="[v => (!!v && !!v.trim()) || 'Bắt buộc nhập số quyết định/văn bằng']"></v-text-field>
			</v-col>
			<v-col cols="12" sm="4" class="py-1">
				<v-text-field v-model="khenThuongObj.NgayBanHanh" label="Ngày ban hành (YYYY-MM-DD) *" type="date"
					outlined dense hide-details="auto" :rules="[v => !!v || 'Bắt buộc chọn ngày ban hành']"></v-text-field>
			</v-col>
			<v-col cols="12" sm="4" class="py-1">
				<v-select v-model="khenThuongObj.HinhThucThanhToan" :items="hinhThucThanhToanList" item-text="text"
					item-value="value" label="Hình thức nhận tiền *" placeholder="Chọn hình thức nhận tiền..." outlined dense hide-details="auto"
					:rules="[v => !!v || 'Bắt buộc chọn hình thức nhận tiền']" @change="onHinhThucChange"></v-select>
			</v-col>
			<v-col cols="12" class="py-1">
				<v-textarea v-model="khenThuongObj.GhiChu" label="Ghi chú thêm" placeholder="Nhập ghi chú bổ sung nếu có..." rows="2" auto-grow outlined dense hide-details></v-textarea>
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
			}
		},
		computed: {
			khenThuongObj() {
				return this.value.KhenThuongObj || this.value || {}
			},
		},
		watch: {
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
		},
		methods: {
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