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
              <c-file-comp :item-des="decisionFileWrapper"
                :lock="localDecision.Decision_Status === HasSQDStatus ? 0 : 1" :api-file="apiFileUploadUrl"
                :url-read-file="fileReadUrl" :allow-upload="localDecision.Decision_Status !== HasSQDStatus" />
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
          <uc-student-detail-table :studentlist="detailStudent" />
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
      return window.vueData?.v_Set?.urlReadFile || "";
    },
    apiFileUploadUrl() {
      return window.vueData?.v_Set?.apiFile || "";
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
        this.localDecision = JSON.parse(JSON.stringify(this.detailDecision));
        this.fileName = this.localDecision.DecisionFile_Name || "";
      }
    },
    localDecision: {
      handler(val) {
        if (val) {
          this.decisionFileWrapper.File_ID = val.DecisionFile_ID;
          this.decisionFileWrapper.File_URL = val.DecisionFile_Url;
          this.decisionFileWrapper.File_Name = val.DecisionFile_Name;
        }
      },
      immediate: true,
      deep: true,
    },
    decisionFileWrapper: {
      handler(val) {
        if (val) {
          this.localDecision.DecisionFile_ID = val.File_ID;
          this.localDecision.DecisionFile_Url = val.File_URL;
          this.localDecision.DecisionFile_Name = val.File_Name;
        }
      },
      deep: true,
    },
  },
  methods: {
    close() {
      this.dialog = false;
    },
    deleteFile() {
      this.localDecision.DecisionFile_ID = null;
      this.localDecision.DecisionFile_Url = null;
      this.localDecision.DecisionFile_Name = null;
      this.fileName = "";
    },
    uploadFile(val) {
      if (val && val.Files && val.Files.length > 0) {
        const file = val.Files[0];
        this.localDecision.DecisionFile_ID = file.FILE_ID;
        this.localDecision.DecisionFile_Url = file.FILE_URL;
        this.localDecision.DecisionFile_Name = file.FILE_NAME;
        this.fileName = file.FILE_NAME;
      }
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
      this.$emit("on-save", this.localDecision);
    },
  },
	}
</script>