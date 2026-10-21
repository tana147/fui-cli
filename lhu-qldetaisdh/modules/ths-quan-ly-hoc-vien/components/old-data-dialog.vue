<template>
	<v-dialog v-model="vueData.isOldData" transition="dialog-bottom-transition" max-width="1000px" persistent>
		<v-card>
			<c-toolbar @onClose="closeModal">
				<template v-slot:title>
					<div class="title primary--text text-left">
						Dữ liệu cũ bước {{thongtinbuoc.TASK_NAME}}
					</div>
				</template>
			</c-toolbar>

			<v-card-text>
				<div v-if="currentField === 1" v-for="(item, index) in DS_ThongTinHoiDong" :key="index">
					<h4 class="mt-3">
						Số Quyết định
					</h4>
					<v-text-field v-model="item.Decision_SoQD" outlined color="primary" dense hide-details disabled />

					<h4 class="mt-3">
						Thời gian bảo vệ
					</h4>
					<v-text-field v-model="item.ThoiGianBaoVe" outlined color="primary" dense hide-details disabled />

					<h4 class="mt-3">
						Hội Đồng bảo vệ
					</h4>
					<c-table label="Danh sách thành viên hội đồng" :headers="tvhdHeader" :items="DS_ThanhVienHoiDong"
						isNew="false" isEdit="false" hide-default-footer>
						<template v-slot:item.HoTenHocHamHocVi="{ item }">
							<span>
								<span>{{ item.HocViHocHam }}. {{ item.HoTenGiangVien }}</span>
							</span>
						</template>

						<template v-slot:item.STT="{ item, index }">
							<span>
								{{ index + 1 }}
							</span>
						</template>
					</c-table>
				</div>

				<div v-if="currentField !== 1" v-for="(item, index) in DataList" :key="index">
					<h4 v-if="item.Task_Detail_Display === 1" class="mt-3">{{index + 1}}. {{item.Task_Detail_Description}}</h4>

					<!-- Text field -->
					<v-text-field outlined dense color="success" v-model="item.Text_Content" :hint="item.Data_Exp"
						disabled
						v-if="item.Task_Detail_Display === 1 && (item.Task_Detail_Type === 'TEXT' || item.Task_Detail_Type === 'TEXTVIEW')" />

					<!-- Date -->
					<div class="dateWrap" v-if="item.Task_Detail_Display === 1 && item.Task_Detail_Type.includes('DATE')">
						<f-date v-model="item.Text_Content" disabled />
					</div>

					<!-- Number -->
					<v-text-field v-if="item.Task_Detail_Display === 1 && item.Task_Detail_Type.includes('DIEM')"
						class="scoreField mb-3 mt-1" color="success" outlined dense v-model="item.Text_Content"
						:hint="item.Data_Exp" hide-details reverse disabled />

					<!-- Textarea -->
					<v-textarea v-model="item.Text_Content"
						v-if="item.Task_Detail_Display === 1 && item.Task_Detail_Type.includes('TEXTAREA')"
						:class="[item.Task_Detail_StyleDisplay ? 'mt-2 ' + item.Task_Detail_StyleDisplay : 'mt-2']"
						outlined name="input-7-1" rows="1" color="green" flat="false" auto-grow dense
						:hide-details="item.Task_Help ? false : true" :hint="item.Task_Help" disabled />

					<div v-if="item.Task_Detail_Display === 1 && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW')">
						<div>
							<v-chip label outlined v-if="item.File_ID" class="mb-3" color="deep-purple accent-4">
								<v-icon left>mdi-file-check-outline</v-icon>
								<a :href="vueData.v_Set.urlReadFile + item.File_URL" target="_blank"
									style="color: deep-purple accent-4">{{item.File_Name}}</a>
							</v-chip>
						</div>
						<v-chip v-if="item.Task_Detail_Display === 1 && !item.File_ID" class="mb-3" color="deep-purple accent-4" outlined label>
							Chưa upload file
						</v-chip>
					</div>
				</div>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		// currentField
		//{ 1: Hội đồng/Thành viên hội đồng
		// 2: Đăng ký bảo vệ
		// 3: Bảo vệ đề tài
		// 0: Không rõ }
		props: ["dsthongtinhoidong", "dstvhd", "dsdkybaove", "dsbaove", "thongtinbuoc", "currentfield"],
		data() {
			return {
				tvhdHeader: [
					{
						text: 'STT',
						value: 'STT',
						class: 'renderCol',
						sortable: false,
						align: 'center',
					},
					{
						text: 'Họ và tên',
						value: 'HoTenHocHamHocVi',
					},
					{
						text: 'Ngành giảng dạy',
						value: 'NganhGiangDay',
					},
					{
						text: 'Cơ quan công tác',
						value: 'CoQuanCongTac',
					},
					{
						text: 'Chức trách',
						value: 'ChucTrach',
					},
				]
			}
		},
		mounted() { },
		computed: {
			DS_ThongTinHoiDong() {
				return this.dsthongtinhoidong
			},
	
			DS_ThanhVienHoiDong() {
				return this.dstvhd
			},
	
			DataList() {
				return this.currentField === 2 ? this.dsdkybaove : this.currentField === 3 ? this.dsbaove : []
			},
	
			currentField() {
				return this.currentfield
			},
		},
		watch: {},
		methods: {
			closeModal() {
				vueData.isOldData = false
			}
		},
	}
</script>