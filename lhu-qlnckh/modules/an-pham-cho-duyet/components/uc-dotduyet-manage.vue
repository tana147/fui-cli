<template>
	<div>
		<v-dialog v-model="dialog" max-width="900">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
					Quản lý đợt duyệt
					<v-spacer></v-spacer>
					<v-btn color="primary" elevation="0" small class="mr-2" @click="openForm(null)">
						<v-icon left small>mdi-plus</v-icon>Thêm đợt duyệt
					</v-btn>
					<v-btn icon @click="dialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<v-data-table dense :headers="headers" :items="items" :items-per-page="10">
						<template v-slot:item.TinhTrang="{ item }">
							<v-chip small :color="item.TinhTrang === 1 ? 'success' : 'grey'" outlined>
								{{ item.TinhTrang === 1 ? 'Đang mở' : 'Đã đóng' }}
							</v-chip>
						</template>
						<template v-slot:item.ThoiGianBatDau="{ item }">
							{{ formatDate(item.ThoiGianBatDau) }}
						</template>
						<template v-slot:item.ThoiGianKetThuc="{ item }">
							{{ formatDate(item.ThoiGianKetThuc) }}
						</template>
						<template v-slot:item.actions="{ item }">
							<v-icon small color="green darken-2" class="mr-2" @click="openForm(item)">
								mdi-square-edit-outline
							</v-icon>
							<v-icon small color="red darken-3" @click="deleteItem(item)">
								mdi-trash-can-outline
							</v-icon>
						</template>
					</v-data-table>
				</v-card-text>
			</v-card>
		</v-dialog>

		<v-dialog v-model="formDialog" max-width="600">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
					{{ editItem.AnPham_DotDuyetID ? 'Chỉnh sửa đợt duyệt' : 'Thêm đợt duyệt mới' }}
					<v-spacer></v-spacer>
					<v-btn icon @click="formDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<v-form ref="form">
						<v-row>
							<v-col cols="12">
								<v-text-field v-model="editItem.TenDotDuyet" label="Tên đợt duyệt"
									:rules="requiredRules" hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="6">
								<v-text-field v-model="editItem.NienKhoa" label="Niên khóa (vd 2025-2026)"
									hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="6">
								<v-switch v-model="editItem.TinhTrang" :true-value="1" :false-value="0"
									label="Đang mở" hide-details class="mt-2"></v-switch>
							</v-col>
							<v-col cols="6">
								<v-text-field v-model="editItem.ThoiGianBatDau" label="Ngày bắt đầu" type="date"
									hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="6">
								<v-text-field v-model="editItem.ThoiGianKetThuc" label="Ngày kết thúc" type="date"
									hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="12">
								<v-textarea v-model="editItem.GhiChu" label="Ghi chú" outlined dense hide-details
									rows="2"></v-textarea>
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn color="primary" elevation="0" :loading="saving" @click="saveItem">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: {
			value: { type: Boolean, default: false },
		},
		emits: ['input', 'on-reload'],
		data() {
			return {
				items: [],
				formDialog: false,
				saving: false,
				editItem: {
					AnPham_DotDuyetID: null, TenDotDuyet: '', NienKhoa: '', TinhTrang: 1,
					ThoiGianBatDau: '', ThoiGianKetThuc: '', GhiChu: '',
				},
				requiredRules: [(v) => (!!v && v.length > 0) || 'Bắt buộc nhập'],
				headers: [
					{ text: 'Tên đợt duyệt', value: 'TenDotDuyet' },
					{ text: 'Niên khóa', value: 'NienKhoa', width: '110' },
					{ text: 'Bắt đầu', value: 'ThoiGianBatDau', width: '110' },
					{ text: 'Kết thúc', value: 'ThoiGianKetThuc', width: '110' },
					{ text: 'Tình trạng', value: 'TinhTrang', width: '110', align: 'center' },
					{ text: 'Thao tác', value: 'actions', width: '90', align: 'center', sortable: false },
				],
			}
		},
		computed: {
			dialog: {
				get() { return this.value },
				set(val) { this.$emit('input', val) },
			},
		},
		watch: {
			dialog(val) {
				if (val) this.fetchList()
			},
		},
		methods: {
			formatDate(val) {
				if (!val) return '-'
				return val.substring(0, 10).split('-').reverse().join('/')
			},
			async fetchList() {
				const data = await ajaxCALLPromise('/AnPham_DotDuyet_Get')
				this.items = data || []
			},
			openForm(item) {
				if (item) {
					this.editItem = {
						...item,
						ThoiGianBatDau: item.ThoiGianBatDau ? item.ThoiGianBatDau.substring(0, 10) : '',
						ThoiGianKetThuc: item.ThoiGianKetThuc ? item.ThoiGianKetThuc.substring(0, 10) : '',
					}
				} else {
					this.editItem = {
						AnPham_DotDuyetID: null, TenDotDuyet: '', NienKhoa: '', TinhTrang: 1,
						ThoiGianBatDau: '', ThoiGianKetThuc: '', GhiChu: '',
					}
				}
				this.formDialog = true
			},
			async saveItem() {
				if (!this.$refs.form.validate()) return
				this.saving = true
				try {
					if (this.editItem.AnPham_DotDuyetID) {
						await ajaxCALLPromise('/AnPham_DotDuyet_Upd', {
							AnPham_DotDuyetID: this.editItem.AnPham_DotDuyetID,
							TenDotDuyet: this.editItem.TenDotDuyet,
							TinhTrang: this.editItem.TinhTrang,
							NienKhoa: this.editItem.NienKhoa,
							ThoiGianBatDau: this.editItem.ThoiGianBatDau,
							ThoiGianKetThuc: this.editItem.ThoiGianKetThuc,
							GhiChu: this.editItem.GhiChu,
						})
					} else {
						await ajaxCALLPromise('/AnPham_DotDuyet_Ins', {
							TenDotDuyet: this.editItem.TenDotDuyet,
							TinhTrang: this.editItem.TinhTrang,
							NienKhoa: this.editItem.NienKhoa,
							ThoiGianBatDau: this.editItem.ThoiGianBatDau,
							ThoiGianKetThuc: this.editItem.ThoiGianKetThuc,
							GhiChu: this.editItem.GhiChu,
						})
					}
					Vue.$toast.success('Đã lưu đợt duyệt', { position: 'top' })
					this.formDialog = false
					this.fetchList()
					this.$emit('on-reload')
				} finally {
					this.saving = false
				}
			},
			deleteItem(item) {
				const $this = this
				confirm({
					title: 'Xác nhận xóa đợt duyệt',
					action: async function () {
						await ajaxCALLPromise('/AnPham_DotDuyet_Del', { AnPham_DotDuyetID: item.AnPham_DotDuyetID })
						$this.fetchList()
						$this.$emit('on-reload')
					},
				})
			},
		},
	}
</script>