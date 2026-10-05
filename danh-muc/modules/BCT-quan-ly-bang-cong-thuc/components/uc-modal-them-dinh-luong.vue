<template>
	<v-dialog v-model="modelValue" max-width="500px" persistent>
		<v-card>
			<v-card-title class="d-flex align-center justify-space-between">
				<span class="text-h6">Thêm cột định lượng</span>
				<v-btn icon="mdi-close" variant="text" size="small" @click="closeModal" />
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4">
				<div class="d-flex align-center justify-space-between mb-3">
					<div class="text-subtitle-2 text-grey-darken-1">
						Chọn các cột định lượng muốn hiển thị
					</div>

					<!-- Checkbox Chọn tất cả (thay cho v-btn) -->
					<v-checkbox v-model="chonTatCaModel" label="Chọn tất cả" color="primary" density="compact"
						hide-details class="ma-0 pa-0" :indeterminate="isIndeterminate" />
				</div>

				<v-row dense>
					<v-col v-for="opt in dinhLuongOpts" :key="opt.val" cols="6" sm="4">
						<v-checkbox v-model="dinhLuongSelect" :value="opt.val" :label="opt.title"
							:disabled="opt.val === 1" color="primary" density="comfortable" hide-details>
							<template v-slot:label>
								<span :class="opt.val === 1 ? 'text-grey' : ''">
									{{ opt.title }}
									<!-- <v-chip v-if="opt.val === 1" size="x-small" color="grey" class="ml-1">
										Bắt buộc
									</v-chip> -->
								</span>
							</template>
						</v-checkbox>
					</v-col>
				</v-row>

				<v-divider class="my-4" />

				<v-alert v-if="changeInfo.added.length > 0 || changeInfo.removed.length > 0" type="info" variant="flat"
					density="compact">
					<div v-if="changeInfo.added.length > 0">
						<strong>Thêm mới:</strong> {{ changeInfo.added.join(', ') }} phần
					</div>
					<div v-if="changeInfo.removed.length > 0">
						<strong class="text-error">Xóa:</strong> {{ changeInfo.removed.join(', ') }} phần
					</div>
				</v-alert>
			</v-card-text>

			<v-divider />

			<v-card-actions class="px-4 py-3">
				<v-spacer />
				<v-btn variant="flat" @click="closeModal">Hủy</v-btn>
				<v-btn color="primary" variant="flat" @click="handleLuuThayDoi" :disabled="!hasChanges">
					Lưu thay đổi
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			modelValue: {
				type: Boolean,
				default: false
			},
			cotDinhLuongHienTai: {
				type: Array,
				default: () => []
			}
		},
	
		emits: ['editAll'],
	
		data() {
			return {
				dinhLuongSelect: [],
				dinhLuongBanDau: [],
	
				dinhLuongOpts: [
					{ title: "1/2 phần", val: 0.5 },
					{ title: "1 phần", val: 1 },
					{ title: "2 phần", val: 2 },
					{ title: "3 phần", val: 3 },
					{ title: "4 phần", val: 4 },
					{ title: "5 phần", val: 5 },
					{ title: "6 phần", val: 6 },
					{ title: "7 phần", val: 7 },
					{ title: "8 phần", val: 8 },
					{ title: "9 phần", val: 9 },
					{ title: "10 phần", val: 10 },
				],
			}
		},
	
		computed: {
			allVals() {
				return this.dinhLuongOpts.map(x => x.val)
			},
	
			isChonTatCa() {
				return this.allVals.length > 0 && this.allVals.every(v => this.dinhLuongSelect.includes(v))
			},
	
			isIndeterminate() {
				const count = this.dinhLuongSelect.length
				return count > 0 && !this.isChonTatCa
			},
	
			// Checkbox "Chọn tất cả" điều khiển danh sách chọn
			chonTatCaModel: {
				get() {
					return this.isChonTatCa
				},
				set(val) {
					if (val) {
						// Chọn tất cả
						this.dinhLuongSelect = [...this.allVals]
					} else {
						// Bỏ chọn tất cả -> chỉ giữ lại phần bắt buộc
						this.dinhLuongSelect = [1]
					}
				}
			},
	
			changeInfo() {
				const banDau = new Set(this.dinhLuongBanDau)
				const hienTai = new Set(this.dinhLuongSelect)
	
				const added = this.dinhLuongSelect.filter(x => !banDau.has(x))
				const removed = this.dinhLuongBanDau.filter(x => !hienTai.has(x))
	
				return { added, removed }
			},
	
			hasChanges() {
				return this.changeInfo.added.length > 0 || this.changeInfo.removed.length > 0
			}
		},
	
		watch: {
			modelValue(val) {
				if (val) {
					// Load các cột hiện tại khi mở modal
					this.dinhLuongSelect = [...this.cotDinhLuongHienTai]
					this.dinhLuongBanDau = [...this.cotDinhLuongHienTai]
				}
			}
		},
	
		methods: {
			handleLuuThayDoi() {
				// Emit thông tin thay đổi lên component cha
				this.$emit('onCapNhatCot', {
					dinhLuongSelect: this.dinhLuongSelect,
					added: this.changeInfo.added,
					removed: this.changeInfo.removed
				})
	
				this.$emit("editAll")
	
				// Đóng modal
				this.closeModal()
			},
	
			closeModal() {
				this.$emit('update:modelValue', false)
			}
		}
	}
</script>