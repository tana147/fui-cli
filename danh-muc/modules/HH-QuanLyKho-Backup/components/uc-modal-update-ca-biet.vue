<template>
	<v-dialog v-model="isShow" width="800">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Cập nhật
					<div class="text-subtitle-2 ">
						Địa điểm hiện tại: {{ selectedCaBiet.TenDiaDiem }}
					</div>
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="pt-1">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="6" class="mt-1">
							<v-autocomplete color="primary" v-model="selectedCaBiet.KhuVuc_Id" density="compact"
								:items="DSKhuVucFilter" item-value="KhuVuc_Id" item-title="TenKhuVuc" label="Khu vực">
							</v-autocomplete>
						</v-col>
						<v-col cols="6" class="mt-1">
							<v-autocomplete color="primary" v-model="selectedCaBiet.TinhTrang" density="compact"
								:items="DSTinhTrangCaBiet" :rules="[rules.required]" item-value="value"
								item-title="title" label="Tình trạng">
							</v-autocomplete>
						</v-col>
						<v-col cols="12" class="mt-1">
							<v-text-field :clearable="false" v-model="selectedCaBiet.SoSeries" :rules="[rules.required]"
								label="Số Series">
							</v-text-field>
						</v-col>
						<v-col cols="6" class="mt-1">
							<uc-input-price v-model="selectedCaBiet.NguyenGia" :rules="[rules.required]"
								label="Nguyên giá"></uc-input-price>
						</v-col>
						<v-col cols="6" class="mt-1">
							<v-text-field :clearable="false" type="number" v-model="selectedCaBiet.ThoiGianKhauHao"
								:rules="[rules.required]" label="Thời gian khấu hao" suffix="Tháng">
							</v-text-field>
						</v-col>
						<v-col cols="12" :md="4" class="mt-1">
							<uc-date-picker label="Ngày bắt đầu sử dụng" v-model="selectedCaBiet.NgayBatDauSuDung"
								:rules="[rules.required]"></uc-date-picker>
						</v-col>
						<v-col cols="12" :md="4" class="mt-1">
							<uc-date-picker label="Ngày bắt đầu bảo hành" v-model="selectedCaBiet.NgayBatDauBaoHanh"
								:rules="[rules.required]" :max="selectedCaBiet.NgayKetThucBaoHanh"></uc-date-picker>
						</v-col>
						<v-col cols="12" :md="4" class="mt-1">
							<uc-date-picker v-model="selectedCaBiet.NgayKetThucBaoHanh" label="Ngày kết thúc bảo hành"
								:rules="[rules.required]" :min="selectedCaBiet.NgayBatDauBaoHanh"></uc-date-picker>
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="tonal" @click="onSubmit">Cập nhật</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		selectedCaBiet: Object,
		DSKhuVuc: Array,
	},

	emits: ['update:isShow', 'onReload'],

	data() {
		return {
			DSTinhTrangCaBiet,
			rules: {
				required: (value) => !!value || 'Trường này không được để trống',
			},
		}
	},
	computed: {
		DSKhuVucFilter() {
			let res = this.DSKhuVuc.filter((KhuVuc) => KhuVuc.DiaDiem_Id === this.selectedCaBiet.DiaDiem_Id)
			return [
				{ KhuVuc_Id: 0, TenKhuVuc: 'Kho' },
				...res
			]
		}

	},
	watch: {},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
				return
			}
			const params = {
				CaBiet_Id: this.selectedCaBiet.CaBiet_Id,
				KhuVuc_Id: this.selectedCaBiet.KhuVuc_Id,
				SoSeries: this.selectedCaBiet.SoSeries,
				NguyenGia: this.selectedCaBiet.NguyenGia,
				TinhTrang: this.selectedCaBiet.TinhTrang,
				ThoiGianKhauHao: this.selectedCaBiet.ThoiGianKhauHao,
				NgayBatDauSuDung: this.selectedCaBiet.NgayBatDauSuDung,
				NgayBatDauBaoHanh: this.selectedCaBiet.NgayBatDauBaoHanh,
				NgayKetThucBaoHanh: this.selectedCaBiet.NgayKetThucBaoHanh,
			}
			apiCall("work/TS_CaBiet_Update", params, (res) => {
				if (res) showToast.success("Thành công");
				this.$emit('onReload', params)
				this.closeDialog()
			})
		}
	},
}
</script>