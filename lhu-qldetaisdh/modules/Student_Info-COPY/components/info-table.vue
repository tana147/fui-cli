<template>
	<!-- {{dsstudentfilter.length}} -->
	<f-table :items="dsstudentfilter" :headers="tableHeader" :label="labelTable" showSearch="true" excel="true"
		:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" dense>
	</f-table>
</template>

<script>
	export default {
	    props: ['dsstudentfilter', 'dsexiststudent'],
	    data() {
	        return {
	            tableHeader: [
	                {
	                    text: 'STT',
	                    value: 'stt',
	                    innerHTML: '{{item.stt}}',
	                    el: 'span',
	                    sortable: false,
	                    align: 'center',
	                    width: 50,
	                },
	                {
	                    text: 'Học viên',
	                    value: 'StudentID',
	                    el: 'div',
	                    width: 200,
	                    innerHTML: "<span class='primary--text'><b>{{item.HoTen}}</b></span><br /><b>{{item.StudentID}}</b><span class='amber--text'> [{{item.LopID}}]</span>",
	                },
	                {
	                    text: 'Ngày sinh',
	                    value: 'NgaySinh',
	                },
	                {
	                    text: 'Niên khóa',
	                    value: 'NienKhoa',
	                },
	                {
	                    text: 'Tên ngành',
	                    value: 'TenNganh',
	                },
	                {
	                    text: 'Cập nhật',
	                    value: 'updTask',
	                    sortable: false,
	                    align: 'center',
	                    el: 'div',
	                    innerHTML: `<v-btn :disabled='!item.isExist && !item.isSelect' @click="selectHocVien(item)" color="indigo" text>Cập nhật thông tin</v-btn>`,
	                },
	                {
	                    text: 'Trạng thái',
	                    value: 'status',
	                    el: 'div',
	                    sortable: false,
	                    align: 'center',
	                    innerHTML: `<v-btn @click="onSave(item)" v-if='!item.isExist && !item.isSelect' color="primary" text>Thêm học viên</v-btn>
												<v-btn :disabled="!item.isCanDelete" @click="delectStudent(item)" v-else color="error" text>Xóa học viên</v-btn>`,
	                },
	                {
	                    text: '',
	                    value: 'resetProcess',
	                    sortable: false,
	                    align: 'center',
	                    el: 'div',
	                    innerHTML: `<v-btn :disabled='!item.isExist && !item.isSelect' @click="getStudentDetail(item)" color="warning" text>Đăng ký mới</v-btn>
	                        <v-btn v-if='item.HasResetProcess === 1' :disabled='!item.isExist && !item.isSelect' @click="openOldView(item)" color="teal" text>Xem dữ liệu đăng ký cũ
	                        </v-btn>`,
	                },
	                {
	                    text: '',
	                    value: 'IsXuLyHocVu',
	                    el: 'div',
	                    width: 100,
	                    align: 'center',
	                    innerHTML: `
									<v-btn @click="onXuLyHocVu(item)" color="purple darken-4" text :disabled="item.IsXuLyHocVu || (!item.isExist && !item.isSelect)">
			                            <span :style="item.IsXuLyHocVu ? 'color: #E65100' : ''">
											{{ item.IsXuLyHocVu ? 'ĐÃ XỬ LÝ HỌC VỤ' : 'XỬ LÝ HỌC VỤ' }}
										</span>
									</v-btn>
									`
	                }
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        labelTable() {
	            return this.dsstudentfilter.length > 0 ? `Danh sách thông tin học viên (${this.dsstudentfilter.length})` : 'Danh sách thông tin học viên'
	        },
	    },
	    watch: {},
	    methods: {
	
	    },
	}
</script>