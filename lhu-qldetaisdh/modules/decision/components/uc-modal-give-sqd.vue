<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="1400" persistent>
    <v-card class="d-flex flex-column decision-modal-card-standard uc-decision-scope">
      <v-toolbar color="success" dark class="uc-decision-toolbar flex-grow-0 flex-shrink-0">
        <h3 class="mb-0">Cấp Số Quyết Định</h3>
        <v-spacer></v-spacer>
        <v-btn icon dark @click="close">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-toolbar>

      <v-card-text class="mt-3 flex-grow-1 d-flex flex-column overflow-hidden">
        <div class="flex-grow-0 flex-shrink-0">
          <v-row class="pt-4">
            <v-col cols="2">
              <v-text-field v-model="localDecision.Decision_SoQD" label="SQĐ" placeholder="Nhập số quyết định" dense
                outlined hide-details color="success" :disabled="localDecision.Decision_Status === HasSQDStatus" />
            </v-col>
            <v-col cols="3">
              <!-- Global custom component for date input -->
              <c-text-field-sqd :ngay.sync="localDecision.Decision_NgayQD" :thang.sync="localDecision.Decision_ThangQD"
                :nam.sync="localDecision.Decision_NamQD" outlined dense label="Ngày cấp SQĐ" color="success"
                hint="Ví dụ: Nhập 28/02/2024 theo cú pháp: 28022024" hide-details
                :disabled="localDecision.Decision_Status === HasSQDStatus" />
            </v-col>
            <v-col cols="2">
              <v-text-field v-model="localDecision.Decision_Type" label="Loại Quyết Định" dense outlined hide-details
                color="success" disabled />
            </v-col>
          </v-row>

          <v-row class="mt-3">
            <v-col>
              <h3>File quyết định</h3>
            </v-col>
          </v-row>

          <v-row>
            <v-col>
              <c-file-comp :item-des="decisionFileWrapper" :api-file="apiFileUploadUrl"
                :url-read-file="fileReadUrl" :allow-upload="true" @on-file-change="onFileChange" />
            </v-col>
          </v-row>

          <!-- Previous files history -->
          <div v-if="previousFilesList.length > 0" class="mt-3">
            <v-row>
              <v-col>
                <h3>Các file QĐ đã từng upload</h3>
              </v-col>
            </v-row>

            <div class="d-flex align-center flex-wrap mt-2">
              <v-chip v-for="(file, index) in previousFilesList" :key="index" color="grey-lighten-4"
                class="text-grey mr-2 mb-2" outlined label>
                <v-icon left>mdi-file-check-outline</v-icon>
                <a class="text-grey text-decoration-none" :href="fileReadUrl + file.DecisionFile_Url" target="_blank">
                  {{ file.DecisionFile_Name }}
                </a>
              </v-chip>
            </div>
          </div>
        </div>

        <!-- Student list detail table -->
        <div class="flex-grow-1 flex-shrink-1 d-flex flex-column overflow-hidden mt-4">
          <uc-student-detail-table :studentlist="detailStudent" class="flex-grow-1 d-flex flex-column" />
        </div>
      </v-card-text>

      <v-card-actions class="px-4 pb-4 flex-grow-0 flex-shrink-0">
        <v-spacer></v-spacer>
        <v-btn color="success" @click="handleSave">
          <v-icon left>mdi-content-save</v-icon>Lưu
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-give-sqd",
  props: {
    value: {
      type: Boolean,
      default: false,
    },
    detailDecision: {
      type: Object,
      default: () => ({}),
    },
    detailStudent: {
      type: Array,
      default: () => [],
    },
    fileList: {
      type: Array,
      default: () => [],
    },
  },
  emits: ["input", "on-save"],
  data() {
    return {
      localDecision: {},
      fileName: "",
      HasSQDStatus: 3,
      tempUploadedFileIds: [],
      fileRules: {
        max_file_size: "100mb",
        mime_types: [
          {
            title: "All files",
            extensions: "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg",
          },
        ],
      },
      decisionFileWrapper: {
        File_ID: null,
        File_URL: null,
        File_Name: null,
        FILE_UPLOAD: null,
      },
    };
  },
  computed: {
    dialog: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
    fileReadUrl() {
      return window.vueData?.v_Set?.urlReadFile || "https://file.lhu.edu.vn/qldetaisdh/";
    },
    apiFileUploadUrl() {
      return window.vueData?.v_Set?.apiFile || "https://file.lhu.edu.vn/qldetaisdh/upload/FileData";
    },
    previousFilesList() {
      return this.fileList.filter(
        (item, index) => index !== this.fileList.length - 1 && item.DecisionFile_ID
      );
    },
  },
  watch: {
    value(val) {
      if (val) {
        this.tempUploadedFileIds = [];
        this.localDecision = JSON.parse(JSON.stringify(this.detailDecision));
        this.fileName = this.localDecision.DecisionFile_Name || "";
        this.resetDecisionFile();
      } else {
        this.cleanupTempFiles();
      }
    },
  },
  beforeDestroy() {
    this.cleanupTempFiles();
  },
  methods: {
    resetDecisionFile() {
      const d = this.detailDecision || {};
      this.decisionFileWrapper = {
        File_ID: d.DecisionFile_ID || null,
        File_URL: d.DecisionFile_Url || null,
        File_Name: d.DecisionFile_Name || null,
        FILE_UPLOAD: null,
      };
    },
    async cleanupTempFiles() {
      if (this.tempUploadedFileIds.length > 0) {
        const fileIds = [...this.tempUploadedFileIds];
        this.tempUploadedFileIds = [];
        try {
          await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: fileIds.join(",") });
        } catch (e) {
          console.error("Lỗi xóa file rác:", e);
        }
        if (window.unsavedUploadedFiles) {
          window.unsavedUploadedFiles = window.unsavedUploadedFiles.filter((id) => !fileIds.includes(id));
        }
      }
      this.resetDecisionFile();
      if (this.localDecision) {
        this.localDecision.DecisionFile_ID = this.detailDecision?.DecisionFile_ID || null;
        this.localDecision.DecisionFile_Url = this.detailDecision?.DecisionFile_Url || null;
        this.localDecision.DecisionFile_Name = this.detailDecision?.DecisionFile_Name || null;
        this.fileName = this.detailDecision?.DecisionFile_Name || "";
      }
    },
    async close() {
      await this.cleanupTempFiles();
      this.dialog = false;
    },
    async onFileChange(fileDes) {
      const newFileId = fileDes?.File_ID || null;
      const oldFileId = this.localDecision.DecisionFile_ID;

      // Nếu trước đó trong phiên này đã tải một file tạm khác mà giờ thay thế bằng file mới:
      if (oldFileId && oldFileId !== newFileId && this.tempUploadedFileIds.includes(oldFileId)) {
        try {
          await ajaxCALLPromise("/FILE_FileDelete", { FileID: oldFileId });
        } catch (e) {
          console.error("Lỗi xóa file tạm thay thế:", e);
        }
        this.tempUploadedFileIds = this.tempUploadedFileIds.filter((id) => id !== oldFileId);
        if (window.unsavedUploadedFiles) {
          window.unsavedUploadedFiles = window.unsavedUploadedFiles.filter((id) => id !== oldFileId);
        }
      }

      // Ghi nhận file tạm mới nếu khác với file ban đầu trong DB
      if (newFileId && !this.tempUploadedFileIds.includes(newFileId)) {
        if (newFileId !== this.detailDecision?.DecisionFile_ID) {
          this.tempUploadedFileIds.push(newFileId);
        }
      }

      this.localDecision.DecisionFile_ID = newFileId;
      this.localDecision.DecisionFile_Url = fileDes?.File_URL || null;
      this.localDecision.DecisionFile_Name = fileDes?.File_Name || null;
      this.fileName = fileDes?.File_Name || "";
    },
    handleSave() {
      if (!this.localDecision.Decision_SoQD) {
        Vue.$toast.error("Không được bỏ trống SQĐ", { position: "top" });
        return;
      }
      if (
        !this.localDecision.Decision_NgayQD ||
        !this.localDecision.Decision_ThangQD ||
        !this.localDecision.Decision_NamQD
      ) {
        Vue.$toast.error("Không được bỏ trống Ngày cấp SQĐ", { position: "top" });
        return;
      }

      // File mới được lưu chính thức, gỡ khỏi danh sách tạm cần dọn
      const savedFileId = this.localDecision.DecisionFile_ID;
      if (savedFileId) {
        this.tempUploadedFileIds = this.tempUploadedFileIds.filter((id) => id !== savedFileId);
        if (window.unsavedUploadedFiles) {
          window.unsavedUploadedFiles = window.unsavedUploadedFiles.filter((id) => id !== savedFileId);
        }
      }

      this.cleanupTempFiles();
      this.$emit("on-save", this.localDecision);
    },
  },
	}
</script>