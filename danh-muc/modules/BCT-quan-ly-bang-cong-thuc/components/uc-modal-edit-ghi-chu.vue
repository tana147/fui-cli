<template>
	<v-dialog v-model="modelValue" max-width="400">
		<v-card>
			<template v-slot:title>
				Nhập ghi chú - {{ detailRecord.ThanhPhan }}
			</template>

			<template v-slot:append>
				<v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
			</template>

			<v-card-text>
				<v-row>
					<v-col cols="12">
						<v-text-field v-model="formData.GhiChu" label="Ghi chú" required autofocus />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer />
				<v-btn variant="flat" @click="onClose">Hủy</v-btn>
				<v-btn color="primary" @click="onSave" variant="flat">
					<v-icon left size="small">mdi-content-save</v-icon>
					Lưu
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ['modelValue', 'detailRecord'],
		emits: ['update:modelValue', 'onReloadGhiChu'],
		data() {
			return {
				vueData,
				formData: {
					GhiChu: null,
				},
			}
		},
		watch: {
			detailRecord: {
				handler(val) {
					if (val && Object.keys(val).length) {
						this.formData = {
							GhiChu: val.GhiChu ?? '',
						}
					}
				},
				immediate: true
			},
		},
		computed: {},
		methods: {
			onClose() {
				this.$emit('update:modelValue', false)
			},
			onSave() {
				const payload = {
					ThanhPhan_Id: this.detailRecord.STT,
					ThanhPhan: this.detailRecord.ThanhPhan,
					GhiChu: this.formData.GhiChu
				}
	
				showAlert(JSON.stringify(payload))
	
				this.$emit('onReload', payload)
				this.onClose()
			}
		}
	}
</script>