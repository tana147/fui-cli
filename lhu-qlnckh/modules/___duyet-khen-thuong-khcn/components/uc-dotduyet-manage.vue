<template>
	<div>
		<v-dialog v-model="dialog" max-width="900" persistent>
			<v-card class="rounded-xs">
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold primary white--text">
					Quản lý đợt duyệt chi tiền khen thưởng
					<v-spacer></v-spacer>
					<v-btn color="white" text small class="mr-2" @click="openForm(null)">
						<v-icon left small>mdi-plus</v-icon>Thêm đợt duyệt
					</v-btn>
					<v-btn icon dark small @click="dialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<v-data-table dense fixed-header height="350px" :headers="headers" :items="items" :items-per-page="10">
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

		<v-dialog v-model="formDialog" max-width="600" persistent>
			<v-card class="rounded-xs">
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold primary white--text">
					{{ editItem.DotDuyetID ? 'Chỉnh sửa đợt duyệt' : 'Thêm đợt duyệt mới' }}
					<v-spacer></v-spacer>
					<v-btn icon dark small @click="formDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-3">
					<v-form ref="form">
						<v-row dense>
							<v-col cols="12">
								<v-text-field v-model="editItem.TenDotDuyet" label="Tên đợt duyệt (VD: Đợt duyệt T01/2026)"
									:rules="requiredRules" hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="6">
								<v-text-field v-model="editItem.NienKhoa" label="Niên khóa (vd 2025-2026)"
									hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="6">
								<v-switch v-model="editItem.TinhTrang" :true-value="1" :false-value="0"
									label="Đang mở duyệt" hide-details class="mt-1"></v-switch>
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
					<v-btn text @click="formDialog = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" :loading="saving" @click="saveItem">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-dotduyet-manage',
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
					DotDuyetID: null,
					TenDotDuyet: '',
					NienKhoa: '',
					TinhTrang: 1,
					ThoiGianBatDau: '',
					ThoiGianKetThuc: '',
					GhiChu: '',
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
				if (typeof val === 'string' && val.includes('/')) return val
				if (moment(val).isValid()) return moment(val).format('DD/MM/YYYY')
				return val
			},
			async fetchList() {
				const data = await ajaxCALLPromise('/ThiKHCN_DotDuyet_Get')
				this.items = data || []
			},
			openForm(item) {
				if (item) {
					let start = ''
					let end = ''
					if (item.ThoiGianBatDau) {
						const rawStart = String(item.ThoiGianBatDau).substring(0, 10)
						if (rawStart.includes('/')) {
							const parts = rawStart.split('/')
							if (parts.length === 3) start = `${parts[2]}-${parts[1]}-${parts[0]}`
						} else if (moment(item.ThoiGianBatDau).isValid()) {
							start = moment(item.ThoiGianBatDau).format('YYYY-MM-DD')
						}
					}
					if (item.ThoiGianKetThuc) {
						const rawEnd = String(item.ThoiGianKetThuc).substring(0, 10)
						if (rawEnd.includes('/')) {
							const parts = rawEnd.split('/')
							if (parts.length === 3) end = `${parts[2]}-${parts[1]}-${parts[0]}`
						} else if (moment(item.ThoiGianKetThuc).isValid()) {
							end = moment(item.ThoiGianKetThuc).format('YYYY-MM-DD')
						}
					}
					this.editItem = {
						...item,
						ThoiGianBatDau: start,
						ThoiGianKetThuc: end,
					}
				} else {
					this.editItem = {
						DotDuyetID: null,
						TenDotDuyet: '',
						NienKhoa: '',
						TinhTrang: 1,
						ThoiGianBatDau: moment().format('YYYY-MM-DD'),
						ThoiGianKetThuc: moment().add(1, 'month').format('YYYY-MM-DD'),
						GhiChu: '',
					}
				}
				this.formDialog = true
			},
			async saveItem() {
				if (!this.$refs.form.validate()) return
				this.saving = true
				try {
					const isNew = !this.editItem.DotDuyetID
					const url = isNew ? '/ThiKHCN_DotDuyet_Ins' : '/ThiKHCN_DotDuyet_Udp'
					const params = {
						TenDotDuyet: this.editItem.TenDotDuyet,
						TinhTrang: this.editItem.TinhTrang,
						NienKhoa: this.editItem.NienKhoa,
						ThoiGianBatDau: this.editItem.ThoiGianBatDau,
						ThoiGianKetThuc: this.editItem.ThoiGianKetThuc,
						GhiChu: this.editItem.GhiChu,
					}
					if (!isNew) {
						params.DotDuyetID = this.editItem.DotDuyetID
					}

					await ajaxCALLPromise(url, params)
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
					title: 'Xác nhận xóa đợt duyệt này?',
					action: async function () {
						await ajaxCALLPromise('/ThiKHCN_DotDuyet_Del', { DotDuyetID: item.DotDuyetID })
						Vue.$toast.success('Xóa đợt duyệt thành công', { position: 'top' })
						$this.fetchList()
						$this.$emit('on-reload')
					},
				})
			},
		},
	}
</script>