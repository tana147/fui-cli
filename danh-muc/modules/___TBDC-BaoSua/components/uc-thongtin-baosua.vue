<template>
	<v-card class="pa-1 mb-1 round"
		style="border-radius: 12px;border-width: 0.1px; box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px;" outlined
		@click="onClick">

		<v-card-title class="text-caption">
			<v-row>
				<v-col cols="5" class="text-grey-darken-1" align-self="center">
					<v-icon size="small" class="">mdi-map-marker-radius-outline</v-icon>
					{{ item.TenViTriPhong }}
				</v-col>
				<v-col class="px-0 d-flex align-center justify-end" align-self="end">
					<v-chip size="x-small" :color="statusToColor(item.MaTinhTrang)" tonal>
						{{ item.TenTinhTrang }}
					</v-chip>
					<v-btn class="ml-1" v-if="item.MaTinhTrang < 2" variant="text" @click.stop="deleteBaoSua"
						color="red" size="x-small" icon="mdi-delete"></v-btn>
				</v-col>
			</v-row>
		</v-card-title>


		<v-card-text class="text-subtitle-2 text-grey-darken-1 pb-0  align-center">
			<v-row>
				<v-col cols="2" style="max-width: 30px">
					<v-avatar style="border: 1px solid #e0b44b " size="25" class="mr-2">
						<v-img sizes="25" small :src="avatar">
						</v-img>
					</v-avatar>
				</v-col>
				<v-col>
					<div class="d-flex align-center text-grey-darken-1" style="font-size: 14px; margin-top: -5px">
						<span class="text-caption">{{ user }}</span>
					</div>
					<div class="d-flex align-center text-grey-darken-1 mt-0" style="font-size: 14px;">
						<span style="margin-top: -3px; font-size: 11px;">{{ formatTime(item.TGBaoSua) }}</span>
					</div>

				</v-col>
			</v-row>
			<span class="mt-1" style="font-size: 14px; white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
			max-width: 100%;
			display: inline-block;">
				<span class="font-weight-medium">Mô tả: </span> {{ item.GhiChu }}
			</span>

		</v-card-text>

		<v-card-title class="text-caption">
			<v-row>
				<v-col class="pt-1" cols="9" align-self="start" style="display: flex; justify-content: flex-start;">
					<div class="align-center text-grey-darken-1" style="font-size: 14px; white-space: nowrap;
				      overflow: hidden;
				      text-overflow: ellipsis;
				      max-width: 100%;
				      display: inline-block;">
						<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->
						<span class="text-caption">{{ item.TenTaiSan }}</span>
					</div>
				</v-col>
				<v-col cols="3" align-self="center" class="text-grey-lighten-1 pt-1 text-end">
					ID: {{ item.MaBaoSua }}
				</v-col>
			</v-row>
		</v-card-title>

		<v-dialog fullscreen v-model="dialogTiepNhan">
			<v-card>
				<v-toolbar>
					<v-toolbar-title>
						<v-icon size="small" class="">mdi-map-marker-radius-outline</v-icon>
						{{ item.TenViTriPhong }}
					</v-toolbar-title>
					<v-chip size="x-small" :color="statusToColor(item.MaTinhTrang)" tonal class="mr-1">
						{{ item.TenTinhTrang }}
					</v-chip>
					<v-btn icon="mdi-close" @click="closeDialogTiepNhan"></v-btn>
				</v-toolbar>
				<v-card-text class="px-3">
					<v-form ref="formSua">
						<v-row>
							<v-col cols="4" :max-width="100" class="text-center pb-0">
								<v-card v-if="item.MaTinhTrang > 1" flat style="border: 1px dashed #9e9e9e !important;">
									<v-card-text class="pa-1">
										<v-img ref="zoomImage"
											:src="image != '' ? 'data:image/png;base64,' + image : ''" aspect-ratio="1"
											height="100%" cover>
											<template v-slot:placeholder v-if="isLoadingHinhAnh">
												<div class="d-flex align-center justify-center fill-height">
													<v-progress-circular color="grey-lighten-4"
														indeterminate></v-progress-circular>
												</div>
											</template>
										</v-img>
									</v-card-text>
								</v-card>
								<uc-hinhanh v-if="item.MaTinhTrang < 2" v-model="image" :lazy="item.KiemTraHinhAnh"
									:label="false" classs="pr-1 pt-1"></uc-hinhanh>
							</v-col>
							<v-col class="pl-0 pb-0">
								<v-row>
									<v-col class="pb-0">
										<span class="text-body-2 text-grey">Mã tài sản: </span>
										<span class="text-body-1 font-weight-medium">{{ item.MaVach }}</span>
										<!-- <v-icon v-if="!editMaVach" @click="updateMaVach">
											mdi-square-edit-outline</v-icon>
										<v-text-field :rules="[v => v != null || 'Vui lòng chọn nhân viên']" reqired
											@input="inputMaVach" inputmode="numeric" v-if="editMaVach" ref="txtMaVach"
											type="number" v-model="maVach" :clearable="false" class="mb-3"
											@keyup.enter="updateMaVach" @blur="updateMaVach">
										</v-text-field> -->
									</v-col>
									<v-divider></v-divider>
								</v-row>
								<v-row>
									<v-col class="pb-0">
										<span class="text-body-2 text-grey">Cơ sở:</span>
										<span class="text-body-1 font-weight-medium">{{ item.TenCoSo }}</span>
										<!-- <v-icon v-if="!editCoSo" @click='updateCoSo'>
											mdi-square-edit-outline</v-icon>
										<v-select :loading="isLoadingCoSo"
											:rules="[v => v != null || 'Vui lòng chọn nhân viên']" reqired ref="slCoSo"
											v-if="editCoSo" :clearable="false" class="text-body-1 font-weight-medium"
											v-model="tenCoSo" :items="dsCoSo" item-title="ToaNha" item-value="MaToaNha"
											return-object menu-icon="" @keyup.enter="updateCoSo" @blur="updateCoSo">
											<template #append-inner>
												<v-icon @click='updateCoSo'>mdi-check-underline</v-icon>
											</template>
										</v-select> -->
									</v-col>
									<v-divider></v-divider>
								</v-row>
								<v-row>
									<v-col class="pb-0">
										<span class="text-body-2 text-grey">Vị trí phòng:</span>
										<span class="text-body-1 font-weight-medium">{{ item.TenViTriPhong }}</span>
										<!-- <v-icon v-if="!editViTriPhong" @click='updateViTriPhong'>
											mdi-square-edit-outline</v-icon>
										<v-autocomplete :loading="isLoadingPhong"
											:rules="[v => v != null || 'Vui lòng chọn nhân viên']" reqired
											ref="cbbViTriPhong" v-if="editViTriPhong" :clearable="false"
											class="text-body-1 font-weight-medium" v-model="tenViTriPhong"
											:items="dsViTriPhong" item-title="TenViTriPhong" item-value="MaViTriPhong"
											return-object menu-icon="" @keyup.enter="updateViTriPhong"
											@blur="updateViTriPhong">
											<template #append-inner>
												<v-icon @click='updateViTriPhong'>mdi-check-underline</v-icon>
											</template>
										</v-autocomplete> -->
									</v-col>
									<v-divider></v-divider>
								</v-row>
								<v-row>
									<v-col class="pb-0">
										<span class="text-body-2 text-grey">Loại danh mục: </span>
										<span class="text-body-1 font-weight-medium">{{ item.TenLoai }}
										</span>
										<!-- <v-icon v-if="!editLoaiDanhMuc" @click='updateLoaiDanhMuc'>
											mdi-square-edit-outline</v-icon>

										<v-autocomplete :loading="isLoadingDanhMuc"
											:rules="[v => !!v || 'Vui lòng chọn nhân viên']" reqired
											ref="cbbLoaiDanhMuc" v-if="editLoaiDanhMuc" :clearable="false"
											class="text-body-1 font-weight-medium" v-model="tenLoaiDanhMuc"
											:items="dsLoaiDanhMuc" item-title="TenLoai" item-value="MaLoai"
											return-object menu-icon="" @keyup.enter="updateLoaiDanhMuc"
											@blur="updateLoaiDanhMuc">
											<template #append-inner>
												<v-icon @click='updateLoaiDanhMuc'>mdi-check-underline</v-icon>
											</template>
										</v-autocomplete> -->
									</v-col>
									<v-divider></v-divider>
								</v-row>
							</v-col>
						</v-row>
						<v-row>
							<v-col class="pb-0">
								<p class="text-body-2 text-grey">Tên tài sản</p>
								<span class="text-body-1 font-weight-medium">{{ item.TenTaiSan }}
								</span>
								<!-- <v-icon v-if="!editTenTaiSan" @click='updateTaiSan'>
									mdi-square-edit-outline</v-icon>

								<v-autocomplete :loading="isLoadingTaiSan"
									:rules="[v => !!v || 'Vui lòng chọn nhân viên']" reqired ref="cbbTenTaiSan"
									v-if="editTenTaiSan" :clearable="false" class="text-body-1 font-weight-medium"
									v-model="tenTaiSan" :items="dsTaiSanTrongPhong" item-title="TenTaiSan"
									item-value="MaCaBiet" return-object menu-icon="" @keyup.enter="updateTaiSan"
									@blur="updateTaiSan">
									<template #append-inner>
										<v-icon @click='updateTaiSan'>mdi-check-underline</v-icon>
									</template>
								</v-autocomplete> -->
							</v-col>
							<v-divider></v-divider>
						</v-row>
					</v-form>
					<v-row class="pt-2">
						<v-col>
							<!-- <div>{{item.MaTinhTrang < 2}}</div> -->
							<v-textarea color="primary" :disabled="!(item.MaTinhTrang < 2)" label="Mô tả lỗi" outlined
								dense v-model="data.GhiChu"
								:style="{ background: '#fff', borderRadius: '4px' }"></v-textarea>
						</v-col>
					</v-row>
					<!-- <v-row>
						<v-col>
							<uc-timeline-tinhtrangsua :items="dsXuLy"></uc-timeline-tinhtrangsua>
						</v-col>
					</v-row> -->
					<!-- <v-row class="position-fixed bottom-0 left-0 right-0">
						<v-col cols="12" class="px-0">
							<v-btn :loading="isLoadingUpdate" @click="validate('formSua', upadteBaoSua)" width="100%"
								color="primary" variant="flat">
								Cập nhật thông tin</v-btn>
						</v-col>
					</v-row> -->
				</v-card-text>
				<v-card-actions>
					<v-btn v-if="item.MaTinhTrang < 2" :loading="isLoadingUpdate"
						@click="validate('formSua', upadteBaoSua)" width="100%" color="primary" variant="flat">
						Cập nhật</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>


		<!-- <v-dialog fullscreen v-model="dialogKiemTra">
			<v-toolbar>
				<v-toolbar-title>
					<v-icon size="small" class="">mdi-map-marker-radius-outline</v-icon>
					{{item.TenViTriPhong}}
				</v-toolbar-title>
				<v-chip size="x-small" :color="statusToColor(item.MaTinhTrang)" tonal class="mr-1">
					{{ item.TenTinhTrang }}
				</v-chip>
				<v-btn icon="mdi-close" @click="dialogKiemTra=false"></v-btn>
			</v-toolbar>
			<v-card height="100%" class="display: flex; flex-direction: column; height: 100%;">
				<v-card-text class="py-3 mt-3">
					<v-row align-center>
						<v-col cols="4" :max-width="100" class="text-center pa-0 ">
							<div style="width:100%; aspect-ratio: 1/1;" class="border-thin">
								<v-img :src="this.data.HinhAnh" @load="isLoaded = false" aspect-ratio="1" height="100%"
									cover>
									<template v-slot:placeholder>
										<div v-if="item.KiemTraHinhAnh == 1 && isLoaded"
											class="d-flex align-center justify-center fill-height">
											<v-progress-circular color="grey-lighten-4"
												indeterminate></v-progress-circular>
										</div>
									</template>
								</v-img>
							</div>

						</v-col>
						<v-col class="ml-1 py-0">
							<v-row>
								<v-col class="py-0">
									<span class="text-body-2 text-grey">Mã tài sản: </span>
									<span class="text-body-1 font-weight-medium">{{data.MaVach}}</span>
								</v-col>
								<v-divider></v-divider>
							</v-row>
							<v-row>
								<v-col class="pb-0">
									<span class="text-body-2 text-grey">Cơ sở:</span>
									<span class="text-body-1 font-weight-medium">{{data.ToaNha}}</span>

								</v-col>
								<v-divider></v-divider>
							</v-row>
							<v-row>
								<v-col class="pb-0">
									<span class="text-body-2 text-grey">Vị trí phòng:</span>
									<span class="text-body-1 font-weight-medium">{{data.TenViTriPhong}}</span>

								</v-col>
								<v-divider></v-divider>
							</v-row>
							<v-row>
								<v-col class="pb-0">
									<span class="text-body-2 text-grey">Loại danh mục: </span>
									<span class="text-body-1 font-weight-medium">{{data.TenLoai}}
									</span>
								</v-col>
								<v-divider></v-divider>
							</v-row>
						</v-col>
					</v-row>
					<v-row>
						<v-col>
							<span class="text-body-2 text-grey">Mô tả lỗi:</span>
							<p class="text-body-1 font-weight-regular">{{data.GhiChu}}
							</p>
						</v-col>
						<v-divider></v-divider>
					</v-row>

					<v-row class="my-2">
						<v-col class="pa-0">
							<v-card flat>
								<v-card-text>
								</v-card-text>
							</v-card>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog> -->
	</v-card>
	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
