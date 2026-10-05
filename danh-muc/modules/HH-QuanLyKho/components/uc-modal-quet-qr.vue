<template>
	<v-dialog :fullscreen="$vuetify.display.xs" v-model="isShow" width="500" height="100%">
		<v-card>
			<v-toolbar color="primary">
				<v-toolbar-title>Quét mã</v-toolbar-title>
				<v-btn size="small" icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-card-text :style="{ padding: '0', aspectRatio: 1 / 1, width: '100%' }">
				<uc-qr v-model="thongTinMaVach" @scan-success="getInfoByMaVach" ref="qrScanner">
					<template v-slot:default>
						<v-row class="mt-2">
							<v-col class="px-0" cols="4" style="text-align: right;"></v-col>

							<v-col class="px-0" cols="4" style="text-align: center;">
								<v-btn icon variant="flat" color="primary"
									@click="this.$refs.qrScanner?.triggerFileInput();">
									<v-icon color="white">mdi-image</v-icon>
								</v-btn>
								<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư viện</div>
							</v-col>

							<v-col class="px-0" cols="4" style="text-align: left;"></v-col>
						</v-row>
					</template>
				</uc-qr>
			</v-card-text>
		</v-card>
	</v-dialog>

	<uc-modal-view-tai-san v-model:isShow="isOpenViewTaiSan" :thongTinTaiSan="thongTinTaiSan"
		@closeQuetQRDialog="closeDialog"></uc-modal-view-tai-san>
</template>

<script>
	export default {
		props:
		{
			isShow: Boolean,
		},

		emits: ['update:isShow'],

		data() {
			return {
				thongTinMaVach: null,
				thongTinTaiSan: {},
	
				isOpenViewTaiSan: false,
			}
		},
		methods: {
			closeDialog() {
				this.$emit('update:isShow', false)
			},
			async getInfoByMaVach() {
				let data
				try {
					data = JSON.parse(this.thongTinMaVach)
				} catch (e) {
					showToast.error("QR không đúng định dạng")
					return
				}
	
				if (!data.maVach || !data.diaDiem) {
					showToast.error("QR thiếu thông tin")
					return
				}
	
				const diaDiemId = Number(data.diaDiem)
	
				if (isNaN(diaDiemId)) {
					showToast.error("Địa điểm không hợp lệ")
					return
				}
	
				apiCall(
					"/work/TS_CaBiet_Select_By_Qr",
					{ MaVach: data.maVach, DiaDiem_Id: Number(data.diaDiem) },
					(res) => {
						const asset = res.data?.[0]
	
						if (!asset) {
							showToast.error('Mã QR này chưa được gán vào tài sản!')
							return
						}
	
						this.thongTinTaiSan = asset
						this.isShow = false
						this.isOpenViewTaiSan = true
					},
					(error) => {
						showToast.error(error.responseJSON?.Message || "Lỗi hệ thống")
					}
				)
			}
	
		},
	}
</script>