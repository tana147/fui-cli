<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Tồn tối thiểu ({{ minimumStockRows.length }})</div>
            <v-spacer></v-spacer>
            <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="isAddMinimumStockDialogOpen = true">
                Thêm tồn tối thiểu</v-btn>
        </div>

        <z-table v-if="isMinimumStockTableReady" :headers="minimumStockTableHeaders" :items="minimumStockRows"
            height="480px" :options="childTableOptions" />

        <v-dialog v-model="isAddMinimumStockDialogOpen" width="720">
            <v-card>
                <template v-slot:title>Thêm tồn tối thiểu</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close" @click="closeAddMinimumStockDialog" />
                </template>
                <v-card-text>
                    <v-row>
                        <v-col cols="4">
                            <v-autocomplete v-model="minimumStockDraft.DiaDiem_Id" :items="allLocationRows"
                                item-title="TenDiaDiem" item-value="DiaDiem_Id" label="Địa điểm" density="compact"
                                hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="minimumStockDraft.SoLuongTonToiThieu" label="SL tồn tối thiểu"
                                density="compact" hide-details="auto" type="number" min="0" step="0.01"
                                @keydown="preventNegative" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="minimumStockDraft.GhiChu" label="Ghi chú" density="compact"
                                hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline"
                        @click="addMinimumStock">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="isUpdateMinimumStockDialogOpen" width="720">
            <v-card>
                <template v-slot:title>Cập nhật tồn tối thiểu</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close"
                        @click="isUpdateMinimumStockDialogOpen = false" />
                </template>
                <v-card-text>
                    <v-row>
                        <v-col cols="4">
                            <v-autocomplete v-model="editData.DiaDiem_Id" :items="allLocationRows"
                                item-title="TenDiaDiem" item-value="DiaDiem_Id" label="Địa điểm" density="compact"
                                hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="editData.SoLuongTonToiThieu" label="SL tồn tối thiểu"
                                density="compact" hide-details="auto" type="number" min="0" step="0.01"
                                @keydown="preventNegative" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="editData.GhiChu" label="Ghi chú" density="compact"
                                hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline"
                        @click="updateMinimumStock">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
    export default {
		props: {
			recordData: { type: Object, default: null },
			active: { type: Boolean, default: false },
		},
		emits: ['reloaded'],
		data() {
			return {
				childTableOptions: {
					movableColumns: false,
					resizableRows: false,
					layout: 'fitDataStretch',
				},
				isMinimumStockTableReady: false,
				minimumStockTableHeaders: [],
				minimumStockRows: [],
				allLocationRows: [],
				isAddMinimumStockDialogOpen: false,
				isUpdateMinimumStockDialogOpen: false,
				minimumStockDraft: {
					DiaDiem_Id: null,
					SoLuongTonToiThieu: null,
					GhiChu: '',
				},
				editData: {},
			}
		},
		watch: {
			active: {
				immediate: true,
				handler(val) {
					if (val && this.recordData?.HangHoa_Id) this.loadMinimumStockRows()
				},
			},
			'recordData.HangHoa_Id'(val) {
				if (this.active && val) this.loadMinimumStockRows()
			},
		},
		created() {
			this.initHeaders()
		},
		methods: {
			initHeaders() {
				this.minimumStockTableHeaders = [
					{ title: '#', formatter: 'rownum', width: 70, hozAlign: 'center' },
					{
						title: 'Địa điểm',
						field: 'TenDiaDiem',
						headerSort: true,
						headerFilter: 'input',
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.openUpdateMinimumStockDialog(item)
						},
						formatter: (cell) => `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue() || ''}</div>`,
					},
					{ title: 'SL tồn tối thiểu', field: 'SoLuongTonToiThieu', headerSort: true, headerFilter: 'input', width: 150, hozAlign: 'right' },
					{ title: 'Ghi chú', field: 'GhiChu', headerSort: true, headerFilter: 'input', width: 180 },
					{
						title: '',
						width: 60,
						hozAlign: 'center',
						headerSort: false,
						formatter: () => '<i class="icon-table text-red mdi mdi-trash-can-outline"></i>',
						cellClick: (e, cell) => this.deleteMinimumStock(cell.getRow().getData()),
					},
				]
			},
			resetMinimumStockDraft() {
				this.minimumStockDraft = {
					DiaDiem_Id: null,
					SoLuongTonToiThieu: null,
					GhiChu: '',
				}
			},
			async loadMinimumStockRows() {
				if (!this.recordData?.HangHoa_Id) return
				this.isMinimumStockTableReady = false
				const [allLocations, response] = await Promise.all([
					apiCallPromise('/work/HH_DiaDiem_Select'),
					apiCallPromise('/work/HH_HangHoa_TonToiThieu_Select', { HangHoa_Id: this.recordData.HangHoa_Id }),
				])
				this.allLocationRows = Array.isArray(allLocations?.data) ? allLocations.data : Array.isArray(allLocations) ? allLocations : []
				this.minimumStockRows = Array.isArray(response?.data) ? response.data : Array.isArray(response) ? response : []
				this.isMinimumStockTableReady = true
			},
			closeAddMinimumStockDialog() {
				this.isAddMinimumStockDialogOpen = false
				this.resetMinimumStockDraft()
			},
			addMinimumStock() {
				if (!this.minimumStockDraft.DiaDiem_Id) {
					showToast.error('Vui lòng chọn địa điểm')
					return
				}
				if (!this.minimumStockDraft.SoLuongTonToiThieu || Number(this.minimumStockDraft.SoLuongTonToiThieu) <= 0) {
					showToast.error('Số lượng tồn tối thiểu phải lớn hơn 0')
					return
				}
				apiCall('/work/HH_HangHoa_TonToiThieu_Insert', {
					Data_JSON: JSON.stringify([{
						HangHoa_Id: this.recordData.HangHoa_Id,
						DiaDiem_Id: this.minimumStockDraft.DiaDiem_Id,
						SoLuongTonToiThieu: String(this.minimumStockDraft.SoLuongTonToiThieu).trim(),
						GhiChu: this.minimumStockDraft.GhiChu ? this.minimumStockDraft.GhiChu.trim() : '',
					}]),
				}, async () => {
					showToast.success('Thêm tồn tối thiểu thành công')
					this.closeAddMinimumStockDialog()
					await this.loadMinimumStockRows()
					this.$emit('reloaded')
				})
			},
			openUpdateMinimumStockDialog(item) {
				this.editData = JSON.parse(JSON.stringify(item))
				this.isUpdateMinimumStockDialogOpen = true
			},
			updateMinimumStock() {
				if (!this.editData.DiaDiem_Id) {
					showToast.error('Vui lòng chọn địa điểm', { position: 'top' })
					return
				}
				if (!this.editData.SoLuongTonToiThieu || this.editData.SoLuongTonToiThieu == 0) {
					showToast.error('Vui lòng số lượng lớn hơn 0', { position: 'top' })
					return
				}
				apiCall('work/HH_HangHoa_TonToiThieu_Update', {
					HangHoa_DiaDiem_TonToiThieu_Id: this.editData.HangHoa_DiaDiem_TonToiThieu_Id,
					HangHoa_Id: this.editData.HangHoa_Id,
					DiaDiem_Id: this.editData.DiaDiem_Id,
					SoLuongTonToiThieu: this.editData.SoLuongTonToiThieu ? this.editData.SoLuongTonToiThieu.toString().trim() : this.editData.SoLuongTonToiThieu,
					GhiChu: this.editData.GhiChu ? this.editData.GhiChu.trim() : this.editData.GhiChu,
				}, async () => {
					showToast.success('Cập nhật thành công!')
					await this.loadMinimumStockRows()
					this.isUpdateMinimumStockDialogOpen = false
					this.$emit('reloaded')
				})
			},
			deleteMinimumStock(item) {
				showConfirm(`Bạn chắc chắn muốn xóa tồn tối thiểu? <br/> <b>${item.TenDiaDiem || ''}</b>`, () => {
					apiCall('work/HH_HangHoa_TonToiThieu_Delete', {
						HangHoa_DiaDiem_TonToiThieu_Id: item.HangHoa_DiaDiem_TonToiThieu_Id,
					}, async () => {
						showToast.success('Xóa thành công')
						await this.loadMinimumStockRows()
						this.$emit('reloaded')
					})
				})
			},
			preventNegative(e) {
				if (e.key === '-' || e.key === 'e' || e.key === '+') {
					e.preventDefault()
				}
			},
		},
	}
</script>