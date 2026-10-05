<template>
	<v-dialog v-model="isShowDialogCapNhatChietKhau" max-width="800px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title>
					Cập nhật chiết khấu cho cửa hàng
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

				<v-row class="pt-2">
					<v-col cols="6">
						<v-select label="Ca làm việc" outlined dense v-model="CaLamViec" :items="DsCaLamViec"
							hide-details item-value="value" item-text="text">
						</v-select>
					</v-col>
				</v-row>

				<v-form class="mt-2" ref="form" v-model='valid' :disabled="CaLamViec === null ? true : false">
					<span class="primary--text font-weight-bold">Ngân hàng quẹt thẻ</span>
					<v-row class="mt-1 mb-1">
						<v-col cols="6">
							<v-select v-model="form.QT_ChietKhau_NganHangID" :items="DsNganHangChietKhau"
								item-text="TenHienThi" item-value="NganHang_ChietKhauID" outlined dense hide-details>
							</v-select>
						</v-col>
					</v-row>

					<span class="primary--text font-weight-bold">Shoppe Food</span>
					<v-row class="mt-1 mb-1">
						<v-col cols="4">
							<v-text-field v-model="form.SPF_ChietKhau_PhanTram" label="Chiết khấu phần trăm" outlined
								dense suffix="%" hide-details @keypress="onlyNumber"
								@blur="form.SPF_ChietKhau_PhanTram = format2(form.SPF_ChietKhau_PhanTram)"></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="form.SPF_ChietKhau_PhanTram_Khac" label="Chiết khấu phần trăm khác"
								outlined dense suffix="%" hide-details step="0.01"></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field type="number" v-model="form.SPF_ChietKhau_TienMat_Khac"
								:disabled="CaLamViec === 'ALL' || CaLamViec === null" label=" Chiết khấu tiền mặt khác"
								outlined dense hide-details></v-text-field>
						</v-col>
					</v-row>

					<span class="primary--text font-weight-bold ">Grab</span>
					<v-row class="mt-1 mb-1">
						<v-col cols="4">
							<v-text-field v-model="form.GRAB_ChietKhau_PhanTram" label="Chiết khấu phần trăm" outlined
								@keypress="onlyNumber" dense suffix="%" hide-details step="0.01"
								@blur="form.GRAB_ChietKhau_PhanTram = format2(form.GRAB_ChietKhau_PhanTram)"></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="form.GRAB_ChietKhau_PhanTram_Khac" step="0.01" @keypress="onlyNumber"
								label="Chiết khấu phần trăm khác" outlined dense suffix="%"
								@blur="form.GRAB_ChietKhau_PhanTram_Khac = format2(form.GRAB_ChietKhau_PhanTram_Khac)"
								hide-details></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field type="number" v-model="form.GRAB_ChietKhau_TienMat_Khac"
								:disabled="CaLamViec === 'ALL' || CaLamViec === null" label="Chiết khấu tiền mặt khác"
								outlined dense hide-details></v-text-field>
						</v-col>
					</v-row>

					<span class="primary--text font-weight-bold ">Xanh SM</span>
					<v-row class="mt-1">
						<v-col cols="4">
							<v-text-field v-model="form.XSM_ChietKhau_PhanTram" label="Chiết khấu phần trăm" outlined
								@keypress="onlyNumber" dense suffix="%" hide-details step="0.01"
								@blur="form.XSM_ChietKhau_PhanTram = format2(form.XSM_ChietKhau_PhanTram)"></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="form.XSM_ChietKhau_PhanTram_Khac" step="0.01" @keypress="onlyNumber"
								label="Chiết khấu phần trăm khác" outlined dense suffix="%"
								@blur="form.XSM_ChietKhau_PhanTram_Khac = format2(form.XSM_ChietKhau_PhanTram_Khac)"
								hide-details></v-text-field>
						</v-col>

						<v-col cols="4">
							<v-text-field type="number" v-model="form.XSM_ChietKhau_TienMat_Khac"
								:disabled="CaLamViec === 'ALL' || CaLamViec === null" label="Chiết khấu tiền mặt khác"
								outlined dense hide-details></v-text-field>
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" text @click="onSubmit">
					Cập nhật
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShowDialogCapNhatChietKhau: Boolean,
		ca: Object,
		cuaHang: Object,
		loadData: Function,
	},
	data() {
		return {
			vueData,
			CaLamViec: null,
			caMap: {
				'': 'Tất cả',
				'1': 'Sáng',
				'2': 'Tối',
				'3': 'Đêm'
			},
			form: {},
			valid: true,
			DsNganHangChietKhau: [],
		}
	},
	async mounted() {
		const dsNganHang = await this.vueData.ajaxCALLPromise('/eorder/NganHangChietKhau_Select', {})
		this.DsNganHangChietKhau = dsNganHang

	},
	computed: {
		DsCaLamViec: function () {
			let ds = []
			this.cuaHang?.Ca.map((item) => {
				ds.push(
					{ value: item.Ca, text: this.caMap[item.Ca] }
				)
			})
			// return ds
			return [{ value: 'ALL', text: 'Tất cả' }, ...ds];
		}
	},
	watch: {
		CaLamViec: function (val) {
			console.log(val)
			const ca = this.cuaHang.Ca.find((item) => item.Ca === this.CaLamViec)

			this.form.QT_ChietKhau_NganHangID = ca?.QT_ChietKhau_NganHangID ?? this.cuaHang.Ca[0].QT_ChietKhau_NganHangID

			this.form.SPF_ChietKhau_PhanTram = ca?.SPF_ChietKhau_PhanTram ?? this.cuaHang.Ca[0].SPF_ChietKhau_PhanTram
			this.form.SPF_ChietKhau_PhanTram_Khac = ca?.SPF_ChietKhau_PhanTram_Khac ?? this.cuaHang.Ca[0].SPF_ChietKhau_PhanTram_Khac
			this.form.SPF_ChietKhau_TienMat_Khac = ca?.SPF_ChietKhau_TienMat_Khac ?? this.cuaHang.Ca[0].SPF_ChietKhau_TienMat_Khac

			this.form.GRAB_ChietKhau_PhanTram = ca?.GRAB_ChietKhau_PhanTram ?? this.cuaHang.Ca[0].GRAB_ChietKhau_PhanTram
			this.form.GRAB_ChietKhau_PhanTram_Khac = ca?.GRAB_ChietKhau_PhanTram_Khac ?? this.cuaHang.Ca[0].GRAB_ChietKhau_PhanTram_Khac
			this.form.GRAB_ChietKhau_TienMat_Khac = ca?.GRAB_ChietKhau_TienMat_Khac ?? this.cuaHang.Ca[0].GRAB_ChietKhau_TienMat_Khac

			this.form.XSM_ChietKhau_PhanTram = ca?.XSM_ChietKhau_PhanTram ?? this.cuaHang.Ca[0].XSM_ChietKhau_PhanTram
			this.form.XSM_ChietKhau_PhanTram_Khac = ca?.XSM_ChietKhau_PhanTram_Khac ?? this.cuaHang.Ca[0].XSM_ChietKhau_PhanTram_Khac
			this.form.XSM_ChietKhau_TienMat_Khac = ca?.XSM_ChietKhau_TienMat_Khac ?? this.cuaHang.Ca[0].XSM_ChietKhau_TienMat_Khac
		},
	},
	methods: {
		onlyNumber(e) {
			if (!/[0-9.]/.test(e.key)) e.preventDefault();
		},
		format2(value) {
			if (value === '' || value === null) return value
			return Number(parseFloat(value).toFixed(2))
		},
		closeDialog() {
			this.$emit('update:isShowDialogCapNhatChietKhau', false)
			this.CaLamViec = null
			this.form = {}
			this.$refs.form.reset()
			this.$refs.form.resetValidation()
		},
		async onSubmit() {
			if (this.CaLamViec === null) {
				Vue.$toast.warning("Bạn chưa chọn ca làm việc", { position: "top" });
				return
			}
			this.$refs.form.validate()
			if (this.valid) {
				const ca = this.cuaHang.Ca.find((item) => item.Ca === this.CaLamViec)
				const params = {
					DoiSoatID: ca?.DoiSoatID ?? 0,
					QT_ChietKhau_NganHangID: this.form.QT_ChietKhau_NganHangID,
					SPF_ChietKhau_PhanTram: this.form.SPF_ChietKhau_PhanTram,
					SPF_ChietKhau_PhanTram_Khac: this.form.SPF_ChietKhau_PhanTram_Khac,
					SPF_ChietKhau_TienMat_Khac: this.form.SPF_ChietKhau_TienMat_Khac,
					GRAB_ChietKhau_PhanTram: this.form.GRAB_ChietKhau_PhanTram,
					GRAB_ChietKhau_PhanTram_Khac: this.form.GRAB_ChietKhau_PhanTram_Khac,
					GRAB_ChietKhau_TienMat_Khac: this.form.GRAB_ChietKhau_TienMat_Khac,
					XSM_ChietKhau_PhanTram: this.form.XSM_ChietKhau_PhanTram,
					XSM_ChietKhau_PhanTram_Khac: this.form.XSM_ChietKhau_PhanTram_Khac,
					XSM_ChietKhau_TienMat_Khac: this.form.XSM_ChietKhau_TienMat_Khac,
					CuaHangID: this.cuaHang?.CuaHangID,
					NgayDoiSoat: this.ca?.NgayDoiSoat,
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Update_ChietKhau', params)
				if (data)
					Vue.$toast.success("Thành công", { position: "top" });
				else
					Vue.$toast.error("Thất bại", { position: "top" });
				this.loadData()
				this.closeDialog()
			}
		}
	},
}
</script>