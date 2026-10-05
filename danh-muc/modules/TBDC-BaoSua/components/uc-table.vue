<template>
	<div class=" border-t" :style="isMobile ? { paddingTop: '52px !important' } : {}">
	</div>
		<v-row align="center" justify="center" class='mt-2'>
			<v-col cols="12" sm="6" lg="3" md="4" class="pa-0">
				<v-card v-if="!isSuccess" class="pa-4"
					:style="{ width: '100%', borderRadius: '8px', background: '#fff' }">
					<v-card-text class="pa-0">
						<div @click="openDialogQuetQR"
							:style="{ background: '#e0e0e0', padding: '20px', textAlign: 'center', borderRadius: '8px' }">
							<v-icon size="40" color="grey darken-2">mdi-qrcode-scan</v-icon>
							<span class="text-body-2 " :style="{ display: 'block', color: '#757575' }">
								Quét mã tài sản
							</span>
						</div>
						<div class="d-flex align-center ma-2">
							<v-divider></v-divider>
							<span class="px-2" :style="{ fontSize: '14px', whiteSpace: 'nowrap' }">Hoặc</span>
							<v-divider></v-divider>
						</div>

						<v-form ref="form">
							<v-row dense>
								<v-col cols="12">
									<v-text-field v-model="maVach" style="background-color:white;" color="primary"
										:clearable="false" label="Mã tài sản (nếu có)">
									</v-text-field>
								</v-col>

								<v-col cols="12" class="mt-2">
									<v-autocomplete v-model="item.DiaDiem_Id" density="compact"
										:rules="[rules.required]" :items="DSDiaDiem" item-value="DiaDiem_Id"
										item-title="TenDiaDiem" label="Địa điểm">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" class="mt-2">
									<v-autocomplete v-model="item.CaBiet_Id" density="compact" :rules="[rules.required]"
										:items="DSCaBiet" item-value="CaBiet_Id" item-title="SoSeries" label="Tài sản">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" class="mt-2">
									<v-select v-model="item.DoUuTien" density="compact" :rules="[rules.required]"
										:items="DSDoUuTien" item-value="value" item-title="title" label="Độ ưu tiên">
									</v-select>
								</v-col>

								<v-col cols="12" class="mt-2">
									<v-textarea rows="3" v-model="item.GhiChu" :rules="[rules.required]" color="primary"
										label="* Mô tả lỗi " outlined dense>
									</v-textarea>
								</v-col>
								<v-col cols="12" class="mt-2">
									<uc-image-upload v-model="item.Files" />
								</v-col>
							</v-row>
						</v-form>
						<div class="d-flex justify-end">
							<!-- <uc-lich-su-bao-sua class-for-btn="mt-4 mr-2"></uc-lich-su-bao-sua> -->
							<v-btn color="primary" @click="onSubmit" variant="outlined" class="mt-4">
								Gửi báo sửa
							</v-btn>
						</div>
					</v-card-text>
				</v-card>

				<v-card v-else max-width="700">
					<v-card-text class="text-center">
						<v-icon size="72" color="success" class="mb-4">mdi-check-circle</v-icon>
						<h2 class="text-h5 font-weight-medium mb-2">Cảm ơn bạn đã gửi phản hồi!</h2>
						<div class="text-body-2 mb-6">
							Phản hồi của bạn đã được ghi nhận. Kỹ thuật sẽ tiếp nhận và xử lý trong thời gian sớm nhất.
						</div>
					</v-card-text>
					<template v-slot:actions>
						<v-spacer></v-spacer>
						<v-btn @click="closeCard" color="primary" variant="flat" class="mr-2">
							Trở về
						</v-btn>
					</template>
				</v-card>
			</v-col>
		</v-row>
	<!-- QR -->
	<v-dialog :fullscreen="isMobile" v-model="isShowDialogQuetQR" width="500" height="100%">
		<v-card>
			<v-toolbar>
				<v-toolbar-title class="text-center text-primary">Quét mã</v-toolbar-title>
				<v-btn icon="mdi-close" @click="closeDialogQuetQR"></v-btn>
			</v-toolbar>
			<v-card-text :style="{ padding: '0', aspectRatio: 1 / 1, width: '100%' }">
				<uc-qr v-model="thongTinMaVach" @scan-success="getInfoByMaVach" ref="qrScanner">
					<template #default>
						<v-row class="mt-2">
							<v-col class="px-0" cols="4"></v-col>
							<v-col class="px-0" cols="4" style="text-align: center;">
								<v-btn icon variant="flat" color="primary" @click="$refs.qrScanner?.triggerFileInput()">
									<v-icon color="white">mdi-image</v-icon>
								</v-btn>
								<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư
									viện
								</div>
							</v-col>
							<v-col class="px-0" cols="4"></v-col>
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
		DSDiaDiem: Array,
	},
	data() {
		return {
			rules: {
				required: (value) => !!value || 'Trường này không được để trống',
			},
			isShowDialogQuetQR: false,

			isSuccess: false,

			DSDoUuTien: [
				{ title: "#1 - Bình thường", value: 'BINH_THUONG' },
				{ title: "#2 - Trung bình", value: 'TRUNG_BINH' },
				{ title: "#3 - Cao", value: 'UU_TIEN' },
				{ title: "#4 - Khẩn cấp", value: 'KHAN_CAP' },
			],
			maVach: null,
			thongTinMaVach: null,
			DSCaBiet: [],
			item: {
				DiaDiem_Id: null,
				CaBiet_Id: null,
				DoUuTien: null,
				GhiChu: null,
				Files: [],
			},

		};
	},
	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},

	async mounted() {
	},
	watch: {
		'item.DiaDiem_Id': async function (value) {
			if (value === null || value === undefined) return
			const data = await apiCallPromise('work/TS_CaBiet_Select_By_DiaDiem_Id', { DiaDiem_Id: value })
			this.DSCaBiet = data
		}
	},
	methods: {
		closeDialogQuetQR() {
			this.isShowDialogQuetQR = false
		},

		openDialogQuetQR() {
			console.log('quet QR');
			this.isShowDialogQuetQR = true
		},

		closeCard() {
			this.isSuccess = false
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.maVach = null
			this.DSCaBiet = []
			this.item = {
				DiaDiem_Id: null,
				CaBiet_Id: null,
				DoUuTien: null,
				GhiChu: null,
				Files: [],
			}
		},

		getInfoByMaVach() {
			const data = JSON.parse(this.thongTinMaVach)

			apiCall(
				"work/TS_CaBiet_Select_By_Qr",
				{ MaVach: data.maVach, DiaDiem_Id: Number(data.diaDiem) },
				(res) => {
					const asset = res.data?.[0]

					if (!asset) {
						showToast.error('Mã QR này chưa được gán vào tài sản!')
						return
					}

					this.maVach = asset.MaVach ?? null
					this.item.DiaDiem_Id = asset.DiaDiem_Id ?? null
					this.item.CaBiet_Id = asset.CaBiet_Id ?? null
					this.item.DoUuTien = asset.DoUuTien ?? null

					this.closeDialogQuetQR()
				},
				(error) => {
					showToast.error(error.responseJSON?.Message || "Lỗi hệ thống")
				}
			)
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate()
			if (!valid) return showToast.info('Thông tin chưa đầy đủ')
			const res = await apiFile.insertAndUpdate(
				{
					file: this.item.Files,
					List_FileID: ''
				},
				{
					maxFileSize: 2, // MB 
					showToast: true,
					validateFileSize: true
				})
			if (!res.isSuccess) return
			const DSFiles = res.data
			let filesID = DSFiles.map(File => File.FileID).join(',')

			const params = {
				DiaDiem_Id: this.item.DiaDiem_Id,
				CaBiet_Id: this.item.CaBiet_Id,
				DoUuTien: this.item.DoUuTien,
				GhiChu: this.item.GhiChu,
				FilesID: filesID,
			}
			const $this = this
			apiCall("work/TS_BaoSua_Insert", params, (res) => {
				if (res) {
					showToast.success("Thành công");
					$this.isSuccess = true
				}
			})
		}
	}
}
</script>