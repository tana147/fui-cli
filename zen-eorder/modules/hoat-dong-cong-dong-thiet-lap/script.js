function getDSNam(n) {
    for (let i = 0; i < n; i++) {
        let obj = {
            text: "Năm ",
            value: null
        }
        obj.text += new Date().getFullYear() - i
        obj.value = new Date().getFullYear() - i
        vueData.DSNam.push(obj)
    }
}
function uploadFile(file) {
    if (vueData.filelist.length == 0) {
        vueData.filelist = file
    } else {
        vueData.filelist = [...vueData.filelist, ...file]
    }
}
function init() {
    vueData.uploadFile = uploadFile
    vueData.handleClick = handleClick
    vueData.HandleMultipleImage = HandleMultipleImage
    vueData.DeleteImage = DeleteImage
}
function handleClick(item, index) {
    vueData.overlay1 = true
    vueData.indexImg = index
}
async function HandleMultipleImage() {
    if (!vueData.filelist || vueData.filelist.length == 0) return
    let res = null
    for (let i = 0; i < vueData.filelist.length; i++) {
        res = await new Promise((resolve, reject) => {
            ajaxCALL("/eorder/HoatDongCongDongHinhAnh_Insert", {
                HoatDongCongDongID: vueData.HoatDongCongDongID,
                FileID: vueData.filelist[i].FileID
            }, res => {
                resolve(res)
            }, error => {
                reject(error)
            })
        })
    }
    if (res) {
        Vue.$toast.success('Thêm mới thành công!', { position: "top" })
        vueData.dialogTable = false
        vueData.filelist = []
        CALL("LoadDSHinhAnhHoatDongCongDong")
    }
}
function DeleteImage(item) {
    confirm({
        title: "Bạn có chắc chắn muốn xoá ?",
        action: function () {
            ajaxCALL("/eorder/HoatDongCongDongHinhAnh_Delete", {
                HoatDongCongDong_HinhAnhID: item.HoatDongCongDong_HinhAnhID
            }, res => {
                if (res) {
                    Vue.$toast.success('Xóa thành công!', { position: "top" })
                    CALL("LoadDSHinhAnhHoatDongCongDong")
                }
            }, error => {
            })
        }
    });
}
Vue.component('f-file-upload-2', {
    props: {
        multiple: {
            type: Boolean,
            default: false
        },
        label: {
            type: String,
            default: 'file upload'
        },
        url: {
            type: String,
            default: ''
        },
        autoclose: {
            type: Boolean,
            default: true
        },
        iconText: {
            type: String,
            default: "mdi-cloud-upload-outline"
        },
        filters: {
            type: Object,
            default: {
                max_file_size: '5mb',
                mime_types: [{ title: "All files", extensions: "*" }]
            }
        },
        resize: {
            type: Object,
            default: {
                width: 1900,
                height: 1600,
                quality: 80
            }
        },
        onclose: {
            default: undefined
        },
    },
    template: `
            <v-btn :id="elID" v-bind="$attrs">
                <v-icon v-if="iconText" :left="label != ''">{{iconText}}</v-icon>{{label}}
                <v-dialog v-model="dialog" persistent width="450">
                    <v-card>
                        <v-card-actions>
                            Upload file
                            <v-spacer></v-spacer>
                            <v-btn :loading="loading" icon @click="dialog = false; UploadingError = []; UploadingFile = [];" ><v-icon>mdi-close</v-icon></v-btn>
                        </v-card-actions>
                        <v-sheet v-if="UploadingError.length>0" color="error" dark class="py-2">
                            <v-card-text class="py-1 px-4" v-for="(t, i) in UploadingError" :key="i">
                                <div><b>{{t.file.name}}</b></div>
                                <div>{{t.message}}</div>
                            </v-card-text>
                        </v-sheet>
                        <v-sheet v-if="UploadingFile.length>0" class="pb-2">
                            <v-card-text class="py-1 px-4" v-for="(t, i) in UploadingFile" :key="i">
                                <v-card-subtitle class="pa-0" >{{t.percent}}% - {{t.name}}</v-card-subtitle>
                                <v-progress-linear :value="t.percent" class="mb-2 mt-1"></v-progress-linear>
                            </v-card-text>
                        </v-sheet>
                    </v-card>
                </v-dialog>
            </v-btn>
        `,
    data: function () {
        return {
            dialog: false,
            loading: true,
            UploadingFile: [],
            UploadingError: [],
            elID: generateID(),
            uploader: null,
            filesUploaded: []
        }
    },
    mounted: function () {
        this.uploaderInit();
    },
    methods: {
        uploaderInit: function () {
            var thisObj = this;
            var uploader = new plupload.Uploader({
                runtimes: 'html5,html4',
                browse_button: thisObj.elID,
                headers: {
                    authorization: 'Bearer ' + getCookie('awt'),
                    uploaddata: Date.now()
                },
                resize: thisObj.resize,
                filters: thisObj.filters,
                init: {
                    PostInit: function () { },
                    OptionChanged: function (up, name, value, oldValue) { },
                    BeforeUpload: function (up, file) {
                        uploader.settings.url = thisObj.url;
                    },
                    FilesAdded: function (up, files) {
                        thisObj.dialog = true;
                        thisObj.UploadingFile = files;
                        thisObj.filesUploaded = [];
                        uploader.start();
                    },
                    FileUploaded: function (up, file, result) {
                        result = JSON.parse(result.response);
                        json_data_parse(result, 0);
                        if (thisObj.multiple) {
                            thisObj.filesUploaded.push(result.Files[0])
                        } else {
                            thisObj.filesUploaded = result;
                        }
                    },
                    UploadComplete: function (up, files) {
                        if (thisObj.filesUploaded) thisObj.$emit('input', thisObj.filesUploaded);
                        else thisObj.$emit('input', files);
                        if (thisObj.UploadingError.length == 0 && thisObj.autoclose) thisObj.dialog = false;
                        thisObj.loading = false;
                    },
                    UploadProgress: function (up, file) { },
                    Error: function (up, err) {
                        thisObj.loading = false;
                        if (err.status == 500) {
                            err.message = JSON.parse(err.response).message;
                        }
                        thisObj.dialog = true;
                        thisObj.UploadingError.push(err);
                    }
                }
            });
            uploader.init();
            thisObj.uploader = uploader;
        }
    },
    watch: {
        dialog: function (newVal, oldVal) {
            if (!newVal && this.onclose) {
                runAction(this.onclose);
            }
        },
        filters: {
            deep: true,
            handler(newVal) {
                this.uploader.setOption("filters", newVal)
                var ext = newVal.mime_types[0].extensions.replace(/([ ]*)/gm, "")
                ext = "." + ext.replace(/,+/gm, ",.")
                $('#' + this.elID).parent().find('.moxie-shim > input[type="file"]').attr("accept", ext);
            }
        }
    }
});