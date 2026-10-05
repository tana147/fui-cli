<template>
	<v-card elevation="0" class="ma-1" style="border: thin solid rgba(0, 0, 0, .12);">
		<v-card-text class="pa-0">
			<v-simple-table fixed-header height="77vh" dense class="table-doi-soat">
				<template v-slot:top>
					<div div class="d-flex flex-row justify-space-between px-4 pb-2 pt-2">
						<div class="text-center">
							Tổng thu <br />
							<b class="red--text">{{ (getTotalSummary('DoiSoat_TM') + totalChuyenKhoanThucTe -
								totalChietKhauTienMat +
								getTotalSummary('DoiSoat_QT_ChietKhau') + getTotalSummary('DoiSoat_SPF_ChietKhau') +
								getTotalSummary('DoiSoat_GRAB_ChietKhau') +
								getTotalSummary('DoiSoat_XSM_ChietKhau'))?.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Tổng hủy <br />
							<b class="red--text">{{ getTotalSummary('DoiSoat_Huy')?.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Tiền mặt <br />
							<b class="red--text">{{ getTotalSummary('DoiSoat_TM')?.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Chuyển khoản <br />
							<b class="red--text">{{ getTotalSummary('DoiSoat_CK')?.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Chuyển khoản thực tế <br />
							<b class="red--text text-decoration-underline cursor-pointer"
								@click='onChuyenKhoanThucTeEmit'>
								{{ totalChuyenKhoanThucTe.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Quẹt thẻ <br />
							<b class="red--text">{{ getTotalSummary('DoiSoat_QT_ChietKhau')?.toLocaleString('vi-VN')
								}}</b>
						</div>
						<div class="text-center">
							Chiết khấu tiền mặt <br />
							<b class="red--text text-decoration-underline cursor-pointer"
								@click='onChietKhauTienMatEmit'>
								{{ totalChietKhauTienMat.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							ShopeeFood <br />
							<b class="red--text">{{ (getTotalSummary('DoiSoat_SPF_ChietKhau') -
								totalChietKhauSPF)?.toLocaleString('vi-VN') }}</b>
						</div>
						<div class="text-center">
							Grab <br />
							<b class="red--text">{{ (getTotalSummary('DoiSoat_GRAB_ChietKhau') -
								totalChietKhauGRAB)?.toLocaleString('vi-VN') }}</b>
						</div>

						<div class="text-center">
							Xanh SM <br />
							<b class="red--text">{{ (getTotalSummary('DoiSoat_XSM_ChietKhau'))?.toLocaleString('vi-VN')
								}}</b>
						</div>
					</div>
				</template>
				<template v-slot:default>
					<thead>
						<tr>
							<th class="text-center" style="max-width:150px">
								Tên cửa hàng
							</th>
							<th class="text-center ">
								Ca
							</th>
							<th class="text-center" style="min-width:80px">
								#
							</th>
							<th class="text-right">
								TM
							</th>
							<th class="text-right">
								CK
							</th>
							<th class="text-right">
								QT
							</th>
							<th class="text-right">
								QT sau
							</th>
							<th class="text-right">
								SPF
							</th>
							<th class="text-right">
								SPF sau
							</th>
							<th class="text-right">
								Grab
							</th>
							<th class="text-right">
								Grab sau
							</th>
							<th class="text-right">
								XSM
							</th>
							<th class="text-right">
								XSM sau
							</th>
							<th class="text-right">
								Tổng huỷ
							</th>
							<th class="text-right">
								Tổng
							</th>
							<th class="text-right">
								Tổng sau
							</th>
						</tr>
					</thead>

					<tbody>
						<template v-for="item in data" :key="item.CuaHangID">
							<template v-for="([key, value], index) in Object.entries(item.Ngay)" :key="key">
								<template v-for="ca in value" :key="ca.Ca">

									<!-- HỆ THỐNG -->
									<tr>
										<!-- Cửa hàng -->
										<td v-if="ca === item.Ca[0]"
											:rowspan="item.Ca.length * 6 + 3 * Object.keys(item.Ngay).length"
											class="text-center border-bottom-primary" style="max-width:150px">
											<span class="font-weight-bold primary--text">
												{{ item.TenCuaHang }}
											</span>

											<div class=" mt-2">
												<v-row class="d-flex justify-center align-center">
													<v-col cols='12'>
														<v-btn small elevation="0" block color="primary"
															@click="CapNhatChietKhau(item, ca)">
															<v-icon left>
																mdi-cog
															</v-icon>
															Chiết khấu
														</v-btn>
													</v-col>
													<v-col cols="12">
														<v-btn small elevation="0" block color="primary"
															@click="DongBoDuLieu(item, ca)">
															<v-icon left>
																mdi-refresh
															</v-icon>
															Đồng bộ
														</v-btn>
													</v-col>
												</v-row>
											</div>
										</td>

										<!-- Ca rowspan = 5-->
										<td :class="{ 'wrong-text': ca.TrangThai === 'WRONG' }" rowspan="6"
											class="text-center font-weight-bold">
											{{ caMap[ca.Ca] }}
											</br>
											({{ moment(ca.NgayDoiSoat).format('DD/MM/YYYY') }})
											</br>
											<!-- Trang thai -->
											<template v-if="!ca.isEditing">
												<v-chip small :color="getStatusColor(ca.TrangThai)" class="mt-2"> {{
													trangThaiMap[ca.TrangThai] }}</v-chip>
											</template>

											<template v-else>
												<v-select dense v-model="ca.TrangThai" :items="DSTrangThaiDoiSoat"
													hide-details item-value="value" item-text="text" class="mt-2"
													style="max-width: 200px">
												</v-select>
											</template>
											</br>
											<!-- chinh sua -->
											<template v-if="!ca.isEditing">
												<v-btn @click="edit(ca)" text class="pa-0 mt-2" icon>
													<v-icon color=" primary">mdi-square-edit-outline</v-icon>
												</v-btn>
											</template>
											<template v-else>
												<v-row class="d-flex justify-center align-center">
													<v-col cols='12' xl='6'>
														<v-btn @click="save(ca)" text class="pa-0" icon>
															<v-icon color=" primary">mdi-content-save</v-icon>
														</v-btn>
													</v-col>
													<v-col cols="12" xl='6'>
														<v-btn @click="exit(ca)" text class="pa-0" icon>
															<v-icon color=" error">mdi-close</v-icon>
														</v-btn>
													</v-col>
												</v-row>
											</template>
										</td>

										<td class="cursor-pointer text-decoration-underline "
											@click="getDanhSachHoaDon(item, ca, 'DOANH_THU')"
											:class="{ 'edit-class': ca.isEditing }"
											:style="ca === item.Ca[0] ? { paddingTop: '10px' } : {}">Hệ
											thống
										</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_TM, ca.KetCa_TM), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'TM')">
											{{ (ca.DoanhThu_TM)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_CK, ca.KetCa_CK), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'CK')">
											{{ (ca.DoanhThu_CK)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_QT, ca.KetCa_QT), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'QT')">
											{{ (ca.DoanhThu_QT)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right " :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.DoanhThu_QT_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_SPF, ca.KetCa_SPF), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'SPF')">
											{{ (ca.DoanhThu_SPF)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right " :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.DoanhThu_SPF_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_GRAB, ca.KetCa_GRAB), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'GRAB')">
											{{ (ca.DoanhThu_GRAB)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right " :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.DoanhThu_GRAB_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_XSM, ca.KetCa_XSM), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'XSM')">
											{{ (ca.DoanhThu_XSM)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right " :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.DoanhThu_XSM_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_Huy, ca.KetCa_Huy), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'DOANH_THU', 'HUY')">
											{{ (ca.DoanhThu_Huy)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalHeThong(ca)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalHeThong_ChietKhau(ca)?.toLocaleString("vi-vn") }}
										</td>
									</tr>
									<!-- KẾT CA -->
									<tr>
										<td class="cursor-pointer text-decoration-underline"
											:class="{ 'edit-class': ca.isEditing }"
											@click="getDanhSachHoaDon(item, ca, 'KET_CA')">Kết ca</td>

										<td class=" text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_TM, ca.KetCa_TM), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'TM')">
											{{ (ca.KetCa_TM)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_CK, ca.KetCa_CK), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'CK')">
											{{ (ca.KetCa_CK)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_QT, ca.KetCa_QT), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'QT')">
											{{ (ca.KetCa_QT)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.KetCa_QT_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_SPF, ca.KetCa_SPF), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'SPF')">
											{{ (ca.KetCa_SPF)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.KetCa_SPF_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_GRAB, ca.KetCa_GRAB), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'GRAB')">
											{{ (ca.KetCa_GRAB)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.KetCa_GRAB_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_XSM, ca.KetCa_XSM), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'XSM')">
											{{ (ca.KetCa_XSM)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ (ca.KetCa_XSM_ChietKhau)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right cursor-pointer text-decoration-underline"
											:class="{ 'red--text': processChenhLech(ca, ca.DoanhThu_Huy, ca.KetCa_Huy), 'edit-class': ca.isEditing }"
											@click="XemHoaDonTheoLoai(item, ca, 'KET_CA', 'HUY')">
											{{ (ca.KetCa_Huy)?.toLocaleString("vi-vn") }}</td>

										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalCa(ca)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalCa_ChietKhau(ca)?.toLocaleString("vi-vn") }}</td>
									</tr>
									<!-- ĐỐI SOÁT -->
									<tr>
										<td :class="{ 'edit-class': ca.isEditing }">Đối soát</td>
										<template v-if="!ca.isEditing">
											<td class=" text-right">
												{{ formatValue(ca.DoiSoat_TM) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_CK) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_QT) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_QT_ChietKhau) }}
											</td>

											<td class="text-right">
												{{ formatValue(ca.DoiSoat_SPF) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_SPF_ChietKhau) }}
											</td>

											<td class="text-right">
												{{ formatValue(ca.DoiSoat_GRAB) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_GRAB_ChietKhau) }}
											</td>

											<td class="text-right">
												{{ formatValue(ca.DoiSoat_XSM) }}
											</td>
											<td class="text-right">
												{{ formatValue(ca.DoiSoat_XSM_ChietKhau) }}
											</td>

											<td class="text-right">
												{{ formatValue(ca.DoiSoat_Huy) }}
											</td>

										</template>

										<template v-else>
											<td>
												<v-text-field v-model="ca.DoiSoat_TM" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>
											<td>
												<v-text-field v-model="ca.DoiSoat_CK" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>

											<td>
												<v-text-field v-model="ca.DoiSoat_QT" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>
											<td :class="{ 'edit-class': ca.isEditing }"></td>

											<td>
												<v-text-field v-model="ca.DoiSoat_SPF" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>
											<td :class="{ 'edit-class': ca.isEditing }"></td>

											<td>
												<v-text-field v-model="ca.DoiSoat_GRAB" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>
											<td :class="{ 'edit-class': ca.isEditing }"></td>

											<td>
												<v-text-field v-model="ca.DoiSoat_XSM" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>
											<td :class="{ 'edit-class': ca.isEditing }"></td>

											<td>
												<v-text-field v-model="ca.DoiSoat_Huy" type="number" hide-details
													single-line reverse dense style="max-width: 150px"></v-text-field>
											</td>

										</template>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalCa(ca)?.toLocaleString("vi-vn") }}</td>
										<td class="text-right" :class="{ 'edit-class': ca.isEditing }">
											{{ getTotalCa_ChietKhau(ca)?.toLocaleString("vi-vn") }}</td>
									</tr>

									<!-- CHÊNH LỆCH -->
									<tr :class="{ 'edit-class': ca.isEditing }">
										<td>Chênh
											lệch</td>
										<td class="text-right">
											{{ formatValue(roundVND(ca.DoanhThu_TM - ca.KetCa_TM)) }}
										</td>
										<td class="text-right">
											{{ formatValue(ca.DoanhThu_CK - ca.KetCa_CK) }}
										</td>

										<td class="text-right">
											{{ formatValue(ca.DoanhThu_QT - ca.KetCa_QT) }}
										</td>
										<td></td>

										<td class="text-right">
											{{ formatValue(ca.DoanhThu_SPF - ca.KetCa_SPF) }}
										</td>
										<td></td>

										<td class="text-right">
											{{ formatValue(ca.DoanhThu_GRAB - ca.KetCa_GRAB) }}
										</td>
										<td></td>

										<td class="text-right">
											{{ formatValue(ca.DoanhThu_XSM - ca.KetCa_XSM) }}
										</td>
										<td></td>

										<td class="text-right ">
											{{ formatValue(ca.DoanhThu_Huy - ca.KetCa_Huy) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalHeThong(ca) - getTotalCa(ca)) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalHeThong_ChietKhau(ca) - getTotalCa_ChietKhau(ca)) }}
										</td>
									</tr>

									<!-- GHI CHÚ -->
									<tr :class="{ 'edit-class': ca.isEditing }">
										<td class="cursor-pointer text-decoration-underline"
											@click="getDanhSachPhieuKetCa(item, ca)">Ghi chú</td>
										<td colspan="13" class="text-left caption">{{ ca.GhiChuKetCa }}</td>
									</tr>

									<!-- GHI CHÚ ĐỐI SOÁT-->
									<tr>
										<td :class="{ 'edit-class': ca.isEditing }">Ghi chú
											đối soát</td>
										<template v-if="!ca.isEditing">
											<td colspan="13" class="text-left caption">
												{{ ca.GhiChuDoiSoat }}</td>
										</template>

										<template v-else>
											<td colspan="13">
												<v-textarea v-model="ca.GhiChuDoiSoat" hide-details single-line dense
													rows='2'></v-textarea>
											</td>
										</template>
									</tr>
								</template>

								<!-- TỔNG-->
								<template v-if='value.length > 0'>
									<!-- TỔNG HỆ THỐNG-->
									<tr>
										<td rowspan="3" class="border-bottom-primary font-weight-bold text-center">Tổng
										</td>
										<td>Hệ thống</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_TM')) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_CK')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_QT')) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_QT_ChietKhau')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_SPF')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'DoanhThu_SPF_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt: {{
													formatValue(getTotalSummaryByCuaHang(value,
													'DoanhThu_SPF_ChietKhau')) }}
												</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_GRAB')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'DoanhThu_GRAB_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalSummaryByCuaHang(value,
													'DoanhThu_GRAB_ChietKhau'))
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_XSM')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'DoanhThu_XSM_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalSummaryByCuaHang(value,
													'DoanhThu_XSM_ChietKhau'))
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'DoanhThu_Huy')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalCuaHangHeThong(value)) }}

										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalCuaHangHeThong_ChietKhau(value)
														-
														getTongChietKhauTientMatByCuaHang(value)
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalCuaHangHeThong_ChietKhau(value)) }}</span>
											</v-tooltip>
										</td>

										<td rowspan="3" colspan="2" class="border-bottom-primary "></td>
									</tr>
									<!-- TỔNG KẾT CA-->
									<tr>
										<td>Kết ca</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_TM')) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_CK')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_QT')) }}
										</td>
										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_QT_ChietKhau')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_SPF')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'KetCa_SPF_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt: {{
													formatValue(getTotalSummaryByCuaHang(value,
													'KetCa_SPF_ChietKhau')) }}</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_GRAB')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'KetCa_GRAB_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalSummaryByCuaHang(value,
													'KetCa_GRAB_ChietKhau'))
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_XSM')) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalSummaryByCuaHang(value, 'KetCa_XSM_ChietKhau')
														-
														getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat')
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalSummaryByCuaHang(value,
													'KetCa_XSM_ChietKhau'))
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right">
											{{ formatValue(getTotalSummaryByCuaHang(value, 'KetCa_Huy')) }}
										</td>

										<td class="text-right">
											{{ formatValue(getTotalCuaHangKetCa(value)) }}
										</td>
										<td class="text-right">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														getTotalCuaHangKetCa_ChietKhau(value)
														-
														getTongChietKhauTientMatByCuaHang(value)
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(getTotalCuaHangKetCa_ChietKhau(value)) }}</span>
											</v-tooltip>
										</td>
									</tr>
									<!-- TỔNG CHÊNH LỆCH-->
									<tr>
										<td class="border-bottom-primary">Chênh lệch</td>
										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_TM') -
											getTotalSummaryByCuaHang(value, 'KetCa_TM')
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_CK') -
											getTotalSummaryByCuaHang(value, 'KetCa_CK')
											) }}
										</td>

										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_QT') -
											getTotalSummaryByCuaHang(value, 'KetCa_QT')
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_QT_ChietKhau') -
											getTotalSummaryByCuaHang(value, 'KetCa_QT_ChietKhau')
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_SPF') -
											getTotalSummaryByCuaHang(value, 'KetCa_SPF')
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														(getTotalSummaryByCuaHang(value, 'DoanhThu_SPF_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat')) -
														(getTotalSummaryByCuaHang(value, 'KetCa_SPF_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat'))
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(
													(getTotalSummaryByCuaHang(value, 'DoanhThu_SPF_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat')) -
													(getTotalSummaryByCuaHang(value, 'KetCa_SPF_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'SPF_Tong_TienMat'))
													)
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_GRAB') -
											getTotalSummaryByCuaHang(value, 'KetCa_GRAB')
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														(getTotalSummaryByCuaHang(value, 'DoanhThu_GRAB_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat')) -
														(getTotalSummaryByCuaHang(value, 'KetCa_GRAB_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat'))
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(
													(getTotalSummaryByCuaHang(value, 'DoanhThu_GRAB_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat')) -
													(getTotalSummaryByCuaHang(value, 'KetCa_GRAB_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'GRAB_Tong_TienMat'))
													)
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_XSM') -
											getTotalSummaryByCuaHang(value, 'KetCa_XSM')
											) }}
										</td>

										<td class="text-right border-bottom-primary">
											<v-tooltip top>
												<template v-slot:activator="{ on, attrs }">
													<span v-bind="attrs" v-on="on">
														{{ formatValue(
														(getTotalSummaryByCuaHang(value, 'DoanhThu_XSM_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat')) -
														(getTotalSummaryByCuaHang(value, 'KetCa_XSM_ChietKhau') -
														getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat'))
														) }}</span>
												</template>
												<span>Trước chiết khấu tiền mặt:
													{{ formatValue(
													(getTotalSummaryByCuaHang(value, 'DoanhThu_XSM_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat')) -
													(getTotalSummaryByCuaHang(value, 'KetCa_XSM_ChietKhau') -
													getChietKhauTienMatByCuaHang(value, 'XSM_Tong_TienMat'))
													)
													}}</span>
											</v-tooltip>
										</td>

										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalSummaryByCuaHang(value, 'DoanhThu_Huy') -
											getTotalSummaryByCuaHang(value, 'KetCa_Huy')
											) }}
										</td>

										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalCuaHangHeThong(value) -
											getTotalCuaHangKetCa(value)
											) }}
										</td>
										<td class="text-right border-bottom-primary">
											{{ formatValue(
											getTotalCuaHangHeThong_ChietKhau(value) -
											getTotalCuaHangKetCa_ChietKhau(value)
											) }}
										</td>
									</tr>
								</template>
							</template>
						</template>
					</tbody>
				</template>

			</v-simple-table>
		</v-card-text>
	</v-card>


