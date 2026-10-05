<template>
	<v-container class="px-0 pt-0 pb-0" fluid>
		<div :class="$vuetify.display.mdAndUp ? 'mx-2' : ''">
			<v-progress-linear :model-value="progress" height="2" color="blue" :buffer-value="100"></v-progress-linear>

		</div>
		<v-row v-if="$vuetify.display.mdAndUp">
			<v-col cols="12" md="3" class="ma-0 pb-0">
				<v-card elevation="2" class="px-2"
					style="border-radius: 12px; box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px; ">
					<!-- <v-card-title class="ml-0 pl-0 text- font-weight-bold"> -->
					<div class="d-flex mt-3 mb-3 text-primary">
						<v-badge inline class="" :content="dsBaoSuaMoi.length" color="red">
							<h4 style="" class="mr-2">Báo sửa mới</h4>
						</v-badge>
					</div>
					<v-virtual-scroll :items="dsBaoSuaMoi" height="650">
						<template v-slot:default="{ item }">
							<uc-baosua :priority="item.DoUuTien" :priorityname="item.TenDoUuTien" :key="item.MaBaoSua"
								:title="item.TenTaiSan" :department="item.TenViTriPhong" :note="item.GhiChu"
								:product="item.TenDanhMuc" :requestId="item.MaBaoSua" :user="item.HoTenNguoiBaoSua"
								:userid="item.CreateUser" :statusText="item.TenTinhTrang" :statusID="item.MaTinhTrang"
								:statuscolor="'green'" :timeAgo="item.TGBaoSua" @task-click="moDialogCapNhatBs(item)">

							</uc-baosua>
							<!-- <v-divider></v-divider> -->
						</template>
					</v-virtual-scroll>
				</v-card>
			</v-col>
			<v-col cols="12" md="9" class="ma-0 pb-0">
				<v-card>
					<!-- <v-select v-model="tinhTrangChon" :items="dsTinhTrang" item-title="ten" item-value="tinhTrang"
									label="Chọn tình trạng sửa chữa" outlined dense @update:model-value="layDsTheoTinhTrang" /> -->
					<!-- <v-card-title>Danh sách báo sửa</v-card-title> -->
					<v-toolbar density="default">
						<!-- <v-toolbar-title>Danh sách</v-toolbar-title> -->
						<!-- <v-spacer></v-spacer> -->

						<v-item-group v-model="tinhTrangChon" mandatory>
							<v-item :value="1" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaTiepNhan" size="small" color="deep-orange"
										:content="thongKe.DaTiepNhan">
										<v-icon size="small">mdi-format-list-bulleted</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-format-list-bulleted</v-icon>
									Tiếp nhận
								</v-btn>
							</v-item>
							<v-item :value="2" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaKiemTra" size="small" color="primary"
										:content="thongKe.DaKiemTra">
										<v-icon size="small">mdi-progress-check</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-progress-check</v-icon>
									Kiểm tra
								</v-btn>
							</v-item>

							<v-item :value="3" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DangSua" size="small" color="warning"
										:content="thongKe.DangSua">
										<v-icon size="small">mdi-cog-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-cog-outline</v-icon>
									Đang sửa
								</v-btn>
							</v-item>
							<v-item :value="4" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaSuaXong" size="small" color="success"
										:content="thongKe.DaSuaXong">
										<v-icon size="small">mdi-sticker-check-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-sticker-check-outline</v-icon>
									Sửa xong
								</v-btn>
							</v-item>

							<v-item :value="5" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.Hu" size="small" color="error" :content="thongKe.Hu">
										<v-icon size="small">mdi-close-octagon-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-close-octagon-outline</v-icon>
									Tài sản hư
								</v-btn>
							</v-item>

							<v-item :value="6" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.BaoSai" size="small" color="error" :content="thongKe.BaoSai">
										<v-icon size="small">mdi-bell-cancel-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-bell-cancel-outline</v-icon>
									Báo sai
								</v-btn>
							</v-item>
						</v-item-group>
						<v-spacer></v-spacer>
						<v-text-field class="mx-2" max-width="150" v-model="searchBaoSua" density="compact"
							label="Search" prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details
							single-line></v-text-field>
					</v-toolbar>
					<v-data-table-virtual density="compact" :items="dsBaoSua" :loading="loading"
						:headers="headersDsBaoSua" height="630" :search="searchBaoSua" item-value="MaBaoSua"
						fixed-header>

						<!-- <template #item="{ index, item }">
									<tr :class="index === hoveredIndex ? 'bg-blue-lighten-5' : ''"
										@mouseenter="hoveredIndex = index" @mouseleave="hoveredIndex = null">
										{{item.TenTaiSan}}
									</tr>
								</template> -->
						<template v-slot:item.HinhAnh="{ item }">
							<template v-if="item.HinhAnh == 1">
								<v-btn variant="text" color="primary" size="small" icon="mdi-image"
									@click="moDialogHinhAnh(item)">
								</v-btn>
							</template>
						</template>
						<!-- <template v-slot:item.DoUuTien="{item}">
							<v-chip v-if="item.DoUuTien" size="small" :color="getPriorityColor(item.DoUuTien)">
								{{item.TenDoUuTien}}</v-chip>
						</template> -->
						<template #item.TenTaiSan="{ item }">
							<!-- <uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" /> -->

						</template>

						<template #item.TenTinhTrang="{ item }">
							<!-- <v-chip size="small" :color="statusToColor(item.MaTinhTrang)">{{item.TenTinhTrang}}
							</v-chip> -->


							<v-timeline truncate-line="both" class="my-1" style="font-size: 10px" size="x-small"
								side="end" direction="horizontal">
								<v-timeline-item icon="mdi-send-circle" icon-color="white" dot-color="warning">
									<template v-slot:opposite>Báo sửa</template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">{{ getShortName(item.HoTenNguoiBaoSua) }}
										</div>
										<p>
											{{ splitDateTime(item.ThoiGianBaoSua).time }} <br />
											{{ splitDateTime(item.ThoiGianBaoSua).date }}
										</p>

									</div>
								</v-timeline-item>

								<v-timeline-item v-if="item.TiepNhan" icon-color="white" icon="mdi-tag"
									dot-color="teal-lighten-3">
									<template v-slot:opposite> Tiếp nhận </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">
											{{ getShortName(item.TiepNhan.TenNhanVienXuLy) }}</div>
										<p class="pa-0">
											{{ splitDateTime(item.TiepNhan.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.TiepNhan.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>

								<v-timeline-item v-if="item.KiemTra" icon-color="white" icon="mdi-clipboard-search"
									dot-color="teal-lighten-3">
									<template v-slot:opposite> Kiểm tra </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">
											{{ getShortName(item.KiemTra.TenNhanVienXuLy) }}</div>
										<p>
											{{ splitDateTime(item.KiemTra.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.KiemTra.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>
								<v-timeline-item v-if="item.DangSua" icon-color="white" icon="mdi-cog"
									dot-color="teal-lighten-3">
									<template v-slot:opposite> Đang sửa </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">
											{{ getShortName(item.DangSua.TenNhanVienXuLy) }}</div>
										<p>
											{{ splitDateTime(item.DangSua.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.DangSua.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>

								<v-timeline-item v-if="item.DaXong" icon="mdi-check" dot-color="success">
									<template v-slot:opposite> Sửa xong </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">
											{{ getShortName(item.DaXong.TenNhanVienXuLy) }}</div>
										<p>
											{{ splitDateTime(item.DaXong.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.DaXong.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>
								<v-timeline-item v-if="item.BaoSai" icon="mdi-cancel" icon-color="white"
									dot-color="error">
									<template v-slot:opposite> Báo sai </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">
											{{ getShortName(item.BaoSai.TenNhanVienXuLy) }}</div>
										<p>
											{{ splitDateTime(item.BaoSai.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.BaoSai.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>

								<v-timeline-item v-if="item.Hu" dot-color="error" icon="mdi-close-octagon-outline"
									icon-color="white">
									<template v-slot:opposite> Tài sản hư </template>
									<div class="text-center">
										<div class="text-caption text-no-wrap">{{ getShortName(item.Hu.TenNhanVienXuLy)
										}}
										</div>
										<p>
											{{ splitDateTime(item.Hu.ThoiGianXuLy).time }} <br />
											{{ splitDateTime(item.Hu.ThoiGianXuLy).date }}
										</p>
									</div>
								</v-timeline-item>
							</v-timeline>
						</template>
						<template v-slot:item.CapNhatBs="{ item }">
							<v-btn variant="text" color="primary" icon="mdi-square-edit-outline"
								@click="moDialogCapNhatBs(item)">
							</v-btn>
						</template>
					</v-data-table-virtual>
				</v-card>
			</v-col>
		</v-row>
		<!-- Mobile view -->
		<v-row v-else>
			<v-col>
				<!-- <v-select class="mb-2" v-model="tinhTrangSelected" :items="dsTinhTrang" item-title="TenTinhTrang"
					item-value="MaTinhTrang" label="Chọn tình trạng" outlined dense
					@update:model-value="getDsBaoSua(tinhTrangSelected)" />
				 -->

				<v-item-group v-model="tinhTrangChon" mandatory>
					<v-row>
						<v-col>
							<v-item :value="0" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn x-small @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.BaoSuaMoi" size="small" color="deep-orange"
										:content="thongKe.BaoSuaMoi">
										<v-icon size="small">mdi-assistant</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-assistant</v-icon>
									Báo sửa mới
								</v-btn>
							</v-item>
						</v-col>
					</v-row>
					<v-row>

						<v-col>
							<v-item :value="1" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaTiepNhan" size="small" color="deep-orange"
										:content="thongKe.DaTiepNhan">
										<v-icon size="small">mdi-format-list-bulleted</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-format-list-bulleted</v-icon>
									Tiếp nhận
								</v-btn>
							</v-item>
						</v-col>
						<v-col>
							<v-item :value="2" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaKiemTra" size="small" color="primary"
										:content="thongKe.DaKiemTra">
										<v-icon size="small">mdi-progress-check</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-progress-check</v-icon>
									Kiểm tra
								</v-btn>
							</v-item>
						</v-col>
						<v-col>
							<v-item :value="3" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DangSua" size="small" color="warning"
										:content="thongKe.DangSua">
										<v-icon size="small">mdi-cog-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-cog-outline</v-icon>
									Đang sửa
								</v-btn>
							</v-item>
						</v-col>
					</v-row>
					<v-row>
						<v-col>
							<v-item :value="4" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.DaSuaXong" size="small" color="success"
										:content="thongKe.DaSuaXong">
										<v-icon size="small">mdi-sticker-check-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-sticker-check-outline</v-icon>
									Sửa xong
								</v-btn>
							</v-item>
						</v-col>
						<v-col>
							<v-item :value="5" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.Hu" size="small" color="error" :content="thongKe.Hu">
										<v-icon size="small">mdi-close-octagon-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-close-octagon-outline</v-icon>
									Tài sản hư
								</v-btn>
							</v-item>
						</v-col>
						<v-col>
							<v-item :value="6" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn @click="toggle" class="text-none" block stacked
									:color="isSelected ? 'primary' : ''">
									<v-badge v-if="thongKe.BaoSai" size="small" color="error" :content="thongKe.BaoSai">
										<v-icon size="small">mdi-bell-cancel-outline</v-icon>
									</v-badge>
									<v-icon v-else size="small">mdi-bell-cancel-outline</v-icon>
									Báo sai
								</v-btn>
							</v-item>
						</v-col>
					</v-row>


				</v-item-group>

				<v-divider class="my-3"></v-divider>
				<v-sheet v-if="loading" :rounded="false" variant="text">
					<v-skeleton-loader :rounded="false" type="article"></v-skeleton-loader>
				</v-sheet>
				<v-card @click="moDialogCapNhatBs(bs)" v-else-if="dsBaoSua.length > 0" class="my-2 px-2 pt-2"
					width="100%" v-for="bs in dsBaoSua" :key="bs.MaBaoSua">
					<v-row class="">
						<v-col cols="2" style="max-width: 30px">
							<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2">
								<v-img :src="'https://file.lhbs.vn/me/avatarOrigin/' + bs.CreateUser + '.jpg'">
								</v-img>
							</v-avatar>
						</v-col>
						<v-col class="ml-1">
							<v-row>
								<v-col>
									<div class="d-flex align-center " style=" margin-top: -5px">
										<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

										<span>{{ bs.HoTenNguoiBaoSua }}</span>
									</div>
									<div class="d-flex align-center mt-0">
										<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

										<span style="margin-top: -3px; font-size: 11px;">{{ bs.NgayBaoSua
										}}</span>
									</div>
								</v-col>
								<v-col cols="5" class="d-flex justify-end">
									<v-chip @click="moDialogCapNhatBs(bs)" :color="statusToColor(bs.MaTinhTrang)">{{
										bs.TenTinhTrang }}
									</v-chip>
								</v-col>
							</v-row>
						</v-col>
					</v-row>
					<v-row class="py-1 mt-0">
						<v-col cols="12" class="d-flex">
							<v-icon class="mr-3" color="#1976D2">mdi-devices</v-icon>
							<!-- <uc-asset-info :macabiet="bs.MaCaBiet" :tentaisan="bs.TenTaiSan"
								classforname="text-body-2" />  -->
						</v-col>
					</v-row>
					<v-divider></v-divider>
					<v-row class="py-1">
						<v-col cols="12">
							<v-icon class="mr-2" color="#E53935">mdi-map-marker-radius-outline</v-icon>
							<span class="text-body-2">{{ bs.TenViTriPhong }}</span>
						</v-col>
					</v-row>
					<v-divider></v-divider>
					<v-row class="py-1 bg-grey-lighten-5">
						<v-col cols="12">
							<v-icon class="mr-2" color="#9E9E9E">mdi-message-text-outline</v-icon>
							<span class="text-subtitle-2 mr-2">{{ bs.GhiChu }}</span>
							<v-btn density="compact" v-if="bs.HinhAnh" @click.stop="getHinhAnh(bs.MaBaoSua)"
								variant="text" color="blue-darken-2" icon="mdi-image-outline"></v-btn>
						</v-col>
					</v-row>
				</v-card>
				<v-card v-else class="my-1 px-2 pt-2" width="100%">
					<v-card-text class="justify-center align-center text-center">Không có dữ liệu</v-card-text>
				</v-card>
			</v-col>

		</v-row>
		<!-- <uc-chi-tiet-sua-chua :key="childKey" v-if="isOpenChiTietBaoSua" @update="reloadData"
			ref="chiTietSua"></uc-chi-tiet-sua-chua> -->
	</v-container>
	<v-dialog v-model="isShowHinhAnh" max-width="500px">
		<v-card>
			<v-toolbar density="compact">
				<v-toolbar-title>Hình ảnh</v-toolbar-title>

				<v-btn variant="text" icon="mdi-close" @click="isShowHinhAnh = false"></v-btn>
			</v-toolbar>

			<v-divider></v-divider>
			<v-card-text class="text-center">
				<v-img v-if="hinhDinhKem" :src="`data:image/png;base64,` + hinhDinhKem" contain></v-img>
				<div v-else class="text-grey">Không có hình ảnh</div>
			</v-card-text>

		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			isOpenChiTietBaoSua: true,
			progress: 0,
			autoReload: null,
			searchBaoSua: null,
			tinhTrangSelected: 0,
			childKey: 0,
			dsBaoSuaMoi: [],
			dsBaoSua: [],
			isLoading: false,
			loading: false,
			dsTinhTrang: [],
			dialogCapNhatBs: false,
			baoSuaDangChon: null,
			isShowHinhAnh: false,
			hinhDinhKem: null,
			thongKe: {
				Tong: 0,
				BaoSuaMoi: 0,
				DaTiepNhan: 0,
				DaKiemTra: 0,
				DangSua: 0,
				DaSuaXong: 0
			},
			tinhTrangChon: 1,
			headersDsBaoSua: [
				{ title: "Phòng", key: "TenViTriPhong", nowrap: true },
				{ title: "Tên tài sản", key: "TenTaiSan" },

				{ title: "Ghi chú lỗi ", key: "GhiChu" },
				// { title: "Ưu tiên ", key: "DoUuTien" },

				// { title: "Ghi chú tiếp nhận", key: "GhiChuTiepNhan" },
				{ title: 'Hình', key: 'HinhAnh' },
				{ title: 'Tình trạng', key: 'TenTinhTrang', align: "center" },
				// { title: "Người gửi", key: "NguoiBaoSua" },
				// { title: "Người nhận", key: "NguoiTiepNhan" },
				// { title: "Ngày báo sửa", key: "ThoiGianBaoSua" },
				{ title: "Cập nhật", key: "CapNhatBs" }
			]
		}
	},
	async mounted() {
		// this.loading = true;
		// this.getTinhTrangBaoSua();
		// if (this.$vuetify.display.mdAndUp) {
		// 	this.tinhTrangChon = 1;
		// } else {
		// 	this.tinhTrangChon = 0;
		// };
		// this.getDsBaoSua(this.tinhTrangChon);
		// this.getBaoSuaMoi();
		// this.getThongKe();
		// this.loading = false;
		// this.batDauLoading();
	},
	beforeUnmount() {
		clearInterval(this.autoReload)
	},
	computed: {},
	watch: {
		tinhTrangChon() {
			this.getDsBaoSua(this.tinhTrangChon);
		}
	},
	methods: {
		batDauLoading() {
			const totalTime = 60000 // 60 giây
			const intervalTime = 100 // cập nhật mỗi 100ms
			const step = 100 / (totalTime / intervalTime)

			// Dọn interval cũ nếu có
			clearInterval(this.autoReload)
			this.progress = 0

			this.autoReload = setInterval(() => {
				if (this.progress < 100) { this.progress += step } else {
					this.progress = 0;
					this.ftest = 1;
					this.reloadData();
				}
			}, intervalTime)
		},

		moDialogHinhAnh(item) {
			this.getHinhAnh(item.MaBaoSua)
		},
		getPriorityColor(priorityLevel) {
			switch (priorityLevel) {
				case 4:
					return 'red'; // Khẩn cấp
				case 3:
					return 'orange'; // Cao
				case 2:
					return 'primary'; // Trung bình
				case 1:
					return 'green'; // Thấp
				default:
					return 'grey'; // Không xác định
			}
		},
		async reloadData() {
			this.getDsBaoSua(this.tinhTrangChon);
			// this.getThongKe();
			// this.getBaoSuaMoi();
		},
		async moDialogCapNhatBs(item) {
			// this.baoSuaDangChon = item;
			// this.isOpenChiTietBaoSua = true;

			// this.$refs.chiTietSua.open(item.MaBaoSua);

			this.baoSuaDangChon = item
			this.childKey++
			this.isOpenChiTietBaoSua = true
			await this.$nextTick()     // đợi Con mount xong
			this.$refs.chiTietSua.open(item.MaBaoSua)

			// this.childKey = this.childKey + 1;
		},
		async getBaoSuaMoi() {
			try {
				const res = await axios.post("TS_BaoSua_SelectBaoSuaMoi");
				this.dsBaoSuaMoi = res.data.data;

			} catch (error) {
				showMessage({ type: "red", title: error.response.data.Message });
			}
		},
		async getTinhTrangBaoSua(MaBaoSua) {
			try {

				const kq = await axios.post("TS_TinhTrangTiepNhanBaoSua_Select");

				this.dsTinhTrang = kq.data.data

			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi lấy tình trạng" });
			}
		},
		async getHinhAnh(MaBaoSua) {
			try {

				const kq = await axios.post("obj/TS_BaoSua_SelectHinhAnh", {
					MaBaoSua: MaBaoSua
				});

				this.hinhDinhKem = kq.data.data.HinhAnh
				this.isShowHinhAnh = true;
			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi khi tải hình ảnh" });
			}
		},
		async getDsBaoSua(TinhTrang) {
			try {
				this.loading = true;
				const res = await axios.post("TS_BaoSua_SelectByTinhTrangXuLy",
					{
						TinhTrang: TinhTrang
					});
				this.dsBaoSua = res.data.data;
				this.dsBaoSua.forEach(element => {
					element.TiepNhan = element.TiepNhan?.trim()
						? JSON.parse(element.TiepNhan)[0]
						: null;
					element.KiemTra = element.KiemTra?.trim()
						? JSON.parse(element.KiemTra)[0]
						: null;
					element.DangSua = element.DangSua?.trim()
						? JSON.parse(element.DangSua)[0]
						: null;
					element.DaXong = element.DaXong?.trim()
						? JSON.parse(element.DaXong)[0]
						: null;
					element.Hu = element.Hu?.trim()
						? JSON.parse(element.Hu)[0]
						: null;

					element.BaoSai = element.BaoSai?.trim()
						? JSON.parse(element.BaoSai)[0]
						: null;
				});
				await this.getBaoSuaMoi();
				await this.getThongKe();
				this.loading = false;
			} catch (error) {
				showMessage({ type: "red", title: error.response.data.Message });
			}
		},
		async getThongKe() {
			try {
				const res = await axios.post("obj/TS_BaoSua_ThongKe");
				this.thongKe = res.data.data;
			} catch (error) {
				showMessage({ type: "red", title: error.response.data.Message });
			}
		},
		getShortName(fullName, wordCount = 1) {
			if (!fullName) return "";

			const words = fullName.trim().split(/\s+/); // tách theo khoảng trắng
			return words.slice(-wordCount).join(" ");
		},
		splitDateTime(dateTimeStr) {
			const [date, time] = dateTimeStr.trim().split(" ");
			return { date, time };
		},
		statusToColor(id) {
			switch (id) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'deep-orange';
					break;
				case 2:
					return 'primary';
					break;
				case 3:
					return 'warning';
					break;
				case 4:
					return 'success';
					break;
				case 5:
					return 'error';
					break;
				case 6:
					return 'error';
					break;

				default:
					return 'green';
					break;
			}
		}
	},
}
</script>