<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			I. Sơ lược lý lịch:
		</h3>
		<v-form ref="form" @submit.prevent="save">
			<v-row>
				<v-col cols="3">
					<v-text-field label="Họ tên" v-model="SoYeuLyLich.HoTen" readonly
						v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-account">
					</v-text-field>
				</v-col>
				<v-col cols="2">
					<v-select label="Giới tính" v-model="SoYeuLyLich.GioiTinh" :items="['Nam', 'Nữ']" required
						prepend-inner-icon="mdi-gender-male-female"></v-select>
				</v-col>
				<v-col cols="2">
					<f-date label="Ngày sinh" outlined dense v-model="SoYeuLyLich.NgaySinh" :date-add="0"
						hide-details />
				</v-col>
				<v-col cols="2">
					<v-text-field label="Đơn vị" v-model="SoYeuLyLich.DonVi" readonly
						v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-domain">
					</v-text-field>
				</v-col>
				<v-col cols="3">
					<v-text-field label="Chức vụ" v-model="SoYeuLyLich.ChucVu" required
						prepend-inner-icon="mdi-account-tie"></v-text-field>
				</v-col>
				<v-col cols="3">
					<v-select label="Học vị" v-model="SoYeuLyLich.HocVi"
						:items="['Cử nhân', 'Kỹ sư', 'Thạc sĩ', 'Tiến sĩ', 'Giáo sư']" required
						prepend-inner-icon="mdi-school-outline"></v-select>
				</v-col>
				<v-col cols="3">
					<v-text-field label="Hướng nghiên cứu chính" v-model="SoYeuLyLich.HuongNghienCuuChinh" required
						prepend-inner-icon="mdi-folder-search-outline"></v-text-field>
				</v-col>
				<v-col cols="3">
					<v-text-field type="tel" label="Điện thoại" v-model="SoYeuLyLich.DienThoai" required
						prepend-inner-icon="mdi-phone">
					</v-text-field>
				</v-col>
				<v-col cols="3">
					<v-text-field label="Email" v-model="SoYeuLyLich.Email" readonly
						v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-email">
					</v-text-field>
				</v-col>
			</v-row>
			<div class="d-flex justify-end mt-2">
				<v-btn @click="save" size="small" variant="flat" color="primary" append-icon="mdi-content-save"
					:loading="isLoading">Lưu</v-btn>
			</div>
		</v-form>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-so-yeu',
		props: {
			userProfile: { type: Array, default: () => [] },
			nhanVienId: [String, Number]
		},
		data() {
			return {
				isLoading: false,
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
					phone: v => /^0[0-9]{9}$/.test(v) || "Số điện thoại không hợp lệ",
				},
				SoYeuLyLich: {}
			}
		},
		watch: {
			userProfile: {
				immediate: true,
				handler(val) {
					if (val && val[0] && val[0][0]) {
						this.SoYeuLyLich = { ...val[0][0] };
					}
				}
			}
		},
		methods: {
			async save() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					Vue.$toast.error('Vui lòng kiểm tra lại các thông tin đã nhập.', { position: "top" });
					return;
				}
	
				this.isLoading = true;
				try {
					const params = { ...this.SoYeuLyLich, NhanVienID: this.nhanVienId };
					await ajaxCALLPromise('/HDKH_Profile_CaNhan_Save', params);
					Vue.$toast.success("Cập nhật sơ lược lý lịch thành công!", { position: 'top' });
				} catch (error) {
					console.error(error)
					Vue.$toast.error(error.message || 'Có lỗi xảy ra, vui lòng thử lại.', { position: "top" });
				} finally {
					this.isLoading = false;
				}
			}
		},
	}
</script>