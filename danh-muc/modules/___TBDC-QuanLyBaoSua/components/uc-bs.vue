<template>
	<v-container fluid>
		<v-row>
			<v-col cols="12" >
				<v-card>
					<v-card-title>Báo sửa mới</v-card-title>
					<v-data-table-virtual :items="dsBaoSuaMoi" :headers="headersBaoSuaMoi" height="200"
						item-value="name" fixed-header>
						<template v-slot:item.HinhAnh="{ item }">
							<template v-if="item.HinhAnh == 1">
								<v-btn variant="text" color="green" size="small" icon="mdi-image"
									@click="moDialogHinhAnh(item)"></v-btn>
							</template>
						</template>
						<template v-slot:item.TiepNhan="{item}">
							<v-btn variant="text" color="green" size="small" icon="mdi-wrench-outline"
								@click="moDialogTiepNhan(item)"></v-btn>
						</template>
						<template #item.TenTaiSan="{ item }">
							<!-- <uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" classforname="font-weight-medium">
							</uc-asset-info> -->
						</template>
					</v-data-table-virtual>
				</v-card>
			</v-col>
			<!-- <v-col cols="12" md="6">
				<v-card>
					<v-card-title>Đã tiếp nhận</v-card-title>
					<v-data-table-virtual :items="dsDaTiepNhan" :headers="headersDaTiepNhan" height="200"
						item-value="name" fixed-header>
						<template v-slot:item.HinhAnh="{ item }">
							<template v-if="item.HinhAnh == 1">
								<v-btn variant="text" color="green" size="small" icon="mdi-image"
									@click="moDialogHinhAnh(item)"></v-btn>
							</template>
						</template>
						<template v-slot:item.CapNhat="{item}">
							<v-btn variant="text" color="green" size="small" icon="mdi-wrench-outline"
								@click="moDialogCapNhat(item)">
							</v-btn>
						</template>
						<template #item.TenTaiSan="{ item }">
							<uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" classforname="font-weight-medium">
							</uc-asset-info>
						</template>
					</v-data-table-virtual>
				</v-card>
			</v-col> -->
		</v-row>
		<v-row>
			<v-col cols="12">
				<v-card>
					<v-card-title>Quản lý báo sửa</v-card-title>
					<v-card-text>
						<v-select v-model="tinhTrangChon" :items="dsTinhTrang" item-title="ten" item-value="tinhTrang"
							label="Chọn tình trạng sửa chữa" outlined dense @update:model-value="layDsTheoTinhTrang" />
					</v-card-text>
					<v-data-table-virtual :items="dsBaoSua" :headers="headersDsBaoSua" height="200" item-value="name"
						fixed-header>
						<template v-slot:item.HinhAnh="{ item }">
							<template v-if="item.HinhAnh == 1">
								<v-btn variant="text" color="green" size="small" icon="mdi-image"
									@click="moDialogHinhAnh(item)"></v-btn>
							</template>
						</template>

						<template v-slot:item.CapNhatBs="{item}">
							<v-btn variant="text" color="green" size="small" icon="mdi-wrench-outline"
								@click="moDialogCapNhatBs(item)">
							</v-btn>
						</template>
						<template #item.TenTaiSan="{ item }">
							<!-- <uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" classforname="font-weight-medium">
							</uc-asset-info> -->
						</template>
					</v-data-table-virtual>
				</v-card>
			</v-col>

		</v-row>
		<!-- Dialog tiếp nhận  -->
		<v-dialog v-model="dialogTiepNhan" max-width="800px">
			<v-card>
				<!-- Tiêu đề dialog -->
				<v-card-title class="d-flex justify-space-between align-center"
					style="background-color: teal; color: white;">
					<v-icon class="mr-2">mdi-map-marker</v-icon>
					<span>{{ baoSuaDangChon?.TenViTriPhong }}</span>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogTiepNhan = false" style="color: white;">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<!-- Tabs -->
				<v-tabs v-model="tabTiepNhan" background-color="blue-grey lighten-5">
					<v-tab value="one">TIẾP NHẬN</v-tab>
					<v-tab value="two">LỊCH SỬ</v-tab>
				</v-tabs>

				<!-- Nội dung từng tab -->
				<v-tabs-window v-model="tabTiepNhan">
					<!-- Tab 1: Tiếp nhận -->
					<v-tabs-window-item value="one">
						<v-card-text>
							<v-textarea label="Ghi chú tiếp nhận" v-model="ghiChuTiepNhan" rows="4" />
						</v-card-text>

						<v-card-actions>
							<v-spacer></v-spacer>

							<v-btn color="teal" dark @click="themTiepNhanBaoSua">TIẾP NHẬN</v-btn>
						</v-card-actions>
					</v-tabs-window-item>

					<!-- Tab 2: Lịch sử -->
					<v-tabs-window-item value="two">
						<v-card-text>
							<v-data-table :headers="headersLichSuBaoSua" :items="lichSuTiepNhan" dense
								hide-default-footer no-data-text="Không có lịch sử" />
						</v-card-text>
					</v-tabs-window-item>
				</v-tabs-window>
			</v-card>
		</v-dialog>

		<!-- Dialog cập nhât -->

		<v-dialog v-model="dialogCapNhat" max-width="800" scrollable>
			<v-card style="max-height: 90vh; display: flex; flex-direction: column;">

				<!-- Tiêu đề dialog -->
				<v-card-title class="d-flex justify-space-between align-center"
					style="background-color: teal; color: white;">
					<v-icon class="mr-2">mdi-map-marker</v-icon>
					<span>{{ baoSuaDangChon?.TenViTriPhong }}</span>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogCapNhat = false" style="color: white;">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<!-- Tabs -->
				<v-tabs v-model="tabCapNhat" background-color="blue-grey lighten-5">
					<v-tab value="one">Kiểm Tra Thông Tin</v-tab>
					<v-tab value="two">LỊCH SỬ</v-tab>
				</v-tabs>

				<!-- Nội dung chính có thể cuộn -->
				<v-card-text style="overflow-y: auto; flex: 1;">
					<v-tabs-window v-model="tabCapNhat">
						<!-- Tab 1: Kiểm Tra Thông Tin -->
						<v-tabs-window-item value="one">
							<v-form ref="formCapNhat">
								<!-- Báo sửa đúng / sai -->
								<v-radio-group v-model="baoSuaDung" inline>
									<v-radio :value="1" label="Báo sửa đúng" />
									<v-radio :value="3" label="Báo sửa sai" />
								</v-radio-group>

								<!-- Mã vạch và Tên tài sản -->
								<!-- <v-row dense>
									<v-col cols="12" sm="6">
										<v-text-field label="Mã vạch" v-model="baoSuaDangChon.MaVach" />
									</v-col>
									<v-col cols="12" sm="6">
										<v-select :items="dsTaiSan" label="Tên tài sản" item-value="MaCaBiet" item-title="TenTaiSan"
											v-model="baoSuaDangChon.TenTaiSan" />
									</v-col>
								</v-row> -->
								<v-row dense>
									<v-col cols="12" sm="6" class="mt-2">
										<div class="text-subtitle-1 font-weight-bold">
											Mã tài sản: {{ baoSuaDangChon.MaVach }}
										</div>
										<div class="text-subtitle-1 font-weight-bold">
											Tên tài sản: {{ baoSuaDangChon.TenTaiSan }}
										</div>
										<div class="text-subtitle-1 font-weight-bold">
											Ghi chú lỗi: {{ baoSuaDangChon.GhiChu }}
										</div>
									</v-col>
								</v-row>


								<!-- Nguyên nhân & Ghi chú -->
								<v-textarea label="Nguyên nhân (*)" v-model="nguyenNhan" :rules="[rule.required]"
									outlined required class="mt-2" />
								<v-textarea label="Ghi chú kiểm tra" v-model="ghiChuKiemTra" outlined class="mt-2"
									:rows="1" />
								<v-text-field label="Chi Phí" v-model="formatchiPhi" :clearable="false"
									@keypress="onlyNumberInput" outlined class="mt-2" type="tel" />

								<!-- Danh sách tài sản liên kết -->
								<v-row>
									<v-col style="margin: 5px 0 0;" class="text-subtitle-1 text-grey-darken-1" cols="6">
										<b>Danh sách tài sản liên kết: </b>
									</v-col>
									<v-col cols="6" align-self="center">
										<div style="display: flex; justify-content: flex-end;">
											<v-btn class="my-2" rounded size="small" color="primary"
												prepend-icon="mdi-plus" @click="modialogThemTaiSanCon"
												text="Thêm tài sản liên kết" variant="tonal" />
										</div>
									</v-col>
								</v-row>

								<!-- Chi tiết tài sản -->
								<v-row>
									<v-col>
										<v-expansion-panels class="mt-3">
											<v-expansion-panel v-for="(item, index) in dsChiTietTaiSan" :key="index">
												<v-expansion-panel-title style="padding-top: 0px; padding-bottom: 0px">
													<div class="d-flex justify-space-between align-center"
														style="width: 100%;">
														<span>{{ item.TenTaiSan }}</span>
														<v-spacer></v-spacer>
														<v-btn v-if="item.HinhAnh == 1" @click="getHinhAnhTs(item.MaTS)"
															variant="text" color="blue-darken-2"
															icon="mdi-image-outline" />
														<v-btn size="x-small" icon="mdi-delete" variant="text"
															color="red"
															@click.stop="()=>{maCaBietCanXoa = baoSuaDangChon.MaCaBiet == item.MaCaBietCon ? item.MaCaBietCha : item.MaCaBietCon; showDialogDelete=true}">
														</v-btn>
													</div>
												</v-expansion-panel-title>

												<v-expansion-panel-text>
													<v-row class="py-1">
														<v-col cols="3"><b>Mã QR:</b></v-col>
														<v-col>{{ item.MaVach }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Model:</b></v-col>
														<v-col>{{ item.TenModel }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Mô tả:</b></v-col>
														<v-col>{{ item.MoTa }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Giá tiền:</b></v-col>
														<v-col>{{ formatCurrency(item.GiaTien ? item.GiaTien : 0)
															}}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Ngày bắt đầu bảo hành:</b></v-col>
														<v-col>{{ item.NgayBaoHanhChiTiet }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Ngày hết hạn bảo hành:</b></v-col>
														<v-col>{{ item.NgayHetHanChiTiet }}</v-col>
													</v-row>
												</v-expansion-panel-text>
											</v-expansion-panel>
										</v-expansion-panels>
									</v-col>
								</v-row>

								<!-- Dialog chọn tài sản con -->
								<v-dialog v-model="dialogThemTaiSanCon" max-width="500">
									<v-card>
										<v-card-text>
											<v-autocomplete v-model="taiSanConDangChon" chips label="Chọn tài sản con"
												:items="dsTaiSanTrongPhongBan" item-title="TenTaiSan"
												item-value="MaCaBiet" multiple />
										</v-card-text>
										<v-card-actions>
											<v-btn text="Đóng" variant="plain" @click="dialogThemTaiSanCon = false" />
											<v-btn color="primary" variant="tonal" class="text-white font-weight-bold"
												@click="insertTaiSanCon">
												Xác nhận
											</v-btn>
										</v-card-actions>
									</v-card>
								</v-dialog>
							</v-form>
						</v-tabs-window-item>

						<!-- Tab 2: Lịch sử -->
						<v-tabs-window-item value="two">
							<v-card-text>
								<v-data-table :headers="headersLichSuBaoSua" :items="lichSuTiepNhan" dense
									hide-default-footer no-data-text="Không có lịch sử" />
							</v-card-text>
						</v-tabs-window-item>
					</v-tabs-window>
				</v-card-text>

				<!-- Nút thao tác dưới -->
				<v-card-actions>
					<v-spacer></v-spacer>

					<v-btn color="teal" dark @click="validate('formCapNhat',capNhatBaoSua)">CẬP NHẬT</v-btn>
					<v-btn color="teal" dark @click="validate('formCapNhat',capNhatHoanThanhBs)">Hoàn Thành</v-btn>
				</v-card-actions>

			</v-card>
		</v-dialog>

		<!-- dialog kiem tra báo sửa -->
		<v-dialog v-model="dialogCapNhatBs" max-width="800px" scrollable>
			<v-card style="max-height: 90vh; display: flex; flex-direction: column;">
				<!-- Tiêu đề dialog -->
				<v-card-title class="d-flex justify-space-between align-center"
					style="background-color: teal; color: white;">
					<v-icon class="mr-2">mdi-map-marker</v-icon>
					<span>{{ baoSuaDangChon?.TenViTriPhong }}</span>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogCapNhatBs = false" style="color: white;">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<!-- Tabs -->
				<v-tabs v-model="tabCapNhatBs" background-color="blue-grey lighten-5">
					<v-tab value="one">Thông Tin Sửa Chữa</v-tab>
					<v-tab value="two">LỊCH SỬ</v-tab>
				</v-tabs>

				<!-- Nội dung cuộn -->
				<v-card-text style="overflow-y: auto; flex: 1;">
					<v-tabs-window v-model="tabCapNhatBs">
						<!-- Tab 1: Kiểm Tra Thông Tin -->
						<v-tabs-window-item value="one">
							<v-form ref="formKiemTra">
								<!-- Báo sửa đúng / sai -->
								<v-radio-group v-model="suaTaiSan" inline required>
									<v-radio :value="true" label="Sửa tài sản" />
									<v-radio :value="false" label="Thay tài sản mới" />
								</v-radio-group>

								<!-- Ghi chú sửa -->
								<v-textarea label="Ghi Chú Sửa (*)" v-model="ghichusua"
									:rules="[v => !!v || 'Bắt buộc nhập nguyên nhân']" outlined required class="mt-2" />

								<!-- Chi phí -->
								<v-text-field label="Chi Phí" v-model="chiPhi" :clearable="false"
									@keypress="onlyNumberInput" outlined class="mt-2" type="number" />


								<!-- Đã sửa xong -->
								<v-radio-group v-model="daSuaXong" inline>
									<v-radio :value="6" label="Đã sửa xong và thiết bị hoạt động tốt" />
									<v-radio :value="7" label="Tài sản hư không sửa được" />
								</v-radio-group>

								<!-- Thành phần con -->
								<v-row>
									<v-col style="margin: 5px 0 0;" class="text-subtitle-1 text-grey-darken-1" cols="6">
										<b>Danh sách tài sản liên kết: </b>
									</v-col>
									<v-col cols="6" align-self="center">
										<div style="display: flex; justify-content: flex-end;">
											<v-btn class="my-2" rounded size="small" color="primary"
												prepend-icon="mdi-plus" @click="modialogThemTaiSanCon"
												text="Thêm tài sản liên kết" variant="tonal" />
										</div>
									</v-col>
								</v-row>

								<!-- Chi tiết tài sản -->
								<v-row>
									<v-col>
										<v-expansion-panels class="mt-3">
											<v-expansion-panel v-for="(item, index) in dsChiTietTaiSan" :key="index">
												<v-expansion-panel-title style="padding-top: 0px; padding-bottom: 0px">
													<div class="d-flex justify-space-between align-center"
														style="width: 100%;">
														<span>{{ item.TenTaiSan }}</span>
														<v-spacer></v-spacer>
														<v-btn v-if="item.HinhAnh == 1" @click="getHinhAnhTs(item.MaTS)"
															variant="text" color="blue-darken-2"
															icon="mdi-image-outline" />
														<v-btn size="x-small" icon="mdi-delete" variant="text"
															color="red"
															@click.stop="()=>{maCaBietCanXoa = baoSuaDangChon.MaCaBiet == item.MaCaBietCon ? item.MaCaBietCha : item.MaCaBietCon; showDialogDelete=true}">
														</v-btn>
													</div>
												</v-expansion-panel-title>

												<v-expansion-panel-text>
													<v-row class="py-1">
														<v-col cols="3"><b>Mã QR:</b></v-col>
														<v-col>{{ item.MaVach }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Model:</b></v-col>
														<v-col>{{ item.TenModel }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Mô tả:</b></v-col>
														<v-col>{{ item.MoTa }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Giá tiền:</b></v-col>
														<v-col>{{ formatCurrency(item.GiaTien ? item.GiaTien : 0)
															}}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Ngày bắt đầu bảo hành:</b></v-col>
														<v-col>{{ item.NgayBaoHanhChiTiet }}</v-col>
													</v-row>
													<v-divider></v-divider>
													<v-row class="py-1">
														<v-col cols="3"><b>Ngày hết hạn bảo hành:</b></v-col>
														<v-col>{{ item.NgayHetHanChiTiet }}</v-col>
													</v-row>
												</v-expansion-panel-text>
											</v-expansion-panel>
										</v-expansion-panels>
									</v-col>
								</v-row>

								<!-- Dialog chọn tài sản con -->
								<v-dialog v-model="dialogThemTaiSanCon" max-width="500">
									<v-card>
										<v-card-text>
											<v-autocomplete v-model="taiSanConDangChon" chips label="Chọn tài sản con"
												:items="dsTaiSanTrongPhongBan" item-title="TenTaiSan"
												item-value="MaCaBiet" multiple />
										</v-card-text>
										<v-card-actions>
											<v-btn text="Đóng" variant="plain" @click="dialogThemTaiSanCon = false" />
											<v-btn color="primary" variant="tonal" class="text-white font-weight-bold"
												@click="insertTaiSanCon">
												Xác nhận
											</v-btn>
										</v-card-actions>
									</v-card>
								</v-dialog>
							</v-form>
						</v-tabs-window-item>

						<!-- Tab 2: Lịch sử -->
						<v-tabs-window-item value="two">
							<v-data-table :headers="headersLichSuBaoSua" :items="lichSuTiepNhan" dense
								hide-default-footer no-data-text="Không có lịch sử" />
						</v-tabs-window-item>
					</v-tabs-window>
				</v-card-text>

				<!-- Footer buttons -->
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="teal" dark @click="validate('formKiemTra', kiemTraBaoSua)">CẬP NHẬT</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- dialog Hinh Anh -->
		<v-dialog v-model="dialogHinhAnh" max-width="600px">
			<v-card>
				<v-card-title class="text-h6">Hình ảnh báo sửa</v-card-title>
				<v-card-text class="d-flex justify-center">
					<v-img v-if="hinhAnh" :src="'data:image/png;base64, ' +hinhAnh" max-width="100%" max-height="400"
						contain></v-img>
					<div v-else>Đang load hình ảnh</div>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="primary" text @click="dialogHinhAnh = false">ĐÓNG</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>


		<v-dialog v-model="dialogThemTaiSanCon" max-width="500">
			<v-card>
				<v-card-text>
					<v-autocomplete v-model="taiSanConDangChon" chips label="Chọn tài sản con"
						:items="dsTaiSanTrongPhongBan" item-title="TenTaiSan" item-value="MaCaBiet" multiple>
					</v-autocomplete>
				</v-card-text>
				<v-card-actions>
					<v-btn text @click="dialogThemTaiSanCon = false">Đóng</v-btn>
					<v-btn color="primary" class="white--text font-weight-bold" @click="insertTaiSanCon">
						Xác nhận
					</v-btn>
				</v-card-actions>

			</v-card>
		</v-dialog>

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
	</v-container>
	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
	
				dsDaTiepNhan: [],
				tabTiepNhan: 0,
				tabCapNhat: 0,
				tabCapNhatBs: 0,
				dialogThongTinTaiSan: false,
				dialogTiepNhan: false,
				dialogCapNhat: false,
				dialogCapNhatBs: false,
				ghiChuTiepNhan: null,
				showDialogDelete: false,
				maCaBietCanXoa: null,
				baoSuaDangChon: null,
				dsBaoSuaMoi: [],
				nguyenNhan: null,
				lichSuTiepNhan: [],
				dsTaiSan: [],
				tinhTrangChon: 1,
				dsBaoSua: [],
				taiSanConDangChon: null,
				dialogThemTaiSanCon: false,
				dsChiTietTaiSan: [],
				dsTaiSanTrongPhongBan: [],
				ghiChuKiemTra: null,
				rule: {
					required: v => !!v || 'Bắt buộc nhập nguyên nhân'
				},
				dialogHinhAnh: false,
				hinhAnh: null,
				dongDangChon: null,
				baoSuaDung: 1,
	
				chiPhi: null,
				ghichusua: null,
				suaTaiSan: true,
				daSuaXong: 6,
	
	
	
				dsTinhTrang: [
					{ ten: "Đã tiếp nhận", tinhTrang: 1 },
					{ ten: "Đã kiểm tra", tinhTrang: 2 },
					{ ten: "Đang sửa", tinhTrang: 3 },
					{ ten: "Đã hoàn thành", tinhTrang: 4 }
	
	
				],
	
				headersBaoSuaMoi: [
					{ title: 'Thời gian gửi', key: 'TGBaoSua' },
					{ title: 'Mã tài sản', key: 'MaVach' },
					{ title: 'Tên tài sản', key: 'TenTaiSan' },
					{ title: 'Danh mục', key: 'TenDanhMuc' },
					{ title: 'Ghi chú lỗi', key: 'GhiChu' },
					{ title: 'Hình ảnh', key: 'HinhAnh' },
					{ title: 'Tiếp nhận', key: 'TiepNhan' },
				],
				headersLichSuBaoSua: [
					{ title: "Người báo sửa", key: "NguoiBaoSua" },
					{ title: "Thời gian báo sửa", key: "TGBaoSua" },
					{ title: "Nội dung báo sửa", key: "GhiChu" },
					{ title: "Phòng", key: "TenViTriPhong" }
				],
				headersDaTiepNhan: [
					{ title: "Tên vị trí phòng", key: "TenViTriPhong" },
					{ title: "Tên tài sản", key: "TenTaiSan" },
					{ title: "Danh mục", key: "TenDanhMuc" },
					{ title: 'Hình ảnh', key: 'HinhAnh' },
					{ title: 'Ghi chú lỗi', key: 'GhiChu' },
					{ title: "Ghi chú tiếp nhận", key: "GhiChuTiepNhan" },
					{ title: "Người gửi", key: "NguoiBaoSua" },
					{ title: "Người nhận", key: "NguoiTiepNhan" },
					{ title: "Cập nhật", key: "CapNhat" }
				],
				headersDsBaoSua: [
					{ title: "Tên vị trí phòng", key: "TenViTriPhong" },
					{ title: "Tên tài sản", key: "TenTaiSan" },
					{ title: "Danh mục", key: "TenDanhMuc" },
					{ title: "Ghi chú lỗi ", key: "GhiChu" },
					{ title: "Ghi chú tiếp nhận", key: "GhiChuTiepNhan" },
					{ title: 'Hình ảnh', key: 'HinhAnh' },
					{ title: "Người gửi", key: "NguoiBaoSua" },
					{ title: "Người nhận", key: "NguoiTiepNhan" },
					{ title: "Cập nhật", key: "CapNhatBs" }
				]
	
			}
		},
	
		mounted() {
			// this.getBaoSuaMoi();
			// this.getDaTiepNhan();
			// this.getDsBaoSua();
	
		},
		watch: {
			tabTiepNhan(val) {
				if (val === 'two' && this.baoSuaDangChon) {
					this.layLichSuTiepNhan(this.baoSuaDangChon.MaCaBiet);
	
				}
			},
			tabCapNhat(val) {
				if (val === 'two' && this.baoSuaDangChon) {
					this.layLichSuTiepNhan(this.baoSuaDangChon.MaCaBiet);
					this.baoSuaDung = 1;
	
				}
			},
			tabCapNhatBs(val) {
				if (val === 'two' && this.baoSuaDangChon) {
					this.layLichSuTiepNhan(this.baoSuaDangChon.MaCaBiet);
					this.baoSuaDung = true;
				}
			},
			dialogCapNhat(val) {
				this.baoSuaDung = 1;
			},
			dialogCapNhatBs(val) {
				this.suaTaiSan = true;
				this.daSuaXong = 6;
			},
			tinhTrangChon() {
				this.getDsBaoSua();
	
			},
	
	
		},
		computed: {
			formatchiPhi: {
				get() {
					if (this.chiPhi === null || this.chiPhi === '') return '';
					const value = Number(this.chiPhi);
					if (isNaN(value)) return '';
					return value.toLocaleString('vi-VN') + ' đ';
				},
				set(newValue) {
					const cleanedValue = newValue.replace(/[^0-9]/g, '');
					this.chiPhi = cleanedValue ? Number(cleanedValue) : null;
				}
			}
		},
		methods: {
			async getBaoSuaMoi() {
				try {
					const res = await axios.post("TS_BaoSua_SelectBaoSuaMoi");
					this.dsBaoSuaMoi = res.data.data;
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
			onlyNumberInput(e) {
				const charCode = e.key.charCodeAt(0);
				// Chỉ cho nhập 0-9
				if (charCode < 48 || charCode > 57) {
					e.preventDefault();
				}
			},
	
	
	
			async getHinhAnh(maBaoSua) {
				try {
					const res = await axios.post("TS_BaoSua_SelectHinhAnh", {
						MaBaoSua: maBaoSua
					});
					this.hinhAnh = res.data.data[0].HinhAnh;
					// console.log(this.hinhAnh)
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
	
			async getHinhAnhTs(MaTS) {
				try {
					const response = await axios.post("/TS_TaiSan_SelectHinhAnh", {
						MaTS: MaTS
					});
					console.log(response.data.data[0].HinhAnh)
					if (response.data.data && response.data.data[0].HinhAnh) {
						this.hinhAnh = response.data.data[0].HinhAnh;
						console.log(this.hinhAnh)
	
						this.dialogHinhAnh = true;
					} else {
						showMessage({ type: "red", title: "Không có hình ảnh" });
					}
				} catch (error) {
					showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi khi tải hình ảnh" });
				}
			},
			async getDaTiepNhan() {
				try {
					const res = await axios.post("TS_TiepNhanBaoSua_SelectTiepNhan");
					this.dsDaTiepNhan = res.data.data;
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
	
			async themTiepNhanBaoSua() {
				await axios.post("TS_TiepNhanBaoSua_Insert", {
					MaBaoSua: this.baoSuaDangChon.MaBaoSua,
					GhiChu: this.ghiChuTiepNhan
				})
					.then(() => {
						this.getBaoSuaMoi();
						this.dialogTiepNhan = false;
						this.getDaTiepNhan();
						this.getDsBaoSua();
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				// this.getTaiSan();
			},
			formatCurrency(amount) {
				return amount.toLocaleString('vi-VN') + 'đ';
			},
	
			async kiemTraBaoSua() {
				await axios.post("TS_TiepNhanBaoSua_Update", {
					MaXuLy: this.baoSuaDangChon.MaXuLy,
					GhiChu: this.ghichusua,
					ChiPhiSua: this.chiPhi ?? 0,
					TinhTrangHoanThanh: 5,
					TinhTrangSuaChua: 0
				})
					.then(() => {
						this.getBaoSuaMoi();
	
						this.getDaTiepNhan();
						this.getDsBaoSua();
						this.dialogCapNhatBs = false;
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
			async capNhatHoanThanhBs() {
				await axios.post("TS_TiepNhanBaoSua_Update", {
					MaXuLy: this.baoSuaDangChon.MaXuLy,
					GhiChu: this.ghichusua,
					ChiPhiSua: this.chiPhi ?? 0,
					TinhTrangHoanThanh: 5,
					TinhTrangSuaChua: 0
				})
					.then(() => {
						this.getBaoSuaMoi();
						this.getDaTiepNhan();
						this.getDsBaoSua();
	
						this.dialogCapNhat = false;
	
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
	
			async getDsTaiSan(maViTriPhong) {
				try {
					const res = await axios.post("TS_CaBietTaiSan_Select_ByLoaiDM",
						{ ViTriPhong: maViTriPhong });
					this.dsTaiSan = res.data.data;
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
			async getDsBaoSua() {
				try {
					const res = await axios.post("TS_TiepNhanBaoSua_SelecctByTinhTrangTiepNhan",
						{
							tinhTrang: this.tinhTrangChon
						});
					this.dsBaoSua = res.data.data;
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
	
			async layLichSuTiepNhan(maCaBiet) {
				try {
					const res = await axios.post("TS_BaoSua_LichSuBaoSua_byMaCaBiet", { MaCaBiet: maCaBiet });
					this.lichSuTiepNhan = res.data.data;
				} catch (error) {
					showMessage({ type: "red", title: "Không lấy được lịch sử!" });
				}
			},
	
			async capNhatBaoSua() {
				try {
	
					// console.log("hehe: " , this.baoSuaDangChon.MaXuLy)
					await axios.post("TS_TiepNhanBaoSua_KiemTraBaoSua", {
	
						MaXuLy: this.baoSuaDangChon.MaXuLy,
						MaCaBiet: this.baoSuaDangChon.MaCaBiet,
						NguyenNhanHu: this.nguyenNhan,
						GhiChuKiemTra: this.ghiChuKiemTra,
						ThongTinKiemTra: this.thongTinKiemTra,
						TinhTrangKiemTra: this.baoSuaDung,
					});
	
					this.getBaoSuaMoi();
					this.dialogCapNhat = false;
					this.getDaTiepNhan();
					this.getDsBaoSua();
					CALL({ MESS: "Cập nhật thành công" });
					// this.getTaiSan();
				} catch (error) {
					console.error(error)
					showMessage({ type: "red", title: error.response?.data?.Message });
				}
			},
			moDialogHinhAnh(item) {
				// Gọi API để lấy hình ảnh dựa vào MaCaBiet
				this.getHinhAnh(item.MaBaoSua);
				this.dialogHinhAnh = true;
				this.hinhAnh = item.DuongDanAnh || null;
				this.dialogHinhAnh = true;
			},
			async moDialogCapNhat(item) {
				this.baoSuaDangChon = item;
				this.dialogCapNhat = true;
				this.tabCapNhat = 0;
				this.chiPhi = '';
	
				this.nguyenNhan = '';
				this.ghiChuKiemTra = '';
				this.getDsTaiSan(item.MaViTriPhong);
				await this.getChiTietTaiSan();
				console.log(this.dsChiTietTaiSan)
			},
			moDialogCapNhatBs(item) {
	
				this.baoSuaDangChon = item;
				this.dialogCapNhatBs = true;
				this.tabCapNhatBs = 'one';
				console.log("macbiet ne:", this.baoSuaDangChon.MaCaBiet);
			},
			moDialogTiepNhan(item) {
	
				this.baoSuaDangChon = item;
				this.ghiChuTiepNhan = null;
				this.dialogTiepNhan = true;
				this.tabTiepNhan = 0;
			},
	
			// async getTaiSanTrongPhongBan() {
			// 	this.dsTaiSanTrongPhongBan = await axios.post("/TaiSan_SelectByViTriPhong_MaCaBiet", {
			// 		MaCaBietCha: this.baoSuaDangChon.MaCaBiet
			// 	})
			// 		.then((resp) => {
			// 			console.log(resp)
			// 			return resp.data.data
			// 		})
			// 		.catch((error) => {
			// 			showMessage({ type: "red", title: error.response.data.Message })
			// 		})
			// 	console.log(this.dsTaiSanTrongPhongBan)
			// },
			async getChiTietTaiSan() {
				this.dsChiTietTaiSan = await axios.post("/TS_TaiSan_SelectByMaCB_ChiTietTaiSan", {
					MaCaBiet: this.baoSuaDangChon.MaCaBiet,
				})
					.then((resp) => {
						return resp.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				console.log(this.dsChiTietTaiSan)
			},
			async dialogThongTinTaiSan() {
				if (this.dialogThongTinTaiSan == true) {
					await this.getThongTinTaiSan();
					await this.getChiTietTaiSan();
				} else {
					this.$emit("close")
				}
			},
			async getTaiSanTrongPhongBan() {
				try {
					const resp = await axios.post('/TS_TaiSan_SelectByViTriPhong_MaCaBiet', {
						MaCaBietCha: this.baoSuaDangChon.MaCaBiet,
					})
					this.dsTaiSanTrongPhongBan = resp.data.data
				} catch (error) {
					showMessage({
						type: 'red',
						title: error.response?.data?.Message || 'Lỗi khi lấy danh sách tài sản',
					})
				}
			},
	
			async modialogThemTaiSanCon() {
				this.dialogThemTaiSanCon = true;
				// this.taiSanConDangChon = []
				await this.getTaiSanTrongPhongBan();
	
			},
			async insertTaiSanCon() {
				await axios.post("/TS_TaiSan_ChiTietTaiSanCon_Insert", {
					MaCaBietCha: this.baoSuaDangChon.MaCaBiet,
					ListMaCaBietCon: this.taiSanConDangChon.toString()
				})
					.then((resp) => {
						this.dialogThemTaiSanCon = false;
						CALL({ "MESS": "Đã thêm" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				this.getChiTietTaiSan()
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
			async deleteTaiSanCon(MaCaBiet) {
				await axios.post("/TS_TaiSan_ChiTietTaiSanCon_Delete", {
					MaCaBietCha: this.baoSuaDangChon.MaCaBiet,
					MaCaBietCon: MaCaBiet
				})
					.then((resp) => {
						this.showDialogDelete = false;
						CALL({ "MESS": "Đã xoá" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				this.getChiTietTaiSan()
			},
		}
	}
</script>