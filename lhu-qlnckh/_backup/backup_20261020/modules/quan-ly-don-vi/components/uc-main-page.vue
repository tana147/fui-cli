<template>
	<v-card>
		<v-card-title class="d-flex align-center">
			<span class="primary--text">Quản lý đơn vị</span>
			<v-spacer></v-spacer>
			<v-text-field v-model="searhInput" placeholder="Tìm kiếm" prepend-icon="mdi-filter-outline" underlined
				hide-details dense style="max-width: 350px;" />
			<v-btn color="success" fab x-small outlined class="mb-2 ms-3" @click="onOpenModalAdd">
				<v-icon>mdi-plus</v-icon>
			</v-btn>
		</v-card-title>
		<v-card-text>
			<v-data-table :items="vueData.DSDonVi" :headers="headers" :items-per-page="50" :search="searhInput">
				<template v-slot:item.Actions="{ item }">
					<div class="d-flex">
						<v-spacer></v-spacer>
						<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
							@click="deleteItem(item)">
							mdi-trash-can-outline
						</v-icon>
						<v-icon style="font-size:18px" color="green darken-2" small class="mr-2"
							@click="editItem(item)">
							mdi-square-edit-outline
						</v-icon>
					</div>
				</template>
			</v-data-table>
		</v-card-text>
		<uc-modal-add-don-vi :isOpen="isShowModalAdd" @onFinish="CALL('DonVi_Get')"
			@updateIsOpen="isShowModalAdd = false" />
		<uc-modal-edit-don-vi :isOpen="isShowModalEdit" @onFinish="CALL('DonVi_Get')" :record="recordItem"
			@updateIsOpen="isShowModalEdit = false" />
	</v-card>

</template>

<script>
export default {
	props: [],
	data() {
		return {
			isShowModalAdd: false,
			isShowModalEdit: false,
			searhInput: '',
			headers: [
				{
					text: 'Mã đơn vị',
					value: 'MaDonVi'
				},
				{
					text: 'Tên đơn vị',
					value: 'TenDonVi'
				},
				{
					text: 'Thao tác',
					value: 'Actions',
					align: 'center',
					width: '100px'
				},
			],
			recordItem: {}
		}
	},
	mounted() { },
	computed: {},
	watch: {},
	methods: {
		onOpenModalAdd() {
			this.isShowModalAdd = true
			console.log("isShowModalAdd", this.isShowModalAdd);
		},
		editItem(record) {
			this.recordItem = Object.assign({}, record)
			this.isShowModalEdit = true
		},
		deleteItem(record) {
			confirm({
				title: `Bạn có chắc muốn xóa đơn vị ${record.TenDonVi}?`,
				action: async function () {
					ajaxCALL('/DonVi_Del', {
						MaDonVi: record.MaDonVi
					}, res => {
						CALL('DonVi_Get')
						Vue.$toast.success("Xóa đơn vị thành công!", { position: "top" })
					}, error => {
						Vue.$toast.error(error.responseJSON.Message, { position: "top" });
						CALL('DonVi_Get')
					})
				}
			});
		}
	},
}
</script>