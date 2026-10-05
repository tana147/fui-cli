<template>
	<v-dialog v-model="modelValue" max-width="800">
		<v-card>
			<v-card-title class="d-flex">
				<span class="text-primary">{{ currentIsEn ? 'Update Competition Data' : 'Cập nhật dữ liệu cuộc thi' }}</span>
				<v-spacer />
				<v-icon size="small" @click="$emit('update:modelValue', false)">mdi-close</v-icon>
			</v-card-title>
			<v-card-text>
				<v-form ref="form">
					<v-row>
						<v-col cols="12" md="6">
							<v-autocomplete v-model="formData.HocSinhID" :label="currentIsEn ? 'Student' : 'Học sinh'" :items="DSHocSinh"
								:item-title="renderTitle" item-value="HocSinhID" readonly :clearable="false" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.ThoiGianThi" :label="currentIsEn ? 'Exam Date' : 'Thời gian thi'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-select v-model="formData.HocKi" :label="currentIsEn ? 'Semester' : 'Học kì'" :items="DSHocKi" item-title="title"
								item-value="value" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.TenCuocThi" :label="currentIsEn ? 'Competition Name' : 'Tên cuộc thi'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.LinhVucDuAn" :label="currentIsEn ? 'Project Field' : 'Lĩnh vực dự án'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.GVHuongDan" :label="currentIsEn ? 'Advisor Teacher' : 'GV hướng dẫn'" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formData.MoTaNganGonNoiDung_MucTieu"
								:label="currentIsEn ? 'Brief Description / Objective' : 'Mô tả ngắn gọn nội dung/mục tiêu'" rows="3" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.To_BoPhan" :label="currentIsEn ? 'Department' : 'Tổ/bộ phận'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.GV_ToHoTro" :label="currentIsEn ? 'Support Teacher / Dept.' : 'GV/tổ hỗ trợ'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.ToChucCongNhan" :label="currentIsEn ? 'Recognizing Organization' : 'Tổ chức công nhận'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.CapDoGiaiThuong" :label="currentIsEn ? 'Award Level' : 'Cấp độ giải thưởng'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.GiaiThuongDatDuoc" :label="currentIsEn ? 'Award Won' : 'Giải thưởng đạt được'" />
						</v-col>
						<v-col cols="12" md="6">
							<v-text-field v-model="formData.MinhChung_SoHieuQD_LinkChungNhan"
								:label="currentIsEn ? 'Proof (Decision No. / Certificate Link)' : 'Minh chứng (Số hiệu QĐ/link chứng nhận)'" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formData.GhiChuBoSung" :label="currentIsEn ? 'Additional Notes' : 'Ghi chú bổ sung'" rows="2" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="grey" @click="$emit('update:modelValue', false)">{{ currentIsEn ? 'Close' : 'Đóng' }}</v-btn>
				<v-btn color="primary" @click="saveData()" variant="elevated">{{ currentIsEn ? 'Update' : 'Cập nhật' }}</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			modelValue: Boolean,
			item: Object,
			CapID: Number,
			LopItem: Object,
			onLoadFinish: Function,
			isEn: {
				type: Boolean,
				default: undefined
			}
		},
		data() {
			return {
				localIsEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
				formData: {
					HocSinhID: null,
					ThoiGianThi: '',
					HocKi: null,
					TenCuocThi: '',
					LinhVucDuAn: '',
					MoTaNganGonNoiDung_MucTieu: '',
					GVHuongDan: '',
					To_BoPhan: '',
					GV_ToHoTro: '',
					ToChucCongNhan: '',
					CapDoGiaiThuong: '',
					GiaiThuongDatDuoc: '',
					MinhChung_SoHieuQD_LinkChungNhan: '',
					GhiChuBoSung: ''
				},
				DSHocSinh: [],
				vueData
			}
		},
		computed: {
			currentIsEn() {
				return this.isEn !== undefined ? this.isEn : this.localIsEn
			},
			DSHocKi() {
				const hk_c1 = [
					{ title: this.currentIsEn ? "Mid Sem 1" : "Giữa HK1", value: "GK_HK1" },
					{ title: this.currentIsEn ? "End Sem 1" : "Cuối HK1", value: "CK_HK1" },
					{ title: this.currentIsEn ? "Mid Sem 2" : "Giữa HK2", value: "GK_HK2" },
					{ title: this.currentIsEn ? "End Sem 2" : "Cuối HK2", value: "CK_HK2" },
				]
				const hk_c2_c3 = [
					{ title: this.currentIsEn ? "Semester 1" : "HK1", value: "HK1" },
					{ title: this.currentIsEn ? "Semester 2" : "HK2", value: "HK2" },
				]
				return this.CapID === 1 ? hk_c1 : hk_c2_c3
			}
		},
		watch: {
			"modelValue": function (isShow) {
				if(!isShow) return
				this.onLoadHS()
				this.formData = { ...this.item }
			}
		},
		mounted() {
			window.addEventListener('storage', this.handleStorageChange)
		},
		beforeUnmount() {
			window.removeEventListener('storage', this.handleStorageChange)
		},
		methods: {
			handleStorageChange(e) {
				if (e.key === 'IsLanguage') {
					this.localIsEn = JSON.parse(e.newValue) ?? false
				}
			},
			async onLoadHS() {
				if (!this.LopItem?.LopID) return
				this.DSHocSinh = await ajaxCALLPromise("lms/HocSinhLop_Get_ByLopID", { NienKhoa: vueData.NienKhoa, LopID: this.LopItem.LopID })
			},
			async saveData() {
				const form = await this.$refs.form
				if (form.validate()) {
					ajaxCALLPromise('lms/TongHopDuLieuCuocThi_Upd', {
						...this.formData,
						TongHopDuLieuCuocThiID: this.item.TongHopDuLieuCuocThiID
					}).then(() => {
						Vue.$toast.success(this.currentIsEn ? "Updated successfully" : "Cập nhật thành công", { position: "top" })
						this.$emit('onLoadFinish')
						form.reset()
						this.$emit('update:modelValue', false)
					})
				}
			},
			renderTitle(item) {
				return `[${item.HocSinhID}] ${item.HoTen} - ${item.TenLop}`
			}
		},
	}
</script>