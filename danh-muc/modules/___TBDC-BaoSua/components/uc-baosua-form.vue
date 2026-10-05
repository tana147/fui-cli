<template>
	<z-layout>
		<v-sheet style="background-color:#F3F4F6; height:100vh">
			<v-row align="center" justify="center">
				<v-col cols="12" sm="6" lg="3" md="4" class="pa-0">
					<v-card v-if="!isSuccess" class="pa-4 test" :style="{ width: '100%', borderRadius: '8px', background: '#fff' }">
						<v-card-text class="pa-0">
							<div @click="tryCamera" :style="{ background: '#e0e0e0', padding: '20px', textAlign: 'center', borderRadius: '8px' }">
								<v-icon size="40" color="grey darken-2">mdi-qrcode-scan</v-icon>
								<span class="text-body-2 " :style="{ display: 'block', color: '#757575' }">Quét mã tài
									sản</span>
							</div>
							<div class="d-flex align-center ma-2">
								<v-divider></v-divider>
								<span class="px-2" :style="{ fontSize: '14px', whiteSpace: 'nowrap' }">Hoặc</span>
								<v-divider></v-divider>
							</div>

							<v-form ref="form1">
								<v-text-field ref="refMaVach" @focus="scrollToField('refMaVach')" inputmode="numeric" style="background-color:white;" color="primary" v-model="maVach" :clearable="false" class="mb-3" label="Mã tài sản (nếu có)" @keyup.enter="getInfoByMaVach" @blur="getInfoByMaVach" autofocus="" @input="inputMaVach" append-inner-icon="mdi-magnify" @click:appendinner="getInfoByMaVach">

								</v-text-field>
								<div v-if="dsTaiSanLienKet.length > 1" class="text-caption font-italic">(*) Tài sản bạn
									chọn
									thuộc một bộ tài sản. Vui lòng
									chọn đúng thiết bị gặp sự cố bên dưới.</div>
								<v-chip-group mandatory="" v-if="dsTaiSanLienKet.length > 1" column="" class="mb-2" v-model="taiSanChon">
									<v-chip size="small" v-for="ts in dsTaiSanLienKet" :value="ts" color="primary">
										{{ ts.TenTaiSan }}
									</v-chip>
								</v-chip-group>

								<v-select ref="refCoSo" @focus="scrollToField('refCoSo')" :loading="isLoadingCoSo" style="background-color:white;" :rules="[rules.required]" color="primary" class="mb-3" v-model="coSo" :items="dsCoSo" density="compact" item-value="MaCoSo" item-title="TenCoSo" :clearable="false" label="Cơ sở">
								</v-select>

								<v-autocomplete ref="refPhong" @focus="scrollToField('refPhong')" :loading="isLoadingPhong" style="background-color:white;" :rules="[rules.required]" color="primary" class="mb-3" return-object="" v-model="phongBan" :items="dsPhong" density="compact" item-value="MaViTriPhong" item-title="TenViTriPhong" :clearable="false" label="Phòng">
								</v-autocomplete>

								<v-autocomplete ref="refLoaiDanhMuc" @focus="scrollToField('refLoaiDanhMuc')" :loading="isLoadingDanhMuc" style="background-color:white;" :rules="[rules.required]" color="primary" class="mb-3" return-object="" v-model="loaiDanhMuc" :items="dsLoaiDanhMuc" density="compact" item-value="MaLoai" item-title="TenLoai" :clearable="false" label="Loại danh mục">
								</v-autocomplete>

								<v-autocomplete ref="refTaiSan" @focus="scrollToField('refTaiSan')" :loading="isLoadingTenTaiSan" style="background-color:white;" :rules="[rules.required]" color="primary" return-object="" v-model="taiSanChon" :items="dsTaiSanByPhongBan" density="compact" item-value="MaCaBiet" item-title="TenTaiSan" :clearable="false" label="Thiết bị">
									<template #item="{ props, item }">
										<v-list-item v-bind="props">
											<v-list-item-subtitle>
												<!-- {{item.TenTaiSan}} -->
												{{ item.raw.MaVach }}
											</v-list-item-subtitle>
										</v-list-item>
									</template>
								</v-autocomplete>

								<uc-image ref="refHinhAnh" @focus="scrollToField('refHinhAnh')" v-model="hinhAnh" max-images="1" classs="py-3"></uc-image>

								<v-textarea rows="3" ref="refMoTa" @focus="scrollToField('refMoTa')" :rules="[rules.required]" color="primary" label="Mô tả lỗi (*)" outlined="" dense="" v-model="note" classs="mb-10" :style="{ background: '#fff', borderRadius: '4px' }">
								</v-textarea>

								<!-- <v-combobox style="background-color:white;" :rules="[rules.required]" color="primary" return-object
											v-model="danhMuc" :items="dsDanhMuc" density="compact" item-value="MaDM" item-title="TenDanhMuc"
											:clearable="false" label="Danh mục">
										</v-combobox> -->
							</v-form>
							<div class="d-flex justify-end">
								<uc-lichsu class-for-btn="mt-4 mr-2"></uc-lichsu>

								<v-btn :loading="isLoading" color="primary" @click="validate('form1', insertBaoSua)" variant="outlined" class="mt-4">
									Gửi báo sửa
								</v-btn>
							</div>

						</v-card-text>

						<!-- <uc-dialog-hoi v-if="thongBao" :kieu="kieu" v-model="thongBao" :message="message"></uc-dialog-hoi> -->

						<v-dialog :fullscreen="$vuetify.display.smAndDown" v-model="showQrDialog" width="500" height="100%">
							<v-card>
								<v-toolbar>
									<v-toolbar-title class="text-center text-primary">Quét mã</v-toolbar-title>
									<v-btn icon="mdi-close" @click="showQrDialog = false"></v-btn>
									<!-- <v-btn icon="mdi-dots-vertical" @click="showQrDialog = false"></v-btn> -->
								</v-toolbar>
								<v-card-text :style="{ padding: '0', aspectRatio: 1 / 1, width: '100%' }">

									<uc-qr v-model="maVach" @scan-success="getInfoByMaVach" ref="qrScanner">
										<template #default="">
											<v-row class="mt-2">
												<v-col class="px-0" cols="4"></v-col>
												<v-col class="px-0" cols="4" style="text-align: center;">
													<v-btn icon="" variant="flat" color="primary" @click="$refs.qrScanner?.triggerFileInput()">
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

									<!-- <uc-qrscan v-model="maVach" @scan-success="getInfoByMaVach" ref="qrScanner">
									<template v-slot:default>
										<v-row class="mt-2">
											<v-col class="px-0" cols="12" style="text-align: center;">
												<v-btn icon variant="flat" color="primary"
													@click="this.$refs.qrScanner?.triggerFileInput();">
													<v-icon color="white">mdi-image</v-icon>
												</v-btn>
												<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư viện
												</div>
											</v-col>
										</v-row>
									</template>
								</uc-qrscan> -->
								</v-card-text>
							</v-card>
						</v-dialog>

						<!-- <v-dialog max-height="80vh" v-model="dialogLichSu" width="1000">
									<v-card :style="{ overflow: 'hidden', maxHeight: '80vh' }">
										<v-toolbar color="primary">
											<v-toolbar-title>Lịch sử báo sửa</v-toolbar-title>
											<v-btn icon="mdi-close" @click="dialogLichSu = false"></v-btn>
										</v-toolbar>
										<v-divider></v-divider>
										<v-card-text>
											<v-data-table-virtual :headers="headers" :items="dsLichSua" item-value="STT" hide-default-footer
												height="400" density="compact" fixed-header>
												<template v-slot:item.TinhTrang="{item}">
													<v-chip
														:color="item.TinhTrangBaoSua == 0 ? 'red': item.TinhTrangSuaChua == 1 ? 'yellow' : item.TinhTrangSuaChua == 2 ? 'indigo': item.TinhTrangSuaChua == 5 ? 'success' : 'teal'">
														{{item.TinhTrang}}</v-chip>
												</template>
												<template v-slot:item.TGBaoSua="{ item }">
													{{ formatDate(item.TGBaoSua) }}
												</template>
											</v-data-table-virtual>
										</v-card-text>
									</v-card>
								</v-dialog> -->

						<v-dialog :fullscreen="$vuetify.display.smAndDown" v-model="isOpenDialogTaiSan" width="960">
							<v-card ref="dialogRef" style="background-color:#F3F4F6; ">
								<v-card-title ref="headerRef" class="pa-0">
									<v-toolbar color="white">
										<v-toolbar-title>Báo sửa</v-toolbar-title>
										<v-btn icon="mdi-close" @click="isOpenDialogTaiSan = false"></v-btn>
									</v-toolbar>
									<v-card flat="" class="mb-1" style="box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px;">
										<v-card-text class="pt-0">
											<div>
												<v-icon>mdi-office-building</v-icon> Cơ sở: <span class="font-weight-bold">{{ getTenCoSo
													}}</span>
											</div>
											<div>
												<v-icon>mdi-door-open</v-icon> Phòng: <span class="font-weight-bold" v-if="phongBan">{{
														phongBan.TenViTriPhong }}</span>
											</div>
										</v-card-text>
									</v-card>
									<v-row class="px-2 pt-1">
										<v-col>
											<v-text-field class="mb-2" style="background-color:white;" color="primary" prepend-inner-icon="mdi-magnify" v-model="timKiem" label="Tìm kiếm">
											</v-text-field>

										</v-col>
										<!-- <v-col cols="4" class="pl-0">
										<v-autocomplete return-object :clearable="false" label="Loại" flat
											v-model="loaiDanhMuc" :items="dsLoaiDanhMuc" item-value="MaLoai"
											item-title="TenLoai" variant="solo"></v-autocomplete>
									</v-col> -->
									</v-row>

									<v-card-title class="pl-1 pb-0">Danh sách tài sản</v-card-title>
									<!-- <v-sheet class="py-1 px-2" color="#F3F4F6">
									<v-chip-group @input="getTenLoaiDanhMuc" selected-class="text-primary" mandatory
										v-model="locDanhMuc">
										<v-chip v-for="(item,index) in dsLoaiDanhMuc" :key="index" :value="item.MaLoai"
											:text="item.TenLoai"></v-chip>
									</v-chip-group>
								</v-sheet> -->
								</v-card-title>

								<v-card-text class="pa-2 pt-0">
									<v-infinite-scroll @touchstart="xuLyScroll" :max-height="scrollHeight" :items="dsTaiSanLoc" @load="load">
										<template v-for="(item, index) in dsTaiSanLoc" :key="item.MaCaBiet">
											<v-sheet color="#F3F4F6">
												<v-card class="mb-2" style="position: relative;" @click="openDialogBaoSua(item)">
													<!-- <div class="position-absolute rounded-circle"
													style="top: 0; right: 0; background-color: #1976d2; color: white; padding: 2px 6px; font-size: 12px;">
													{{++index}}
												</div> -->
													<v-card-text>
														<v-row>
															<v-col cols="4" style="max-width: 100px;" class="pa-0">
																<v-img class="rounded" :height="100" aspect-ratio="1" :width="100" cover="" lazy-src="https://cdn.zentea.vn/filedata/lhbs-quanlyts/lhbs.png" :src="item.HinhAnh">
																	<template v-slot:placeholder="">
																		<div class="d-flex align-center justify-center fill-height">
																			<v-progress-circular color="grey-lighten-4" indeterminate="">
																			</v-progress-circular>
																		</div>
																	</template>
																</v-img>
															</v-col>
															<v-col cols="8" class="pl-2 pt-0">
																Tên tài sản: <span class="font-weight-bold">{{
																	item.TenTaiSan }}</span>
																<br>
																Mã tài sản: <span class="font-weight-bold">{{
																	item.MaVach }}</span>
																<span style=" white-space: nowrap; overflow: hidden; text-overflow: ellipsis;  display: block; width: 100%; ">
																	<span>Alias:</span> <span class="font-weight-bold">{{ item.TenDanhMuc }}
																		{{ item.NhomDanhMuc }}</span>
																</span>

															</v-col>
														</v-row>
													</v-card-text>
												</v-card>
											</v-sheet>
										</template>
										<template v-slot:empty="">
											<!-- Hết! -->
										</template>
										<template v-slot:load-more="{ props }">
											<!-- <v-btn icon="mdi-refresh" size="small" variant="text" v-bind="props"></v-btn> -->
										</template>
									</v-infinite-scroll>
								</v-card-text>
								<!-- <v-card-text v-else>Không có tài sản</v-card-text> -->
							</v-card>
						</v-dialog>

						<!-- <v-dialog transition="slide-x-reverse-transition" :fullscreen="$vuetify.display.xs"
						v-model="isOpenDialogBaoSua" max-width="500">
						<v-card style="background-color:#F3F4F6;">
							<v-card-title ref="headerRef" class="pa-0">
								<v-toolbar color="white">
									<v-toolbar-title>Báo sửa</v-toolbar-title>
									<v-btn icon="mdi-close" @click="isOpenDialogBaoSua = false"></v-btn>
								</v-toolbar>
								<v-card flat style="box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px;">
									<v-card-text class="pt-0">
										<div>
											<v-icon>mdi-office-building</v-icon> Cơ sở: <span
												class="font-weight-bold">{{getTenCoSo}}</span>
										</div>
										<div>
											<v-icon>mdi-door-open</v-icon> Phòng:
											<span class="font-weight-bold"
												v-if="phongBan">{{phongBan.TenViTriPhong}}</span>
										</div>

										<div
											style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: inline-block; width:100%">
											<v-icon>mdi-tools</v-icon> Tài sản:
											
											<span class="font-weight-bold" v-if="taiSanChon">
												{{taiSanChon.TenTaiSan}}
											</span>
										</div>
									</v-card-text>
								</v-card>
							</v-card-title>
							<v-card-text class="pa-2 pt-0">
								<v-form ref="form2">
									<uc-image v-model="hinhAnh" max-images='1' classs="py-3"></uc-image>
									<v-textarea required :rules="[rules.required]" color="primary" label="Mô tả lỗi (*)"
										outlined dense v-model="note" classs="mb-10"
										:style="{ background: '#fff', borderRadius: '4px' }"></v-textarea>
								</v-form>

							</v-card-text>
							<v-card-actions>
								<v-btn :loading="isLoading" @click="validate('form2',insertBaoSua)" width="100%"
									color="primary" variant="flat">
									Gửi báo sửa </v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog> -->
					</v-card>
					<v-card max-width="700" v-if="isSuccess">

						<v-card-text class="text-center">
							<v-icon size="72" color="success" class="mb-4">mdi-check-circle</v-icon>

							<h2 class="text-h5 font-weight-medium mb-2">Cảm ơn bạn đã gửi phản hồi!</h2>

							<div class="text-body-2 mb-6">
								Phản hồi của bạn đã được ghi nhận. Kỹ thuật sẽ tiếp nhận và xử lý trong thời gian sớm
								nhất.
							</div>

						</v-card-text>
						<template v-slot:actions="">
							<v-spacer></v-spacer>
							<v-btn @click="redirectBaoSua" variant="flat" class="ma-0">
								Tiếp tục báo sửa
							</v-btn>
							<v-btn @click="redirectTrangChu" color="primary" variant="flat" class="ma-0">
								Về trang chủ
							</v-btn>
						</template>
						<!-- <v-card-actions>
						<v-spacer></v-spacer>
						<v-btn @click="isSuccess=false" variant="flat" class="ma-0">
							Báo sửa
						</v-btn>
						<v-btn @click="redirectTrangChu" variant="flat" class="ma-0">
							Trang chủ
						</v-btn>
					</v-card-actions> -->

					</v-card>
				</v-col>
			</v-row>
			<v-dialog v-model="isConfirm" max-width="500">
				<v-card>
					<v-card-title class="text-h6">Lưu ý</v-card-title>
					<v-card-text class="pt-0">
						<span>Tài sản đã được ghi nhận với lỗi:</span>
						<div v-for="(item, index) in dsMoTa" :key="index">
							<strong>- {{ item.GhiChu }}</strong>({{ item.ThoiGianBaoSua }})
						</div>
						<span>Nếu bạn gặp sự cố như trên, <strong>vui lòng không gửi báo sửa</strong> để tránh trùng
							lặp!</span>
					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn color="red" @click="isConfirm = false">Tiếp tục</v-btn>
						<v-btn color="primary" variant="tonal" text="" @click="() => { isConfirm = false; $refs.form1.reset(); dsTaiSanLienKet = []; }">
							Huỷ</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>
			<uc-confirm ref="confirm"></uc-confirm>
			<v-alert style="z-index: 9999;" :text="message" class="mt-10 py-3" position="fixed" location="top" elevation="2" v-model="thongBao" :type="kieu"></v-alert>
		</v-sheet>
	</z-layout>
