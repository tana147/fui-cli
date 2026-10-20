<template>
    <v-dialog v-model="isDialogSQD" transition="dialog-bottom-transition" max-width="1400" persistent="">
        <v-card>
            <v-toolbar color="success" dark class="toolbar">
                <h3 class="mb-0">Cấp SQĐ</h3>
                <v-spacer></v-spacer>
                <v-icon @click="$emit('update:isDialogSQD', false)">mdi-close</v-icon>
            </v-toolbar>
            <v-card-title></v-card-title>
            <v-card-text>
                <v-row>
                    <v-col cols="2">
                        <v-text-field
                            label="SQĐ"
                            placeholder="Nhập ngày cấp SQĐ"
                            v-model="vueData.detailDecision.Decision_SoQD"
                            dense
                            outlined
                            hide-details
                            color="success"
                            :disabled="vueData.detailDecision.Decision_Status === HasSQDStatus"
                        />
                    </v-col>
                    <v-col cols="2">
                        <c-text-field-sqd
                            outlined
                            dense
                            :ngay.sync="vueData.detailDecision.Decision_NgayQD"
                            :thang.sync="vueData.detailDecision.Decision_ThangQD"
                            :nam.sync="vueData.detailDecision.Decision_NamQD"
                            label="Ngày cấp SQĐ"
                            color="success"
                            hint="Ví dụ: Nhập 28/02/2024 theo cú pháp: 28022024"
                            hide-details
                            :disabled="vueData.detailDecision.Decision_Status === HasSQDStatus"
                        />
                    </v-col>
                </v-row>

                <v-row class="p-0">
                    <v-col>
                        <h3>File QĐ giao đề tài</h3>
                    </v-col>
                </v-row>

                <v-row>
                    <v-col>
                        <div class="d-flex">
                            <div cols="2">
                                <f-file-upload
                                    label=""
                                    :url="vueData.v_Set.apiFile"
                                    :filters="fileRules"
                                    color="v-btn--outlined v-size--default info--text"
                                    @input="uploadFile"
                                    hide-details
                                />
                            </div>

                            <div v-if="vueData.detailDecision.Decision_Status !== HasSQDStatus" class="ml-3" style="margin-top: 2px">
                                <v-chip v-if="vueData.detailDecision.DecisionFile_ID" color="deep-purple accent-4" outlined label hide-details close @click:close="deleteFile">
                                    <v-icon left>mdi-file-check-outline</v-icon>
                                    <a style="color: deep-purple accent-4" :href="vueData.v_Set.urlReadFile + vueData.detailDecision.DecisionFile_Url" target="_blank">{{
                                        vueData.detailDecision.DecisionFile_Name ?? fileName
                                    }}</a>
                                </v-chip>
                                <v-chip v-else color="deep-purple accent-4" outlined label hide-details> Chưa upload file </v-chip>
                            </div>

                            <div v-else style="margin-top: 2px" class="ml-3">
                                <v-chip v-if="vueData.detailDecision.DecisionFile_ID" color="deep-purple accent-4" outlined label hide-details>
                                    <v-icon left>mdi-file-check-outline</v-icon>
                                    <a style="color: deep-purple accent-4" :href="vueData.v_Set.urlReadFile + vueData.detailDecision.DecisionFile_Url" target="_blank">{{
                                        vueData.detailDecision.DecisionFile_Name ?? fileName
                                    }}</a>
                                </v-chip>
                                <v-chip v-else color="deep-purple accent-4" outlined label hide-details> Chưa upload file </v-chip>
                            </div>
                        </div>
                    </v-col>
                </v-row>

                <!-- Danh sách file QĐ -->
                <div v-if="FileQDList.length > 0" class="mt-3">
                    <v-row class="p-0">
                        <v-col>
                            <h3>Các file QĐ đã từng upload</h3>
                        </v-col>
                    </v-row>

                    <div class="ml-0 d-flex align-items-center flex-wrap gap-2 mt-3">
                        <v-chip class="ml-0 mr-3" v-for="(file, index) in FileQDList" :key="index" color="gray accent-4" outlined label>
                            <v-icon left>mdi-file-check-outline</v-icon>
                            <a style="color: gray" :href="vueData.v_Set.urlReadFile + file.DecisionFile_Url" target="_blank">
                                {{ file.DecisionFile_Name }}
                            </a>
                        </v-chip>
                    </div>

                    <br />
                </div>

                <v-row>
                    <v-col>
                        <student-detail-table :studentlist="vueData.detailStudent" />
                    </v-col>
                </v-row>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <!-- <v-btn class="info" @click="onPrint"> <v-icon class="mr-1 mb-1">mdi-printer</v-icon>In </v-btn> -->
                <v-btn class="success" @click="onUpdateSQD(vueData.detailDecision)"><v-icon class="mr-1 mb-1">mdi-content-save</v-icon>Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['isDialogSQD'],
    data() {
        return {
            typeList: ['Thạc sĩ', 'Tiến sĩ'],
            HasSQDStatus: 3,
            fileRules: {
                max_file_size: '100mb',
                mime_types: [
                    {
                        title: 'All files',
                        extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg',
                    },
                ],
            },
        }
    },
    computed: {
        heDaoTaoValues() {
            // Chuyển đổi mảng heDaoTao thành mảng chứa các giá trị VALUE
            return vueData.heDaoTao.map((item) => item.VALUE)
        },
        FileQDList() {
            return vueData.FileList.filter((item, index) => index !== vueData.FileList.length - 1 && item.DecisionFile_ID)
        },
    },
    watch: {},
    methods: {
        deleteFile() {
            vueData.detailDecision.DecisionFile_ID = null
            vueData.detailDecision.DecisionFile_Url = null
            vueData.detailDecision.DecisionFile_Name = null
            this.fileName = null
        },
        uploadFile(value) {
            console.log('Upload file api', value)
            let file = value.Files[0]
            vueData.detailDecision.DecisionFile_ID = file.FILE_ID
            vueData.detailDecision.DecisionFile_Url = file.FILE_URL
            vueData.detailDecision.DecisionFile_Name = file.FILE_NAME
            this.fileName = file.FILE_NAME
        },
        onPrint() {
            vueData.getDecisionId = vueData.detailDecision.Decision_ID
            console.log('vueData.getDecisionId zzzzzzzz', vueData.detailDecision.Decision_ID, vueData.detailDecision.Decision_Type)
            htmlToPdf(vueData.detailDecision.Decision_ID, vueData.detailDecision.Decision_Type)
            this.onUpdateSQD(vueData.detailDecision)
            vueData.isDetailDialog = false
            vueData.Tab_SoQuyetDinh = 1
        },
        onUpdateSQD(Decision) {
            const $this = this
            console.log('vueData.detailDecision', vueData.detailDecision)
            console.log("XXXXXX", Decision)
            if (vueData.detailDecision.Decision_SoQD !== '') {
                if (vueData.detailDecision.Decision_NgayQD !== '' && vueData.detailDecision.Decision_ThangQD !== '' && vueData.detailDecision.Decision_NamQD !== '') {
                    ajaxCALL(
                        '/Decision_Upd_SoQD',
                        {
                            Decision_ID: Decision.Decision_ID,
                            Decision_SoQD: vueData.detailDecision.Decision_SoQD,
                            Decision_NgayQD: vueData.detailDecision.Decision_NgayQD,
                            Decision_ThangQD: vueData.detailDecision.Decision_ThangQD,
                            Decision_NamQD: vueData.detailDecision.Decision_NamQD,
                            DecisionFile_ID: Decision.DecisionFile_ID,
                            DecisionFile_Url: Decision.DecisionFile_Url,
                            DecisionFile_Name: Decision.DecisionFile_Name,
                        },
                        (res) => {
                            Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
                            getDecision()
                            vueData.isDetailDialog = false
                        },
                        (error) => {
                            console.log('Update SQD error', error)
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        },
                    )
                } else {
                    Vue.$toast.error(`Không được bỏ trống Ngày cấp SQĐ`, { position: 'top' })
                }
            } else {
                Vue.$toast.error(`Không được bỏ trống SQĐ`, { position: 'top' })
            }
        },
    },
}
</script>
