<template>
	<v-dialog v-model="dialog" fullscreen transition="dialog-bottom-transition">
		<v-card>
			<v-toolbar color="primary">
				<v-toolbar-title>Danh sách các lịch bảo trì định kỳ</v-toolbar-title>
				<v-btn icon="mdi-close" @click="dialog = false"></v-btn>
			</v-toolbar>
			<v-card-text>
				<v-data-table :items="items" :headers="headers" class="elevation-1">
					<template #item.actions="{ item }">
						<v-btn size="small" icon="mdi-delete" color="red" variant="text"
							@click="deleteItem(item.MaLichDinhKy)"></v-btn>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		data() {
			return {
				dialog: false, items: [],
				headers: [
					{ title: 'Tên Lịch', key: 'TenLichBaoTri' }, { title: 'Ngày Bắt đầu', key: 'NgayBatDau' },
					{ title: 'Loại định kỳ', key: 'LoaiDinhKy' }, { title: 'Thao tác', key: 'actions', sortable: false }
				]
			};
		},
		methods: {
			async open() {
				this.dialog = true;
				const res = await axios.post("TS_LichBaoTriDinhKy_Select");
				this.items = res.data.data || [];
			},
			async deleteItem(id) {
				if (!await this.$refs.confirm.open({ title: 'Xóa lịch', message: 'Xóa lịch định kỳ này?', okColor: 'red' })) return;
				await axios.post("TS_LichBaoTriDinhKy_Delete", { MaLichDinhKy: id });
				this.open(); 
				this.$emit('refresh');
			}
		}
	}
</script>