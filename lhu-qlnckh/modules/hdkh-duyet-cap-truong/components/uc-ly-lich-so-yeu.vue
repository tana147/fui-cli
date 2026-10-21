<template>
	<div>
		<h3 class="text-primary mb-3 mt-2 font-weight-bold">
			I. Sơ lược lý lịch:
		</h3>
		<v-form ref="form" @submit.prevent="save">
			<v-row dense>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-text-field label="Họ tên" v-model="SoYeuLyLichLocal.HoTen" readonly variant="outlined"
						density="compact" v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-account"
						hide-details>
					</v-text-field>
				</v-col>
				<v-col cols="12" sm="6" md="2" class="py-1">
					<v-select label="Giới tính" v-model="SoYeuLyLichLocal.GioiTinh" :items="['Nam', 'Nữ']" required
						variant="outlined" density="compact" prepend-inner-icon="mdi-gender-male-female" hide-details>
					</v-select>
				</v-col>
				<v-col cols="12" sm="6" md="2" class="py-1">
					<f-date label="Ngày sinh" outlined dense v-model="SoYeuLyLichLocal.NgaySinh" :date-add="0"
						hide-details />
				</v-col>
				<v-col cols="12" sm="6" md="2" class="py-1">
					<v-text-field label="Đơn vị" v-model="SoYeuLyLichLocal.DonVi" readonly variant="outlined"
						density="compact" v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-domain"
						hide-details>
					</v-text-field>
				</v-col>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-text-field label="Chức vụ" v-model="SoYeuLyLichLocal.ChucVu" required variant="outlined"
						density="compact" prepend-inner-icon="mdi-account-tie" hide-details></v-text-field>
				</v-col>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-select label="Học vị" v-model="SoYeuLyLichLocal.HocVi"
						:items="['Cử nhân', 'Kỹ sư', 'Thạc sĩ', 'Tiến sĩ', 'Giáo sư']" required variant="outlined"
						density="compact" prepend-inner-icon="mdi-school-outline" hide-details></v-select>
				</v-col>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-text-field label="Hướng nghiên cứu chính" v-model="SoYeuLyLichLocal.HuongNghienCuuChinh" required
						variant="outlined" density="compact" prepend-inner-icon="mdi-folder-search-outline"
						hide-details></v-text-field>
				</v-col>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-text-field type="tel" label="Điện thoại" v-model="SoYeuLyLichLocal.DienThoai"
						:rules="[rules.phone]" required variant="outlined" density="compact"
						prepend-inner-icon="mdi-phone" hide-details>
					</v-text-field>
				</v-col>
				<v-col cols="12" sm="6" md="3" class="py-1">
					<v-text-field label="Email" v-model="SoYeuLyLichLocal.Email" readonly variant="outlined"
						density="compact" v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-email"
						hide-details>
					</v-text-field>
				</v-col>
			</v-row>
			<div class="d-flex justify-end mt-3">
				<v-btn @click="save" size="small" variant="flat" color="primary" append-icon="mdi-content-save"
					:loading="isLoading" class="text-none px-4 rounded-sm">Lưu thông tin</v-btn>
			</div>
		</v-form>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-so-yeu',
		props: {
			soYeuLyLich: { type: Object, default: () => ({}) },
			nhanVienId: { type: String, default: '' }
		},
		emits: ['on-reload'],
		data() {
			return {
				isLoading: false,
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
					phone: v => !v || /^0[0-9]{9}$/.test(v) || "Số điện thoại không hợp lệ",
				},
				SoYeuLyLichLocal: {}
			}
		},
		created() {
			this.copyPropToLocal();
		},
		watch: {
			soYeuLyLich: {
				handler() {
					this.copyPropToLocal();
				},
				deep: true
			}
		},
		methods: {
			copyPropToLocal() {
				this.SoYeuLyLichLocal = { ...this.soYeuLyLich };
			},
			async save() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					Vue.$toast.error('Vui lòng kiểm tra lại các thông tin đã nhập.', { position: "top" });
					return;
				}
	
				this.isLoading = true;
				try {
					const params = { ...this.SoYeuLyLichLocal, NhanVienID: this.nhanVienId };
					const res = await ajaxCALLPromise('/HDKH_Profile_CaNhan_Save', params);
					if (res && res[0]) {
						Vue.$toast.success(res[0].Message || 'Cập nhật lý lịch cá nhân thành công!', { position: 'top'});
					} else {
						Vue.$toast.success('Cập nhật lý lịch cá nhân thành công!', { position: 'top'});
					}
					this.$emit('on-reload');
				} catch (error) {
					console.error("Lỗi lưu lý lịch cá nhân:", error);
					Vue.$toast.error(error.message || 'Có lỗi xảy ra, vui lòng thử lại.', { position: "top" });
				} finally {
					this.isLoading = false;
				}
			}
		},
	}
</script>