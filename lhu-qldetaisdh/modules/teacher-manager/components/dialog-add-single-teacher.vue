<template>
	<div>
        <v-dialog v-model="vueData.isAddTeacherDialog" persistent eager transition="dialog-bottom-transition" max-width="900px">
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Thêm giảng viên</p>
                    </template>
                </c-toolbar>

                <v-card-text>
                    <v-row dense>
                        <v-col cols="3">
                            <v-select v-model="HocViHocHam" :items="vueData.DsGetHocHam" item-text="Column1" item-value="Column1" dense outlined hide-details label="Học hàm, học vị" />
                        </v-col>
                        <v-col cols="9">
                            <v-text-field v-model="HoTen" outlined dense hide-details label="Họ tên giảng viên" />
                        </v-col>

                        <v-col cols="4">
                            <v-autocomplete v-model="NganhSelect" :items="NganhGiangDay" item-text="TenNganh" item-value="NganhID" dense outlined hide-details label="Ngành giảng dạy" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="SoDienThoai" type="number" outlined dense hide-details label="Số điện thoại" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="Email" type="email" outlined dense hide-details label="Email" />
                        </v-col>

                        <v-col cols="6">
                            <v-text-field v-model="CoQuan" outlined dense hide-details label="Cơ quan công tác" />
                        </v-col>
                        <v-col cols="6">
                            <v-text-field v-model="CoQuanCongTacTiengViet" outlined dense hide-details placeholder="Dành cho ngành Ngôn ngữ Anh" label="Cơ quan công tác (bằng tiếng Việt)" />
                        </v-col>

                        <v-col cols="4">
                            <v-text-field v-model="NganHangName" outlined dense hide-details label="Tên ngân hàng" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="SoTaiKhoan" outlined dense hide-details label="Số TK ngân hàng" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="MaSoThue" outlined dense hide-details label="Mã số thuế" />
                        </v-col>
                        

                        <v-col cols="12">
                            <v-textarea rows="2" v-model="DiaChi" label="Địa chỉ" outlined dense hide-details />
                        </v-col>
                    </v-row>

                    <div class="mt-3">
                        <h3>File văn bằng</h3>
                        <div class="d-flex align-center ml-auto" style="gap: 15px">
                            <div>
                                <f-file-upload label="" v-model="VanBang_Upload" :url="vueData.v_Set.apiFile" :filters="fileRules" color="v-btn--outlined v-size--default info--text" />
                            </div>
                            <div class="mt-3">
                                <div v-if="FileVanBangID !== null">
                                    <v-chip label outlined close class="mb-3" color="deep-purple accent-4" @click:close="deleteVanBangFile">
                                        <v-icon left>mdi-file-check-outline</v-icon>
                                        <a :href="vueData.v_Set.urlReadFile + '/FileData/' + FileVanBangID" target="_blank" style="color: deep-purple accent-4">{{ FileVanBangName }}</a>
                                    </v-chip>
                                </div>

                                <v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file </v-chip>
                            </div>
                        </div>
                    </div>
                    <div class="mt-3">
                        <h3>File lý lịch</h3>
                        <div class="d-flex align-center ml-auto" style="gap: 15px">
                            <div>
                                <f-file-upload label="" v-model="LyLich_Upload" :url="vueData.v_Set.apiFile" :filters="fileRules" color="v-btn--outlined v-size--default info--text" />
                            </div>
                            <div class="mt-3">
                                <div v-if="FileLyLichID !== null">
                                    <v-chip label outlined close class="mb-3" color="deep-purple accent-4" @click:close="deleteLyLichFile">
                                        <v-icon left>mdi-file-check-outline</v-icon>
                                        <a :href="vueData.v_Set.urlReadFile + '/FileData/' + FileLyLichID" target="_blank" style="color: deep-purple accent-4">{{ FileLyLichName }}</a>
                                    </v-chip>
                                </div>

                                <v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file </v-chip>
                            </div>
                        </div>
                    </div>
                </v-card-text>

                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="addTeacher" color="success"><v-icon left>mdi-plus</v-icon> Thêm</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ['dsgiangvien'],
    data() {
        return {
            HoTen: '',
            CoQuan: '',
            CoQuanCongTacTiengViet: '',
            HocViHocHam: '',
            DiaChi: '',
            SoDienThoai: '',

            NganHangName: '',
            SoTaiKhoan: '',
            MaSoThue: '',
            Email: '',
            LyLich_Upload: null,
            FileLyLichID: null,
            VanBang_Upload: null,
            FileVanBangID: null,

            NganhSelect: null,
            DsHeDaoTao: [],
            HeArr: [],

            fileRules: {
                max_file_size: '50mb',
                mime_types: [
                    {
                        title: 'Pdf files',
                        extensions: 'pdf',
                    },
                ],
            },
        }
    },
    mounted() {},
    computed: {
        AddTeacherDialog: function () {
            return vueData.isAddTeacherDialog
        },
        DsGiangVien: function () {
            return this.dsgiangvien
        },
		NganhGiangDay: function (){
			return vueData.NganhGiangDay
		},
    },
    watch: {
        AddTeacherDialog: function (val) {
            if (val) {
                this.loadheDaoTao()
            }
        },
        VanBang_Upload: function (val) {
            if (val) {
                console.log('val', val.Files[0].FILE_NAME)
                this.FileVanBangID = val.Files[0].FILE_ID
                this.FileVanBangName = val.Files[0].FILE_NAME
                this.FileVanBangUrl = val.Files[0].FILE_URL
            }
        },
        LyLich_Upload: function (val) {
            if (val) {
                console.log('val', val.Files[0].FILE_NAME)
                this.FileLyLichID = val.Files[0].FILE_ID
                this.FileLyLichName = val.Files[0].FILE_NAME
                this.FileLyLichUrl = val.Files[0].FILE_URL
            }
        },
    },
    methods: {
        addTeacher() {
            // Kiểm tra các trường bắt buộc
            const requiredFields = [this.HocViHocHam, this.HoTen, this.CoQuan, this.DiaChi, this.SoDienThoai, this.NganhSelect]
            if (requiredFields.some((field) => !field)) {
                Vue.$toast.error(`Không được bỏ trống các trường thông tin giảng viên`, { position: 'top' })
                return
            }

            // Tìm giảng viên trùng lặp
            const existingTeacher = this.DsGiangVien.find(
                (item) => item.HoTenGiangVien === this.HoTen.trim() && item.HocViHocHam === this.HocViHocHam.trim() && item.NganhGiangDay === getNganhName(this.NganhSelect),
            )

            // Dữ liệu giảng viên
            const teacherData = {
                HocViHocHam: this.HocViHocHam.trim(),
                HoTenGiangVien: this.HoTen.trim(),
                CoQuanCongTac: this.CoQuan.trim(),
                CoQuanCongTacTiengViet: this.CoQuanCongTacTiengViet.trim(),
                NganhID: this.NganhSelect,
                NganhGiangDay: getNganhName(this.NganhSelect),
                DiaChi: this.DiaChi,
                SoDienThoai: this.SoDienThoai,
                
                TenNganHang: this.NganHangName,
                SoTKNganHang: this.SoTaiKhoan,
                MaSoThue: this.MaSoThue,
                Email_GV: this.Email,
                FileVanBang_ID: this.FileVanBangID,
                FileVanBang_Name: this.FileVanBangName,
                FileVanBang_Url: this.FileVanBangUrl,
                FileLyLichKH_ID: this.FileLyLichID,
                FileLyLichKH_Name: this.FileLyLichName,
                FileLyLichKH_Url: this.FileLyLichUrl,
            }

            const handleSuccess = () => {
                Vue.$toast.success(`Thêm giảng viên thành công`, { position: 'top' })
                CALL('getDsGiangVien')
                this.closeDialog()
            }

            const handleError = (error) => {
                Vue.$toast.error(`${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
                console.log('Fail to add teacher')
            }

            // Nếu giảng viên đã tồn tại
            if (existingTeacher) {
                confirm({
                    title: 'Giảng viên này đã tồn tại, bạn có chắc muốn thêm giảng viên này?',
                    action: () => ajaxCALL('/giangvien_ins', teacherData, handleSuccess, handleError),
                })
            } else {
                ajaxCALL('/giangvien_ins', teacherData, handleSuccess, handleError)
            }
        },

        loadheDaoTao() {
            ajaxCALL(
                '/hedaotao_get',
                null,
                (res) => {
                    this.DsHeDaoTao = res.data
                },
                (error) => {
                    Vue.$toast.error(` ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
                    console.log('Fail to load he dao tao', error)
                },
            )
        },

        closeDialog() {
            vueData.isAddTeacherDialog = false
            this.HocViHocHam = ''
            this.HoTen = ''
            this.CoQuan = ''
            this.NganhSelect = null
        },
        deleteVanBangFile() {
            this.VanBang_Upload = null
            this.FileVanBangID = null
            this.FileVanBangName = null
            this.FileVanBangUrl = null
        },
        deleteLyLichFile() {
            this.LyLich_Upload = null
            this.FileLyLichID = null
            this.FileLyLichName = null
            this.FileLyLichUrl = null
        },
    },
	}
</script>