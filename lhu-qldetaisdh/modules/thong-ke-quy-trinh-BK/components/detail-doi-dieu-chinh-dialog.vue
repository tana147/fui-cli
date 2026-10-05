<template>
	<div>
		<v-dialog v-model="vueData.IsDetailDoiDieuChinhModal" transition="dialog-bottom-transition" max-width="1380px"
			persistent>
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Chi tiết đổi/điều chỉnh đề tài</p>
						<v-chip v-if="DetailData.SoLanDoiDieuChinh != null" class="ml-2" color="info" dark>
							{{ DetailData.SoLanDoiDieuChinh }} lần đổi/điều chỉnh
						</v-chip>
					</template>
				</c-toolbar>

				<v-card-text>
					<div class="mt-3">
						<v-card>
							<v-card-title class="primary--text">
								<!-- {{ lableTable }} -->
								<v-spacer></v-spacer>
								<v-text-field v-model="search" append-icon="mdi-magnify" label="Search" single-line
									hide-details></v-text-field>
							</v-card-title>
							<v-simple-table>
								<thead>
									<tr>
										<th class="hoTenWrap" style="width: 150px;">Họ tên</th>
										<th style="width: 150px;">Niên khóa</th>
										<th>Ngành</th>
										<th class="gvhdWrap">Đề tài đã đổi</th>
										<th class="gvhdWrap">GVHD 1</th>
										<th class="gvhdWrap">GVHD 2</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="(item, index) in mergedItems" :key="index">
										<!-- Họ và tên học viên -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											<span class="green--text">
												<b>{{ item.HoSV }} {{ item.TenSV }}</b>
											</span>
											<br />
											<b>{{ item.StudentID }}</b>
											<span class="amber--text">[{{ item.LopID }}]</span>
										</td>

										<!-- Niên khóa -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											{{ item.NienKhoa }}
										</td>

										<!-- Ngành -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											{{ item.TenNganh }}
										</td>

										<!-- Tên đề tài -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											{{ item.TenDeTai }}
										</td>

										<!-- Giảng viên 1 -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											{{ item.GVHD1 }}
										</td>

										<!-- Giảng viên 2 -->
										<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
											{{ item.GVHD2 }}
										</td>
									</tr>
								</tbody>
							</v-simple-table>
						</v-card>
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
	    props: ['detaildata'],
	    data() {
	        return {
	            DsChiTietDoiDieuChinh: [],
	            search: null,
	
	            tableHeader: [
	                {
	                    text: 'Học viên',
	                    value: 'StudentID',
	                    width: 200,
	                },
	                {
	                    text: 'Niên khóa',
	                    value: 'NienKhoa',
	                    sortable: false,
	                    align: 'center',
	                    width: 110,
	                },
	                {
	                    text: 'Tên ngành',
	                    value: 'TenNganh',
	                    width: 200,
	                },
	                {
	                    text: 'Tên đề tài đã đổi/điều chỉnh',
	                    value: 'TenDeTai',
	                    width: 500,
	                },
	                {
	                    text: 'GVHD 1',
	                    value: 'GVHD1',
	                    width: 180,
	                },
	                {
	                    text: 'GVHD 2',
	                    value: 'GVHD2',
	                    width: 180,
	                },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        IsDetailDoiDieuChinhModal() {
	            return vueData.IsDetailDoiDieuChinhModal
	        },
	        DetailData() {
	            console.log('asdas', this.detaildata)
	            return this.detaildata
	        },
	        mergedItems() {
	            if (!this.DsChiTietDoiDieuChinh || this.DsChiTietDoiDieuChinh.length === 0) return []
	
	            const merged = []
	            let currentItem = null
	
	            this.DsChiTietDoiDieuChinh.forEach((item, index) => {
	                if (!currentItem || currentItem.StudentID !== item.StudentID) {
	                    if (currentItem) {
	                        merged.push(currentItem)
	                    }
	                    currentItem = { ...item, rowspan: 1, STT: index + 1 }
	                } else {
	                    currentItem.rowspan++
	                }
	            })
	
	            if (currentItem) {
	                merged.push(currentItem)
	            }
	
	            return merged
	        },
	    },
	    watch: {
	        IsDetailDoiDieuChinhModal: function (val) {
	            if (val) {
	                this.onLoadChiTiet()
	            }
	        },
	    },
	    methods: {
	        onLoadChiTiet() {
	            ajaxCALL(
	                '/Student_Doi_DieuChinhChiTiet',
	                {
	                    Student_ID: this.DetailData.Student_ID,
	                    Process_ID: this.DetailData.Process_ID,
	                },
	                (res) => {
	                    this.DsChiTietDoiDieuChinh = res.data.map((item, index) => {
	                        return {
	                            ...item,
	                            STT: index + 1,
	                        }
	                    })
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Fail to load chi tiet doi dieu chinh', error)
	                },
	            )
	        },
	        closeDialog() {
	            vueData.IsDetailDoiDieuChinhModal = false
	        },
	    },
	}
</script>