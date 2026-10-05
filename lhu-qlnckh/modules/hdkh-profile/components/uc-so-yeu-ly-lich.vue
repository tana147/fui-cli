<template>
	<h3 class="text-primary mb-2 mt-2 font-weight-bold">
		I. Sơ lược lý lịch:
	</h3>
	<v-form ref="form" @submit.prevent="save">
		<v-row>
			<v-col cols="2">
				<v-text-field label="Họ tên" v-model="SoYeuLyLich.HoTen" :rules="[rules.required]" readonly
					v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-account">
				</v-text-field>
			</v-col>
			<v-col cols="1">
				<v-select label="Giới tính" v-model="SoYeuLyLich.GioiTinh" :rules="[rules.required]"
					:items="['Nam', 'Nữ']" required prepend-inner-icon="mdi-gender-male-female"></v-select>
			</v-col>
			<v-col cols="3">
				<f-date label="Ngày sinh" outlined dense v-model="SoYeuLyLich.NgaySinh" :date-add="0" hide-details
					:rules="[rules.required]" />
			</v-col>
			<v-col cols="3">
				<v-text-field label="Đơn vị" v-model="SoYeuLyLich.DonVi" :rules="[rules.required]" readonly
					v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-domain">
				</v-text-field>
			</v-col>
			<v-col cols="3">
				<v-text-field label="Chức vụ" v-model="SoYeuLyLich.ChucVu" :rules="[rules.required]" required
					prepend-inner-icon="mdi-account-tie"></v-text-field>
			</v-col>
			<v-col cols="3">
				<v-select label="Học vị" v-model="SoYeuLyLich.HocVi" :rules="[rules.required]"
					:items="['Cử nhân', 'Kỹ sư', 'Thạc sĩ', 'Tiến sĩ', 'Giáo sư']" required
					prepend-inner-icon="mdi-school-outline"></v-select>
			</v-col>
			<v-col cols="3">
				<v-text-field label="Hướng nghiên cứu chính" v-model="SoYeuLyLich.HuongNghienCuuChinh"
					:rules="[rules.required]" required prepend-inner-icon="mdi-folder-search-outline"></v-text-field>
			</v-col>
			<v-col cols="3">
				<v-text-field type="tel" label="Điện thoại" v-model="SoYeuLyLich.DienThoai" :rules="[rules.phone]"
					required prepend-inner-icon="mdi-phone">
				</v-text-field>
			</v-col>
			<v-col cols="3">
				<v-text-field label="Email" v-model="SoYeuLyLich.Email" :rules="[rules.required]" readonly
					v-tooltip="'Trường này không thể chỉnh sửa!'" prepend-inner-icon="mdi-email">
				</v-text-field>
			</v-col>
		</v-row>
		<div class="d-flex justify-end mt-2">
			<v-btn @click="save" size="small" variant="flat" color="primary" append-icon="mdi-content-save">Lưu</v-btn>
		</div>
	</v-form>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
				rules: {
					required: value => !!value || 'Trường này là bắt buộc.',
					phone: v => /^0[0-9]{9}$/.test(v) || "Số điện thoại không hợp lệ",
				},
				SoYeuLyLich: vueData.userProfile[0][0] ?? {}
			}
		},
		mounted() {
			this.SoYeuLyLich.HoTen = this.vueData.user.LastName + ' ' + this.vueData.user.FirstName
			this.SoYeuLyLich.Email = this.vueData.user.Email
			this.SoYeuLyLich.DonVi = this.vueData.user.DepartmentID
		},
		computed: {},
		watch: {},
		methods: {
			async save() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					Vue.$toast.error('Vui lòng kiểm tra lại các thông tin đã nhập.', { position: "top" });
					return;
				}
	
				this.isLoading = true;
				try {
					const params = { ...this.SoYeuLyLich };
					await ajaxCALL('/HDKH_Profile_CaNhan_Save', params, res => {
						Vue.$toast.success(res.data[0].Message, { position: "top" });
						CALL("getUserProfile")
					})
				} catch (error) {
					console.log(error)
					Vue.$toast.error(error.message || 'Có lỗi xảy ra, vui lòng thử lại.', { position: "top" });
				} finally {
					this.isLoading = false;
				}
			}
		},
	}
</script>