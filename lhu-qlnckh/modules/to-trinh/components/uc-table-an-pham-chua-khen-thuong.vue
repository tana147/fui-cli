<template>
	<v-data-table v-model="SelectedAnPham" class="elevation-1" :headers="headers" :items="DSAnPhamChuaKhenThuong"
		show-select item-key="AnPhamID">
	</v-data-table>
</template>

<script>
	export default {
		props: ["value", "dsanphamchuacoquyetdinh"],
		data() {
			return {
				headers: [
					{ text: 'STT', sortable: false, value: "STT", },
					{ text: 'Tên ấn phẩm', sortable: false, value: "TenAnPham" },
					{ text: 'Tác giả', sortable: false, value: "TacGia" },
					{ text: 'Tên tạp chí', sortable: false, value: "TenTapChi" },
					{ text: 'Năm đăng', sortable: false, value: "NamDangBai" },
					{ text: 'Nơi đăng', sortable: false, value: "NoiDangBai" },
				],
				SelectedAnPham: []
			}
		},
		mounted() { },
		computed: {
			DSAnPhamChuaKhenThuong: function () {
				return this.dsanphamchuacoquyetdinh
			},
			DSAnPhamDuocKhenThuong: function () {
				return this.value
			}
	
		},
		watch: {
	
		},
		methods: {
			save() {
				let Duplicates = this.DSAnPhamDuocKhenThuong.filter(item => this.SelectedAnPham.includes(item))
				Duplicates.forEach(item => {
					let index = this.SelectedAnPham.indexOf(item)
					this.SelectedAnPham.splice(index, 1)
				})
				this.$emit("input", [...this.value, ...this.SelectedAnPham])
				this.SelectedAnPham = []
			},
		},
	}
</script>