<template>
	<div>
		<v-dialog v-model="dialog" max-width="700">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
					<span class="subtitle-1 font-weight-bold primary--text">Quản lý đợt Hội đồng NCKH Sinh Viên</span>
					<v-spacer></v-spacer>
					<v-btn color="primary" elevation="0" small class="mr-2" @click="openForm(null)">
						<v-icon left small>mdi-plus</v-icon>Thêm đợt
					</v-btn>
					<v-btn small icon @click="dialog = false">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-2">
					<v-data-table dense :headers="headers" :items="items" :items-per-page="10">
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

		<v-dialog v-model="formDialog" max-width="500">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
					<span class="subtitle-1 font-weight-bold primary--text">
						{{ editItem.DotId ? 'Chỉnh sửa đợt' : 'Thêm đợt mới' }}
					</span>
					<v-spacer></v-spacer>
					<v-btn small icon @click="formDialog = false">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-2">
					<v-form ref="form">
						<v-row>
							<v-col cols="12">
								<v-text-field v-model="editItem.TenDot" label="Tên đợt (vd: BC NCKH SV - Lần thứ 41 Năm 2025)"
									:rules="requiredRules" hide-details outlined dense></v-text-field>
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="editItem.NamHoc" label="Năm học (vd: 2025-2026)"
									:rules="requiredRules" hide-details outlined dense></v-text-field>
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
		emits: ['input', 'on-dot-changed'],
		data() {
			return {
				items: [],
				formDialog: false,
				saving: false,
				editItem: { DotId: null, TenDot: '', NamHoc: '' },
				requiredRules: [(v) => (!!v && v.length > 0) || 'Bắt buộc nhập'],
				headers: [
					{ text: 'Tên đợt', value: 'TenDot' },
					{ text: 'Năm học', value: 'NamHoc', width: '140' },
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
			async fetchList() {
				const data = await ajaxCALLPromise('/NCKH_Dot_Get')
				this.items = (data || []).filter(item => item.LoaiHoiDong === 1)
			},
			openForm(item) {
				this.editItem = item ? { ...item } : { DotId: null, TenDot: '', NamHoc: '' }
				this.formDialog = true
			},
			async saveItem() {
				if (!this.$refs.form.validate()) return
				this.saving = true
				try {
					if (this.editItem.DotId) {
						await ajaxCALLPromise('/NCKH_Dot_Upd', {
							DotID: this.editItem.DotId,
							LoaiHoiDong: 1,
							TenDot: this.editItem.TenDot,
							NamHoc: this.editItem.NamHoc,
						})
					} else {
						await ajaxCALLPromise('/NCKH_Dot_Ins', {
							LoaiHoiDong: 1,
							TenDot: this.editItem.TenDot,
							NamHoc: this.editItem.NamHoc,
						})
					}
					Vue.$toast.success('Đã lưu đợt', { position: 'top' })
					this.formDialog = false
					this.fetchList()
					this.$emit('on-dot-changed')
				} finally {
					this.saving = false
				}
			},
			deleteItem(item) {
				const $this = this
				confirm({
					title: 'Xác nhận xóa đợt',
					action: async function () {
						await ajaxCALLPromise('/NCKH_Dot_Del', { DotID: item.DotId })
						$this.fetchList()
						$this.$emit('on-dot-changed')
					},
				})
			},
		},
	}
</script>