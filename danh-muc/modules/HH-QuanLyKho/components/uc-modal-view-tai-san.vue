<template>
	<v-dialog :fullscreen="$vuetify.display.xs" :model-value="isShow" width="500" @update:model-value="closeDialog">
		<v-card>
			<v-toolbar color="primary">
				<template v-if="$vuetify.display.xs">
					<v-toolbar-title>Thông tin tài sản</v-toolbar-title>
					<v-btn size="small" icon="mdi-close" @click="closeDialog"></v-btn>
				</template>
				<template v-else>
					<v-toolbar-title>Thông tin tài sản</v-toolbar-title>
					<v-spacer />
					<v-btn icon="mdi-close" size="small" @click="closeDialog" />
				</template>
			</v-toolbar>

			<v-card-text class="px-4 py-2">
				<!-- Mobile -->
				<template v-if="$vuetify.display.xs">
					<template v-for="section in sections" :key="section.title">
						<div class="px-2 pt-1 pb-1">
							<div
								class="text-caption text-uppercase text-medium-emphasis font-weight-medium mb-2 text-primary">
								{{ section.title }}
							</div>
							<template v-for="f in section.fields" :key="f.key">
								<div class="d-flex justify-space-between align-center py-1">
									<div class="text-caption text-medium-emphasis">
										{{ f.label }}
									</div>

									<div v-if="f.key === 'TinhTrang'">
										<v-chip size="small"
											:color="mapTinhTrangHangHoaCaBiet[thongTinTaiSan?.[f.key]]?.color"
											variant="tonal">
											{{ formatValue(f, mapTinhTrangHangHoaCaBiet[thongTinTaiSan?.[f.key]]?.text)
											}}
										</v-chip>
									</div>

									<div v-else class="text-body-2 font-weight-medium text-right">
										{{ formatValue(f, thongTinTaiSan?.[f.key]) }}
									</div>
								</div>
							</template>
						</div>
						<!-- <v-divider /> -->
					</template>
				</template>

				<!-- Desktop -->
				<template v-else>
					<v-list density="compact" class="py-0">
						<template v-for="(row, i) in desktopRows" :key="i">
							<v-list-item>
								<v-row no-gutters>
									<v-col v-for="f in row" :key="f.key" :cols="row.length === 1 ? 12 : 6">
										<div class="py-1" :class="{ 'pr-4': row.length > 1 }">
											<div class="text-caption text-medium-emphasis mb-1">{{ f.label }}</div>
											<div v-if="f.key === 'TinhTrang'">
												<v-chip size="small"
													:color="mapTinhTrangHangHoaCaBiet[thongTinTaiSan?.[f.key]]?.color"
													variant="tonal">
													{{ formatValue(f,
													mapTinhTrangHangHoaCaBiet[thongTinTaiSan?.[f.key]]?.text)
													}}
												</v-chip>
											</div>
											<div v-else class="text-body-2 font-weight-medium">
												{{ formatValue(f, thongTinTaiSan?.[f.key]) }}
											</div>
										</div>
									</v-col>
								</v-row>
							</v-list-item>
							<v-divider v-if="i < desktopRows.length - 1" />
						</template>
					</v-list>
				</template>
			</v-card-text>

			<v-card-actions class="px-4 pb-4 border-0">
				<v-btn color="grey" variant="flat" prepend-icon="mdi-close" @click="closeAll">
					Thoát
				</v-btn>
				<v-btn color="primary" variant="flat" prepend-icon="mdi-qrcode-scan" @click="closeDialog">
					Tiếp tục quét
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			thongTinTaiSan: {
				type: Object,
				default: () => ({})
			}
		},
	
		emits: ['closeQuetQRDialog'],
	
		data() {
			return {
				mapTinhTrangHangHoaCaBiet,
				sections: [
					{
						title: 'Thông tin chung',
						fields: [
							{ label: 'Mã tài sản', key: 'MaVach' },
							{ label: 'Tên tài sản', key: 'TenHangHoa' },
							{ label: 'Số serial', key: 'SoSeries' }
						]
					},
					{
						title: 'Giá trị & vị trí',
						fields: [
							{ label: 'Nguyên giá', key: 'NguyenGia', type: 'money' },
							{ label: 'Giá trị còn lại', key: 'GiaTriConLai', type: 'money' },
							{ label: 'Thời gian khấu hao', key: 'ThoiGianKhauHao' },
							{ label: 'Địa điểm', key: 'TenDiaDiem' },
							{ label: 'Khu vực', key: 'TenKhuVuc' }
						]
					},
					{
						title: 'Bảo hành & trạng thái',
						fields: [
							{ label: 'Ngày bắt đầu bảo hành', key: 'NgayBatDauBaoHanh', type: 'date' },
							{ label: 'Ngày kết thúc bảo hành', key: 'NgayKetThucBaoHanh', type: 'date' },
							{ label: 'Ngày bắt đầu sử dụng', key: 'NgayBatDauSuDung', type: 'date' },
							{ label: 'Tình trạng', key: 'TinhTrang' }
						]
					}
				],
	
				desktopRows: [
					[{ label: 'Mã tài sản', key: 'MaVach' }, { label: 'Số serial', key: 'SoSeries' }],
					[{ label: 'Tên tài sản', key: 'TenHangHoa' }],
					[{ label: 'Nguyên giá', key: 'NguyenGia', type: 'money' }, { label: 'Địa điểm', key: 'DiaDiem_Id' }],
					[{ label: 'Ngày bắt đầu bảo hành', key: 'NgayBatDauBaoHanh', type: 'date' }, { label: 'Ngày kết thúc bảo hành', key: 'NgayKetThucBaoHanh', type: 'date' }],
					[{ label: 'Ngày bắt đầu sử dụng', key: 'NgayBatDauSuDung', type: 'date' }, { label: 'Tình trạng', key: 'TinhTrang' }]
				]
			}
		},
	
		methods: {
			closeDialog() {
				this.$emit('update:isShow', false)
			},
	
			formatValue(field, value) {
				if (value === null || value === undefined || value === '') return '-'
	
				if (field.type === 'money') {
					return Number(value).toLocaleString('vi-VN')
				}
	
				if (field.type === 'date') {
					const d = new Date(value)
					return isNaN(d) ? value : d.toLocaleDateString('vi-VN')
				}
	
				return value
			},
	
			closeAll() {
				this.$emit('update:isShow', false)
				this.$emit('closeQuetQRDialog')
			}
		}
	}
</script>