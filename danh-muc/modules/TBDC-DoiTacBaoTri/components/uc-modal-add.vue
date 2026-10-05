<template>
	<v-dialog v-model="isShow" width="500">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Thêm mới
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-card-text class="pt-0">
				<v-form ref="form">
					<v-text-field :rules="[v => !!v || 'Vui lòng nhập tên đối tác']" v-model="item.TenDoiTac"
						label="* Nhập tên tên đối tác" hide-details="auto">
					</v-text-field>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline"
					@click="onSubmit">Lưu</v-btn>
			</v-card-actions>

		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		loadData: Function
	},
	data() {
		return {
			item: {},
		}
	},
	mounted() {
	},
	computed: {
	},
	watch: {},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) return
			const params = {
				TenDoiTac: this.item.TenDoiTac,
			}
			apiCall("work/TS_DoiTacBaoTri_Insert", params, (res) => {
				if (res) showToast.success("Thành công");
				this.closeDialog()
				this.loadData()
			})
		}
	},
}
</script>