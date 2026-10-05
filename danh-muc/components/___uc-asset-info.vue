<template>
	<v-dialog class="rounded" v-model="dialogThongTinTaiSan" max-width="600" :fullscreen="$vuetify.display.xs">
		<!-- Tên hiện, khi click sẽ mở chi tiết -->
		<template v-slot:activator="{ props: activatorProps }">
			<div @click="dialogThongTinTaiSan = true" v-bind="activatorProps" :class="classforname"
				style=" cursor: pointer;">
				{{ tentaisan }}
			</div>
		</template>

		<v-toolbar density="compact">
			<v-toolbar-title>Thông tin tài sản</v-toolbar-title>
			<v-btn icon="mdi-close" size="small" class="mr-2" @click="dialogThongTinTaiSan = false"></v-btn>
		</v-toolbar>

		<!-- Chi tiết thông tin tài sản -->
		<v-sheet color="basil" style="border-radius: 0px; margin-bottom: 56px">

			<v-sheet v-if="isLoading" :rounded="false" variant="text">
				<v-skeleton-loader :rounded="false" type="article"></v-skeleton-loader>
			</v-sheet>

			<v-card-text v-else-if="!thongTinChinh || !thongTinChinh.MaCaBiet" class="text-center">
				Không tìm thấy tài sản
			</v-card-text>

			<v-card-text v-else class="pt-0">
				<!-- Hình, tên -->
				<div class="d-flex align-center" style="grap: 1rem !important; height: 4.25rem !important;">
					<v-avatar tile
						:image="thongTinChinh?.Hinh && thongTinChinh.Hinh.trim() !== '' ? 'data:image/png;base64,' + thongTinChinh.Hinh : '/_cdn/lhbs-quanlyts/photo.png'"
						size="52"></v-avatar>
					<span v-if="!isEditTen" class="font-weight-bold mx-2"
						style="display: -webkit-box !important;	overflow: hidden !important;-webkit-box-orient: vertical !important;-webkit-line-clamp: 3 !important;font-size: 14px !important;line-height: 20px !important">
						{{ thongTinChinh.TenTaiSan }}


						<!-- <v-chip size="x-small">{{ thongTinChinh.TenTinhTrang}}</v-chip> -->
					</span>
					<v-form v-else style="width: 100%" ref="formEditTen">
						<v-text-field v-model="tenTaiSanUpdate" reqired
							:rules="[v => !!v || 'Vui lòng nhập tên tài sản']"></v-text-field>

					</v-form>
					<v-spacer></v-spacer>
					<v-btn v-if="isEditTen" variant="text" density="comfortable" color="error"
						icon="mdi-close-circle-outline" class="" @click="isEditTen = false">
					</v-btn>
					<v-btn v-if="isEditTen" variant="text" density="comfortable" color="primary" icon="mdi-content-save"
						class="mr-2" @click="validate('formEditTen', updateTenTaiSan)">
					</v-btn>
					<v-btn v-if="isEditTen" variant="text" density="comfortable" color="error" icon="mdi-delete"
						class="mr-2" @click="deleteTaiSan">
					</v-btn>

					<v-btn v-if="!isEditTen" variant="text" density="comfortable" icon="mdi-pencil-circle-outline"
						class="mr-2" @click="() => { tenTaiSanUpdate = thongTinChinh.TenTaiSan; isEditTen = true }"></v-btn>
				</div>

				<!-- Thông tin -->
				<v-expansion-panels elevation="0" id="asset" variant="accordion" class="d-flex" v-model="panelSelected">

					<!-- Thông số kỹ thuật -->
					<v-expansion-panel class="px-0 mx-0" :value="1">
						<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
							<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
							<span class="mx-2 text-subtitle-1">Thông số kỹ thuật</span>
						</v-expansion-panel-title>
						<!-- <v-divider></v-divider> -->
						<v-expansion-panel-text class="px-0 mx-0">
							<v-table density="compact" class="w-100">
								<tbody>
									<tr v-for="(ts, index) in thongTinChinh.ThongSoKyThuat" :key="index">

										<td class="text-grey-darken-1 py-1">{{ ts.TenThongSo }}:</td>
										<td class="pl-8" v-if="ts.TenThongSo == 'GPUs' && Array.isArray(ts.GiaTri)">
											<ul>
												<li v-for="(gpu, index) in ts.GiaTri" :key="index">
													{{ gpu.Name }}
												</li>
											</ul>
										</td>
										<td v-else class="">{{ ts.GiaTri }} {{ ts.DonVi }}</td>
									</tr>
								</tbody>
							</v-table>
						</v-expansion-panel-text>
					</v-expansion-panel>
					<!-- Thông số kỹ thuật thực tế -->
					<v-expansion-panel v-if="thongTinChinh.CauHinhThucTe.length > 0" class="px-0 mx-0" :value="200">
						<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
							<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
							<span class="mx-2 text-subtitle-1">Thông số kỹ thuật thực tế</span>
						</v-expansion-panel-title>
						<!-- <v-divider></v-divider> -->
						<v-expansion-panel-text class="px-0 mx-0">
							<v-table density="compact" class="w-100">
								<tbody>
									<tr>
										<td class="text-grey-darken-1 py-1">Hostname:</td>
										<td class="">{{ thongTinChinh.CauHinhThucTe[0].HostName }}</td>
									</tr>
									<tr>
										<td class="text-grey-darken-1 py-1">Last seen:</td>
										<td class="">{{ thongTinChinh.LastSeen }}
											<v-btn color="primary" density="compact" @click="isOpenLichSuKetNoi = true"
												icon variant="text">
												<v-icon>mdi-history</v-icon>
											</v-btn>
										</td>
									</tr>
									<tr>
										<td class="text-grey-darken-1 py-1">OS:</td>
										<td class="">{{ thongTinChinh.CauHinhThucTe[0].OS }}</td>
									</tr>
									<tr>
										<td class="text-grey-darken-1 py-1">CPU:</td>
										<td class="">{{ thongTinChinh.CauHinhThucTe[0].CPU }}</td>
									</tr>


									<tr>
										<td class="text-grey-darken-1 py-1">GPU:</td>
										<td class="pl-8">
											<ul>
												<li v-for="(gpu, index) in thongTinChinh.CauHinhThucTe[0].GPUs"
													:key="index">
													{{ gpu.Name }}
												</li>
											</ul>

										</td>
									</tr>


									<tr>
										<td class="text-grey-darken-1 py-1">RAM:</td>
										<td class="">
											<v-expansion-panels>
												<v-expansion-panel elevation="0" density="compact"
													v-for="(ram, index) in thongTinChinh.CauHinhThucTe[0].RAMs"
													:key="index" :value="300 + index">
													<v-expansion-panel-title min-height="30px" class="py-0 bg-white">
														<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
														<span class="mx-2 text-body-2">{{ ram.Capacity }} -
															{{ ram.Manufacturer }} - {{ ram.MemoryType }}</span>
													</v-expansion-panel-title>
													<v-expansion-panel-text>
														<v-table density="compact">
								<tbody>
									<tr v-for="(ts, index) in convertToDisplay(ram)" :key="index">
										<td class="text-grey-darken-1 py-1">{{ ts.TenThongSo }}:</td>
										<td class="">{{ ts.GiaTri }}</td>
									</tr>
								</tbody>
							</v-table>


						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
				</td>
				</tr>

				<tr>
					<td class="text-grey-darken-1 py-1">Disks:</td>
					<td class="">
						<v-expansion-panels>
							<v-expansion-panel elevation="0" density="compact"
								v-for="(disk, index) in thongTinChinh.CauHinhThucTe[0].Disks" :key="index"
								:value="300 + index">
								<v-expansion-panel-title min-height="30px" class="py-0 bg-white">
									<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
									<span class="mx-2 text-body-2">{{ disk.Size }} -
										{{ disk.Model }}</span>
								</v-expansion-panel-title>
								<v-expansion-panel-text class="px-2">

									<v-row v-for="(partition, name) in disk.Partitions" :key="name">
										<v-col cols="3"><b>{{ name }}</b></v-col>
										<v-col cols="9">

											<div class="d-flex justify-space-between">
												<div>{{ partition.Free }} free</div>
												<div>{{ partition.Total }} total</div>
											</div>
											<v-progress-linear :model-value="getUsedPercent(partition)" height="20"
												color="primary" rounded class="mt-1">
												<template #default>
													{{ getUsedPercent(partition) }}%
												</template>
											</v-progress-linear>

										</v-col>

									</v-row>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
					</td>
				</tr>
				<tr>
					<td class="text-grey-darken-1 py-1">Mainboard Manufacturer:</td>
					<td class="">{{ thongTinChinh.CauHinhThucTe[0].MainboardManufacturer }}</td>
				</tr>
				<tr>
					<td class="text-grey-darken-1 py-1">Mainboard Product:</td>
					<td class="">{{ thongTinChinh.CauHinhThucTe[0].MainboardProduct }}</td>
				</tr>

				<tr>
					<td class="text-grey-darken-1 py-1">Mainboard Serial:</td>
					<td class="">{{ thongTinChinh.CauHinhThucTe[0].MainboardSerial }}</td>
				</tr>

				</tbody>
				</v-table>
				</v-expansion-panel-text>
				</v-expansion-panel>

				<!-- Thông tin quản lý -->
				<v-expansion-panel :value="2">
					<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
						<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
						<span class="mx-2 text-subtitle-1">Thông tin quản lý</span>
					</v-expansion-panel-title>
					<!-- <v-divider></v-divider> -->
					<v-expansion-panel-text>
						<v-table density="compact" class="w-100">
							<tbody>
								<tr>
									<td class="text-grey-darken-1 py-1">Mã tài sản:</td>
									<td class="">
										{{ thongTinChinh.MaVach }}
										<!-- <v-tooltip max-width="200" max-height="200" activator="parent" location="top">
												<uc-mavach :ma-vach="thongTinChinh.MaVach"></uc-mavach>
											</v-tooltip> -->
									</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Số series:</td>
									<td class="">{{ thongTinChinh.SoSeries }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Ví trí:</td>
									<td class="">{{ thongTinChinh.TenViTriPhong }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Model:</td>
									<td class="">{{ thongTinChinh.TenModel }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Hãng sản xuất:</td>
									<td class="">{{ thongTinChinh.HangSanXuat }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Danh mục:</td>
									<td class="">{{ thongTinChinh.TenDanhMuc }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Mô tả:</td>
									<td class="">{{ thongTinChinh.MoTa }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Giá:</td>
									<td class="">{{ formatMoney(thongTinChinh.GiaTien) }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Cá nhân được cấp:</td>
									<td class="">{{ thongTinChinh.TenCaNhanDuocCap }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Phòng ban:</td>
									<td class="">{{ thongTinChinh.TenPhongBan }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Ngày nhập:</td>
									<td class="">{{ thongTinChinh.NgayNhap }}</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Bảo hành:</td>
									<td class="">{{ thongTinChinh.NgayBatDauBaoHanh }} - {{
										thongTinChinh.NgayHetHanBaoHanh }} </td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Chi phí vận hành:</td>
									<td class="">{{ formatMoney(thongTinChinh.ChiPhiGiaTriSuDung) }} </td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Thời gian khấu hao:</td>
									<td class="">{{ thongTinChinh.ThoiGianKhauHao }} Tháng</td>
								</tr>
								<tr>
									<td class="text-grey-darken-1 py-1">Giá trị còn lại sau khấu hao:</td>
									<td class="">{{ formatMoney(thongTinChinh.GiaTriConLai) }} </td>
								</tr>
							</tbody>
						</v-table>
					</v-expansion-panel-text>
				</v-expansion-panel>

				<!-- Tài sản liên kết -->
				<v-expansion-panel :value="3">
					<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
						<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
						<span class="mx-2 text-subtitle-1">Tài sản liên kết</span>
					</v-expansion-panel-title>
					<!-- <v-divider></v-divider> -->
					<v-expansion-panel-text>
						<v-row class="mt-0">
							<v-col class="pt-0">
								<v-card variant="text">
									<v-row class="py-2 px-3">
										<v-col class="text-grey-darken-1" cols="8"
											style="display: flex; align-items: center;">Tài
											sản liên kết</v-col>
										<v-col>
											<v-col class="d-flex justify-end ma-0  pa-0">
												<v-btn class="mr-1" outlined density="compact" color="primary"
													icon="mdi-plus" variant="tonal"
													@click="isOpenThemTaiSanLienKet = true">
												</v-btn>
											</v-col>
										</v-col>
									</v-row>

									<v-data-table :items="dsTaiSanLienKet" item-value="MaCaBiet"
										:headers="headerTaiSanLienKet" hide-default-footer hide-default-header>
										<template v-slot:item.TenTaiSan="{ item }">
											<div class="d-flex align-center flex-wrap">
												<uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
													:mataisan="item.MaTS" />
												<span class="text-caption ms-1">- {{ item.MaVach }}</span>
											</div>
										</template>
										<template v-slot:item.Xoa="{ item }">
											<v-btn color="red" density="compact" @click="deleteTaiSanCon(item.MaCaBiet)"
												icon variant="text">
												<v-icon>mdi-delete</v-icon>
											</v-btn>
										</template>
									</v-data-table>
								</v-card>
							</v-col>
						</v-row>
					</v-expansion-panel-text>
				</v-expansion-panel>

				<!-- Lịch sử luân chuyển -->
				<v-expansion-panel :value="4">
					<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
						<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
						<span class="mx-2 text-subtitle-1">Lịch sử luân chuyển</span>
					</v-expansion-panel-title>
					<!-- <v-divider></v-divider> -->
					<v-expansion-panel-text>
						<v-row class="mt-0">
							<v-col class="pt-0">
								<v-card variant="text">
									<v-card-text class="pa-0">
										<v-data-table :loading="isLoadingLuanChuyen" hide-default-footer
											:items="dsLichSuLuanChuyen" :headers="headerLichSu">

										</v-data-table>
									</v-card-text>
								</v-card>
							</v-col>
						</v-row>
					</v-expansion-panel-text>
				</v-expansion-panel>

				<!-- Lịch sử sửa chữa -->
				<v-expansion-panel :value="5">
					<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
						<!-- <v-icon color="warning">mdi-numeric-1-circle-outline</v-icon> -->
						<span class="mx-2 text-subtitle-1">Lịch sử sửa chữa</span>
					</v-expansion-panel-title>
					<!-- <v-divider></v-divider> -->
					<v-expansion-panel-text>
						<v-row class="mt-0">
							<v-col>
								<v-data-table :loading="isLoadingBaoSua" hide-default-footer :items="dsLichSuSuaChua"
									:headers="headerSuaChua">
									<template #item.Ngay="{ item }">
										<v-list-item class="pl-0">
											<v-list-item-title class="text-body-2">{{ item.NgayBaoSua }}
											</v-list-item-title>
											<v-list-item-subtitle>{{ item.GhiChu }}</v-list-item-subtitle>
										</v-list-item>

									</template>
									<template #item.TenTinhTrang="{ item }">
										<v-chip size="small" :color="statusToColor(item.MaTinhTrang)">
											{{ item.TenTinhTrang }}</v-chip>
									</template>
									<template #item.Xem="{ item }">
										<v-btn icon="mdi-open-in-new" @click="xemChiTietBaoSua(item)" variant="text"
											size="small" density="compact"></v-btn>
									</template>

								</v-data-table>
							</v-col>
						</v-row>
					</v-expansion-panel-text>
				</v-expansion-panel>
				</v-expansion-panels>
				<v-bottom-navigation grow color="primary">


					<v-btn value="nearby" @click="isOpenChuyenViTri = true">
						<v-icon>mdi-map-marker-radius</v-icon>
						<span>Chuyển vị trí</span>
					</v-btn>
					<v-btn value="recent" @click="isOpenUpdateQR = true">
						<v-icon>mdi-qrcode</v-icon>
						<span>Cập nhật QR</span>
					</v-btn>

					<v-btn block v-if="this.thongTinChinh.MaVach && this.thongTinChinh.TenViTriPhong" value="BaoSua"
						@click="openBaoSua">
						<v-icon>mdi-wrench</v-icon>

						<span>Báo sửa</span>
					</v-btn>
				</v-bottom-navigation>
			</v-card-text>
			<!-- <v-card-actions v-if="this.thongTinChinh.MaVach">
				<v-btn block value="BaoSua" @click="openBaoSua">
					<v-icon class="mr-2">mdi-wrench</v-icon>
				
					<span>Báo sửa</span>
				</v-btn>
			</v-card-actions> -->
		</v-sheet>

	</v-dialog>
	<!-- Hộp thoại xác nhận xóa -->
	<v-dialog v-model="showDialogDelete" max-width="500px">
		<v-card>
			<v-card-title class="headline">Xác nhận xoá</v-card-title>
			<v-divider class="mb-3"></v-divider>
			<v-card-text class="text-center">
				Bạn có chắc xoá dữ liệu không?
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="gray" variant="flat" text @click="showDialogDelete = false">Huỷ</v-btn>
				<v-btn color="red" variant="flat" text @click="deleteTaiSanCon(maCaBietCanXoa)">Đồng ý</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isOpenLichSuKetNoi" max-width="500px">
		<v-toolbar density="compact">
			<v-toolbar-title>Lịch sử kết nối</v-toolbar-title>
			<v-spacer></v-spacer>
			<v-btn icon="mdi-close" size="small" class="mr-2" @click="isOpenLichSuKetNoi = false"></v-btn>
		</v-toolbar>

		<!-- Chi tiết thông tin tài sản -->
		<v-sheet color="basil" style="border-radius: 0px; margin-bottom: 56px">
			<v-card-text>
				<v-data-table :loading="isLoadingLichSuKetNoi" hide-default-footer :items="dsLichSuKetNoi"
					:headers="headerLichSuKetNoi">


				</v-data-table>
			</v-card-text>

		</v-sheet>
	</v-dialog>

	<v-dialog v-model="isOpenUpdateQR" max-width="500px">
		<v-card>
			<v-form ref="formQR">
				<v-toolbar color="primary">
					<v-toolbar-title>{{ thongTinChinh.TenTaiSan }}</v-toolbar-title>
					<v-btn size="small" icon="mdi-close" @click="isOpenUpdateQR = false"></v-btn>
				</v-toolbar>
				<v-divider></v-divider>

				<v-card-text>

					<span v-if="thongTinChinh.MaVach" class="text-subtitle-1">Mã QR hiện tại:
						{{ thongTinChinh.MaVach }}</span>
					<v-autocomplete reqired :rules="[v => !!v || 'Vui lòng nhập dữ liệu']" class="my-2"
						style="min-width: 200px" v-model="qrUpdate" placeholder="Mã vạch" :items="dsMaVachChuaDung"
						item-value="MaVach" item-title="MaVach" density="compact" :clearable="false" hide-details>
					</v-autocomplete>

					<v-btn prepend-icon="mdi-qrcode-scan" variant="tonal" @click="showQrDialog = true">Quét mã
						QR</v-btn>
				</v-card-text>
				<v-divider></v-divider>

				<v-card-actions>

					<v-btn block variant="tonal" @click="validate('formQR', () => updateMaQR(maCaBietDangChon))"
						color="primary">
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
				<uc-qr v-model="qrUpdate" ref="qrScanner">
					<template v-slot:default>
						<v-row class="mt-2">
							<!-- Qr -->
							<v-col class="px-0" cols="4" style="text-align: right;"></v-col>

							<!-- Chọn hình ảnh -->
							<v-col class="px-0" cols="4" style="text-align: center;">
								<v-btn icon variant="flat" color="primary"
									@click="this.$refs.qrScanner?.triggerFileInput();">
									<v-icon color="white">mdi-image</v-icon>
								</v-btn>
								<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư viện</div>
							</v-col>

							<!-- Flash -->
							<v-col class="px-0" cols="4" style="text-align: left;"></v-col>
						</v-row>
					</template>
				</uc-qr>
			</v-card-text>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isOpenChuyenViTri" max-width="500px">
		<v-card>
			<v-form ref="formChuyenViTri">
				<v-toolbar color="">
					<v-toolbar-title>Chuyển vị trí</v-toolbar-title>
					<v-btn size="small" icon="mdi-close" @click="isOpenChuyenViTri = false"></v-btn>
				</v-toolbar>
				<v-divider></v-divider>

				<v-card-text>
					<span v-if="thongTinChinh.TenViTriPhong" class="text-subtitle-1">Vị trí hiện tại:
						{{ thongTinChinh.TenViTriPhong }}</span>

					<v-autocomplete reqired :rules="[v => !!v || 'Vui lòng vị trí']" class="my-3" density="compact"
						label="Vị trí phòng" :items="dsViTriPhong" v-model="viTriChuyenDen"
						item-title="TenViTriPhongCoSo" item-value="MaViTriPhong">
					</v-autocomplete>
				</v-card-text>
				<v-divider></v-divider>

				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn variant="tonal" @click="validate('formChuyenViTri', chuyenViTri)" color="primary">
						Chuyển
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isOpenThemTaiSanLienKet" max-width="500">
		<v-card>
			<v-card-text>
				<v-autocomplete v-model="taiSanConDangChon" chips label="Chọn tài sản liên kết"
					:items="dsTaiSanTrongPhongBan" item-title="TenTaiSan" item-value="MaCaBiet" multiple>
				</v-autocomplete>
			</v-card-text>
			<v-card-actions>
				<v-btn text="Đóng" variant="plain" @click="isOpenThemTaiSanLienKet = false"></v-btn>

				<v-btn color="primary" variant="tonal" class="text-white font-weight-bold" @click="insertTaiSanCon">
					Xác nhận
				</v-btn>
			</v-card-actions>

		</v-card>
	</v-dialog>
	<uc-chi-tiet-sua-chua ref="chiTietSua"></uc-chi-tiet-sua-chua>

	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
export default {
	props: ["tentaisan", "macabiet", "mataisan", "classforname"],
	data() {
		return {
			// editTenTaiSan: null,
			// editQR: null,
			panelSelected: null,
			showQrDialog: false,
			dsMaVachChuaDung: [],
			qrUpdate: null,
			isOpenUpdateQR: false,
			isOpenLichSuKetNoi: false,
			isLoadingLichSuKetNoi: false,
			dsLichSuKetNoi: [],
			isEditTen: false,
			tenTaiSanUpdate: "",
			maQR: null,
			maCaBietQR: null,
			isOpenChuyenViTri: false,
			isLoading: false,
			viTriChuyenDen: null,
			isLoadingLuanChuyen: false,
			isLoadingBaoSua: false,
			dialogHinhAnh: false,
			hinhDinhKem: "",
			dsTaiSanLienKet: [],
			dialogThongTinTaiSan: false,
			showDialogDelete: false,
			maCaBietCanXoa: null,
			taiSanConDangChon: [],
			dsViTriPhong: [],
			dialog: false,
			isOpenThemTaiSanLienKet: false,
			tab: "Thông tin tài sản",
			thongTinChinh: {
				MaCaBiet: "",
				TenTaiSan: "",
				TenModel: "",
				MaTS: "",
				MoTa: "",
				SoLuong: "",
				GiaTien: "",
				NgayNhap: "",
				NgayBatDauBaoHanh: "",
				NgayHetHanBaoHanh: "",
				HinhAnh: 0,
				ThongSoKyThuat: [],
				ChiPhiGiaTriSuDung: 0,
				ThoiGianKhauHao: 0,
				GiaTriConLai: 0,
				SoSeries: "",
			},

			dsChiTietTaiSan: {
				TenModel: "",
				MoTa: "",
				TenTaiSan: "",
				GiaTien: "",
				NgayBaoHanhChiTiet: "",
				NgayHetHanChiTiet: "",
			},
			dsLichSuLuanChuyen: [],
			dsLichSuSuaChua: [],
			headerLichSu: [
				// { title: "Phòng cũ", key: "PhongCu" },
				{ title: "Phòng", key: "PhongMoi" },
				{ title: "Vị trí", key: "TenViTriPhong" },
				{ title: "Nhân viên", key: "HoTenCaNhanDuocCap" },
				{ title: "Ngày chuyển", key: "NgayChuyen" },
			],
			headerTaiSanLienKet: [
				{ title: "Tên", key: "TenTaiSan" },
				{ title: "Xóa", key: "Xoa", align: "end" },
			],
			headerLichSuKetNoi: [
				{ title: "On", key: "CreateTime" },
				{ title: "Last seen", key: "LastSeen" },
				{ title: "Date", key: "Date" },
			],
			headerSuaChua: [
				{ title: "Ngày", key: "Ngay", align: "start" },

				// { title: "Người báo sửa", key: "NguoiBaoSua" },
				// { title: "Nhân viên tiếp nhận", key: "NguoiTiepNhan" },
				// { title: "Phòng", key: "TenViTriPhong" },
				{ title: "Tình trạng", key: "TenTinhTrang", nowrap: true },
				{ title: "Xem", key: "Xem" },
			],
			dsTaiSanTrongPhongBan: [],
		};
	},
	mounted() { },

	computed: {},
	watch: {

		async dialogThongTinTaiSan() {
			if (this.dialogThongTinTaiSan == true && !this.maQR) {
				await this.getThongTinTaiSan();
				await this.getTaiSanLienKet();
			} else {
				this.$emit("close");
			}
		},
		async isOpenThemTaiSanLienKet() {
			this.taiSanConDangChon = [];
			if (this.isOpenThemTaiSanLienKet == true) {
				await this.getTaiSanTrongPhongBan();
			}
		},
		panelSelected() {
			console.log(this.panelSelected);
			switch (this.panelSelected) {
				case 3:
					this.getTaiSanLienKet();
					break;
				case 4:
					this.getLichSuLuanChuyen();
					break;
				case 5:
					this.getLichSuSuaChua();
				default:
					break;
			}
		},
		async maQR() {
			if (this.maQR) {
				await this.getThongTinTaiSanTheoQR();
			}
		},

		async macabiet() {
			if (this.macabiet) {
				this.thongTinChinh.MaCaBiet = this.macabiet
				// await this.getThongTinTaiSanTheoQR();
			}
		},


		isOpenChuyenViTri() {
			if (this.isOpenChuyenViTri) {
				this.viTriChuyenDen = null;
				this.getDanhSachViTriPhong();
			}
		},
		isOpenUpdateQR() {
			if (this.isOpenUpdateQR) {
				this.getMaVachChuaDung();
			}
		},

		isOpenLichSuKetNoi() {
			if (this.isOpenLichSuKetNoi) {
				this.getLichSuKetNoi();
			}
		},
		qrUpdate() {
			if (this.qrUpdate) {
				this.showQrDialog = false;
			}
		},
	},
	methods: {
		async updateMaQR(MaCaBiet) {
			try {
				await axios
					.post("CaBietTaiSan_Insert_Mavach", {
						MaCB: this.thongTinChinh.MaCaBiet,
						MaVach: this.qrUpdate,
					})
					.then(() => {
						CALL({ MESS: "Cập nhật thành công" });
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message });
					});

				this.showCapNhatQR = false;
				this.update();
				await this.getThongTinTaiSan();
				this.isOpenUpdateQR = false;
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi cập nhật mã QR" });
			}
		},
		async validate(
			refName,
			callback,
			confirmText = "Bạn có muốn lưu dữ liệu?",
			reset = true
		) {
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
		update() {
			this.$emit("update");
		},
		close() {
			this.$emit("close");
		},
		getUsedPercent(partition) {
			const total = parseFloat(partition.Total);
			const free = parseFloat(partition.Free);
			const used = total - free;
			return Math.round((used / total) * 100);
		},
		convertToDisplay(obj) {
			return Object.entries(obj).map(([key, value]) => ({
				TenThongSo: key,
				GiaTri: value,
			}));
		},
		convertDiskToDisplay(disk) {
			const result = [];

			for (const [key, value] of Object.entries(disk)) {
				if (key === "Partitions" && typeof value === "object") {
					for (const [partitionName, partitionInfo] of Object.entries(value)) {
						for (const [subKey, subVal] of Object.entries(partitionInfo)) {
							result.push({
								TenThongSo: `Partition ${partitionName} ${subKey}`,
								GiaTri: subVal,
							});
						}
					}
				} else {
					result.push({
						TenThongSo: key,
						GiaTri: value,
					});
				}
			}

			return result;
		},
		openBaoSua() {
			window.location.href = "/TBDC-BaoSua?maVach=" + this.thongTinChinh.MaVach;
		},
		async open(ma) {
			this.maQR = ma;
			this.dialogThongTinTaiSan = true;
		},
		statusToColor(id) {
			switch (id) {
				case 0:
					return "error";
					break;
				case 1:
					return "deep-orange";
					break;
				case 2:
					return "primary";
					break;
				case 3:
					return "warning";
					break;
				case 4:
					return "success";
					break;
				case 5:
					return "error";
					break;
				case 6:
					return "error";
					break;

				default:
					return "green";
					break;
			}
		},
		xemChiTietBaoSua(item) {
			this.$refs.chiTietSua.open(item.MaBaoSua);
		},
		formatMoney(amount) {
			return new Intl.NumberFormat("vi-VN", {
				style: "currency",
				currency: "VND",
			}).format(amount);
		},

		async chuyenViTri() {
			try {
				await axios.post("DonVi_ChuyenViTriTaiSan", {
					DanhSachMaCaBiet: this.thongTinChinh.MaCaBiet.toString(),
					ViTriPhongID: this.viTriChuyenDen,
				});

				CALL({ MESS: "Cập nhật thành công" });
				this.update();

				this.isOpenChuyenViTri = false;
				await this.getThongTinTaiSan();
			} catch (error) {
				console.log(error);
				showMessage({ type: "red", title: error.response.data.Message });
			}
		},

		async getDanhSachViTriPhong() {
			try {
				const response = await axios.post("ViTriPhong_SelectByPhongBan", {
					PhongBanID: this.thongTinChinh.PhongBanID,
				});
				this.dsViTriPhong = response.data.data || [];
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi lấy vị trí phòng" });
			}
		},

		async getLichSuKetNoi() {
			try {
				const response = await axios.post("LichSuKetNoi_Select_ByMaCaBiet", {
					MaCaBiet: this.thongTinChinh.MaCaBiet,
				});
				this.dsLichSuKetNoi = response.data.data || [];
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi lấy lịch sử kết nối" });
			}
		},

		async getThongTinTaiSan() {
			try {
				this.isLoading = true;
				let maTim = null;
				maTim = this.macabiet ? this.macabiet : this.thongTinChinh.MaCaBiet;
				this.thongTinChinh = await axios
					.post("/obj/TS_TaiSan_SelectByMaTS", {
						MaCaBiet: maTim
					})
					.then((resp) => {
						return resp.data.data;
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message });
					});

				this.thongTinChinh.ThongSoKyThuat = this.thongTinChinh.ThongSoKyThuat
					? JSON.parse(this.thongTinChinh.ThongSoKyThuat)
					: [];

				this.thongTinChinh.ThongSoKyThuat.forEach((element) => {
					if (element.TenThongSo == "GPUs") {
						element.GiaTri = element.GiaTri ? JSON.parse(element.GiaTri) : [];
						console.log(element);
					}
				});

				this.thongTinChinh.CauHinhThucTe = this.thongTinChinh.CauHinhThucTe
					? JSON.parse(this.thongTinChinh.CauHinhThucTe)
					: [];

				this.thongTinChinh.CauHinhThucTe[0].RAMs = this.thongTinChinh
					.CauHinhThucTe[0].RAMs
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].RAMs)
					: [];

				this.thongTinChinh.CauHinhThucTe[0].GPUs = this.thongTinChinh
					.CauHinhThucTe[0].GPUs
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].GPUs)
					: [];
				// this.thongTinChinh.CauHinhThucTe[0].RAMs.forEach(element => {
				// // element = JSON.parse(element);
				// });

				this.thongTinChinh.CauHinhThucTe[0].Disks = this.thongTinChinh
					.CauHinhThucTe[0].Disks
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].Disks)
					: [];


				// this.thongTinChinh.CauHinhThucTe[0].Disks.forEach(element => {
				// 	// element = JSON.parse(element);
				// 	// element.Partitions = JSON.parse(element.Partitions)
				// });
				// console.log(this.thongTinChinh.CauHinhThucTe[0].Disks)
			} catch (error) {
				console.log(error);
			} finally {
				this.isLoading = false;
			}
		},

		async getThongTinTaiSanTheoQR() {
			try {
				this.isLoading = true;

				this.thongTinChinh = await axios
					.post("/obj/TaiSan_Select_ByMaQR", {
						MaQR: this.maQR,
					})
					.then((resp) => {
						return resp.data.data;
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message });
					});

				this.thongTinChinh.ThongSoKyThuat = this.thongTinChinh.ThongSoKyThuat
					? JSON.parse(this.thongTinChinh.ThongSoKyThuat)
					: [];

				this.thongTinChinh.ThongSoKyThuat.forEach((element) => {
					if (element.TenThongSo == "GPUs") {
						element.GiaTri = element.GiaTri ? JSON.parse(element.GiaTri) : [];
						console.log(element);
					}
				});
				this.thongTinChinh.CauHinhThucTe = this.thongTinChinh.CauHinhThucTe
					? JSON.parse(this.thongTinChinh.CauHinhThucTe)
					: [];

				this.thongTinChinh.CauHinhThucTe[0].RAMs = this.thongTinChinh
					.CauHinhThucTe[0].RAMs
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].RAMs)
					: [];
				this.thongTinChinh.CauHinhThucTe[0].GPUs = this.thongTinChinh
					.CauHinhThucTe[0].GPUs
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].GPUs)
					: [];

				this.thongTinChinh.CauHinhThucTe[0].Disks = this.thongTinChinh
					.CauHinhThucTe[0].Disks
					? JSON.parse(this.thongTinChinh.CauHinhThucTe[0].Disks)
					: [];
				this.maCaBietQR = this.thongTinChinh?.MaCaBiet || null;

			} catch (error) {
				console.log(error);
			} finally {
				// this.macabiet = this.thongTinChinh?.MaCaBiet || null;
				// alert(this.thongTinChinh.MaCaBiet)
				this.isLoading = false;
			}
		},

		formatCurrency(amount) {
			return amount.toLocaleString("vi-VN") + "đ";
		},

		async getLichSuLuanChuyen() {
			try {
				console.log(
					`macabiet: ${this.macabiet}, maCaBietQR: ${this.maCaBietQR}`
				);
				this.isLoadingLuanChuyen = true;
				this.dsLichSuLuanChuyen = await axios
					.post("/LogLuanChuyen_SelectByMaCaBiet", {
						MaCaBiet: this.thongTinChinh.MaCaBiet,
					})
					.then((resp) => {
						return resp.data.data;
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message });
					});
			} catch (error) {
			} finally {
				this.isLoadingLuanChuyen = false;
			}
		},

		async getLichSuSuaChua() {
			this.isLoadingBaoSua = true;
			this.dsLichSuSuaChua = await axios
				.post("/BaoSua_SelectByMaCaBiet", {
					MaCaBiet: this.thongTinChinh.MaCaBiet,
				})
				.then((resp) => {
					return resp.data.data;
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
			this.isLoadingBaoSua = false;
		},

		async getTaiSanLienKet() {
			this.dsTaiSanLienKet = await axios
				.post("/TaiSan_SelectByMaCB_ChiTietTaiSan", {
					MaCaBiet: this.thongTinChinh.MaCaBiet,
				})
				.then((resp) => {
					return resp.data.data;
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
		},

		closeDialog() {
			this.dialog = false;
		},

		async getTaiSanTrongPhongBan() {
			this.dsTaiSanTrongPhongBan = await axios
				.post("/TaiSan_SelectByViTriPhong_MaCaBiet", {
					MaCaBietCha: this.thongTinChinh.MaCaBiet,
				})
				.then((resp) => {
					return resp.data.data;
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
			console.log(this.dsTaiSanTrongPhongBan);
		},

		async updateTenTaiSan() {
			try {
				await axios.post("/TaiSan_Update_Ten", {
					MaTS: this.thongTinChinh.MaTS,
					TenTaiSan: this.tenTaiSanUpdate
				})
				CALL({ MESS: "Đã cập nhật" });
				this.isEditTen = false;
				this.getThongTinTaiSan()
				this.update();
			} catch (error) {
				showMessage({ type: "red", title: error.response.data.Message });
			}
		},

		async insertTaiSanCon() {
			await axios
				.post("/TaiSan_ChiTietTaiSanCon_Insert", {
					MaCaBietCha: this.thongTinChinh.MaCaBiet,
					ListMaCaBietCon: this.taiSanConDangChon.toString(),
				})
				.then((resp) => {
					this.isOpenThemTaiSanLienKet = false;
					CALL({ MESS: "Đã thêm" });
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
			this.getTaiSanLienKet();
			this.$emit("close");
			this.update();
		},

		async deleteTaiSanCon(MaCaBiet) {
			const confirmed = await this.$refs.confirm.open({
				title: "Xác nhận",
				message: "Bạn có muốn xóa tài sản liên kết?",
				okText: "Xóa",
				cancelText: "Hủy",
				okColor: "error",
				cancelColor: "blue-grey",
			});
			if (!confirmed) return;

			await axios
				.post("/TaiSan_ChiTietTaiSanCon_Delete", {
					MaCaBietCha: this.thongTinChinh.MaCaBiet,
					MaCaBietCon: MaCaBiet,
				})
				.then((resp) => {
					this.showDialogDelete = false;
					CALL({ MESS: "Đã xoá" });
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
			this.getTaiSanLienKet();
			this.update();
		},

		async deleteTaiSan(MaCaBiet) {
			const confirmed = await this.$refs.confirm.open({
				title: "Xác nhận",
				message: "Bạn có muốn xóa tài sản?",
				okText: "Xóa",
				cancelText: "Hủy",
				okColor: "error",
				cancelColor: "blue-grey",
			});
			if (!confirmed) return;

			await axios
				.post("/CaBietTaiSan_Delete", {
					MaCaBiet: this.thongTinChinh.MaCaBiet

				})
				.then((resp) => {
					this.showDialogDelete = false;
					CALL({ MESS: "Đã xoá" });
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message });
				});
			this.dialogThongTinTaiSan = false;
			this.update();
		},
		async getMaVachChuaDung() {
			this.dsMaVachChuaDung = await axios
				.post("MaVach_ChuaDung")
				.then((res) => {
					// console.log("data ne: ", res.data.data)
					return res.data.data;
				})
				.catch((err) => {
					showMessage({ type: "red", title: err.response.data.Message });
				});
		},
		async getHinhAnh(MaTS) {
			try {
				const response = await axios.post("/TaiSan_SelectHinhAnh", {
					MaTS: MaTS,
				});
				console.log(response.data.data[0].HinhAnh);
				if (response.data.data && response.data.data[0].HinhAnh) {
					this.hinhDinhKem = response.data.data[0].HinhAnh;
					this.dialogHinhAnh = true;
				} else {
					showMessage({ type: "red", title: "Không có hình ảnh" });
				}
			} catch (error) {
				showMessage({
					type: "red",
					title: error.response?.data?.Message || "Lỗi khi tải hình ảnh",
				});
			}
		},
	},
}
</script>