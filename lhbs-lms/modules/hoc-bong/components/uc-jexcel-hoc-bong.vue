<template>
	<div class="w-100 pa-2 uc-jexcel-hoc-bong">
		<uc-jexcel class="height-excel-tong-ket-hoc-ki" v-if="vueData.DSHocSinh?.length > 0" v-model="vueData.instance"
			:freeze-columns="vueData.freezeColumns" :freeze-rows="2" v-model:dataSource="vueData.DSHocSinh"
			:columns="vueData.columnHeader" :key="vueData.keyComp" :filters="true" :exportExcel="true"
			@onChange="handleChange" @rowData="GetRowData" :styleSheet="vueData.styleSheet">
		</uc-jexcel>
		<v-alert v-else type="info" variant="tonal" class="my-4 text-center">
			<div v-if="vueData.activeTab === 'PHONG_TRAO'">
				<div class="mb-3 text-body-2">
					Chưa có danh sách khen thưởng cho phong trào này. Bạn có thể nhấn <b>"+ Thêm"</b> ở trên để thêm học sinh/lớp, hoặc bấm <b>"In giấy khen mẫu"</b> bên dưới để xem trước hình thức và phôi giấy khen.
				</div>
				<v-btn
					size="small"
					variant="flat"
					color="orange-darken-2"
					prepend-icon="mdi-printer-eye"
					:loading="vueData.isLoadingPrintSample"
					:disabled="!vueData.selectedPhongTrao"
					@click="vueData.exportGiayKhenMauPT && vueData.exportGiayKhenMauPT()"
				>
					In giấy khen mẫu (Xem trước phôi)
				</v-btn>
			</div>
			<div v-else>
				Không có dữ liệu học bổng cho học kì và khối đã chọn.
			</div>
		</v-alert>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				vueData
			}
		},
		mounted() {
			this.onDetailAction = event => {
				const button = event.target.closest('.hb-delete-detail')
				if (!button) return
				const detail = (vueData.DSHocBongDetail || []).find(x => String(x.ChiTietID) === String(button.dataset.id))
				if (!detail) return
				vueData.DelChiTietPTSelected = [detail]
				vueData.IsShowDialogDelChiTietPT = true
			}
			document.addEventListener('click', this.onDetailAction)
		},
		beforeUnmount() {
			document.removeEventListener('click', this.onDetailAction)
		},
		methods: {
			handleChange(val) {
				// Xử lý cập nhật dữ liệu nếu cần
				const cellAdresss = jspreadsheet.helpers.getCellNameFromCoords(val.x, val.y) // (j+3) là địa chỉ cột điểm đầu tiên, i là row let
				let styleCell = {}
				styleCell[cellAdresss] = `background-color : yellow`
				vueData.instance[0].setStyle(styleCell)
			},
			//Hứng dữ liệu từ bên trong component chung uc-jexcel để lấy row có cell thay đổi dữ liệu
			GetRowData(val) {
				//val có cấu trúc [1, '21200024', 'Nguyễn Thanh An', '09A', '11/09/2010',...] (row học sinh)
				//Tạo biến DSHocSinhChange để push HocSinhID có thay đổi dữ liệu (val[1])
				const exist = vueData.DSHocSinhChange.find(x => x == val[1])
				if (!exist) {
					vueData.DSHocSinhChange.push(val[1])
				}
			},
			download() {
				vueData.instance.helpers.download()
			},
		}
	}
</script>