export default {
	props: {
		item: {
			type: Object
		},
	},
	computed: {
		user() {
			return vueData.user.UserName
		},
		avatar() {
			return `https://file.lhbs.vn/me/avatar/${!!this.item.NguoiBaoSua ? this.item.NguoiBaoSua : ''}.jpg`;
		},
	},
	emits: ['update'],
	watch: {
		image(newVal, oldVal) {
			// if (this.data.HinhAnh != newVal) {
			// 	this.data.HinhAnh = newVal;
			// }
		},
		// editMaVach(newVal) {
		// 	if (newVal) this.focusCbb();
		// },
		// editCoSo(newVal) {
		// 	if (newVal) this.focusCbb();
		// },
		// editViTriPhong(newVal) {
		// 	if (newVal) this.focusCbb();
		// },
		// editTenTaiSan(newVal) {
		// 	if (newVal) this.focusCbb();
		// },
		// tenCoSo(newVal, oldVal) {
		// 	if (newVal != oldVal && typeof newVal == 'object') {
		// 		this.getDSPhong();
		// 	}
		// },
		// tenViTriPhong(newVal, oldVal) {
		// 	if (newVal != oldVal && typeof newVal == 'object') {
		// 		this.getDSLoaiDanhMuc();
		// 	}
		// },
		// tenLoaiDanhMuc(newVal, oldVal) {
		// 	if (newVal != oldVal && typeof newVal == 'object') {
		// 		this.getTaiSanByViTriPhong();
		// 	}
		// }

	},
	data() {
		return {
			tab: null,
			data: { ...this.item },
			ghiChuTiepNhan: "",
			image: "",
			maVach: "",

			tenTaiSan: {},
			tenCoSo: {},
			tenViTriPhong: {},
			tenLoaiDanhMuc: {},
			taiSanByMaVach: {},
			tinhTrangKiemTra: 1,

			dsTaiSanTrongPhong: [],
			dsLichSu: [],
			dsCoSo: [],
			dsXuLy: [],
			dsViTriPhong: [],
			dsLoaiDanhMuc: [],

			dialogKiemTra: false,
			dialogTiepNhan: false,
			isUpdating: false,
			isFromAPI: false,
			isLoaded: true,
			isLoadingCoSo: false,
			isLoadingPhong: false,
			isLoadingDanhMuc: false,
			isLoadingTaiSan: false,
			isLoadingUpdate: false,
			isLoadingHinhAnh: false,

			editMaVach: false,
			editTenTaiSan: false,
			editCoSo: false,
			editViTriPhong: false,
			editLoaiDanhMuc: false,
			editMoTa: false,


		}
	},
	mounted() {
		// this.generateQR();
	},
	methods: {
		formatDate: window.formatDate,
		formatTime: window.formatTime,
		formatDateTime: window.formatDateTime,

		focusCbb() {
			this.$nextTick(() => {
				if (this.editMaVach) {
					this.$refs.txtMaVach.focus()
				}
				else if (this.editCoSo) {
					this.$refs.slCoSo.focus();
				}
				else if (this.editViTriPhong) {
					this.$refs.cbbViTriPhong.focus();
				}
				else if (this.editLoaiDanhMuc) {
					this.$refs.cbbLoaiDanhMuc.focus();
				}
				else if (this.editTenTaiSan) {
					this.$refs.cbbTenTaiSan.focus();
				}
			});
		},

		async validate(refName, callback, confirmText = "Bạn có muốn lưu dữ liệu?", reset = true) {

			const form = this.$refs[refName];
			if (!form) {
				console.warn(`Form ref "${refName}" not found.`);
				return;
			}

			const { valid } = await form.validate();

			if (valid && typeof callback === "function") {
				const confirmed = await this.$refs.confirm.open(confirmText);
				if (!confirmed) return;
				await callback();
				if (reset) form.reset();
			}
		},

		inputMaVach(value) {
			this.maVach = value.target.value.replace(/[^0-9]/g, '').slice(0, 8);
		},
		// updateMaVach() {
		// 	if (this.editMaVach) {
		// 		this.getInfoByMaVach();
		// 		this.editMaVach = false;
		// 	} else { this.editMaVach = true; }

		// },
		// updateTaiSan() {
		// 	if (this.editTenTaiSan && this.tenTaiSan != null && typeof this.tenTaiSan == "object") {
		// 		this.data.TenTaiSan = this.tenTaiSan.TenTaiSan;
		// 		this.data.MaVach = this.tenTaiSan.MaVach;
		// 		this.maVach = this.tenTaiSan.MaVach;
		// 		this.data.MaCaBiet = this.tenTaiSan.MaCaBiet;
		// 		this.data.MaCaBiet = this.tenTaiSan.MaCaBiet;
		// 	} else {
		// 		this.tenTaiSan = this.data;
		// 	}
		// 	this.editTenTaiSan = !this.editTenTaiSan;
		// },
		// updateCoSo() {
		// 	if (this.editCoSo) {
		// 		if (this.data.MaToaNha !== this.tenCoSo.MaToaNha) {
		// 			console.log("CoSo: ", this.tenCoSo)
		// 			this.data.MaToaNha = this.tenCoSo.MaToaNha;
		// 			this.data.ToaNha = this.tenCoSo.ToaNha;
		// 			this.getDSPhong();

		// 			this.maVach = null;
		// 			this.tenViTriPhong = null;
		// 			this.data.TenViTriPhong = null;
		// 			this.data.MaViTriPhong = null;
		// 			this.data.MaVach = null;
		// 			this.checkCoSo = true;
		// 			this.editViTriPhong = true;
		// 		}
		// 		this.editCoSo = false;
		// 	} else {
		// 		this.editCoSo = true;
		// 	}
		// },
		// updateViTriPhong() {
		// 	if (this.editViTriPhong && this.tenViTriPhong != null && typeof this.tenViTriPhong == "object") {
		// 		if (this.data.MaViTriPhong != this.tenViTriPhong.MaViTriPhong) {
		// 			this.data.MaVach = null;
		// 			this.data.MaViTriPhong = this.tenViTriPhong.MaViTriPhong;
		// 			this.data.TenViTriPhong = this.tenViTriPhong.TenViTriPhong;
		// 			this.getDSLoaiDanhMuc();

		// 			this.maVach = null;
		// 			this.tenLoaiDanhMuc = null;
		// 			this.data.MaLoai = null;
		// 			this.data.TenLoai = null;
		// 			this.checkViTri = true;
		// 			this.editLoaiDanhMuc = true;
		// 		}
		// 		this.editViTriPhong = false;
		// 	}
		// 	else if (this.tenViTriPhong == null) {
		// 		if (!this.checkCoSo) { this.tenViTriPhong = this.data; }
		// 	}
		// 	else { this.editViTriPhong = !this.editViTriPhong; }

		// },
		// updateLoaiDanhMuc() {
		// 	if (this.editLoaiDanhMuc && this.tenLoaiDanhMuc != null && typeof this.tenLoaiDanhMuc == "object") {
		// 		if (this.data.MaLoai != this.tenLoaiDanhMuc.MaLoai) {
		// 			this.data.MaVach = null;
		// 			this.data.MaLoai = this.tenLoaiDanhMuc.MaLoai;
		// 			this.data.TenLoai = this.tenLoaiDanhMuc.TenLoai;
		// 			this.getTaiSanByViTriPhong();
		// 			this.maVach = null;
		// 			this.tenTaiSan = null;
		// 			this.data.TenTaiSan = null;
		// 			this.data.MaCaBiet = null;
		// 			this.editTenTaiSan = true;
		// 		}
		// 		this.editLoaiDanhMuc = false;
		// 	} else if (this.tenLoaiDanhMuc == null) {
		// 		if (!this.checkViTri) { this.tenLoaiDanhMuc = this.data; }
		// 	}
		// 	else { this.editLoaiDanhMuc = !this.editLoaiDanhMuc; }
		// },
		async onClick() {
			// if (this.item.MaTinhTrang < 2) {
			this.dialogTiepNhan = true;
			// this.maVach = this.item.MaVach;
			// this.tenTaiSan = { MaCaBiet: this.iten.MaCaBiet, TenTaiSan: this.item.TenTaiSan, MaVach: this.item.MaVach };
			// this.tenCoSo = { MaToaNha: this.item.MaToaNha, ToaNha: this.item.ToaNha };
			// this.tenViTriPhong = { MaViTriPhong: this.item.MaViTriPhong, TenViTriPhong: this.item.TenViTriPhong };
			// this.tenLoaiDanhMuc = { MaLoai: this.item.MaLoai, TenLoai: this.item.TenLoai };
			// await this.getDSCoSo();
			// await this.getDSPhong();
			// await this.getDSLoaiDanhMuc();
			// await this.getTaiSanByViTriPhong();
			// } else {
			// 	this.dialogKiemTra = true;
			// }
			await this.getXuLyByMaBaoSua();
			if (this.item.KiemTraHinhAnh == 1) {
				this.getHinhAnh();
			}


		},
		closeDialogTiepNhan() {
			this.dialogTiepNhan = false;
			this.editMaVach = false;
			this.editTenTaiSan = false;
			this.editCoSo = false;
			this.editViTriPhong = false;
			this.editLoaiDanhMuc = false;
			this.editMoTa = false;

			this.data = { ...this.item };
		},
		async getXuLyByMaBaoSua() {
			try {
				const res = await axios.post("XuLyBaoSua_SelectByMaBaoSua", { MaBaoSua: this.item.MaBaoSua })
				this.dsXuLy = res.data.data;
			} catch (err) {
				console.error(err);
			}
		},
		async getHinhAnh() {
			try {
				this.isLoadingHinhAnh = true;
				const res = await axios.post("/obj/BaoSua_SelectHinhAnh", {
					MaBaoSua: this.item.MaBaoSua
				})
				if (res.data.data.HinhAnh != '') {
					this.image = res.data.data.HinhAnh;
				} else {
					this.image = '';
				}
			}
			catch (err) {
				console.error(err)
			}
			finally {
				this.isLoadingHinhAnh = false;
			}
		},
		// async getInfoByMaVach() {
		// 	if (!!this.maVach && this.maVach.length == 8) {
		// 		this.taiSanByMaVach = await axios.post("/TaiSan_Select_byQR", {
		// 			QR: this.maVach
		// 		})
		// 			.then((res) => {
		// 				return res.data.data[0];

		// 			})
		// 			.catch((err) => {
		// 				this.showQrDialog = false
		// 				this.kieu = "error";
		// 				this.thongBao = true;
		// 				this.message = err.response.data.Message;
		// 				this.maVach = null;
		// 				console.log(err);
		// 			})
		// 		if (this.taiSanByMaVach !== null || this.taiSanByMaVach !== undefined) {

		// 			this.isFromAPI = true;
		// 			this.data.MaVach = this.maVach;
		// 			this.tenCoSo = { MaToaNha: this.taiSanByMaVach.MaToaNha, ToaNha: this.taiSanByMaVach.ToaNha };
		// 			this.tenViTriPhong = { MaViTriPhong: this.taiSanByMaVach.MaViTriPhong, TenViTriPhong: this.taiSanByMaVach.TenViTriPhong };
		// 			this.tenLoaiDanhMuc = { MaLoai: this.taiSanByMaVach.MaLoai, TenLoai: this.taiSanByMaVach.TenLoai };
		// 			this.tenTaiSan = { TenTaiSan: this.taiSanByMaVach.TenTaiSan, MaCaBiet: this.taiSanByMaVach.MaCaBiet };
		// 			console.log("data: ", this.tenCoSo);
		// 			this.data.MaToaNha = this.taiSanByMaVach.MaToaNha;
		// 			this.data.ToaNha = this.taiSanByMaVach.ToaNha;
		// 			this.data.MaViTriPhong = this.taiSanByMaVach.MaViTriPhong;
		// 			this.data.TenViTriPhong = this.taiSanByMaVach.TenViTriPhong;
		// 			this.data.MaCaBiet = this.taiSanByMaVach.MaCaBiet;
		// 			this.data.TenTaiSan = this.taiSanByMaVach.TenTaiSan;
		// 			this.data.MaLoai = this.taiSanByMaVach.MaLoai;
		// 			this.data.TenLoai = this.taiSanByMaVach.TenLoai;
		// 			this.$nextTick(() => {
		// 				this.isFromAPI = false;
		// 			});
		// 		}
		// 	} else {
		// 		this.maVach = this.data.MaVach;
		// 	}
		// },
		// async getDSCoSo() {
		// 	this.isLoadingCoSo = true;
		// 	try {
		// 		const res = await axios.post("/CoSo_Select")
		// 		this.dsCoSo = res.data.data
		// 	} catch (err) {
		// 		console.error(err)
		// 	}
		// 	this.isLoadingCoSo = false;
		// },
		// async getDSPhong() {
		// 	this.isLoadingPhong = true;
		// 	try {
		// 		const res = await axios.post("/ViTriPhong_SelectByMaToaNha", {
		// 			MaToaNha: this.tenCoSo.MaToaNha
		// 		})
		// 		this.dsViTriPhong = res.data.data;
		// 	} catch (err) {
		// 		console.error(err);
		// 	}
		// 	this.isLoadingPhong = false;
		// },


		async deleteBaoSua() {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xoá không?',
						okText: 'Xoá',
						cancelText: 'Hủy',
						okColor: 'red',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				const res = await axios.post("BaoSua_Delete", {
					MaBaoSua: this.item.MaBaoSua
				})
				CALL(webSocket_Send({
					group: "BaoSua",
					data: {
						ThongBao: 123,
					}
				}));
				this.$emit('update');
				CALL({ "MESS": "Xoá thành công" })

			} catch (err) {
				showMessage({ type: "red", title: err.response.data.Message })
			}
		},
		async upadteBaoSua() {
			try {
				this.isLoadingUpdate = true;
				const res = await axios.post("BaoSua_Update_New", {
					MaBaoSua: this.item.MaBaoSua,
					MaCaBiet: this.item.MaCaBiet,
					MoTa: this.data.GhiChu,
					HinhAnh: this.image != '' ? this.image : undefined
				})
				CALL(webSocket_Send({
					group: "BaoSua",
					data: {
						ThongBao: 123,
					}
				}));
				this.$emit('update');
				CALL({ "MESS": "Cập nhật thành công" });
				this.dialogTiepNhan = false;
			} catch (err) {
				showMessage({ type: "red", title: err.response.data.Message })
			} finally {
				this.isLoadingUpdate = false;
			}
		},
		async getTaiSanByViTriPhong() {
			this.isLoadingTaiSan = true;
			try {
				const res = await axios.post("/CaBietTaiSan_ByPhongBanVaLoaiDanhMuc", {
					MaViTriPhong: this.tenViTriPhong.MaViTriPhong,
					MaLoai: this.tenLoaiDanhMuc.MaLoai
				})
				this.dsTaiSanTrongPhong = res.data.data;
				// console.log(res.data.data)
			} catch (err) {
				console.error(err)
			}
			this.isLoadingTaiSan = false;
		},
		async getDSLoaiDanhMuc() {
			this.isLoadingDanhMuc = true;
			try {
				if (!this.tenViTriPhong) {
					return;
				}

				const res = await axios.post("/SelectLoaiDanhMuc_ByViTriPhong", {
					MaViTriPhong: this.tenViTriPhong.MaViTriPhong
				});
				this.dsLoaiDanhMuc = res.data.data;

			} catch (err) {
				console.error(err);
			}
			this.isLoadingDanhMuc = false;
		},


		statusToColor(id) {
			switch (id) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'light-green';
					break;
				case 2:
					return 'orange';
					break;
				case 3:
					return 'green';
					break;
				case 4:
					return 'light-blue-accent-3';
					break;

				default:
					return 'green';
					break;
			}
		},
	}
}
</script>