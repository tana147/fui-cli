<template>
	<v-dialog v-model="isShowDialogDongBoDuLieu" max-width="500px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title>
					Đồng bộ dữ liệu
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text class="d-flex flex-column">
				<b class="font-weight-bold">
					Tên cửa hàng: <span class="success--text">{{ cuaHang?.TenCuaHang }}</span>
				</b>
				<span class=" font-weight-bold">
					Ngày: {{ moment(ca?.NgayDoiSoat).format("DD/MM/YYYY") }}
				</span>
				<v-select class="mt-2" label="Ca làm việc" outlined dense v-model="CaLamViec" :items="DsCaLamViec"
					hide-details item-value="value" item-text="text">
				</v-select>

				<span class="primary--text font-weight-bold mt-2">Tuỳ chọn đồng bộ</span>
				<v-checkbox input-value="true" value label="Đồng bộ hệ thống" readonly="true" hide-details
					dense></v-checkbox>
				<v-checkbox v-model="isDongBoKetCa" label="Đồng bộ kết ca" hide-details dense></v-checkbox>
				<v-checkbox v-model="isDongBoChietKhau" label="Đồng bộ chiết khấu" hide-details dense></v-checkbox>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" text @click="onSubmit">
					Đồng bộ
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShowDialogDongBoDuLieu: Boolean,
		ca: Object,
		cuaHang: Object
	},
	data() {
		return {
			vueData,
			caMap: {
				'1': 'Sáng',
				'2': 'Tối',
				'3': 'Đêm'
			},
			isDongBoKetCa: false,
			CaLamViec: null,
			isDongBoChietKhau: false,
		}
	},
	mounted() {
	},
	computed: {
		DsCaLamViec: function () {
			let ds = []
			this.cuaHang?.Ca.map((item) => {
				ds.push(
					{ value: item.Ca, text: this.caMap[item.Ca] }
				)
			})
			return [{ value: 'ALL', text: 'Tất cả' }, ...ds];
		}

	},
	watch: {},
	methods: {
		closeDialog() {
			this.$emit('update:isShowDialogDongBoDuLieu', false)
			this.isDongBoKetCa = false
			this.isDongBoChietKhau = false
			this.CaLamViec = null
		},
		async onSubmit() {
			if (this.CaLamViec === null) {
				Vue.$toast.warning("Bạn chưa chọn ca làm việc", { position: "top" });
				return
			}
			const ca = this.cuaHang.Ca.find((item) => item.Ca === this.CaLamViec)
			const params = {
				DoiSoatID: ca?.DoiSoatID ?? 0,
				CuaHangID: this.cuaHang?.CuaHangID,
				NgayDoiSoat: this.ca?.NgayDoiSoat,
				Is_DongBoKetCa: this.isDongBoKetCa,
				Is_DongBoChietKhau: this.isDongBoChietKhau
			}
			const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_DongBo', params)
			if (data)
				Vue.$toast.success("Thành công", { position: "top" });
			else
				Vue.$toast.error("Thất bại", { position: "top" });
			this.closeDialog()
		}
	},
}
</script>