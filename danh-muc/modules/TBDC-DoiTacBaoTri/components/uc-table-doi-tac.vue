<template>
	<div class="pa-2 border-b border-t">
		<v-row dense>
			<v-col cols="3">
				<v-text-field v-model="search" density="compact" variant="outlined" label="Tìm kiếm" flat
					clearable></v-text-field>
			</v-col>
		</v-row>
	</div>

	<v-data-table :headers="headers" :items="data" :search="search" density="compact" fixed-header
		style="height:calc(100vh - 105px)" items-per-page-text="Bản ghi" :items-per-page="20"
		:items-per-page-options="[15, 20, 50, 100]">

		<template v-slot:item.actions="{ item }">
			<v-menu>
				<template v-slot:activator="{ props }">
					<v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
				</template>
				<v-list density="compact">
					<v-list-item @click="onEdit(item)" prepend-icon="mdi-square-edit-outline"
						title="Cập nhật"></v-list-item>
					<v-divider />
					<v-list-item @click="onDelete(item)" prepend-icon="mdi-trash-can" title="Xóa"></v-list-item>
				</v-list>
			</v-menu>
		</template>

		<template v-slot:no-data>
			<uc-empty text="Chưa có đối tác"></uc-empty>
		</template>
	</v-data-table>
</template>

<script>
export default {
	props: {
		data: Array,
		loadData: Function
	},
	emits: ['edit-emit'],
	data() {
		return {
			search: null,
			headers: [
				{ title: "#", key: "STT", sortable: false },
				{ title: "Tên đối tác", key: "TenDoiTac" },
				{ title: '', key: 'actions', sortable: false },
			],
		}
	},
	mounted() { },
	computed: {},
	watch: {},
	methods: {
		onEdit(item) {
			this.$emit("edit-emit", item)
		},

		async onDelete(item) {
			const $this = this
			const params = {
				DoiTac_BaoTri_Id: item.DoiTac_BaoTri_Id,
			}
			showConfirm(
				`Xác nhận xoá: <b>${item.TenDoiTac}</b>`,
				() => {
					apiCall("work/TS_DoiTacBaoTri_Delete", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.loadData()
					})
				}
			)
		},
	},
}
</script>