<template>
	<div>
		<v-container>
			<edit-flow-detail-dialog :itemdetail="editItem" :fncheck="fnCheck" :detailtype="detailType" />
			<add-root-dialog :tasklist="taskList" />
			<edit-root-dialog :item="editItem" :tasklist="taskList" />
			<add-flow-detail-dialog :fncheck="fnCheck" :detailtype="detailType" />

			<div class="d-flex justify-center align-center mb-2">
				<v-btn @click="vueData.isAddRootDialog = true" color="primary" text>
					<v-icon>mdi-plus-circle-outline</v-icon> Thêm task mới
				</v-btn>
			</div>
			<!-- <v-btn @click="addArr">Test</v-btn> -->
			<v-expansion-panels v-model="vueData.panel" accordion>
				<!-- <div v-for="(itemTask, indexTask) in taskList" :key="indexTask">
				</div> -->
				<v-expansion-panel v-for="(item,index) in rootList" :key="index">
					<v-expansion-panel-header class="stepperStep" color="primary" dark disable-icon-rotate>
						{{index + 1}}./ {{item.Task_Name}}
						<template v-slot:actions>
							<!-- <v-tooltip left color="warning">
								<template v-slot:activator="{ on, attrs }">
									<v-btn v-on="on" x-small fab icon>
										<v-icon color="white">mdi-trash-can-outline</v-icon>
									</v-btn>
								</template>
								<span>Xóa</span>
							</v-tooltip>
							<v-tooltip left color="success">
								<template v-slot:activator="{ on, attrs }">
									<v-btn @click="callEditRootDialog(item)" v-on="on" x-small fab icon>
										<v-icon color="white">mdi-square-edit-outline</v-icon>
									</v-btn>
								</template>
								<span>Sửa</span>
							</v-tooltip> -->
							<v-icon></v-icon>
						</template>
					</v-expansion-panel-header>
					<v-expansion-panel-content>
						<div class="d-flex justify-center align-center mt-2">
							<v-btn color="red darken-3" text @click="deleteRoot(item)">
								<v-icon color="red darken-3">mdi-trash-can-outline</v-icon> Xóa task
							</v-btn>
							<v-btn @click="vueData.isEditRootDialog = true" color="green darken-2" text
								@click="callEditRootDialog(item)">
								<v-icon color="green darken-2">mdi-square-edit-outline</v-icon> Cập nhật task
							</v-btn>
						</div>
						<div class="d-flex justify-center align-center mt-2">
							<v-btn color="primary" text @click="vueData.isAddFlowDialog = true">
								<v-icon>mdi-plus-circle-outline</v-icon> Thêm task
								detail mới
							</v-btn>
						</div>


						<div v-for="(itemDetail, indexDetail) in taskDetailList" :key="indexDetail"
							v-if="itemDetail.Task_ID === item.Task_ID" class="d-flex align-center mb-5">
							<v-row>
								<v-col class="d-flex align-center" cols="10">
									<h4 class="justify-start">{{indexDetail + 1}}.
										{{itemDetail.Task_Detail_Description}}
									</h4>
								</v-col>

								<v-col cols="2">
									<div class="ml-4 d-flex justify-end wrapEditArea">
										<!-- <div class="d-flex justify-center align-center mr-4">
											<v-btn @click="swapItemUp(index)" v-if="indexDetail > 0" text x-small fab
												icon>
												<v-icon>mdi-menu-up</v-icon>
											</v-btn>
											<v-btn @click="swapItemDown(index)"
												v-if="indexDetail < taskDetailList.length - 1" text x-small fab icon>
												<v-icon>mdi-menu-down</v-icon>
											</v-btn>
										</div> -->

										<v-tooltip left color="warning">
											<template v-slot:activator="{ on, attrs }">
												<v-btn @click="deleteTaskDetail(itemDetail)" v-on="on" x-small fab icon>
													<v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
												</v-btn>
											</template>
											<span>Xóa</span>
										</v-tooltip>
										<v-tooltip left color="success">
											<template v-slot:activator="{ on, attrs }">
												<v-btn @click="callEditDialog(itemDetail)" v-on="on" x-small fab icon>
													<v-icon color="green darken-2">mdi-square-edit-outline</v-icon>
												</v-btn>
											</template>
											<span>Sửa</span>
										</v-tooltip>
									</div>
								</v-col>
							</v-row>
						</div>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn color="success">Lưu</v-btn>
						</v-card-actions>
					</v-expansion-panel-content>
				</v-expansion-panel>

			</v-expansion-panels>
		</v-container>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				items1: ['TEXT', 'TEXT || BUTTON', 'TEXTAREA', 'FILE', 'FILEVIEW', 'TEXTVIEW'],
				processList: [],
				taskList: [],
				rootList: [],
				taskDetailList: [],
				editItem: {},
				AddData: {
					Flow_Des: "",
					Flow_Type: null,
					Flow_AllowNull: false,
					Role: "",
	
				},
				fnCheck: [
					{
						name: "fnCheckTenDeTai"
					},
					{
						name: "fnCheckHocPhi(StudentID)"
					},
					{
						name: "fnCheckNoMon"
					},
				],
				detailType: [
					{
						name: "TEXTAREA | FUN",
					},
					{
						name: "TEXT",
					},
					{
						name: "CHECKBOX",
					},
					{
						name: "FILE",
					},
					{
						name: "FILEVIEW",
					},
					{
						name: "TEXTVIEW",
					},
					{
						name: "FUN",
					},
					{
						name: "TABLE",
					},
					{
						name: "DIEM",
					},
					{
						name: "TEXTAREA"
					},
				],
			}
		},
		mounted() {
			this.onLoadAdminFlow()
		},
		computed: {},
		watch: {
			"vueData.isAddWorkTreeDialog": function (val) {
				console.log("val", val)
			}
		},
		methods: {
			callEditDialog(item) {
				this.editItem = item
				vueData.isEditDialog = true
			},
			callEditRootDialog(item) {
				this.editItem = item
				vueData.isEditRootDialog = true
			},
			deleteRoot(item) {
				confirm({
					title: "Xóa task",
					content: (`Bạn có muốn xóa task "${item.Task_Name}" không?`),
					action: () => {
						console.log("delete success")
					},
					cancel: function () {
	
					}.bind(this)
				});
			},
			onLoadAdminFlow() {
				ajaxCALL("/Admin_Flow_Get", null,
					(res) => {
						this.processList = res.data[0]
						this.taskList = res.data[1]
						this.rootList = res.data[2]
						this.taskDetailList = res.data[3]
	
						console.log("this.processList", this.processList)
						console.log("this.taskList", this.taskList)
						console.log("this.rootList", this.rootList)
						console.log("this.taskDetailList", this.taskDetailList)
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("fail to load list", error)
					})
			},
			addArr() {
				openWindow("https://phongvu.vn/")
			},
			deleteTaskDetail(item) {
				confirm({
					title: "Xóa task detail",
					content: (`Bạn có muốn xóa task "${item.Task_Detail_Description}" không?`),
					action: () => {
						console.log("delete success")
					},
					cancel: function () {
	
					}.bind(this)
				});
			},
			swapItemUp(index) {
				if (index > -1) {
					// const temp = this.taskDetailArr[index]
					// this.taskDetailArr[index] = this.taskDetailArr[index - 1]
					// this.taskDetailArr[index - 1] = temp
					// console.log("this.taskDetailArr", this.taskDetailArr)
				}
			},
			swapItemDown(index) {
				if (index > -1) {
					// const temp = this.taskDetailArr[index]
					// this.taskDetailArr[index] = this.taskDetailArr[index + 1]
					// this.taskDetailArr[index + 1] = temp
					// console.log("this.taskDetailArr", this.taskDetailArr)
				}
			},
		},
	}
</script>