</template>

<script>
	export default {
		props: {
		maViTriPhong: {
			type: [Number, String]
		},
		maCoSo: {
			type: [Number, String]
		}
	},
	data() {
		return {
			dialog: true,
			kieu: 'success',
			message: "Thành công",
			pageNumber: 1,
			scrollHeight: 0,
			timKiem: '',

			isEmpty: false,
			isConfirm: false,
			isSuccess: false,
			isLoadingImage: true,
			isLoading: false,
			isLoadingCoSo: false,
			isLoadingPhong: false,
			isLoadingDanhMuc: false,
			isLoadingTenTaiSan: false,
			isOpenDialogTaiSan: false,
			isOpenDialogBaoSua: false,

			thongBao: false,
			showQrDialog: false,
			dialogLichSu: false,

			hinhAnh: [],
			dsMoTa: [],
			dsCoSo: [],
			dsPhong: [],
			dsLoaiDanhMuc: [],
			dsTaiSanPerPage: [],
			dsLichSua: [],
			dsTaiSanByPhongBan: [],
			dsTaiSanLienKet: [],
			tracking: "Input",
			taiSanBaoSua: null,
			taiSan: null,
			taiSanChon: null,
			maVach: null,
			loaiDanhMuc: { MaLoai: 0, TenLoai: '--Tất cả--' },
			locDanhMuc: 0,
			danhMuc: null,
			phongBan: null,
			coSo: null,
			taiSanLienKetChon: null,
			note: null,
			imgCache: {},
			fromAPI: false,

			rules: {
				required: (value) => {
					if (value === null || value === undefined || value === "") return 'Trường này là bắt buộc';
					if (typeof value === 'object' && Object.keys(value).length === 0) return 'Trường này là bắt buộc';
					return true;
				},
				maVach: (val) => {
					if (val.length > 0 && val.length < 8) return false;
					return true;
				}
			},

			headers: [
				{
					title: 'STT',
					align: 'start',
					sortable: false,
					key: 'STT',
				},
				{ title: 'Phòng', key: 'TenViTriPhong' },
				{ title: 'Tên tài sản', key: 'TenTaiSan' },
				{ title: 'Tình trạng', key: 'TinhTrang' },
				{ title: 'Ghi chú', key: 'GhiChu' },
				{ title: 'Thời gian gửi', key: 'TGBaoSua' },
			],
			test: { BaoSua: [] },
		};
	},
	computed: {
		getTenCoSo() {
			const tenCoSo = this.dsCoSo.find(coSo => coSo.MaCoSo == this.coSo);
			return tenCoSo ? tenCoSo.TenCoSo : 'Cơ sở không tồn tại';
		},
		getTenLoaiDanhMuc() {
			if (this.dsLoaiDanhMuc.length > 1) {
				const a = this.dsLoaiDanhMuc.find(item => item.MaLoai == this.locDanhMuc);
				this.loaiDanhMuc = a;
			}
		},
		dsTaiSanLoc() {
			if ((!this.timKiem || this.timKiem.trim() === '') && this.loaiDanhMuc.MaLoai == 0) {
				return this.dsTaiSanPerPage;
			}
			const searchTerm = this.timKiem.trim().toLowerCase();

			const ketQuaLoc = this.dsTaiSanPerPage.filter(item => {
				const tenTaiSan = item.TenTaiSan ? item.TenTaiSan.toLowerCase() : '';
				const maVach = item.MaVach ? item.MaVach : '';
				const loaiDanhMuc = item.TenLoai ? item.TenLoai : '';
				const danhMuc = item.TenDanhMuc ? item.TenDanhMuc : '';
				const isTimKiem = tenTaiSan.includes(searchTerm)
					|| maVach.includes(searchTerm)
					|| loaiDanhMuc.includes(searchTerm)
					|| danhMuc.includes(searchTerm)

				return isTimKiem;
			});
			return ketQuaLoc;
		},
	},

	async mounted() {

		// 1. Lấy chuỗi truy vấn từ window.location
		const queryString = window.location.search; // Sẽ trả về "?id=42&name=product-a&type=new"

		// 2. Tạo một đối tượng URLSearchParams từ chuỗi đó
		const urlParams = new URLSearchParams(queryString);
		const maViTriPhong = urlParams.get('maViTriPhong');       // Trả về chuỗi "42"
		const maTaiSan = urlParams.get('maVach');   // Trả về chuỗi "product-a"


		if (maViTriPhong) {
			this.tracking = "QRPhong"
		} else
			if (maTaiSan) {
				this.tracking = "TaiSan"
			}


		await this.getDSCoSo();
		this.checkScreen();
		(() => {
			if (typeof this.maCoSo !== "undefined" && typeof this.maViTriPhong !== "undefined") {
				this.phongBan = this.dsPhong.find(i => i.MaViTriPhong === parseInt(this.maViTriPhong));
				return this.isOpenDialogTaiSan = true;
			}
			return this.isOpenDialogTaiSan = false;
		})();
		this.updateScrollHeight();
		window.addEventListener('resize', this.updateScrollHeight);

		// const urlParams = new URLSearchParams(window.location.search);
		// const ma = urlParams.get('maVach');
		if (maTaiSan != '') {
			// document.activeElement.blur();

			this.maVach = maTaiSan;
			await this.getInfoByMaVach()
		}

	},
	watch: {
		async coSo(newVal, oldVal) {
			if (newVal !== oldVal && !!newVal) {
				if (!this.fromAPI) {
					this.phongBan = null;
					this.loaiDanhMuc = { MaLoai: 0, TenLoai: '--Tất cả--' };
					// this.danhMuc = null;
					this.maVach = null;
					this.taiSanChon = null;
				}
				await this.getDSPhong();
			}
		},
		async phongBan(newVal, oldVal) {
			if (newVal !== oldVal && newVal !== null && typeof newVal == 'object') {

				if (!this.fromAPI) {
					this.loaiDanhMuc = { MaLoai: 0, TenLoai: '--Tất cả--' };
					// this.danhMuc = null;
					this.maVach = null;
					this.taiSanChon = null;
				}
				await this.getDSLoaiDanhMuc();
				await this.getDSTaiSanByPhongBan();
			}
		},
		async loaiDanhMuc(newVal, oldVal) {
			if (newVal !== oldVal && typeof this.phongBan == 'object' && !!this.phongBan) {
				if (!this.fromAPI) {
					// this.danhMuc = null;
					this.taiSanChon = null;
					this.maVach = null;
				}

				await this.getDSTaiSanByPhongBan();
				// await this.getDSDanhMuc();
			}
		},


		async taiSanChon(newVal, oldVal) {
			if (newVal !== oldVal && !!newVal) {
				if (!this.fromAPI) {
					// await this.getTaiSanLienKet();
					this.maVach = null;
					this.taiSan = null;
					// console.log("TSChonj:", newVal);
					await this.getMoTaLoiByMaCaBiet(newVal.MaCaBiet);
				}
				if (!!newVal.MaVach) {
					this.maVach = newVal.MaVach;
					// this.loaiDanhMuc =  newVal.MaLoai;
					// this.danhMuc = newVal.MaDM;
					await this.getTaiSanLienKet();
				}

			}
		},
		// async maVach(newVal) {
		// 	if (newVal.length == 8) {
		// 		await this.getInfoByMaVach();
		// 	}
		// }
	},
	methods: {
		redirectTrangChu() {
			window.location.href = 'https://taisan.lhbs.vn/';
		},
		redirectBaoSua() {
			window.location.href = 'https://taisan.lhbs.vn/BaoSua';
		},
		async getTaiSanLienKet() {
			try {
				const resp = await axios.post("/TS_TaiSan_SelectByMaCB_ChiTietTaiSan", {
					MaCaBiet: this.taiSanChon.MaCaBiet
				});
				this.dsTaiSanLienKet = resp.data.data
				// if (this.taiSan !== null && this.taiSan !== undefined) {
				this.dsTaiSanLienKet.unshift(this.taiSanChon)
				// if (this.dsTaiSanLienKet.some(item => item.MaCaBiet !== this.taiSan)) {
				// }
				// }
			} catch (error) {
				showMessage({
					type: "red",
					title: error.response?.data?.Message || "Lỗi lấy tài sản liên kết"
				});
			}
		},
		scrollToField(refName) {
			setTimeout(() => {
				const el = this.$refs[refName]?.$el || this.$refs[refName];
				if (el) {
					el.scrollIntoView({ behavior: 'smooth', block: 'center' });
				}
			}, 200);
		},
		xuLyScroll(value) {
			console.error(value)
		},
		async validate(refName, callback, reset = true) {

			const form = this.$refs[refName];
			if (!form) {
				console.warn(`Form ref "${refName}" not found.`);
				return;
			}

			const { valid } = await form.validate();
			if (valid && typeof callback === "function") {
				// console.error("ok rùi nè")

				const confirmed = await this.$refs.confirm.open('Bạn chắc chắn muốn gửi báo sửa!');
				if (!confirmed) return;
				await callback();
				if (reset) form.reset();
			} else {
				this.alert('error', 'Vui lòng nhập đầy đủ thông tin')
			}
		},
		updateScrollHeight() {
			this.$nextTick(() => {
				const dialogRef = this.$refs.dialogRef;
				const headerRef = this.$refs.headerRef;
				const dialogEl = dialogRef?.$el || dialogRef;
				const headerEl = headerRef?.$el || headerRef;
				if (headerEl && dialogEl) {
					const dialogHeight = dialogEl.offsetHeight;
					const headerHeight = headerEl.offsetHeight;
					// console.error("Cao dialog: ",dialogHeight);
					// console.error("Cao header: ",headerHeight);

					this.scrollHeight = window.innerHeight - headerHeight
				} else {
					console.warn('Không lấy được offsetHeight từ headerRef')
				}
			})
		},
		async load({ done }) {
			if (this.isEmpty) {
				done('empty');
				return;
			}
			await this.getDSTaiSanByPhongBanPerPage();
			done('ok');
			await this.getHinhAnhTS(this.dsTaiSanPerPage);
		},
		webSocketNe() {
			CALL(webSocketJoinGroup(this.test));
		},

		alert(kieu, message) {
			this.kieu = kieu;
			this.message = message;
			this.thongBao = true;
			setTimeout(() => {
				this.thongBao = false;
			}, 3000)
		},

		inputMaVach(value) {
			this.maVach = value.target.value.replace(/[^0-9]/g, '').slice(0, 8);
		},
		async tryCamera() {
			try {
				this.tracking = "QR";
				// Kiểm tra trạng thái quyền camera bằng navigator.permissions
				if ('permissions' in navigator && 'mediaDevices' in navigator) {
					const permissionStatus = await navigator.permissions.query({ name: 'camera' });
					console.log('Trạng thái quyền camera:', permissionStatus.state);

					if (permissionStatus.state === 'denied') {
						this.alert('error', "Vui lòng cấp quyền truy cập camera.");
						return;
					}

					if (permissionStatus.state === 'prompt' || permissionStatus.state === 'granted') {
						// Thử yêu cầu quyền camera để đảm bảo có thể truy cập
						const stream = await navigator.mediaDevices.getUserMedia({ video: true });
						console.log('Quyền camera được cấp, stream:', stream);

						// Dừng stream ngay sau khi kiểm tra (không cần giữ stream)
						stream.getTracks().forEach(track => track.stop());

						// Mở dialog nếu quyền được cấp
						this.showQrDialog = true;
					}
				} else {
					// Fallback: Nếu trình duyệt không hỗ trợ navigator.permissions
					console.warn('Trình duyệt không hỗ trợ navigator.permissions, thử getUserMedia trực tiếp.');
					const stream = await navigator.mediaDevices.getUserMedia({ video: true });
					stream.getTracks().forEach(track => track.stop());
					this.showQrDialog = true;
				}
			} catch (err) {
				console.error('Lỗi kiểm tra quyền camera:', err.message);
				if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
					this.alert('error', "Quyền truy cập camera bị từ chối.");
				} else if (err.name === 'NotFoundError') {
					this.alert('error', "Không tìm thấy camera trên thiết bị.");
					this.alert('error', "Quyền truy cập camera bị từ chối.")
				} else {
					this.alert('error', "Không thể kiểm tra quyền camera: " + err.message);
				}
			}
		},
		openDialogBaoSua(item) {
			// this.loaiDanhMuc = item;
			this.taiSanChon = item;
			this.isOpenDialogTaiSan = false;
			// this.isOpenDialogBaoSua = true;
			console.log(item)
		},
		checkScreen() {
			console.log("Màn hình: ", {
				name: this.$vuetify.display.name,
				width: this.$vuetify.display.width,
				height: this.$vuetify.display.height,
				smAndDown: this.$vuetify.display.smAndDown,
				xs: this.$vuetify.display.smAndDown,
				sm: this.$vuetify.display.sm,
				md: this.$vuetify.display.md,
				lg: this.$vuetify.display.lg,
				xl: this.$vuetify.display.xl,
			});
		},
		formatDate(dateString) {
			if (!dateString) return "";
			const date = new Date(dateString);
			if (isNaN(date)) return "";

			const day = String(date.getDate()).padStart(2, "0");
			const month = String(date.getMonth() + 1).padStart(2, "0");
			const year = date.getFullYear();

			return `${day}/${month}/${year}`;
		},
		async getMoTaLoiByMaCaBiet(maCaBiet) {
			try {
				const res = await axios.post('/TS_BaoSua_Select_DaCo_ByMaCaBiet', { MaCaBiet: maCaBiet });

				this.dsMoTa = res.data.data;
				if (this.dsMoTa.length > 0) {
					this.isConfirm = true;
				} else {
					this.isConfirm = false;
				};

			} catch (err) {
				console.error("Lỗi khi lấy mô ta lỗi: ", err);
				this.isConfirm = false;
			}
		},
		async getDSCoSo() {
			console.log("Hàm cơ sở");
			this.isLoadingCoSo = true;
			this.dsCoSo = await axios.post("/TS_CoSo_Select")
				.then((res) => {
					console.log("API cơ sở");
					if (typeof this.maCoSo !== 'undefined') {
						this.coSo = parseInt(this.maCoSo);
					}
					return res.data.data;
				})
				.catch((err) => { console.error(err) })
			this.isLoadingCoSo = false;
		},
		async getHinhAnhTS(ds) {
			await Promise.all(ds.map(async item => {
				if (item.KiemTraHinhAnh == 1) {
					if (this.imgCache[item.MaTS]) {
						item.HinhAnh = this.imgCache[item.MaTS];
					} else {
						try {
							const res = await axios.post("TS_TaiSan_SelectHinhAnh", { MaTS: item.MaTS });
							const hinhAnh = 'data:image/png;base64,' + res.data.data[0].HinhAnh;
							this.imgCache[item.MaTS] = hinhAnh;
							item.HinhAnh = hinhAnh;
						} catch (err) {
							const defaultImg = 'https://cdn.zentea.vn/filedata/lhbs-quanlyts/lhbs.png';
							this.imgCache[item.MaTS] = defaultImg;
							item.HinhAnh = defaultImg;
						}
					}
				} else {
					const defaultImg = 'https://cdn.zentea.vn/filedata/lhbs-quanlyts/lhbs.png';
					this.imgCache[item.MaTS] = defaultImg;
					item.HinhAnh = defaultImg;
				}
			}));
		},

		async getDSPhong() {
			this.isLoadingPhong = true;
			this.dsPhong = await axios.post("/TS_ViTriPhong_SelectByCoSo", {
				MaCoSo: this.coSo
			})
				.then((res) => {
					return res.data.data;
				})
				.catch((err) => {
					console.error(err);
				})
			this.isLoadingPhong = false;
			if (typeof this.maViTriPhong !== 'undefined') {
				this.phongBan = this.dsPhong.find(i => i.MaViTriPhong === parseInt(this.maViTriPhong));
			}
		},
		async getDSTaiSanByPhongBan() {
			try {
				this.isLoadingTenTaiSan = true;
				const res = await axios.post("/TS_CaBietTaiSan_ByPhongBanVaLoaiDanhMuc", {
					MaViTriPhong: this.phongBan.MaViTriPhong,
					MaLoai: this.loaiDanhMuc.MaLoai,
				})
				this.dsTaiSanByPhongBan = res.data.data;

				this.isLoadingTenTaiSan = false;
				// console.log(res.data.data)
			} catch (err) {
				console.error(err)
			}
		},

		async getDSTaiSanByPhongBanPerPage() {
			try {
				if (typeof this.phongBan != 'undefined') {
					// console.error("Phong: ", this.phongBan)
					// console.error(this.pageNumber);
					const res = await axios.post("/TS_CaBietTaiSan_ByPhongBanVaLoaiDanhMucPerPage", {
						MaViTriPhong: this.phongBan.MaViTriPhong,
						MaLoai: this.loaiDanhMuc.MaLoai,
						PageNumber: this.pageNumber,
					})
					const data = res.data.data;
					if (data != null && data.length === 0) {
						this.isEmpty = true;
					} else {
						data.forEach(item => {
							item.HinhAnh = '';
						});
						this.dsTaiSanPerPage.push(...data);
						this.pageNumber += 1;
					}
				}
				// console.log(res.data.data)
			} catch (err) {
				console.error(err)
			}
		},
		async getDSLoaiDanhMuc() {
			try {
				this.isLoadingDanhMuc = true;
				if (typeof this.phongBan != 'object') {
					return;
				}
				const res = await axios.post("/TS_SelectLoaiDanhMuc_ByViTriPhong", {
					MaViTriPhong: this.phongBan.MaViTriPhong
				})
				this.dsLoaiDanhMuc = res.data.data
				this.dsLoaiDanhMuc.unshift({ MaLoai: 0, TenLoai: '--Tất cả--' })
				this.isLoadingDanhMuc = false;

			} catch (err) {
				console.error(err);
			}
		},
		async getInfoByMaVach() {
			if (!!this.maVach && this.maVach.length == 8) {
				try {
					this.taiSan = await axios.post("/TS_TaiSan_Select_byQR", {
						QR: this.maVach
					})
						.then((res) => {
							console.log("API qr");
							this.showQrDialog = false;
							this.$refs.refMaVach.blur();
							return res.data.data[0];

						})
						.catch((err) => {
							this.showQrDialog = false
							// this.kieu = "error";
							// this.thongBao = true;
							// this.message = err.response.data.Message;
							showMessage({ type: "red", title: err.response.data.Message })
							this.maVach = null;
							console.log(err);
						})

					if (this.taiSan !== null || this.taiSan !== undefined) {

						this.fromAPI = true;
						this.coSo = this.taiSan.MaCoSo;
						this.phongBan = {
							MaViTriPhong: this.taiSan.MaViTriPhong,
							TenViTriPhong: this.taiSan.TenViTriPhong
						};
						this.taiSanChon = {
							MaCaBiet: this.taiSan.MaCaBiet,
							TenTaiSan: this.taiSan.TenTaiSan,
							MaLoai: this.taiSan.MaLoai,
							MaDM: this.taiSan.MaDM
						};
						this.loaiDanhMuc = {
							MaLoai: this.taiSan.MaLoai,
							TenLoai: this.taiSan.TenLoai
						};
						await this.getTaiSanLienKet();
						await this.getMoTaLoiByMaCaBiet(this.taiSan.MaCaBiet);
						// this.maVach=this.taiSan.MaVach
					}
				} catch (err) {
					// const error = err.response.data.Message;
					this.dsTai
					console.error(err)
					// this.alert('error', 'Lỗi')
				}
				finally {
					this.$nextTick(() => {
						this.fromAPI = false;
					});
				}
			}
		},

		// async getInfoByMaCaBiet(maCaBiet) {
		// 	try {
		// 		if (!maCaBiet) return;
		// 		this.taiSan = await axios.post("/TaiSan_Select_byMaCaBiet", {
		// 			MaCaBiet: maCaBiet
		// 		})
		// 			.then((res) => {
		// 				return res.data.data[0];
		// 			})
		// 			.catch((err) => {
		// 				showMessage({ type: "red", title: err.response.data.Message })

		// 			})

		// 		if (this.taiSan !== null || this.taiSan !== undefined) {

		// 			this.fromAPI = true;
		// 			this.coSo = this.taiSan.MaToaNha;
		// 			this.maVach = this.taiSan.MaVach;
		// 			this.phongBan = {
		// 				MaViTriPhong: this.taiSan.MaViTriPhong,
		// 				TenViTriPhong: this.taiSan.TenViTriPhong
		// 			};
		// 			this.taiSanChon = {
		// 				MaCaBiet: this.taiSan.MaCaBiet,
		// 				TenTaiSan: this.taiSan.TenTaiSan,
		// 				MaLoai: this.taiSan.MaLoai,
		// 				MaDM: this.taiSan.MaDM
		// 			};
		// 			this.loaiDanhMuc = {
		// 				MaLoai: this.taiSan.MaLoai,
		// 				TenLoai: this.taiSan.TenLoai
		// 			};
		// 			await this.getMoTaLoiByMaCaBiet(this.taiSan.MaCaBiet)
		// 		}
		// 	} catch (err) {
		// 		console.error(err)
		// 	}
		// 	finally {
		// 		this.$nextTick(() => {
		// 			this.fromAPI = false;
		// 		});
		// 	}

		// },
		async insertBaoSua() {
			// const { valid } = await this.$refs.form1.validate();
			// if (valid) {

			console.error(this.taiSanChon);
			this.isLoading = true;
			await axios.post("/TS_BaoSua_Insert", {
				MaCaBiet: this.taiSanChon.MaCaBiet,
				GhiChu: this.note,
				MaViTriPhong: this.phongBan.MaViTriPhong,
				HinhAnh: this.hinhAnh[0],
				MaLoai: this.taiSanChon.MaLoai,
				MaDM: this.taiSanChon.MaDM,
				Tracking: this.tracking
			})
				.then((res) => {
					// this.alert('success', "Cảm ơn bạn đã phản hồi")
					this.isOpenDialogTaiSan = false;
					this.isOpenDialogBaoSua = false;
					this.maVach = null;
					this.taiSan = null;
					this.note = null;
					this.phongBan = null;
					this.coSo = null;
					this.hinhAnh = [];
					this.dsPhong = [];
					this.dsLoaiDanhMuc = [];
					this.dsTaiSanByPhongBan = [];
					this.taiSanChon = null;
					this.loaiDanhMuc = { MaLoai: 0, TenLoai: '--Tất cả--' };
					this.isSuccess = true;
					console.log(res.data);
					CALL(webSocket_Send({
						group: "BaoSua",
						data: {
							ThongBao: 123,
						}
					}));
					this.isLoading = false;
					return res.data.data[0];
				})
				.catch((err) => {
					this.isLoading = false;
					console.log(err);
				})
			// }
			// else {
			// 	this.kieu = "warning";
			// 	this.thongBao = true;
			// 	this.message = "Vui lòng nhập đầy đủ thông tin!";
			// }
		},
		async getBaoSuaByNguoiBaoSua() {
			this.dialogLichSu = true;

			this.dsLichSua = await axios.post("/TS_BaoSua_SelectByNguoiBaoSua", {})
				.then((res) => {
					return res.data.data;
				})
				.catch((err) => {
					console.log(err);
				});
			console.log(this.dsLichSua);
		}
	}
	}
</script>