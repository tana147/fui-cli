<template>
	<v-dialog v-model="vueData.IsShowDialogBankDetail" persistent width="600">
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>
					<b class="primary--text ml-1">{{ vueData.CTHoaDon?.MaSoHoaDon }} • {{ vueData.CTHoaDon?.NgayThemMoi
						}} {{ vueData.CTHoaDon?.GioThemMoi }} • {{ vueData.CTHoaDon?.NhanVienThemMoi }} • {{
						vueData.CTHoaDon?.HoaDonID }}</b>
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="vueData.IsShowDialogBankDetail = false"><v-icon>mdi-close</v-icon></v-btn>
			</v-toolbar>
			<v-card-text>
				<v-row dense>
					<v-col cols="12">
						<span class=" font-weight-bold">
							Tên ngân hàng: {{ vueData.CTBank?.BankName }}
						</span>
					</v-col>
					<v-col cols="12">
						<span class=" font-weight-bold">
							Thông tin hoá đơn: {{ vueData.CTBank?.OrderInfo }}
						</span>
					</v-col>
					<v-col cols="12">
						<span class=" font-weight-bold">
							Số tiền: {{ Number(vueData.CTBank.Amount)?.toLocaleString("vi-vn") }}
						</span>
					</v-col>
					<v-col cols="12">
						<span class=" font-weight-bold">
							Thời gian: {{ moment(vueData.CTBank.CreateTime)?.format('DD/MM/YYYY HH:mm:ss') }}
						</span>
					</v-col>
				</v-row>
			</v-card-text>
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
	    mounted() { },
	    computed: {},
	    watch: {
	
	    },
	    methods: {
	
	    },
	}
</script>