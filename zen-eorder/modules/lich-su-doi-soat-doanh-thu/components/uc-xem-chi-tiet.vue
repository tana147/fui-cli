<template>
	<v-dialog v-model="isShowDialogViewDetail" max-width="800px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<span class="primary--text">
					Xem chi tiết
				</span>
				<v-spacer></v-spacer>
				<v-icon color="primary" @click="closeDialog">
					mdi-close
				</v-icon>
			</v-card-title>
			<v-card-text class="d-flex flex-column">
				<b class="font-weight-bold">
					Tên cửa hàng: <span class="success--text">{{item?.TenCuaHang}}</span>
				</b>
				<span class=" font-weight-bold">
					Ngày đối soát: {{ moment(item?.NgayDoiSoat).format("DD/MM/YYYY")}}
				</span>
				<span class=" font-weight-bold">
					Ca: {{ caMap[item?.Ca]}}
				</span>
				<span class=" font-weight-bold">
					Trạng thái: {{ trangThaiMap[item?.TrangThai]}}
				</span>
				<v-simple-table dense>
					<thead>
						<tr>
							<th>Loại</th>
							<th class="text-right">TM</th>
							<th class="text-right">CK</th>
							<th class="text-right">QT</th>
							<th class="text-right">SPF</th>
							<th class="text-right">GRAB</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td class="font-weight-bold">Doanh thu</td>
							<td class="text-right">{{ item.DoanhThu_TM?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.DoanhThu_CK?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.DoanhThu_QT?.toLocaleString('vi-VN')}}</td>
							<td class="text-right">{{ item.DoanhThu_SPF?.toLocaleString('vi-VN')}}</td>
							<td class="text-right">{{ item.DoanhThu_GRAB?.toLocaleString('vi-VN')}}</td>
						</tr>
						<tr>
							<td class="font-weight-bold">Kết ca</td>
							<td class="text-right">{{ item.KetCa_TM?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.KetCa_CK?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.KetCa_QT?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.KetCa_SPF?.toLocaleString('vi-VN') }}</td>
							<td class="text-right">{{ item.KetCa_GRAB?.toLocaleString('vi-VN') }}</td>
						</tr>
						<tr>
							<td class="font-weight-bold">Chênh lệch</td>
							<td class="text-right">{{ (item.DoanhThu_TM - item.KetCa_TM)?.toLocaleString('vi-VN') }}
							</td>
							<td class="text-right">{{ (item.DoanhThu_CK - item.KetCa_CK)?.toLocaleString('vi-VN') }}
							</td>
							<td class="text-right">{{ (item.DoanhThu_QT - item.KetCa_QT)?.toLocaleString('vi-VN') }}
							</td>
							<td class="text-right">{{ (item.DoanhThu_SPF - item.KetCa_SPF)?.toLocaleString('vi-VN') }}
							</td>
							<td class="text-right">{{ (item.DoanhThu_GRAB - item.KetCa_GRAB)?.toLocaleString('vi-VN') }}
							</td>
						</tr>
					</tbody>
				</v-simple-table>

				<span class="primary--text font-weight-bold mt-1 ">Quẹt thẻ</span>
				<v-row class="mb-1">
					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu phần trăm: {{ item?.QT_ChietKhau_PhanTram}}%
						</span>
					</v-col>
				</v-row>

				<span class="primary--text font-weight-bold">Shoppe Food</span>
				<v-row class="mb-1">
					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu phần trăm: {{ item?.SPF_ChietKhau_PhanTram}}%
						</span>
					</v-col>

					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu phần trăm khác: {{ item?.SPF_ChietKhau_PhanTram_Khac}}%
						</span>
					</v-col>

					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu tiền mặt khác: {{ item?.SPF_ChietKhau_TienMat_Khac?.toLocaleString('vi-VN')}}
						</span>
					</v-col>
				</v-row>

				<span class="primary--text font-weight-bold ">Grab</span>
				<v-row>
					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu phần trăm: {{ item?.GRAB_ChietKhau_PhanTram}}%
						</span>
					</v-col>

					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu phần trăm khác: {{ item?.GRAB_ChietKhau_PhanTram_Khac}}%
						</span>
					</v-col>

					<v-col cols="4">
						<span class=" font-weight-bold">
							Chiết khấu tiền mặt khác: {{ item?.GRAB_ChietKhau_TienMat_Khac?.toLocaleString('vi-VN')}}
						</span>
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			item: Object,
			isShowDialogViewDetail: Boolean
		},
		data() {
			return {
				vueData,
				caMap: {
					'': 'Tất cả',
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				},
				trangThaiMap: {
					'NOT': 'Chưa đối soát',
					'WRONG': 'Có sai lệch',
					'COMPLETED': 'Đã đối soát'
				},
			};
		},
		computed: {
	
		},
	
		methods: {
			closeDialog() {
				this.$emit('update:isShowDialogViewDetail', false)
			}
		}
	}
</script>