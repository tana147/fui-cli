<template>
	<v-dialog v-model="vueData.isOpenDialogChietKhau" scrollable width="600">
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>Thiết lập chiết khấu - {{ vueData.rowSelectedObject.TenCuaHang }}</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="vueData.isOpenDialogChietKhau = false"><v-icon>mdi-close</v-icon></v-btn>
			</v-toolbar>
			<v-card-text>
				<v-row>
					<v-col cols="6">
						<v-select v-model="vueData.rowSelectedObject.NganHang_ChietKhauID" label="Ngân hàng"
							:items="vueData.DSNganHangChietKhau" item-text="TenHienThi"
							item-value="NganHang_ChietKhauID" outlined dense hide-details></v-select>
					</v-col>
					<v-col cols="6">
						<v-text-field type="number" v-model="vueData.rowSelectedObject.ChietKhau_GRAB" label="GRAB"
							outlined dense suffix="%" step="0.01"
							@blur="vueData.rowSelectedObject.ChietKhau_GRAB = format2(vueData.rowSelectedObject.ChietKhau_GRAB)"
							hide-details></v-text-field>
					</v-col>
					<v-col cols="6">
						<v-text-field type="number" v-model="vueData.rowSelectedObject.ChietKhau_SPF" label="SPF"
							outlined dense suffix="%" step="0.01"
							@blur="vueData.rowSelectedObject.ChietKhau_SPF = format2(vueData.rowSelectedObject.ChietKhau_SPF)"
							hide-details></v-text-field>
					</v-col>
					<v-col cols="6">
						<v-text-field type="number" v-model="vueData.rowSelectedObject.ChietKhau_XSM" label="XSM"
							outlined dense suffix="%" step="0.01"
							@blur="vueData.rowSelectedObject.ChietKhau_XSM = format2(vueData.rowSelectedObject.ChietKhau_XSM)"
							hide-details></v-text-field>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn text color="primary" @click="onSubmit">Lưu</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>
<script>
export default {
	data() {
		return {
			vueData,
		}
	},
	methods: {
		format2(value) {
			if (value === '' || value === null) return value
			return Number(parseFloat(value).toFixed(2))
		},
		onSubmit() {
			const params = {
				CuaHangID: vueData.rowSelectedObject.CuaHangID,
				ChietKhau_GRAB: vueData.rowSelectedObject.ChietKhau_GRAB,
				ChietKhau_XSM: vueData.rowSelectedObject.ChietKhau_XSM,
				ChietKhau_SPF: vueData.rowSelectedObject.ChietKhau_SPF,
				NganHang_ChietKhauID: vueData.rowSelectedObject.NganHang_ChietKhauID
			}

			confirm({
				title: `<b>Xác nhận</b>`,
				message: `Cập nhật chiết khấu cho <b>${vueData.rowSelectedObject.TenCuaHang} </b>`,
				action: function () {
					ajaxCALL("/eorder/CuaHang_Update_ChietKhau", params, (res) => {
						showToast({ type: "green", title: "Cập nhật chiết khấu của cửa hàng thành công!" })
						vueData.isOpenDialogChietKhau = false
						runAction(vueData.getCuaHang)
					})
				},
			})
		},
	},
	watch: {

	},
	computed: {},

}
</script>