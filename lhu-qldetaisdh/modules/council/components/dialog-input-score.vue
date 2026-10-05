<template>
	<div>
		<v-dialog v-model="vueData.isInputDialog" transition="dialog-bottom-transition" max-width="1600px" persistent>
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">
							Nhập điểm HV:
							<span class="red--text">[{{ thongTinHocVien.Student_ID }}] {{ thongTinHocVien.Ho_SV }}
								{{ thongTinHocVien.Ten_SV }}
								[{{ thongTinHocVien.Lop_ID }}] <v-chip v-if="isPublished"
									color="primary">Đã công bố điểm</v-chip>
							</span>
						</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-row>
						<v-col cols="12" class="p-0 pb-0">
							<h3>Biên bản họp</h3>
							<file-comp-custom :publishstatus="isPublished ? 1 : 0" :getdiem="getdiem"
								:item="hoiDongObj" @on-file-uploaded="onFileUploaded"></file-comp-custom>
						</v-col>
						<v-col cols="12" class="p-0 pb-0 pt-0">
							<div>
								<h3>Biển bản kiểm phiếu</h3>
								<file-comp-custom-KD :publishstatus="isPublished ? 1 : 0" :getdiem="getdiem"
									:item="hoiDongObj" @on-file-uploaded="onFileUploaded"></file-comp-custom-KD>
							</div>
						</v-col>
						<v-col cols="12" class="p-0 pb-0 pt-0">
							<v-textarea auto-grow rows="1" placeholder="Nhập ghi chú" label="Ghi chú"
								v-model="hoiDongObj.NhanXet" outlined dense hide-details
								:readonly="isPublished && !isSystemAdmin" />
						</v-col>
						<v-col class="pb-0">
							<div>
								<v-data-table :headers="headertable" :items="dsHoiDong" hide-default-footer dense>
									<template v-slot:item.stt="{ item, index }">
										{{ index + 1 }}
									</template>
									<template v-slot:item.FileNhanXet="{ item, index }">
										<file-comp class="ml-14" :getdiem="getdiem && getdiem[1] ? getdiem[1][index] : null" :item="item" @on-file-uploaded="onFileUploaded" />
									</template>
									<template v-slot:item.FileDiem="{ item, index }">
										<file-comp-diem class="ml-14" :getdiem="getdiem && getdiem[1] ? getdiem[1][index] : null" :item="item" @on-file-uploaded="onFileUploaded" />
									</template>
									<template v-slot:item.NhanXet="{ item, index }">
										<v-textarea hide-details outlined dense auto-grow rows="1"
											v-model="item.NhanXet" :readonly="(isPublished || item.Is_PublishDiem === 1) && !isSystemAdmin" />
									</template>
									<template v-slot:item.Diem="{ item, index }">
										<v-text-field reverse outlined hide-details dense v-model="item.Diem"
											type="number" :hint="item.Data_Exp" @input="updateDiem(item)"
											@blur="formatDiem(item)" :readonly="(isPublished || item.Is_PublishDiem === 1) && !isSystemAdmin" />
									</template>
								</v-data-table>

								<div class="d-flex mt-2 justify-end">
									<div class="d-flex justify-center align-center">
										<h3>Điểm trung bình: {{ ' ' }}</h3>
										<h3 class="red--text ml-1">{{ isNaN(DiemTrungBinh) ? 0.0 : DiemTrungBinh }}</h3>
									</div>
								</div>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<!-- Khi chưa công bố điểm -->
					<v-btn v-if="!isPublished" color="success" :loading="isSaving" @click="onSave"> Lưu tạm </v-btn>
					<v-btn v-if="!isPublished" color="warning" :loading="isPublishing" @click="publicScore"> Công bố điểm </v-btn>
					<!-- Khi đã công bố điểm: cho phép SystemRight = 1 cập nhật điểm -->
					<v-btn v-if="isPublished && isSystemAdmin" color="success" :loading="isSaving" @click="onSave"> Cập nhật điểm </v-btn>
					<!-- Khi đã công bố điểm: cho phép cập nhật file scan -->
					<v-btn v-if="isPublished" color="primary" :loading="isUpdatingFiles" @click="onUpdateFileScan"> Cập nhật file scan </v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ['editedItem', 'dshoidonggiangvien', 'getdiem', 'dshoidongId'],
	    data() {
	        return {
	            flagNhanXet: 0,
	            flagKiemDinh: 1,
	            arr: [],
	            test: null,
	            dsHoiDong: [],
	            isUpdatingFiles: false,
	            isSaving: false,
	            isPublishing: false,
	            tempUploadedFiles: [],
	            initialSnapshot: {
	                hdNhanXet: null,
	                hdKiemPhieu: null,
	                tvMap: {}
	            },
	            hoiDongObj: {
	                DiemHoiDong: 0,
	                FileNhanXetID: null,
	                FileNhanXetName: null,
	                Is_PublishDiem: 0,
	                FileKiemPhieuID: null,
	                FileKiemPhieuName: null,
	                FILE_UPLOAD: {
	                    File_Name: null,
	                    File_ID: null,
	                    File_Type: null,
	                    File_URL: null,
	                },
	                FILE_UPLOAD_1: {
	                    File_Name: null,
	                    File_ID: null,
	                    File_Type: null,
	                    File_URL: null,
	                },
	                NhanXet: null,
	            },
	
	            headertable: [
	                {
	                    text: 'STT',
	                    value: 'stt',
	                    sortable: false,
	                    align: 'center',
	                    class: 'sttCol',
	                },
	                {
	                    text: 'Thành viên',
	                    value: 'HoTenHocHamHocVi',
	                    class: 'customCol2',
	                    width: 180,
	                },
	                {
	                    text: 'Chức trách',
	                    value: 'ChucTrach',
	                    class: 'chucTrachWrap',
	                    width: 120,
	                },
	                {
	                    text: 'File nhận xét',
	                    value: 'FileNhanXet',
	                    class: 'cmtFileInput',
	                    align: 'center',
	                    sortable: false,
	                    width: 50,
	                },
	                {
	                    text: 'File Điểm',
	                    value: 'FileDiem',
	                    class: 'cmtFileInput',
	                    align: 'center',
	                    sortable: false,
	                    width: 50,
	                },
	                {
	                    text: 'Điểm ',
	                    value: 'Diem',
	                    align: 'center',
	                    width: '100',
	                    sortable: false,
	                },
	                {
	                    text: 'Ghi chú',
	                    value: 'NhanXet',
	                    align: 'center',
	                    width: 200,
	                },
	            ],
	        }
	    },
	    mounted() {
	        window.addEventListener('beforeunload', this.cleanupUnsavedFiles);
	    },
	    beforeDestroy() {
	        window.removeEventListener('beforeunload', this.cleanupUnsavedFiles);
	        this.cleanupUnsavedFiles();
	    },
	    computed: {
	        isSystemAdmin() {
	            const user = window.vueData?.user || (typeof vueData !== 'undefined' ? vueData?.user : null);
	            const right = user?.SystemRight ?? user?.systemRight ?? user?.system_right;
	            return Number(right) === 2 || Number(right) === 9;
	        },
	        isPublished() {
	            const fromHoiDong = this.hoiDongObj?.Is_PublishDiem === 1;
	            const fromEdited = this.editedItem?.Is_PublishDiem === 1;
	            const fromDsHoiDong = this.dshoidongId?.Is_PublishDiem === 1;
	            const fromGetDiem = this.getdiem?.[0]?.[0]?.Is_PublishDiem === 1;
	            return fromHoiDong || fromEdited || fromDsHoiDong || fromGetDiem;
	        },
	        DiemTrungBinh() {
	            let sum = 0;
	            const filterDiem = this.dsHoiDong.filter((item) => item.Diem && parseFloat(item.Diem) > 0);
	
	            filterDiem.forEach((item) => {
	                sum += parseFloat(item.Diem ?? 0);
	            });
	
	            const sumTrungBinh = filterDiem.length > 0 ? (sum / filterDiem.length) : 0;
	            this.hoiDongObj.DiemHoiDong = sumTrungBinh;
	            return sumTrungBinh.toFixed(2);
	        },
	        thongTinHocVien() {
	            return this.editedItem || {};
	        },
	        isInpScoreModel() {
	            return vueData.isInputDialog;
	        },
	    },
	    watch: {
	        getdiem: {
	            handler(val) {
	                if (val) {
	                    this.initDialogData();
	                }
	            },
	            deep: true,
	            immediate: true
	        },
	        dshoidonggiangvien: {
	            handler(val) {
	                if (val && (!this.getdiem || !this.getdiem[1] || this.getdiem[1].length === 0)) {
	                    this.initDialogData();
	                }
	            },
	            deep: true
	        },
	        isInpScoreModel: function (val) {
	            if (val) {
	                this.initDialogData();
	            }
	        },
	    },
	    methods: {
	        initDialogData() {
	            if (!this.getdiem || !Array.isArray(this.getdiem) || this.getdiem.length < 2) {
	                return;
	            }
	
	            // 1. Map Hội đồng chung (Recordset 0)
	            const hdData = this.getdiem[0]?.[0] || {};
	            const nxId = hdData.FileNhanXetID ?? null;
	            const nxName = hdData.FileNhanXetName ?? null;
	            const kpId = hdData.FileKiemPhieuID ?? null;
	            const kpName = hdData.FileKiemPhieuName ?? null;
	
	            this.hoiDongObj = {
	                DiemHoiDong: hdData.DiemHoiDong ?? 0,
	                FileNhanXetID: nxId,
	                FileNhanXetName: nxName,
	                Is_PublishDiem: hdData.Is_PublishDiem ?? (this.dshoidongId?.Is_PublishDiem ?? 0),
	                FileKiemPhieuID: kpId,
	                FileKiemPhieuName: kpName,
	                FILE_UPLOAD: {
	                    File_Name: nxName,
	                    File_ID: nxId,
	                    File_Type: null,
	                    File_URL: nxId ? (`/FileData/${nxId}`) : null,
	                },
	                FILE_UPLOAD_1: {
	                    File_Name: kpName,
	                    File_ID: kpId,
	                    File_Type: null,
	                    File_URL: kpId ? (`/FileData/${kpId}`) : null,
	                },
	                NhanXet: hdData.NhanXet ?? null,
	            };
	
	            // 2. Map Danh sách thành viên (Recordset 1)
	            let tvList = [];
	            if (this.getdiem[1] && Array.isArray(this.getdiem[1]) && this.getdiem[1].length > 0) {
	                tvList = this.sortThanhVien(this.getdiem[1]);
	            } else if (this.dshoidonggiangvien && Array.isArray(this.dshoidonggiangvien)) {
	                tvList = this.sortThanhVien(this.dshoidonggiangvien);
	            }
	
	            this.dsHoiDong = tvList.filter(item => item.GiangVienID || item.TVHDID).map((item) => {
	                const hoTen = item.HoTenHocHamHocVi || ((item.HocViHocHam ? item.HocViHocHam + '. ' : '') + (item.HoTenGiangVien || ''));
	                const fileNxId = item.FileNhanXetID ?? null;
	                const fileNxName = item.FileNhanXetName ?? null;
	                const fileDiemId = item.FileDiemID ?? null;
	                const fileDiemName = item.FileDiemName ?? null;
	
	                return {
	                    ...item,
	                    HoTenHocHamHocVi: hoTen,
	                    Diem: item.Diem !== null && item.Diem !== undefined && item.Diem !== '' ? Number(item.Diem) : null,
	                    NhanXet: item.NhanXet ?? '',
	                    FileNhanXetID: fileNxId,
	                    FileNhanXetName: fileNxName,
	                    FileDiemID: fileDiemId,
	                    FileDiemName: fileDiemName,
	                    FILE_UPLOAD: {
	                        File_Name: fileNxName,
	                        File_ID: fileNxId,
	                        File_Type: null,
	                        File_URL: fileNxId ? (`/FileData/${fileNxId}`) : null,
	                    },
	                    FILE_UPLOAD_DIEM: {
	                        File_Name: fileDiemName,
	                        File_ID: fileDiemId,
	                        File_Type: null,
	                        File_URL: fileDiemId ? (`/FileData/${fileDiemId}`) : null,
	                    },
	                };
	            });
	
	            // 3. Chụp snapshot để đối chiếu xóa file cũ
	            this.captureInitialSnapshot();
	        },
	        onFileUploaded(fileId) {
	            if (fileId) {
	                if (!this.tempUploadedFiles.includes(fileId)) {
	                    this.tempUploadedFiles.push(fileId);
	                }
	                if (!window.unsavedUploadedFiles) {
	                    window.unsavedUploadedFiles = [];
	                }
	                if (!window.unsavedUploadedFiles.includes(fileId)) {
	                    window.unsavedUploadedFiles.push(fileId);
	                }
	            }
	        },
	        captureInitialSnapshot() {
	            window.unsavedUploadedFiles = [];
	            this.tempUploadedFiles = [];
	
	            const hdNhanXet = this.hoiDongObj?.FileNhanXetID ?? (this.getdiem?.[0]?.[0]?.FileNhanXetID ?? null);
	            const hdKiemPhieu = this.hoiDongObj?.FileKiemPhieuID ?? (this.getdiem?.[0]?.[0]?.FileKiemPhieuID ?? null);
	            const tvMap = {};
	            if (this.dsHoiDong && Array.isArray(this.dsHoiDong)) {
	                this.dsHoiDong.forEach(tv => {
	                    const tvId = tv.TVHDID || tv.GiangVienID;
	                    if (tvId) {
	                        tvMap[tvId] = {
	                            fileNhanXet: tv.FileNhanXetID ?? null,
	                            fileDiem: tv.FileDiemID ?? null
	                        };
	                    }
	                });
	            }
	            this.initialSnapshot = {
	                hdNhanXet,
	                hdKiemPhieu,
	                tvMap
	            };
	        },
	        getOldReplacedFileIds() {
	            const oldFileIds = [];
	            const init = this.initialSnapshot;
	
	            if (init.hdNhanXet && init.hdNhanXet !== this.hoiDongObj.FileNhanXetID) {
	                oldFileIds.push(init.hdNhanXet);
	            }
	            if (init.hdKiemPhieu && init.hdKiemPhieu !== this.hoiDongObj.FileKiemPhieuID) {
	                oldFileIds.push(init.hdKiemPhieu);
	            }
	            if (init.tvMap) {
	                this.dsHoiDong.forEach(tv => {
	                    const tvId = tv.TVHDID || tv.GiangVienID;
	                    const initTv = init.tvMap[tvId];
	                    if (initTv) {
	                        if (initTv.fileNhanXet && initTv.fileNhanXet !== tv.FileNhanXetID) {
	                            oldFileIds.push(initTv.fileNhanXet);
	                        }
	                        if (initTv.fileDiem && initTv.fileDiem !== tv.FileDiemID) {
	                            oldFileIds.push(initTv.fileDiem);
	                        }
	                    }
	                });
	            }
	            return [...new Set(oldFileIds.filter(Boolean))];
	        },
	        async cleanupUnsavedFiles() {
	            let filesToDelete = [];
	            if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
	                filesToDelete = [...window.unsavedUploadedFiles];
	            } else if (this.tempUploadedFiles && this.tempUploadedFiles.length > 0) {
	                filesToDelete = [...this.tempUploadedFiles];
	            }
	
	            if (filesToDelete.length > 0) {
	                const uniqueFileIds = [...new Set(filesToDelete.filter(Boolean))];
	                if (uniqueFileIds.length > 0) {
	                    try {
	                        await ajaxCALLPromise('/FILE_FileDeleteMulti', { FileIDs: uniqueFileIds.join(',') });
	                    } catch (e) {
	                        console.error('Lỗi xóa file rác upload tạm:', e);
	                    }
	                }
	                window.unsavedUploadedFiles = [];
	                this.tempUploadedFiles = [];
	            }
	        },
	        sortThanhVien(arr) {
	            if (!Array.isArray(arr)) return arr;
	
	            if (arr.length === 3) {
	                const order = ["Chủ tịch", "Phản biện", "Thư ký"];
	                return arr.slice().sort((a, b) => {
	                    return order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach);
	                });
	            }
	
	            if (arr.length === 5) {
	                const order = ["Chủ tịch", "Phản biện 1", "Phản biện 2", "Ủy viên", "Thư ký"];
	                return arr.slice().sort((a, b) => {
	                    return order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach);
	                });
	            }
	
	            return arr;
	        },
	        updateDiem(item) {
	            item.Diem = Number(item.Diem);
	        },
	        formatDiem(item) {
	            item.Diem = Number(item.Diem).toFixed(2);
	        },
	        async closeDialog() {
	            await this.cleanupUnsavedFiles();
	            vueData.isInputDialog = false;
	        },
	        async onSave() {
	            this.isSaving = true;
	            try {
	                await ajaxCALLPromise('/HoiDong_GiangVien_Upd_Diem', {
	                    HoiDongID: this.thongTinHocVien.HoiDongID,
	                    StudentID: this.thongTinHocVien.Student_ID,
	                    DiemHoiDongObj: this.hoiDongObj,
	                    HoiDongThanhVienObj_Arr: this.dsHoiDong,
	                });
	
	                // Xóa file cũ bị thay thế nếu có
	                const oldFileIds = this.getOldReplacedFileIds();
	                if (oldFileIds.length > 0) {
	                    try {
	                        await ajaxCALLPromise('/FILE_FileDeleteMulti', { FileIDs: oldFileIds.join(',') });
	                    } catch (err) {
	                        console.error("Lỗi xóa file cũ sau lưu tạm:", err);
	                    }
	                }
	
	                // Nếu đã công bố và là admin, đồng bộ lại điểm đã công bố vào flow
	                if (this.isPublished && this.isSystemAdmin) {
	                    await ajaxCALLPromise('/HoiDong_Pub_Diem', {
	                        HoiDong_ID: this.thongTinHocVien.HoiDongID,
	                        Student_ID: this.thongTinHocVien.Student_ID,
	                    });
	                }
	
	                window.unsavedUploadedFiles = [];
	                this.tempUploadedFiles = [];
	
	                Vue.$toast.success(this.isPublished ? 'Cập nhật điểm thành công' : 'Nhập điểm thành công', { position: 'top' });
	                vueData.isInputDialog = false;
	            } catch (error) {
	                const msg = error?.responseJSON?.Message || error?.Response?.Message || (this.isPublished ? 'Lỗi cập nhật điểm' : 'Lỗi lưu điểm');
	                Vue.$toast.error(msg, { position: 'top' });
	                console.error('Fail to input score', error);
	            } finally {
	                this.isSaving = false;
	            }
	        },
	        async onUpdateFileScan() {
	            this.isUpdatingFiles = true;
	            try {
	                await ajaxCALLPromise('/HoiDong_Upd_FileScan', {
	                    HoiDongID: this.thongTinHocVien.HoiDongID,
	                    StudentID: this.thongTinHocVien.Student_ID,
	                    DiemHoiDongObj: this.hoiDongObj,
	                    HoiDongThanhVienObj_Arr: this.dsHoiDong,
	                });
	
	                // Xóa các file cũ đã bị thay thế
	                const oldFileIds = this.getOldReplacedFileIds();
	                if (oldFileIds.length > 0) {
	                    try {
	                        await ajaxCALLPromise('/FILE_FileDeleteMulti', { FileIDs: oldFileIds.join(',') });
	                    } catch (err) {
	                        console.error("Lỗi xóa file cũ sau cập nhật:", err);
	                    }
	                }
	
	                window.unsavedUploadedFiles = [];
	                this.tempUploadedFiles = [];
	
	                Vue.$toast.success('Cập nhật file scan thành công', { position: 'top' });
	                vueData.isInputDialog = false;
	            } catch (error) {
	                const msg = error?.responseJSON?.Message || error?.Response?.Message || 'Lỗi cập nhật file scan';
	                Vue.$toast.error(msg, { position: 'top' });
	                console.error('Fail to update file scan', error);
	            } finally {
	                this.isUpdatingFiles = false;
	            }
	        },
	        async publicScore() {
	            let checkHDThanhVien = true;
	            if (this.hoiDongObj.FileKiemPhieuID === null && this.hoiDongObj.FileNhanXetID === null) {
	                Vue.$toast.error('Chưa đủ file biên bản', { position: 'top' });
	                return;
	            }
	            this.dsHoiDong.find((item) => {
	                if (item.FileNhanXetID === null) {
	                    Vue.$toast.error(`Giảng viên ${item.HoTenHocHamHocVi} chưa có file nhận xét`, { position: 'top' });
	                    checkHDThanhVien = false;
	                    return;
	                }
	                if (item.Diem === null || item.Diem === '') {
	                    Vue.$toast.error(`Giảng viên ${item.HoTenHocHamHocVi} chưa nhập điểm`, { position: 'top' });
	                    checkHDThanhVien = false;
	                    return;
	                }
	            });
	
	            if (!checkHDThanhVien) {
	                return;
	            }
	
	            this.isPublishing = true;
	            try {
	                // 1. Lưu điểm trước
	                await ajaxCALLPromise('/HoiDong_GiangVien_Upd_Diem', {
	                    HoiDongID: this.thongTinHocVien.HoiDongID,
	                    StudentID: this.thongTinHocVien.Student_ID,
	                    DiemHoiDongObj: this.hoiDongObj,
	                    HoiDongThanhVienObj_Arr: this.dsHoiDong,
	                });
	
	                // Xóa file cũ nếu có thay thế
	                const oldFileIds = this.getOldReplacedFileIds();
	                if (oldFileIds.length > 0) {
	                    try {
	                        await ajaxCALLPromise('/FILE_FileDeleteMulti', { FileIDs: oldFileIds.join(',') });
	                    } catch (err) {
	                        console.error("Lỗi xóa file cũ sau công bố:", err);
	                    }
	                }
	                window.unsavedUploadedFiles = [];
	                this.tempUploadedFiles = [];
	
	                // 2. Gọi công bố điểm
	                await ajaxCALLPromise('/HoiDong_Pub_Diem', {
	                    HoiDong_ID: this.thongTinHocVien.HoiDongID,
	                    Student_ID: this.thongTinHocVien.Student_ID,
	                });
	
	                Vue.$toast.success('Công bố điểm thành công', { position: 'top' });
	                vueData.isInputDialog = false;
	            } catch (error) {
	                const msg = error?.responseJSON?.Message || error?.Response?.Message || 'Lỗi công bố điểm';
	                Vue.$toast.error(msg, { position: 'top' });
	                console.error('Fail to public score', error);
	            } finally {
	                this.isPublishing = false;
	            }
	        },
	    },
	}
</script>