<template>
	<v-dialog v-model="isShow" max-width="500px">
		<v-card>
			<v-form ref="formQR">
				<v-toolbar color="primary">
					<v-toolbar-title>{{ selectedCaBiet.SoSeries }}</v-toolbar-title>
					<v-btn size="small" icon="mdi-close" @click="closeDialog"></v-btn>
				</v-toolbar>
				<v-divider></v-divider>

				<v-card-text>

					<v-autocomplete v-model="selectedDiaDiem" label="Chọn địa điểm" :items="DSDiaDiem"
						item-title="TenDiaDiem" item-value="DiaDiem_Id" />

					<v-autocomplete class="my-2" style="min-width: 200px" v-model="maVach" placeholder="Mã vạch"
						:items="DsMaVach" item-value="MaVach" item-title="MaVach" density="compact" :clearable="false"
						hide-details>
					</v-autocomplete>

					<v-btn prepend-icon="mdi-qrcode-scan" variant="tonal" @click="showQrDialog = true">Quét mã
						QR</v-btn>
				</v-card-text>
				<v-divider></v-divider>

				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn variant="tonal" @click="updateMaVach()" color="primary">
						Cập nhật
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>

	<v-dialog :fullscreen="$vuetify.display.xs" v-model="showQrDialog" width="500" height="100%">
		<v-card>
			<v-toolbar color="primary">
				<v-toolbar-title>Quét mã</v-toolbar-title>
				<v-btn size="small" icon="mdi-close" @click="showQrDialog = false"></v-btn>
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

</template>

<script>
	export default {

	props: {
		isShow: Boolean,
		selectedCaBiet: Object,
		DSDiaDiem: Array,
	},

	emits: ['update:isShow', 'onReload'],

	data() {
		return {
			showQrDialog: false,
			maVach: null,
			thongTinMaVach: null,
			DsMaVach: [],

			selectedDiaDiem: null,
		}
	},

	mounted() {
	},

	watch: {
		isShow(val) {
			if (val) {
				this.maVach = this.selectedCaBiet.MaVach ?? null
				this.selectedDiaDiem = this.selectedCaBiet.DiaDiem_Id ?? null
				// console.log(this.selectedCaBiet)
			}
		},
		selectedDiaDiem(val) {
			if (val) {
				this.onLoadMaVach(val)
			}
		}
	},

	methods: {
		async onLoadMaVach(diaDiem_Id) {
			if (!this.selectedDiaDiem) {
				showToast.error('Chưa chọn địa điểm!');
				return
			}

			this.DsMaVach = await apiCallPromise("/work/TS_MaVach_Select", { DiaDiem_Id: diaDiem_Id })
		},

		updateMaVach() {
			if (!this.maVach) {
				showToast.error("Vui lòng chọn mã vạch trước khi gán!");
				return;
			}

			if (this.selectedDiaDiem !== this.selectedCaBiet.DiaDiem_Id) {
				showToast.error("Địa điểm đang chọn không trùng khớp!")
				return
			}

			const params = {
				MaVach: this.maVach,
				DiaDiem_Id: this.selectedDiaDiem,
				CaBiet_Id: this.selectedCaBiet.CaBiet_Id,
			}
			apiCall("work/TS_CaBiet_Update_Qr", params, (res) => {
				if (res) showToast.success(`Đã gán mã vạch ${this.maVach} cho tài sản ${this.selectedCaBiet.SoSeries}`);
				this.closeDialog()
				this.$emit('onReload', { CaBiet_Id: this.selectedCaBiet.CaBiet_Id, MaVach: this.maVach })
			})
		},

		closeDialog() {
			this.$emit('update:isShow', false)
			this.maVach = null
			this.selectedDiaDiem = null
		},
		getInfoByMaVach() {
			// showToast.success(this.thongTinMaVach)
			const data = JSON.parse(this.thongTinMaVach)
			this.selectedDiaDiem = Number(data.diaDiem)
			this.maVach = data.maVach

			this.showQrDialog = false
		},

	}

}
</script>