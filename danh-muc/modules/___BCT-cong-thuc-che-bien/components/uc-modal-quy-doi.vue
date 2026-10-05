<template>
	<v-dialog v-model="modelValue" max-width="400">
		<v-card>
			<template v-slot:title>Chọn đơn vị quy đổi chung</template>
			<template v-slot:append>
				<v-btn size="small" variant="text" v-bind="props" icon="mdi-close" @click="onClose"></v-btn>
			</template>
			<v-card-text>
				<v-row>
					<!-- Chọn hoặc nhập nhóm thành phần -->
					<v-col cols="12">
						<v-select v-model="formData.DonViChung" :items="donViOpts" label="Đơn vị" required />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" @click="onSave" prepend-icon="mdi-swap-horizontal" variant="flat">Quy đổi</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ["modelValue", 'donViOpts'],
		emits: ["update:modelValue", "onReload", "updateDonVi"],
		data() {
			return {
				formData: {
					DonViChung: null,
				},
			}
		},
	
		computed: {},
	
		methods: {
			resetForm() {
				this.formData = {
					DonViChung: null,
				}
			},
			onClose() {
				this.$emit("update:modelValue", false)
				this.resetForm()
			},
			onSave() {
				if (!this.formData.DonViChung) {
					showToast.error(`Chưa chọn đơn vị`)
					return
				}
				const payload = {
					DonViChung: this.formData.DonViChung
				}
				this.$emit("updateDonVi", this.formData.DonViChung)
	
				showToast.success(`Đã quy đổi sang ${this.formData.DonViChung}`)
				this.$emit("onReload")
				this.resetForm()
				this.onClose()
			},
		}
	}
</script>