</template>

<script>
	export default {
		props: {
			data: Array,
			DataDSChuyenKhoanThucTe: Array,
			DataDSChietKhauTienMat: Array
		},
		data() {
			return {
				vueData,
				trangThaiMap: {
					'NOT': 'Chưa đối soát',
					'WRONG': 'Có sai lệch',
					'COMPLETED': 'Đã đối soát'
				},
				mapStatusColor: {
					'NOT': '',
					'WRONG': 'error',
					'COMPLETED': 'success'
				},
				DSTrangThaiDoiSoat: [
					{ value: "NOT", text: "Chưa đối soát" },
					{ value: "WRONG", text: "Có sai lệch" },
					{ value: "COMPLETED", text: "Đã đối soát" }
				],
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				}
			}
		},
		mounted() {
		},
		computed: {
			totalChuyenKhoanThucTe() {
				let res = 0
				this.DataDSChuyenKhoanThucTe.forEach((ck) => res += Number(ck.GiaTri))
				return res ?? 0
			},
	
			totalChietKhauTienMat() {
				let res = 0
				this.DataDSChietKhauTienMat.forEach((ck) => res += (Number(ck.SPF_Tong_TienMat) + Number(ck.GRAB_Tong_TienMat) + Number(ck.XSM_Tong_TienMat)))
				return res ?? 0
			},
			totalChietKhauSPF() {
				let res = 0
				this.DataDSChietKhauTienMat.forEach((ck) => res += Number(ck.SPF_Tong_TienMat))
				return res ?? 0
			},
			totalChietKhauGRAB() {
				let res = 0
				this.DataDSChietKhauTienMat.forEach((ck) => res += Number(ck.GRAB_Tong_TienMat))
				return res ?? 0
			},
		},
		watch: {},
		methods: {
			formatValue(value) {
				return value === 0 ? '' : value?.toLocaleString("vi-vn")
			},
	
			getTotalSummary(name) {
				let res = 0
				this.data.map((cuaHang) => {
					cuaHang.Ca.map((ca) => {
						res += Number(ca[name])
					})
				})
				return res
			},
	
			getTotalSummaryByCuaHang(value, name) {
				let res = 0
	
				Object.values(value || {}).flat().forEach(ca => {
					res += Number(ca?.[name] || 0)
				})
	
				return res
			},
	
			getTotalCuaHangHeThong(value) {
				return (
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_TM')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_CK')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_QT')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_SPF')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_GRAB'))
				) || 0;
			},
	
			getTotalCuaHangHeThong_ChietKhau(value) {
				return (
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_TM')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_CK')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_QT_ChietKhau')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_SPF_ChietKhau')) +
					Number(this.getTotalSummaryByCuaHang(value,
						'DoanhThu_GRAB_ChietKhau'))
				) || 0;
			},
	
			getTotalCuaHangKetCa(cuaHang) {
				return (
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_TM')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_CK')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_QT')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_SPF')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_GRAB'))
				) || 0;
			},
	
			getTotalCuaHangKetCa_ChietKhau(cuaHang) {
				return (
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_TM')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_CK')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_QT_ChietKhau')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_SPF_ChietKhau')) +
					Number(this.getTotalSummaryByCuaHang(cuaHang,
						'KetCa_GRAB_ChietKhau'))
				) || 0;
			},
	
			getTotalHeThong(Ca) {
				return (
					Number(Ca.DoanhThu_TM) +
					Number(Ca.DoanhThu_CK) +
					Number(Ca.DoanhThu_QT) +
					Number(Ca.DoanhThu_SPF) +
					Number(Ca.DoanhThu_GRAB)
				) || 0;
			},
	
			getTotalHeThong_ChietKhau(Ca) {
				return (
					Number(Ca.DoanhThu_TM) +
					Number(Ca.DoanhThu_CK) +
					Number(Ca.DoanhThu_QT_ChietKhau) +
					Number(Ca.DoanhThu_SPF_ChietKhau) +
					Number(Ca.DoanhThu_GRAB_ChietKhau)
				) || 0;
			},
	
			getTotalCa(Ca) {
				return (
					Number(Ca.KetCa_TM) +
					Number(Ca.KetCa_CK) +
					Number(Ca.KetCa_QT) +
					Number(Ca.KetCa_SPF) +
					Number(Ca.KetCa_GRAB)
				) || 0;
			},
	
			getTotalCa_ChietKhau(Ca) {
				return (
					Number(Ca.KetCa_TM) +
					Number(Ca.KetCa_CK) +
					Number(Ca.KetCa_QT_ChietKhau) +
					Number(Ca.KetCa_SPF_ChietKhau) +
					Number(Ca.KetCa_GRAB_ChietKhau)
				) || 0;
			},
			roundVND(amount) {
				const remainder = amount % 1000;
	
				if (remainder > 500) {
					return amount + (1000 - remainder); // làm tròn lên
				} else {
					return amount - remainder; // làm tròn xuống
				}
			},
	
			processChenhLech(ca, HeThong, KetCa) {
				const flag = this.roundVND(HeThong - KetCa) != 0 ? true : false
				if (ca.TrangThai !== 'COMPLETED' && flag) ca.TrangThai = "WRONG"
				return flag
			},
	
			async getDanhSachPhieuKetCa(item, ca) {
				const params = {
					CuaHangID: ca.CuaHangID,
					Ngay: ca.NgayDoiSoat,
					Ca: ca.Ca
				}
				this.$emit('phieuKetCaEmit', item, ca, params)
			},
	
			async getDanhSachHoaDon(item, ca, loai) {
				const params = {
					DoiSoatID: ca.DoiSoatID,
					LoaiDuLieu: loai,
					HinhThucThanhToan: "",
				}
				this.$emit('danhSachHoaDonEmit', item, ca, params)
			},
	
			XemHoaDonTheoLoai(item, ca, loai, hinhThuc) {
				const params = {
					DoiSoatID: ca.DoiSoatID,
					LoaiDuLieu: loai,
					HinhThucThanhToan: hinhThuc,
				}
				this.$emit('danhSachHoaDonTheoLoaiEmit', item, ca, params, loai)
			},
	
			DongBoDuLieu(item, ca) {
				this.$emit('dongBoDuLieuEmit', item, ca)
			},
	
			CapNhatChietKhau(item, ca) {
				this.$emit('capNhatChietKhauEmit', item, ca)
			},
			getStatusColor(trangThai) {
				return this.mapStatusColor[trangThai]
			},
	
			edit(ca) {
				ca.isEditing = true
			},
			exit(ca) {
				ca.isEditing = false
			},
	
			async save(ca) {
				const params = {
					DoiSoatID: ca.DoiSoatID,
					// DOANH THU
					DoanhThu_TM: ca.DoanhThu_TM,
					DoanhThu_CK: ca.DoanhThu_CK,
					DoanhThu_QT: ca.DoanhThu_QT,
					DoanhThu_SPF: ca.DoanhThu_SPF,
					DoanhThu_GRAB: ca.DoanhThu_GRAB,
					DoanhThu_XSM: ca.DoanhThu_XSM,
					DoanhThu_Huy: ca.DoanhThu_Huy,
					// KET CA
					KetCa_TM: ca.KetCa_TM,
					KetCa_CK: ca.KetCa_CK,
					KetCa_QT: ca.KetCa_QT,
					KetCa_SPF: ca.KetCa_SPF,
					KetCa_GRAB: ca.KetCa_GRAB,
					KetCa_XSM: ca.KetCa_XSM,
					KetCa_Huy: ca.KetCa_Huy,
					// DOI SOAT
					DoiSoat_TM: Number(ca.DoiSoat_TM),
					DoiSoat_CK: Number(ca.DoiSoat_CK),
					DoiSoat_QT: Number(ca.DoiSoat_QT),
					DoiSoat_SPF: Number(ca.DoiSoat_SPF),
					DoiSoat_GRAB: Number(ca.DoiSoat_GRAB),
					DoiSoat_XSM: Number(ca.DoiSoat_XSM),
					DoiSoat_Huy: Number(ca.DoiSoat_Huy),
					GhiChuDoiSoat: ca.GhiChuDoiSoat,
					TrangThai: ca.TrangThai
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Update_DoanhThu', params)
				if (data)
					Vue.$toast.success("Thành công", { position: "top" });
				else
					Vue.$toast.error("Thất bại", { position: "top" });
				ca.isEditing = false
			},
			onChuyenKhoanThucTeEmit() {
				this.$emit('chuyenKhoanEmit')
			},
			onChietKhauTienMatEmit() {
				this.$emit('chietKhauTienMatEmit')
			},
			getChietKhauTienMatByCuaHang(Ca, field) {
				const CuaHangID = Ca[0]?.CuaHangID
				const NgayDoiSoat = Ca[0]?.NgayDoiSoat
				const ChietKhauTienMat = this.DataDSChietKhauTienMat.find((x) => x.Ngay === NgayDoiSoat && x.CuaHangID === CuaHangID)
				const TienMatChietKhau = ChietKhauTienMat?.[field]
				return TienMatChietKhau ?? 0
			},
			getTongChietKhauTientMatByCuaHang(Ca) {
				const SPF_Tong_TienMat = Number(this.getChietKhauTienMatByCuaHang(Ca, 'SPF_Tong_TienMat'))
				const GRAB_Tong_TienMat = Number(this.getChietKhauTienMatByCuaHang(Ca, 'GRAB_Tong_TienMat'))
				const XSM_Tong_TienMat = Number(this.getChietKhauTienMatByCuaHang(Ca, 'XSM_Tong_TienMat'))
				const total = SPF_Tong_TienMat + GRAB_Tong_TienMat + XSM_Tong_TienMat
				return total
			}
	
		},
	}
</script>